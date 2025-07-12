module Components.AnnotatedText exposing (view, viewRegisteredPhrase, viewSentenceSegment)

import Bindings exposing (DocSegV2, DocSegVariants(..), Phrase, SentSegV2, SentSegVariants(..), Token, TokenStatus(..))
import Datastore.DictContext
import Datastore.DocContext
import Datastore.FocusContext as FocusContext
import Dict
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, style)
import Html.Attributes.Extra
import Html.Events exposing (onMouseDown, onMouseEnter, onMouseUp)
import Utils exposing (rb, rt, rtc, ruby, unreachableHtml)
import Utils.ModifierState as ModifierState


type alias Args msg =
    { dict : Datastore.DictContext.T
    , bypass_shadowned : Bool
    , modifier_state : ModifierState.Model
    , mouse_handler : FocusContext.Msg -> msg
    , focus_predicate : SentSegV2 -> Bool
    , cst_display_predicate : SentSegV2 -> Bool
    , doc_cst_display_predicate : DocSegV2 -> Bool
    }


view :
    Args msg
    -> Datastore.DocContext.T
    -> List (Html msg)
view args doc =
    List.map (viewDocumentSegment args) doc.segments


viewDocumentSegment :
    Args msg
    -> DocSegV2
    -> Html msg
viewDocumentSegment args segment =
    if not (args.doc_cst_display_predicate segment) then
        Utils.htmlEmpty

    else
        case segment.inner of
            Sentence { segments } ->
                span [ class "sentence-span" ]
                    (List.filterMap (viewSentenceSegment args) segments)

            DocumentWhitespace ->
                span [ class "document-whitespace-span" ] [ Html.text segment.text ]


tokenDictLookup : Datastore.DictContext.T -> String -> Maybe Token
tokenDictLookup dict_ctx orthography =
    Dict.get orthography dict_ctx.tokenDict


phraseDictLookup : Datastore.DictContext.T -> String -> Maybe Phrase
phraseDictLookup dict_ctx orthography =
    Dict.get orthography dict_ctx.phraseDict


viewPhraseSubsegment :
    Args msg
    -> SentSegV2
    -> Html msg
viewPhraseSubsegment args cst =
    let
        attrs =
            [ Utils.attributeIf args.modifier_state.alt <| onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter cst))
            , Utils.attributeIf args.modifier_state.alt <| onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown cst))
            , Utils.attributeIf args.modifier_state.alt <| onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
            , Utils.classIf (args.focus_predicate cst) "tkn-focus"
            ]
    in
    case cst.inner of
        TokenSeg { orthography } ->
            span (attrs ++ [ class "single-token-span" ]) [ Html.text cst.text ]

        WhitespaceSeg ->
            span (attrs ++ [ class "sentence-whitespace-span" ]) [ Html.text cst.text ]

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
viewRegisteredTkn args attrs text tkn cst =
    ruby []
        [ rb []
            [ span
                (attrs
                    ++ [ tokenStatusToClass tkn.status
                       , onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter cst))
                       , onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown cst))
                       , onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
                       , class "clickable-tkn-span"
                       , Utils.classIf (args.focus_predicate cst) "tkn-focus"
                       ]
                )
                [ Html.text text ]
            ]
        , rt [] [ Html.text tkn.definition ]
        , rtc []
            [ rt [] [ Html.text tkn.phonetic ]
            ]
        ]


viewRegisteredPhrase :
    Args msg
    -> List (Html.Attribute msg)
    -> Phrase
    -> SentSegV2
    -> List SentSegV2
    -> Html msg
viewRegisteredPhrase args attrs phrase cst components =
    ruby []
        [ rb []
            [ span
                (attrs
                    ++ [ Utils.attributeIfNot args.modifier_state.alt <| onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter cst))
                       , Utils.attributeIfNot args.modifier_state.alt <| onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown cst))
                       , Utils.attributeIfNot args.modifier_state.alt <| onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
                       , tokenStatusToClass phrase.status
                       , Utils.classIf (args.focus_predicate cst) "tkn-focus"
                       ]
                )
                (List.map (viewPhraseSubsegment args) components)
            ]
        , rt [] [ Html.text phrase.definition ]
        ]


viewSentenceSegment :
    Args msg
    -> SentSegV2
    -> Maybe (Html msg)
viewSentenceSegment args cst =
    if not (args.cst_display_predicate cst) then
        Nothing

    else
        Just
            (case cst.inner of
                TokenSeg { orthography } ->
                    case tokenDictLookup args.dict orthography of
                        Nothing ->
                            viewUnregisteredTkn [ class "single-token-span", class "tkn-nostatus" ] cst.text

                        Just tkn ->
                            viewRegisteredTkn args [ class "single-token-span" ] cst.text tkn cst

                PhraseSeg { normalisedOrthography, components } ->
                    case phraseDictLookup args.dict normalisedOrthography of
                        Nothing ->
                            unreachableHtml "Phrase not found in dict"

                        Just phrase ->
                            viewRegisteredPhrase args [ class "phrase-span" ] phrase cst components

                WhitespaceSeg ->
                    span [ class "sentence-whitespace-span" ] [ Html.text cst.text ]
            )
