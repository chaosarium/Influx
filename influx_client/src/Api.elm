module Api exposing (Data(..), stringOfHttpErrMsg)

import Http


type Data value
    = NotAsked
    | Loading
    | Success value
    | Failure Http.Error


stringOfHttpErrMsg : Http.Error -> String
stringOfHttpErrMsg httpError =
    "HTTP error: "
        ++ (case httpError of
                Http.BadUrl e ->
                    "Bad URL: " ++ e

                Http.Timeout ->
                    "Timeout"

                Http.NetworkError ->
                    "Network error"

                Http.BadStatus code ->
                    "Bad response status: " ++ String.fromInt code

                Http.BadBody e ->
                    "Bad response body: " ++ e
           )
