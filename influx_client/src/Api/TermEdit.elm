module Api.TermEdit exposing (..)

import Bindings exposing (..)
import Http


edit :
    TermEditRequest
    -> (Result Http.Error TermEditResponse -> msg)
    -> Cmd msg
edit request onResponse =
    let
        url =
            "http://127.0.0.1:3000/term/edit"
    in
    Http.post
        { url = url
        , body = Http.jsonBody (termEditRequestEncoder request)
        , expect = Http.expectJson onResponse termEditResponseDecoder
        }
