module Api.TokenEdit exposing (..)

import Bindings
import Http


create :
    Bindings.Token
    -> (Result Http.Error Bindings.Token -> msg)
    -> Cmd msg
create token onResponse =
    let
        url =
            "http://127.0.0.1:3000/vocab/create_token"
    in
    Http.post
        { url = url
        , body = Http.jsonBody (Bindings.tokenEncoder token)
        , expect = Http.expectJson onResponse Bindings.tokenDecoder
        }


update :
    Bindings.Token
    -> (Result Http.Error Bindings.Token -> msg)
    -> Cmd msg
update token onResponse =
    let
        url =
            "http://127.0.0.1:3000/vocab/update_token"
    in
    Http.post
        { url = url
        , body = Http.jsonBody (Bindings.tokenEncoder token)
        , expect = Http.expectJson onResponse Bindings.tokenDecoder
        }


delete :
    Bindings.Token
    -> (Result Http.Error Bindings.Token -> msg)
    -> Cmd msg
delete token onResponse =
    let
        url =
            "http://127.0.0.1:3000/vocab/delete_token"
    in
    Http.post
        { url = url
        , body = Http.jsonBody (Bindings.tokenEncoder token)
        , expect = Http.expectJson onResponse Bindings.tokenDecoder
        }
