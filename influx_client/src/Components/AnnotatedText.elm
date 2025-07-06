module Components.AnnotatedText exposing (view, viewMultiwordTokenShadows, viewSentenceConstituent)

import Bindings exposing (..)
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
    , focus_predicate : SentenceConstituent -> Bool
    , cst_display_predicate : SentenceConstituent -> Bool
    , doc_cst_display_predicate : DocumentConstituent -> Bool
    }


view :
    Args msg
    -> Datastore.DocContext.T
    -> List (Html msg)
view args doc =
    List.map (viewDocumentConstituent args) doc.constituents


viewDocumentConstituent :
    Args msg
    -> DocumentConstituent
    -> Html msg
viewDocumentConstituent args constituent =
    if not (args.doc_cst_display_predicate constituent) then
        Utils.htmlEmpty

    else
        case constituent of
            Sentence { constituents } ->
                span [ class "sentence-span" ]
                    (List.filterMap (viewSentenceConstituent args) constituents)

            DocumentWhitespace { text } ->
                span [ class "document-whitespace-span" ] [ Html.text text ]


getShadowed : SentenceConstituent -> Bool
getShadowed cst =
    case cst of
        MultiwordToken { shadowed } ->
            shadowed

        SubwordToken { shadowed } ->
            shadowed

        SingleToken { shadowed } ->
            shadowed

        PhraseToken { shadowed } ->
            shadowed

        SentenceWhitespace { shadowed } ->
            shadowed


tokenDictLookup : Datastore.DictContext.T -> String -> Maybe Token
tokenDictLookup dict_ctx orthography =
    Dict.get orthography dict_ctx.tokenDict


phraseDictLookup : Datastore.DictContext.T -> String -> Maybe Phrase
phraseDictLookup dict_ctx orthography =
    Dict.get orthography dict_ctx.phraseDict


viewMultiwordTokenShadow :
    SentenceConstituent
    -> Html msg
viewMultiwordTokenShadow cst =
    let
        attrs =
            []
    in
    case cst of
        MultiwordToken { text } ->
            Utils.unreachableHtml "MultiwordToken within MultiwordToken???"

        SubwordToken { text } ->
            span (attrs ++ [ class "subword-token-span" ]) [ Html.text text ]

        SingleToken { text } ->
            span (attrs ++ [ class "single-token-span" ]) [ Html.text text ]

        PhraseToken _ ->
            Utils.unreachableHtml "phrase within phrase???"

        SentenceWhitespace { text } ->
            span (attrs ++ [ class "sentence-whitespace-span" ]) [ Html.text text ]


viewMultiwordTokenShadows :
    List SentenceConstituent
    -> Html msg
viewMultiwordTokenShadows csts =
    span [ class "multiword-token-shadows-span" ]
        (List.intersperse (span [ class "sentence-whitespace-span" ] [ Html.text " " ]) (List.map viewMultiwordTokenShadow csts))


viewPhraseSubconstituent :
    Args msg
    -> SentenceConstituent
    -> Html msg
viewPhraseSubconstituent args cst =
    let
        attrs =
            [ Utils.attributeIf args.modifier_state.alt <| onMouseEnter (args.mouse_handler (FocusContext.SelectMouseEnter cst))
            , Utils.attributeIf args.modifier_state.alt <| onMouseDown (args.mouse_handler (FocusContext.SelectMouseDown cst))
            , Utils.attributeIf args.modifier_state.alt <| onMouseUp (args.mouse_handler (FocusContext.SelectMouseUp ()))
            , Utils.classIf (args.focus_predicate cst) "tkn-focus"
            ]
    in
    case cst of
        MultiwordToken { text } ->
            span (attrs ++ [ class "multiword-token-span" ]) [ Html.text text ]

        SubwordToken { text } ->
            span (attrs ++ [ class "subword-token-span" ]) [ Html.text text ]

        SingleToken { text } ->
            span (attrs ++ [ class "single-token-span" ]) [ Html.text text ]

        PhraseToken _ ->
            Utils.unreachableHtml "phrase within phrase???"

        SentenceWhitespace { text } ->
            span (attrs ++ [ class "sentence-whitespace-span" ]) [ Html.text text ]


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
    -> SentenceConstituent
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
    -> SentenceConstituent
    -> List SentenceConstituent
    -> Html msg
viewRegisteredPhrase args attrs phrase cst shadows =
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
                (List.map (viewPhraseSubconstituent args) shadows)
            ]
        , rt [] [ Html.text phrase.definition ]
        ]


viewSentenceConstituent :
    Args msg
    -> SentenceConstituent
    -> Maybe (Html msg)
viewSentenceConstituent args cst =
    if (getShadowed cst && args.bypass_shadowned) || not (args.cst_display_predicate cst) then
        Nothing

    else
        Just
            (case cst of
                MultiwordToken { text } ->
                    case tokenDictLookup args.dict text of
                        Nothing ->
                            viewUnregisteredTkn [ class "multiword-token-span" ] text

                        Just tkn ->
                            viewRegisteredTkn args [ class "multiword-token-span" ] text tkn cst

                SubwordToken { text, orthography } ->
                    case tokenDictLookup args.dict orthography of
                        Nothing ->
                            viewUnregisteredTkn [ class "subword-token-span" ] text

                        Just tkn ->
                            viewRegisteredTkn args [ class "subword-token-span" ] text tkn cst

                SingleToken { text, orthography } ->
                    case tokenDictLookup args.dict orthography of
                        Nothing ->
                            viewUnregisteredTkn [ class "single-token-span", class "tkn-nostatus" ] text

                        Just tkn ->
                            viewRegisteredTkn args [ class "single-token-span" ] text tkn cst

                PhraseToken { normalisedOrthography, shadows } ->
                    case phraseDictLookup args.dict normalisedOrthography of
                        Nothing ->
                            unreachableHtml "Phrase not found in dict"

                        Just phrase ->
                            viewRegisteredPhrase args [ class "phrase-span" ] phrase cst shadows

                SentenceWhitespace { text } ->
                    span [ class "sentence-whitespace-span" ] [ Html.text text ]
            )
