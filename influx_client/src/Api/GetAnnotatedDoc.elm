module Api.GetAnnotatedDoc exposing (..)

import Bindings
import Http
import Json.Decode


decoder : Json.Decode.Decoder Bindings.GetDocResponse
decoder =
    Bindings.getDocResponseDecoder


get :
    { filepath : String
    }
    -> (Result Http.Error Bindings.GetDocResponse -> msg)
    -> Cmd msg
get args onResponse =
    let
        url =
            "http://127.0.0.1:3000/doc/" ++ args.filepath
    in
    Http.get
        { url = url
        , expect = Http.expectJson onResponse decoder
        }
