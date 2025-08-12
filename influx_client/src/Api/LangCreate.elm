module Api.LangCreate exposing (create)

import Bindings exposing (..)
import Http


create :
    LanguageCreateRequest
    -> (Result Http.Error Language -> msg)
    -> Cmd msg
create request onResponse =
    let
        url =
            "http://127.0.0.1:3000/lang/create"
    in
    Http.post
        { url = url
        , body = Http.jsonBody (languageCreateRequestEncoder request)
        , expect = Http.expectJson onResponse languageDecoder
        }
