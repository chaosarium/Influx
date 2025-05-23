module Datastore.DocContext exposing (..)

import Bindings exposing (AnnotatedDocument, DocumentConstituent)


type alias T =
    { text : String
    , constituents : List DocumentConstituent
    , numSentences : Int
    , numTokens : Int
    }


empty : T
empty =
    { text = ""
    , constituents = []
    , numSentences = 0
    , numTokens = 0
    }


fromAnnotatedDocument : AnnotatedDocument -> T
fromAnnotatedDocument annotated_doc =
    { text = annotated_doc.text
    , constituents = annotated_doc.constituents
    , numSentences = annotated_doc.numSentences
    , numTokens = annotated_doc.numTokens
    }
