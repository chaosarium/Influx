module Datastore.DocContext exposing (..)

import Bindings exposing (AnnotatedDocument, DocumentConstituent, InfluxResourceId(..))


type alias T =
    { text : String
    , lang_id : InfluxResourceId
    , constituents : List DocumentConstituent
    , numSentences : Int
    , numTokens : Int
    }


empty : T
empty =
    { text = ""
    , lang_id = SerialId -1 -- placeholder
    , constituents = []
    , numSentences = 0
    , numTokens = 0
    }


fromAnnotatedDocument : InfluxResourceId -> AnnotatedDocument -> T
fromAnnotatedDocument lang_id annotated_doc =
    { text = annotated_doc.text
    , lang_id = lang_id
    , constituents = annotated_doc.constituents
    , numSentences = annotated_doc.numSentences
    , numTokens = annotated_doc.numTokens
    }
