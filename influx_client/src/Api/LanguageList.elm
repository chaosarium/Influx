module Api.LanguageList exposing (..)

import Bindings exposing (LanguageEntry, languageEntryDecoder)
import Http
import Json.Decode


decoder : Json.Decode.Decoder (List LanguageEntry)
decoder =
    Json.Decode.list languageEntryDecoder


getLanguages : { onResponse : Result Http.Error (List LanguageEntry) -> msg } -> Cmd msg
getLanguages options =
    Http.get
        { url = "http://127.0.0.1:3000/lang"
        , expect = Http.expectJson options.onResponse decoder
        }
