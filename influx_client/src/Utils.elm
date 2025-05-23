module Utils exposing (..)

import Html
import Html.Attributes
import Url


unwrappedPercentDecode : String -> String
unwrappedPercentDecode s =
    case Url.percentDecode s of
        Just r ->
            r

        Nothing ->
            "error: can't percent decode"


percentEncode : String -> String
percentEncode s =
    Url.percentEncode s


unreachableHtml : Html.Html msg
unreachableHtml =
    Html.div [ Html.Attributes.class "err-unreachable" ]
        [ Html.text "UNREACHABLE" ]


ruby =
    Html.node "ruby"


rt =
    Html.node "rt"


rtc =
    Html.node "rtc"


rb =
    Html.node "rb"
