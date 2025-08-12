module Api.DocDelete exposing (delete)

import Http


delete :
    String
    -> (Result Http.Error () -> msg)
    -> Cmd msg
delete documentId onResponse =
    let
        url =
            "http://127.0.0.1:3000/doc/delete/" ++ documentId
    in
    Http.post
        { url = url
        , body = Http.emptyBody
        , expect = Http.expectWhatever onResponse
        }
