module Api.GetLanguages exposing (..)

import Bindings
import Http
import Json.Decode


decoder : Json.Decode.Decoder (List Bindings.Language)
decoder =
    Json.Decode.list Bindings.languageDecoder


get : {} -> (Result Http.Error (List Bindings.Language) -> msg) -> Cmd msg
get args onResponse =
    Http.get
        { url = "http://127.0.0.1:3000/lang"
        , expect = Http.expectJson onResponse decoder
        }
