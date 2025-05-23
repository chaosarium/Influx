module Api.GetDocuments exposing (..)

import Bindings
import Http
import Json.Decode


decoder : Json.Decode.Decoder (List Bindings.DocEntry)
decoder =
    Json.Decode.list Bindings.docEntryDecoder


get :
    { languageId : String
    }
    -> (Result Http.Error (List Bindings.DocEntry) -> msg)
    -> Cmd msg
get args onResponse =
    let
        url =
            "http://127.0.0.1:3000/docs/" ++ args.languageId
    in
    Http.get
        { url = url
        , expect = Http.expectJson onResponse decoder
        }
