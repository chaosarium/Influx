module Components.AnnotatedText exposing (view)

import Bindings exposing (..)
import Datastore.DictContext
import Datastore.DocContext
import Datastore.FocusContext
import Dict
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onMouseDown, onMouseEnter, onMouseOver, onMouseUp)
import Utils exposing (rb, rt, rtc, ruby, unreachableHtml)


view :
    { dict : Datastore.DictContext.T
    , mouse_handler : Datastore.FocusContext.Msg -> msg
    , focus_predicate : SentenceConstituent -> Bool
    }
    -> Datastore.DocContext.T
    -> Html msg
view args doc =
    div [ class "annotated-doc-div" ]
        (List.map (viewDocumentConstituent args) doc.constituents)


viewDocumentConstituent :
    { dict : Datastore.DictContext.T
    , mouse_handler : Datastore.FocusContext.Msg -> msg
    , focus_predicate : SentenceConstituent -> Bool
    }
    -> DocumentConstituent
    -> Html msg
viewDocumentConstituent args constituent =
    case constituent of
        Sentence { constituents } ->
            span [ class "sentence-span" ]
                (List.filterMap (viewSentenceConstituent args) constituents)

        DocumentWhitespace { text } ->
            span [ class "document-whitespace-span" ] [ Html.text text ]


getShadowed : SentenceConstituent -> Bool
getShadowed cst =
    case cst of
        CompositToken { shadowed } ->
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


viewPhraseSubconstituent : Datastore.DictContext.T -> SentenceConstituent -> Html msg
viewPhraseSubconstituent dict_ctx cst =
    case cst of
        CompositToken { text } ->
            span [ class "composit-token-span" ] [ Html.text text ]

        SubwordToken { text } ->
            span [ class "subword-token-span" ] [ Html.text text ]

        SingleToken { text } ->
            span [ class "single-token-span" ] [ Html.text text ]

        PhraseToken _ ->
            Utils.unreachableHtml "phrase within phrase???"

        SentenceWhitespace { text } ->
            span [ class "sentence-whitespace-span" ] [ Html.text text ]


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
    { dict : Datastore.DictContext.T
    , mouse_handler : Datastore.FocusContext.Msg -> msg
    , focus_predicate : SentenceConstituent -> Bool
    }
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
                       , onMouseEnter (args.mouse_handler (Datastore.FocusContext.SelectMouseOver cst))
                       , onMouseDown (args.mouse_handler (Datastore.FocusContext.SelectMouseDown cst))
                       , onMouseUp (args.mouse_handler (Datastore.FocusContext.SelectMouseUp ()))
                       , class "clickable-tkn-span"
                       ]
                    |> Utils.classIf (class "tkn-focus") (args.focus_predicate cst)
                )
                [ Html.text text ]
            ]
        , rt [] [ Html.text tkn.definition ]
        , rtc []
            [ rt [] [ Html.text tkn.phonetic ]
            ]
        ]


viewRegisteredPhrase :
    { dict : Datastore.DictContext.T
    , mouse_handler : Datastore.FocusContext.Msg -> msg
    , focus_predicate : SentenceConstituent -> Bool
    }
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
                    ++ [ onMouseEnter (args.mouse_handler (Datastore.FocusContext.SelectMouseOver cst))
                       , onMouseDown (args.mouse_handler (Datastore.FocusContext.SelectMouseDown cst))
                       , onMouseUp (args.mouse_handler (Datastore.FocusContext.SelectMouseUp ()))
                       , tokenStatusToClass phrase.status
                       ]
                    |> Utils.classIf (class "tkn-focus") (args.focus_predicate cst)
                )
                (List.map (viewPhraseSubconstituent args.dict) shadows)
            ]
        , rt [] [ Html.text phrase.definition ]
        ]


viewSentenceConstituent :
    { dict : Datastore.DictContext.T
    , mouse_handler : Datastore.FocusContext.Msg -> msg
    , focus_predicate : SentenceConstituent -> Bool
    }
    -> SentenceConstituent
    -> Maybe (Html msg)
viewSentenceConstituent args cst =
    if getShadowed cst then
        Nothing

    else
        Just
            (case cst of
                CompositToken { text } ->
                    case tokenDictLookup args.dict text of
                        Nothing ->
                            viewUnregisteredTkn [ class "composit-token-span" ] text

                        Just tkn ->
                            viewRegisteredTkn args [ class "composit-token-span" ] text tkn cst

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
