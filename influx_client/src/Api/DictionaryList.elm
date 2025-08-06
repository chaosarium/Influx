module Api.DictionaryList exposing (dictionaryList)

import Http
import Json.Decode as Decode
import Url.Builder


dictionaryList : (Result Http.Error (List String) -> msg) -> Cmd msg
dictionaryList toMsg =
    Http.get
        { url =
            Url.Builder.crossOrigin
                "http://127.0.0.1:3000"
                [ "dictionary", "list" ]
                []
        , expect = Http.expectJson toMsg (Decode.list Decode.string)
        }
