module Api.DocumentList exposing (..)

import Bindings exposing (DocEntry, docEntryDecoder)
import Http
import Json.Decode


decoder : Json.Decode.Decoder (List DocEntry)
decoder =
    Json.Decode.list docEntryDecoder


getDocuments :
    { languageId : String
    , onResponse : Result Http.Error (List DocEntry) -> msg
    }
    -> Cmd msg
getDocuments options =
    let
        url =
            "http://127.0.0.1:3000/docs/" ++ options.languageId
    in
    Http.get
        { url = url
        , expect = Http.expectJson options.onResponse decoder
        }
