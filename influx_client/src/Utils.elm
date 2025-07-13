module Utils exposing (..)

import Html
import Html.Attributes
import Html.Attributes.Extra
import Html.Extra
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


htmlEmpty =
    Html.text ""


attributeEmpty : Html.Attribute msg
attributeEmpty =
    Html.Attributes.Extra.empty


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


attributeIf : Bool -> Html.Attribute msg -> Html.Attribute msg
attributeIf =
    Html.Attributes.Extra.attributeIf


attributeIfNot : Bool -> Html.Attribute msg -> Html.Attribute msg
attributeIfNot cond attr =
    attributeIf (not cond) attr


classIf : Bool -> String -> Html.Attribute msg
classIf cond class =
    if cond then
        Html.Attributes.class class

    else
        Html.Attributes.Extra.empty


classIfNot : Bool -> String -> Html.Attribute msg
classIfNot cond attr =
    classIf (not cond) attr


htmlIf : Bool -> Html.Html msg -> Html.Html msg
htmlIf cond html =
    Html.Extra.viewIf cond html



-- The following can be enabled for debugging purposes. Do not touch them.


dbgLog : String -> a -> a
dbgLog msg value =
    -- Debug.log msg value
    value


dbgToString : a -> String
dbgToString value =
    -- Debug.toString value
    "debug not enabled"
