module Components.Popup exposing (Config, view)

import Html exposing (Html, div)
import Html.Attributes exposing (class, style)


{-| Configuration for the popup component
-}
type alias Config msg =
    { isVisible : Bool
    , position : { x : Float, y : Float }
    , content : List (Html msg)
    }


{-| Reusable popup component that can display any HTML content
The popup will be positioned absolutely at the given coordinates
-}
view : Config msg -> Html msg
view config =
    if config.isVisible then
        div
            [ class "popup-container"
            , style "position" "absolute"
            , style "left" (String.fromFloat config.position.x ++ "px")
            , style "top" (String.fromFloat config.position.y ++ "px")
            , style "z-index" "1000"
            ]
            [ div
                [ class "popup-content" ]
                config.content
            ]

    else
        Html.text ""
