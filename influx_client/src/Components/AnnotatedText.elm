module Components.AnnotatedText exposing (AnnotationConfig, AnnotationOption(..), PopupContent(..), view, viewRegisteredPhrase, viewSentenceSegment)

import Bindings exposing (DocSegV2, DocSegVariants(..), Phrase, SentSegV2, SentSegVariants(..), Token, TokenStatus(..))
import Components.Popup as Popup
import Datastore.DictContext
import Datastore.DocContext
import Datastore.FocusContext as FocusContext
import Dict
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, style)
import Html.Attributes.Extra
import Html.Events exposing (onMouseDown, onMouseEnter, onMouseLeave, onMouseUp)
import Json.Decode as Decode
import Utils exposing (rb, rt, rtc, ruby, unreachableHtml)
import Utils.ModifierState as ModifierState


type AnnotationOption
    = Phonetic
    | Definition
    | Lemma
    | Upos
    | Xpos
    | None


type alias AnnotationConfig =
    { topAnnotation : AnnotationOption
    , bottomAnnotation : AnnotationOption
    }


type alias Args msg =
    { dict : Datastore.DictContext.T
    , modifier_state : ModifierState.Model
    , mouse_handler : FocusContext.Msg -> msg
    , focus_predicate : SentSegV2 -> Bool
    , seg_display_predicate : SentSegV2 -> Bool
    , doc_seg_display_predicate : DocSegV2 -> Bool
    , popup_state : Maybe { position : { x : Float, y : Float }, content : PopupContent }
    , on_hover_start : { x : Float, y : Float } -> PopupContent -> msg
    , on_hover_end : msg
    , annotation_config : AnnotationConfig
    }


type PopupContent
    = TokenPopup Token SentSegV2
    | PhrasePopup Phrase SentSegV2


view :
    Args msg
    -> Datastore.DocContext.T
    -> List (Html msg)
view args doc =
    let
        documentSegments =
            List.map (viewDocumentSegment args) doc.segments

        popup =
            case args.popup_state of
                Nothing ->
                    Html.text ""

                Just { position, content } ->
                    Popup.view
                        { isVisible = True
                        , position = position
                        , content = createPopupContent content
                        }
    in
    documentSegments ++ [ popup ]


createPopupContent : PopupContent -> List (Html msg)
createPopupContent content =
    case content of
        TokenPopup token seg ->
            [ div [ class "popup-field" ]
                [ div [ class "popup-label" ] [ Html.text "Word" ]
                , div [ class "popup-value" ] [ Html.text token.orthography ]
                ]
            , div [ class "popup-field" ]
                [ div [ class "popup-label" ] [ Html.text "Definition" ]
                , div [ class "popup-value popup-definition" ] [ Html.text token.definition ]
                ]
            , div [ class "popup-field" ]
                [ div [ class "popup-label" ] [ Html.text "Phonetic" ]
                , div [ class "popup-value" ] [ Html.text token.phonetic ]
                ]
            ]
                ++ (case seg.attributes.lemma of
                        Just lemma ->
                            [ div [ class "popup-field" ]
                                [ div [ class "popup-label" ] [ Html.text "Lemma" ]
                                , div [ class "popup-value popup-lemma" ] [ Html.text lemma ]
                                ]
                            ]

                        Nothing ->
                            []
                   )
                ++ (case seg.attributes.upos of
                        Just pos ->
                            [ div [ class "popup-field" ]
                                [ div [ class "popup-label" ] [ Html.text "Part of Speech" ]
                                , div [ class "popup-value popup-pos" ] [ Html.text pos ]
                                ]
                            ]

                        Nothing ->
                            []
                   )

        PhrasePopup phrase seg ->
            [ div [ class "popup-field" ]
                [ div [ class "popup-label" ] [ Html.text "Phrase" ]
                , div [ class "popup-value" ] [ Html.text (String.join " " phrase.orthographySeq) ]
                ]
            , div [ class "popup-field" ]
                [ div [ class "popup-label" ] [ Html.text "Definition" ]
                , div [ class "popup-value popup-definition" ] [ Html.text phrase.definition ]
                ]
            ]


onHoverWithPosition : (Float -> Float -> msg) -> Html.Attribute msg
onHoverWithPosition toMsg =
    Html.Events.on "mouseenter"
        (Decode.map2 toMsg
            (Decode.at [ "target", "offsetLeft" ] Decode.float)
            (Decode.map2 (+)
                (Decode.at [ "target", "offsetTop" ] Decode.float)
                (Decode.at [ "target", "offsetHeight" ] Decode.float)
            )
        )


doubleRubyC : String -> List (Html.Attribute msg) -> List (Html msg) -> String -> Html msg
doubleRubyC topText mainAttrs mainContent bottomText =
    span
        ([ Html.Attributes.attribute "data-top" topText
         , Html.Attributes.attribute "data-bottom" bottomText
         , class "double-ruby tkn-auto-width"
         ]
            ++ mainAttrs
        )
        mainContent


viewDocumentSegment :
    Args msg
    -> DocSegV2
    -> Html msg
viewDocumentSegment args segment =
    if not (args.doc_seg_display_predicate segment) then
        Utils.htmlEmpty

    else
        case segment.inner of
            Sentence { segments } ->
                span [ class "sentence-span annotated-text-container" ]
                    (List.filterMap (viewSentenceSegment args) segments)

            DocumentWhitespace ->
                span [ class "document-whitespace-span" ] [ Html.text segment.text ]


tokenDictLookup : Datastore.DictContext.T -> String -> Maybe Token
tokenDictLookup dict_ctx orthography =
    Dict.get orthography dict_ctx.tokenDict


phraseDictLookup : Datastore.DictContext.T -> String -> Maybe Phrase
phraseDictLookup dict_ctx orthography =
    Dict.get orthography dict_ctx.phraseDict


getAnnotationText : AnnotationOption -> Maybe Token -> Maybe Phrase -> SentSegV2 -> String
getAnnotationText option maybeToken maybePhrase seg =
    case option of
        None ->
            ""

        Phonetic ->
            case maybeToken of
                Just token ->
                    token.phonetic

                Nothing ->
                    ""

        Definition ->
            case ( maybeToken, maybePhrase ) of
                ( Just token, _ ) ->
                    token.definition

                ( Nothing, Just phrase ) ->
                    phrase.definition

                ( Nothing, Nothing ) ->
                    ""

        Lemma ->
            case seg.attributes.lemma of
                Just lemma ->
                    if lemma /= seg.text then
                        lemma

                    else
                        ""

                Nothing ->
                    ""

        Upos ->
            Maybe.withDefault "" seg.attributes.upos

        Xpos ->
            Maybe.withDefault "" seg.attributes.xpos


viewPhraseSubsegment :
    Args msg
    -> SentSegV2
    -> Html msg
viewPhraseSubsegment args seg =
    let
        attrs =
            [ Utils.attributeIf args.modifier_state.alt <| onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter seg))
            , Utils.attributeIf args.modifier_state.alt <| onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown seg))
            , Utils.attributeIf args.modifier_state.alt <| onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
            , Utils.classIf (args.focus_predicate seg) "tkn-focus"
            ]
    in
    case seg.inner of
        TokenSeg _ ->
            span (attrs ++ [ class "single-token-span" ]) [ Html.text seg.text ]

        WhitespaceSeg ->
            span (attrs ++ [ class "sentence-whitespace-span" ]) [ Html.text seg.text ]

        PunctuationSeg ->
            span (attrs ++ [ class "sentence-punctuation-span" ]) [ Html.text seg.text ]

        PhraseSeg _ ->
            Utils.unreachableHtml "phrase within phrase???"


tokenStatusToClass : TokenStatus -> Html.Attribute msg
tokenStatusToClass status =
    case status of
        Unmarked ->
            class "tkn-unmarked"

        Ignored ->
            class "tkn-ignored"

        L1 ->
            class "tkn-l1"

        L2 ->
            class "tkn-l2"

        L3 ->
            class "tkn-l3"

        L4 ->
            class "tkn-l4"

        L5 ->
            class "tkn-l5"

        Known ->
            class "tkn-known"


{-| When token missing from dictionary context, show error message.
Should not normally happen.
-}
viewUnregisteredTkn : List (Html.Attribute msg) -> String -> Html msg
viewUnregisteredTkn attrs text =
    span attrs [ Html.text (text ++ " [ERR: NO STATUS]") ]


viewRegisteredTkn :
    Args msg
    -> List (Html.Attribute msg)
    -> String
    -> Token
    -> SentSegV2
    -> Html msg
viewRegisteredTkn args attrs text tkn seg =
    let
        topText =
            getAnnotationText args.annotation_config.topAnnotation (Just tkn) Nothing seg

        bottomText =
            getAnnotationText args.annotation_config.bottomAnnotation (Just tkn) Nothing seg
    in
    doubleRubyC
        topText
        (attrs
            ++ [ tokenStatusToClass tkn.status
               , onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter seg))
               , onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown seg))
               , onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
               , onHoverWithPosition (\x y -> args.on_hover_start { x = x, y = y } (TokenPopup tkn seg))
               , onMouseLeave args.on_hover_end
               , class "clickable-tkn-span"
               , Utils.classIf (args.focus_predicate seg) "tkn-focus"
               ]
        )
        [ Html.text text ]
        bottomText


viewRegisteredPhrase :
    Args msg
    -> List (Html.Attribute msg)
    -> Phrase
    -> SentSegV2
    -> List SentSegV2
    -> Html msg
viewRegisteredPhrase args attrs phrase seg components =
    let
        topText =
            getAnnotationText args.annotation_config.topAnnotation Nothing (Just phrase) seg

        bottomText =
            getAnnotationText args.annotation_config.bottomAnnotation Nothing (Just phrase) seg
    in
    doubleRubyC
        topText
        (attrs
            ++ [ Utils.attributeIfNot args.modifier_state.alt <| onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter seg))
               , Utils.attributeIfNot args.modifier_state.alt <| onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown seg))
               , Utils.attributeIfNot args.modifier_state.alt <| onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
               , onHoverWithPosition (\x y -> args.on_hover_start { x = x, y = y } (PhrasePopup phrase seg))
               , onMouseLeave args.on_hover_end
               , tokenStatusToClass phrase.status
               , class "clickable-tkn-span"
               , Utils.classIf (args.focus_predicate seg) "tkn-focus"
               ]
        )
        (List.map (viewPhraseSubsegment args) components)
        bottomText


viewSentenceSegment :
    Args msg
    -> SentSegV2
    -> Maybe (Html msg)
viewSentenceSegment args seg =
    if not (args.seg_display_predicate seg) then
        Nothing

    else
        Just
            (case seg.inner of
                TokenSeg { orthography } ->
                    case tokenDictLookup args.dict orthography of
                        Nothing ->
                            viewUnregisteredTkn [ class "single-token-span", class "tkn-nostatus" ] seg.text

                        Just tkn ->
                            viewRegisteredTkn args [ class "single-token-span" ] seg.text tkn seg

                PhraseSeg { normalisedOrthography, components } ->
                    case phraseDictLookup args.dict normalisedOrthography of
                        Nothing ->
                            unreachableHtml "Phrase not found in dict"

                        Just phrase ->
                            viewRegisteredPhrase args [ class "phrase-span" ] phrase seg components

                WhitespaceSeg ->
                    span [ class "sentence-whitespace-span", Utils.classIf (args.focus_predicate seg) "tkn-focus" ] [ Html.text seg.text ]

                PunctuationSeg ->
                    span
                        [ class "sentence-punctuation-span"
                        , Utils.classIf (args.focus_predicate seg) "tkn-focus"
                        , onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter seg))
                        , onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown seg))
                        , onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
                        , class "clickable-tkn-span"
                        ]
                        [ Html.text seg.text ]
            )
