module Utils.FancyMouse exposing (onAltMouseUp)

import Html
import Html.Events.Extra.Mouse as Mouse


onAltMouseUp : msg -> msg -> Html.Attribute msg
onAltMouseUp msg noop_msg =
    Mouse.onUp
        (\event ->
            if event.keys.alt then
                msg

            else
                noop_msg
        )
