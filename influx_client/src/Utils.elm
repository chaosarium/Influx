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
    Html.div [ Html.Attributes.class "dbg-unreachable" ]
        [ Html.text ("UNREACHABLE: " ++ s) ]


todoHtml : String -> Html.Html msg
todoHtml s =
    Html.div [ Html.Attributes.class "dbg-todo" ]
        [ Html.text ("TODO: " ++ s) ]


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


maybeIsJust : Maybe a -> Bool
maybeIsJust maybe =
    case maybe of
        Just _ ->
            True

        Nothing ->
            False


maybeSelect : Maybe a -> b -> b -> b
maybeSelect maybe justRet nothingRet =
    case maybe of
        Just _ ->
            justRet

        Nothing ->
            nothingRet
