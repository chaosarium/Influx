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


unreachableHtml : String -> Html.Html msg
unreachableHtml s =
    Html.div [ Html.Attributes.class "err-unreachable" ]
        [ Html.text ("UNREACHABLE: " ++ s) ]


ruby =
    Html.node "ruby"


rt =
    Html.node "rt"


rtc =
    Html.node "rtc"


rb =
    Html.node "rb"


classIf : Html.Attribute msg -> Bool -> List (Html.Attribute msg) -> List (Html.Attribute msg)
classIf attr cond attrs =
    if cond then
        attr :: attrs

    else
        attrs


htmlEmpty =
    Html.text ""
