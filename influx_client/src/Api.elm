module Api exposing (Data(..), stringOfHttpErrMsg, valueOrUnreachable)

import Html.Styled as Html exposing (Html, a, audio, br, button, div, h1, h2, h3, li, ol, p, span, strong, text, ul)
import Html.Styled.Attributes as Attributes exposing (class, controls, css, href, id, src, style)
import Http
import Utils


type Data value
    = NotAsked
    | Loading
    | Failure Http.Error
    | Success value


valueOrUnreachable : Data value -> (value -> Html msg) -> Html msg
valueOrUnreachable data toHtml =
    case data of
        NotAsked ->
            div [ class "http-status-not-asked" ] [ Html.text "Not asked" ]

        Loading ->
            div [ class "http-status-loading" ] [ Html.text "Loading..." ]

        Failure httpError ->
            div [ class "http-status-failure" ] [ Html.text (stringOfHttpErrMsg httpError) ]

        Success value ->
            toHtml value


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
