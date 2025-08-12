module Api.LangDelete exposing (delete)

import Http


delete :
    String
    -> (Result Http.Error () -> msg)
    -> Cmd msg
delete languageId onResponse =
    let
        url =
            "http://127.0.0.1:3000/lang/delete/" ++ languageId
    in
    Http.post
        { url = url
        , body = Http.emptyBody
        , expect = Http.expectWhatever onResponse
        }
