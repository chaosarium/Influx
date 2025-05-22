module Components.AnnotatedText exposing (view)

import Bindings exposing (..)
import Html exposing (Html, div, span)
import Html.Attributes exposing (class)


view : AnnotatedDocument -> Html msg
view doc =
    div [ class "annotated-doc-div" ]
        (List.map viewDocumentConstituent doc.constituents)


viewDocumentConstituent : DocumentConstituent -> Html msg
viewDocumentConstituent constituent =
    case constituent of
        Sentence { constituents } ->
            span [ class "sentence-span" ]
                (List.filterMap viewSentenceConstituent constituents)

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


viewSentenceConstituent : SentenceConstituent -> Maybe (Html msg)
viewSentenceConstituent cst =
    if getShadowed cst then
        Nothing

    else
        case cst of
            CompositToken { text } ->
                Just (span [ class "composit-token-span" ] [ Html.text text ])

            SubwordToken { text } ->
                Just (span [ class "subword-token-span" ] [ Html.text text ])

            SingleToken { text } ->
                Just (span [ class "single-token-span" ] [ Html.text text ])

            PhraseToken { text } ->
                Just (span [ class "phrase-token-span" ] [ Html.text text ])

            SentenceWhitespace { text } ->
                Just (span [ class "sentence-whitespace-span" ] [ Html.text text ])
