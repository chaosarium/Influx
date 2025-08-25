module Components.AnnotatedText exposing (AnnotationConfig, AnnotationOption(..), view, viewRegisteredPhrase, viewSentenceSegment)

import Bindings exposing (DocSegV2, DocSegVariants(..), Phrase, SentSegV2, SentSegVariants(..), Token, TokenStatus(..))
import Components.Popover as Popover
import Datastore.DictContext
import Datastore.DocContext
import Datastore.FocusContext as FocusContext
import Dict
import Html.Styled as Html exposing (Attribute, Html, div, span, text)
import Html.Styled.Attributes as Attributes exposing (class, style)
import Html.Styled.Events as Events exposing (onDoubleClick, onMouseDown, onMouseEnter, onMouseUp)
import Json.Decode as Decode
import Utils exposing (attributeIf, attributeIfNot, classIf, rb, rt, rtc, ruby, unreachableHtml)
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
    , on_token_double_click : SentSegV2 -> msg
    , annotation_config : AnnotationConfig
    , showFurigana : Bool
    }


view :
    Args msg
    -> Datastore.DocContext.T
    -> List (Html msg)
view args doc =
    List.map (viewDocumentSegment args) doc.segments


getTokenContent : Bool -> Dict.Dict String String -> String -> List (Html msg)
getTokenContent showFurigana miscAttrs textStr =
    if showFurigana then
        case Dict.get "furigana_ruby" miscAttrs of
            Just furiganaHtml ->
                Utils.htmlOfString furiganaHtml

            Nothing ->
                [ text textStr ]

    else
        [ text textStr ]


doubleRubyC : String -> List (Attribute msg) -> List (Html msg) -> String -> Html msg
doubleRubyC topText mainAttrs mainContent bottomText =
    span
        ([ Attributes.attribute "data-top" topText
         , Attributes.attribute "data-bottom" bottomText
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
        text ""

    else
        case segment.inner of
            Sentence { segments } ->
                span [ class "sentence-span annotated-text-container" ]
                    (List.filterMap (viewSentenceSegment args) segments)

            DocumentWhitespace ->
                span [ class "document-whitespace-span" ] [ text segment.text ]


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
            [ attributeIf args.modifier_state.alt <| onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter seg))
            , attributeIf args.modifier_state.alt <| onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown seg))
            , attributeIf args.modifier_state.alt <| onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
            , classIf (args.focus_predicate seg) "tkn-focus"
            ]
    in
    case seg.inner of
        TokenSeg _ ->
            span (attrs ++ [ class "single-token-span" ]) [ text seg.text ]

        WhitespaceSeg ->
            span (attrs ++ [ class "sentence-whitespace-span" ]) [ text seg.text ]

        PunctuationSeg ->
            span (attrs ++ [ class "sentence-punctuation-span" ]) [ text seg.text ]

        PhraseSeg _ ->
            -- This should not happen normally
            unreachableHtml "phrase within phrase???"


tokenStatusToClass : TokenStatus -> Attribute msg
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
viewUnregisteredTkn : List (Attribute msg) -> String -> Html msg
viewUnregisteredTkn attrs textStr =
    span attrs [ text (textStr ++ " [ERR: NO STATUS]") ]


viewRegisteredTkn :
    Args msg
    -> List (Attribute msg)
    -> String
    -> Token
    -> SentSegV2
    -> Html msg
viewRegisteredTkn args attrs textStr tkn seg =
    let
        topText =
            getAnnotationText args.annotation_config.topAnnotation (Just tkn) Nothing seg

        bottomText =
            getAnnotationText args.annotation_config.bottomAnnotation (Just tkn) Nothing seg

        tokenContent =
            getTokenContent args.showFurigana seg.attributes.misc textStr

        popoverContent =
            Popover.viewTokenPopover tkn seg
    in
    Popover.view
        { content = popoverContent
        , triggerContent =
            [ doubleRubyC
                topText
                (attrs
                    ++ [ tokenStatusToClass tkn.status
                       , onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown seg))
                       , onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
                       , onDoubleClick (args.on_token_double_click seg)
                       , onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter seg))
                       , class "clickable-tkn-span"
                       , classIf (args.focus_predicate seg) "tkn-focus"
                       ]
                )
                tokenContent
                bottomText
            ]
        , triggerAttributes = []
        }


viewRegisteredPhrase :
    Args msg
    -> List (Attribute msg)
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

        phraseContent =
            if args.showFurigana then
                case Dict.get "furigana_ruby" seg.attributes.misc of
                    Just furiganaHtml ->
                        Utils.htmlOfString furiganaHtml

                    Nothing ->
                        List.map (viewPhraseSubsegment args) components

            else
                List.map (viewPhraseSubsegment args) components

        popoverContent =
            Popover.viewPhrasePopover phrase seg
    in
    Popover.view
        { content = popoverContent
        , triggerContent =
            [ doubleRubyC
                topText
                (attrs
                    ++ [ attributeIfNot args.modifier_state.alt <| onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown seg))
                       , attributeIfNot args.modifier_state.alt <| onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
                       , attributeIfNot args.modifier_state.alt <| onDoubleClick (args.on_token_double_click seg)
                       , attributeIfNot args.modifier_state.alt <| onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter seg))
                       , tokenStatusToClass phrase.status
                       , class "clickable-tkn-span"
                       , classIf (args.focus_predicate seg) "tkn-focus"
                       ]
                )
                phraseContent
                bottomText
            ]
        , triggerAttributes = []
        }


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
                    span [ class "sentence-whitespace-span", classIf (args.focus_predicate seg) "tkn-focus" ] [ text seg.text ]

                PunctuationSeg ->
                    span
                        [ class "sentence-punctuation-span"
                        , classIf (args.focus_predicate seg) "tkn-focus"
                        , onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter seg))
                        , onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown seg))
                        , onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
                        , class "clickable-tkn-span"
                        ]
                        [ text seg.text ]
            )
