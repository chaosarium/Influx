module BindingsUtils exposing (..)

import Bindings exposing (..)


getSentenceConstituentOrthography : SentenceConstituent -> String
getSentenceConstituentOrthography sc =
    case sc of
        CompositToken { orthography } ->
            orthography

        SubwordToken { orthography } ->
            orthography

        SingleToken { orthography } ->
            orthography

        SentenceWhitespace { orthography } ->
            orthography

        PhraseToken { normalisedOrthography } ->
            normalisedOrthography


orthographySeqToNormalized : List String -> String
orthographySeqToNormalized orthographySeq =
    orthographySeq |> String.join " "


tokenDefaultUnmarkedToL1 : Token -> Token
tokenDefaultUnmarkedToL1 token =
    case token.status of
        Unmarked ->
            { token | status = L1 }

        _ ->
            token


phraseDefaultUnmarkedToL1 : Phrase -> Phrase
phraseDefaultUnmarkedToL1 phrase =
    case phrase.status of
        Unmarked ->
            { phrase | status = L1 }

        _ ->
            phrase
