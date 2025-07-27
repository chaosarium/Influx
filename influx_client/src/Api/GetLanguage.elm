module Api.GetLanguage exposing (get)

import Bindings exposing (..)
import Http
import Json.Decode


get :
    { langId : String }
    -> (Result Http.Error (Maybe Language) -> msg)
    -> Cmd msg
get { langId } onResponse =
    let
        url =
            "http://127.0.0.1:3000/lang/" ++ langId
    in
    Http.get
        { url = url
        , expect = Http.expectJson onResponse (Json.Decode.nullable languageDecoder)
        }
