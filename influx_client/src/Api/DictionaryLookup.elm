module Api.DictionaryLookup exposing (dictionaryLookup)

import Bindings exposing (WordDefinition, wordDefinitionDecoder)
import Http
import Json.Decode as Decode
import Url.Builder


dictionaryLookup : { dictPath : String, query : String } -> (Result Http.Error (List WordDefinition) -> msg) -> Cmd msg
dictionaryLookup { dictPath, query } toMsg =
    Http.get
        { url =
            Url.Builder.crossOrigin
                "http://127.0.0.1:3000"
                [ "dictionary", "lookup" ]
                [ Url.Builder.string "dict_path" dictPath
                , Url.Builder.string "query" query
                ]
        , expect = Http.expectJson toMsg (Decode.list wordDefinitionDecoder)
        }
