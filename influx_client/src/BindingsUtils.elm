module BindingsUtils exposing (..)

import Bindings exposing (..)


getSentenceSegmentOrthography : SentSegV2 -> String
getSentenceSegmentOrthography sc =
    case sc.inner of
        TokenSeg { orthography } ->
            orthography

        WhitespaceSeg ->
            sc.text

        PhraseSeg { normalisedOrthography } ->
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
