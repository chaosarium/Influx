module Utils exposing (..)

import Html.Parser
import Html.Parser.Util
import Html.Styled as Html exposing (Attribute, Html)
import Html.Styled.Attributes as Attributes
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


unreachableHtml : String -> Html msg
unreachableHtml s =
    Html.div [ Attributes.class "dbg-unreachable" ]
        [ Html.text ("UNREACHABLE: " ++ s) ]


todoHtml : String -> Html msg
todoHtml s =
    Html.div [ Attributes.class "dbg-todo" ]
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


attributeEmpty : Attribute msg
attributeEmpty =
    Attributes.attribute "data-empty" ""


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


attributeIf : Bool -> Attribute msg -> Attribute msg
attributeIf cond attr =
    if cond then
        attr

    else
        attributeEmpty


attributeIfNot : Bool -> Attribute msg -> Attribute msg
attributeIfNot cond attr =
    attributeIf (not cond) attr


classIf : Bool -> String -> Attribute msg
classIf cond class =
    if cond then
        Attributes.class class

    else
        attributeEmpty


classIfNot : Bool -> String -> Attribute msg
classIfNot cond attr =
    classIf (not cond) attr


htmlIf : Bool -> Html msg -> Html msg
htmlIf cond html =
    if cond then
        html

    else
        Html.text ""



-- The following can be enabled for debugging purposes. Do not touch them.


dbgLog : String -> a -> a
dbgLog msg value =
    let
        _ =
            msg
    in
    -- Debug.log msg value
    value


dbgToString : a -> String
dbgToString value =
    let
        _ =
            value
    in
    -- Debug.toString value
    "debug not enabled"


htmlOfString : String -> List (Html msg)
htmlOfString t =
    case Html.Parser.run t of
        Ok nodes ->
            Html.Parser.Util.toVirtualDom nodes
                |> List.map Html.fromUnstyled

        Err _ ->
            [ unreachableHtml ("failed to parse" ++ t) ]
