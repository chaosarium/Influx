module Api.GetLanguages exposing (..)

import Bindings
import Http
import Json.Decode


decoder : Json.Decode.Decoder (List Bindings.LanguageEntry)
decoder =
    Json.Decode.list Bindings.languageEntryDecoder


get : { onResponse : Result Http.Error (List Bindings.LanguageEntry) -> msg } -> Cmd msg
get options =
    Http.get
        { url = "http://127.0.0.1:3000/lang"
        , expect = Http.expectJson options.onResponse decoder
        }
