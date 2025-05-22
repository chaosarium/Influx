module Api.GetAnnotatedDoc exposing (..)

import Bindings
import Http
import Json.Decode


decoder : Json.Decode.Decoder Bindings.GetDocResponse
decoder =
    Bindings.getDocResponseDecoder


get :
    { languageId : String
    , filepath : String
    }
    -> (Result Http.Error Bindings.GetDocResponse -> msg)
    -> Cmd msg
get args onResponse =
    let
        url =
            "http://127.0.0.1:3000/docs/" ++ args.languageId ++ "/" ++ args.filepath
    in
    Http.get
        { url = url
        , expect = Http.expectJson onResponse decoder
        }
