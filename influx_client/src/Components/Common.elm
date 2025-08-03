module Components.Common exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


clickyA : List (Attribute msg) -> List (Html msg) -> Html msg
clickyA attrs children =
    a (attrs ++ [ class "clicky-a" ])
        children
