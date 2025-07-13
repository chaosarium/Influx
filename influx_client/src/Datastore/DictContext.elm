module Datastore.DictContext exposing (..)

import Bindings exposing (..)
import BindingsUtils exposing (..)
import Dict exposing (Dict)



-- DATA


type alias T =
    { tokenDict : Dict String Token
    , phraseDict : Dict String Phrase
    , lang_id : InfluxResourceId
    }


type alias TestT =
    Dict (List String) Phrase


empty : T
empty =
    { tokenDict = Dict.empty
    , phraseDict = Dict.empty
    , lang_id = SerialId -1 -- placeholder
    }


fromTermDictionary : InfluxResourceId -> TermDictionary -> T
fromTermDictionary lang_id term_dict =
    { tokenDict = term_dict.tokenDict
    , phraseDict = term_dict.phraseDict
    , lang_id = lang_id
    }


lookupToken : T -> String -> Maybe Token
lookupToken dict_ctx token =
    Dict.get token dict_ctx.tokenDict


lookupPhrase : T -> String -> Maybe Phrase
lookupPhrase dict_ctx term =
    Dict.get term dict_ctx.phraseDict


overwriteTerm : T -> Term -> T
overwriteTerm dict_ctx term =
    case term of
        TokenTerm token ->
            { dict_ctx | tokenDict = Dict.insert token.orthography token dict_ctx.tokenDict }

        PhraseTerm phrase ->
            { dict_ctx | phraseDict = Dict.insert (BindingsUtils.orthographySeqToNormalized phrase.orthographySeq) phrase dict_ctx.phraseDict }



-- MESSAGES


type Msg
    = NoOp
