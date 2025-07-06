module Datastore.DictContext exposing (..)

import Bindings exposing (AnnotatedDocument, Phrase, Token)
import BindingsUtils exposing (..)
import Dict exposing (Dict)



-- DATA


type alias T =
    { tokenDict : Dict String Token
    , phraseDict : Dict String Phrase
    }


type alias TestT =
    Dict (List String) Phrase


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


lookupToken : T -> String -> Maybe Token
lookupToken dict_ctx token =
    Dict.get token dict_ctx.tokenDict


lookupPhrase : T -> String -> Maybe Phrase
lookupPhrase dict_ctx term =
    Dict.get term dict_ctx.phraseDict


overwriteToken : T -> Token -> T
overwriteToken dict_ctx token =
    { dict_ctx | tokenDict = Dict.insert token.orthography token dict_ctx.tokenDict }


overwritePhrase : T -> Phrase -> T
overwritePhrase dict_ctx phrase =
    { dict_ctx | phraseDict = Dict.insert (BindingsUtils.orthographySeqToNormalized phrase.orthographySeq) phrase dict_ctx.phraseDict }



-- MESSAGES


type Msg
    = NoOp
