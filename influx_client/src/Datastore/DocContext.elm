module Datastore.DocContext exposing (..)

import Bindings exposing (AnnotatedDocV2, DocSegV2, InfluxResourceId(..))


type alias T =
    { text : String
    , lang_id : InfluxResourceId
    , segments : List DocSegV2
    }


empty : T
empty =
    { text = ""
    , lang_id = SerialId -1 -- placeholder
    , segments = []
    }


fromAnnotatedDocument : InfluxResourceId -> AnnotatedDocV2 -> T
fromAnnotatedDocument lang_id annotated_doc =
    { text = annotated_doc.text
    , lang_id = lang_id
    , segments = annotated_doc.segments
    }
