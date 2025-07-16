module Api.GetDocuments exposing (..)

import Bindings
import Http
import Json.Decode


decoder : Json.Decode.Decoder (List Bindings.DocEntry)
decoder =
    Json.Decode.list Bindings.docEntryDecoder


get :
    { languageId : Maybe Bindings.InfluxResourceId
    }
    -> (Result Http.Error (List Bindings.DocEntry) -> msg)
    -> Cmd msg
get args onResponse =
    Http.post
        { url = "http://127.0.0.1:3000/docs"
        , body = Http.jsonBody (Bindings.getDocsRequestEncoder { languageId = args.languageId })
        , expect = Http.expectJson onResponse decoder
        }
