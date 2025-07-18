module BindingsUtils exposing (..)

import Bindings exposing (..)


getSentenceSegmentOrthography : SentSegV2 -> String
getSentenceSegmentOrthography sc =
    case sc.inner of
        TokenSeg { orthography } ->
            orthography

        PhraseSeg { normalisedOrthography } ->
            normalisedOrthography

        WhitespaceSeg ->
            sc.text

        PunctuationSeg ->
            sc.text


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


influxResourceIdToString : InfluxResourceId -> String
influxResourceIdToString id =
    case id of
        SerialId intId ->
            String.fromInt intId

        StringId stringId ->
            stringId
