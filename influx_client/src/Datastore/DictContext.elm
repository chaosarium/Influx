module Datastore.DictContext exposing (..)

import Bindings exposing (AnnotatedDocument, Phrase, Token)
import Dict exposing (Dict)


type alias T =
    { tokenDict : Dict String Token
    , phraseDict : Dict String Phrase
    }


empty : T
empty =
    { tokenDict = Dict.empty
    , phraseDict = Dict.empty
    }


fromAnnotatedDocument : Bindings.AnnotatedDocument -> T
fromAnnotatedDocument annotated_doc =
    { tokenDict =
        case annotated_doc.tokenDict of
            Nothing ->
                Dict.empty

            Just tokenDict ->
                tokenDict
    , phraseDict =
        case annotated_doc.phraseDict of
            Nothing ->
                Dict.empty

            Just phraseDict ->
                phraseDict
    }


lookupTerm : T -> String -> Maybe Token
lookupTerm dict_ctx term =
    Dict.get term dict_ctx.tokenDict


lookupPhrase : T -> String -> Maybe Phrase
lookupPhrase dict_ctx term =
    Dict.get term dict_ctx.phraseDict
