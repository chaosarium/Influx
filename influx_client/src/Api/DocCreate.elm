module Api.DocCreate exposing (create)

import Bindings exposing (..)
import Http


create :
    DocumentCreateRequest
    -> (Result Http.Error Document -> msg)
    -> Cmd msg
create request onResponse =
    let
        url =
            "http://127.0.0.1:3000/doc/create"
    in
    Http.post
        { url = url
        , body = Http.jsonBody (documentCreateRequestEncoder request)
        , expect = Http.expectJson onResponse documentDecoder
        }
