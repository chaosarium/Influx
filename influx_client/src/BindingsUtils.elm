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
