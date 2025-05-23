module Components.AnnotatedText exposing (view)

import Bindings exposing (..)
import Datastore.DictContext
import Datastore.DocContext
import Dict
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, style)
import Utils exposing (rb, rt, rtc, ruby)


view : Datastore.DictContext.T -> Datastore.DocContext.T -> Html msg
view dict_ctx doc_ctx =
    div [ class "annotated-doc-div" ]
        (List.map (viewDocumentConstituent dict_ctx) doc_ctx.constituents)


viewDocumentConstituent : Datastore.DictContext.T -> DocumentConstituent -> Html msg
viewDocumentConstituent dict_ctx constituent =
    case constituent of
        Sentence { constituents } ->
            span [ class "sentence-span" ]
                (List.filterMap (viewSentenceConstituent dict_ctx) constituents)

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
            Utils.unreachableHtml

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


viewUnregisteredTkn : List (Html.Attribute msg) -> String -> Html msg
viewUnregisteredTkn attrs text =
    span attrs [ Html.text (text ++ " [WARNING: NO STATUS]") ]


viewRegisteredTkn : List (Html.Attribute msg) -> String -> Token -> Html msg
viewRegisteredTkn attrs text tkn =
    ruby []
        [ rb []
            [ span
                (List.concat [ attrs, [ tokenStatusToClass tkn.status ] ])
                [ Html.text text ]
            ]
        , rt [] [ Html.text tkn.definition ]
        , rtc []
            [ rt [] [ Html.text tkn.phonetic ]
            ]
        ]


viewSentenceConstituent : Datastore.DictContext.T -> SentenceConstituent -> Maybe (Html msg)
viewSentenceConstituent dict_ctx cst =
    if getShadowed cst then
        Nothing

    else
        Just
            (case cst of
                CompositToken { text } ->
                    case tokenDictLookup dict_ctx text of
                        Nothing ->
                            viewUnregisteredTkn [ class "composit-token-span" ] text

                        Just tkn ->
                            viewRegisteredTkn [ class "composit-token-span" ] text tkn

                SubwordToken { text, orthography } ->
                    case tokenDictLookup dict_ctx orthography of
                        Nothing ->
                            viewUnregisteredTkn [ class "subword-token-span" ] text

                        Just tkn ->
                            viewRegisteredTkn [ class "subword-token-span" ] text tkn

                SingleToken { text, orthography } ->
                    case tokenDictLookup dict_ctx orthography of
                        Nothing ->
                            viewUnregisteredTkn [ class "single-token-span", class "tkn-nostatus" ] text

                        Just tkn ->
                            viewRegisteredTkn [ class "single-token-span" ] text tkn

                PhraseToken { shadows } ->
                    span [ class "phrase-span" ]
                        (List.map (viewPhraseSubconstituent dict_ctx) shadows)

                SentenceWhitespace { text } ->
                    span [ class "sentence-whitespace-span" ] [ Html.text text ]
            )
