module Api.DocEdit exposing (edit)

import Bindings exposing (..)
import Http


edit :
    Document
    -> (Result Http.Error Document -> msg)
    -> Cmd msg
edit document onResponse =
    let
        url =
            "http://127.0.0.1:3000/doc/edit"
    in
    Http.post
        { url = url
        , body = Http.jsonBody (documentEncoder document)
        , expect = Http.expectJson onResponse documentDecoder
        }
