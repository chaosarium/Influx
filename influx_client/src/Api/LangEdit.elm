module Api.LangEdit exposing (edit)

import Bindings exposing (..)
import Http


edit :
    Language
    -> (Result Http.Error Language -> msg)
    -> Cmd msg
edit language onResponse =
    let
        url =
            "http://127.0.0.1:3000/lang/edit"
    in
    Http.post
        { url = url
        , body = Http.jsonBody (languageEncoder language)
        , expect = Http.expectJson onResponse languageDecoder
        }
