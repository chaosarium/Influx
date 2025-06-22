module Utils.FancyMouse exposing (onAltMouseUp)

import Html
import Html.Events.Extra.Mouse as Mouse



-- onAltMouseUp : msg -> Html.Attribute msg
-- onAltMouseUp msg =
--     Mouse.onUp
--         (\event ->
--             if event.altKey then
--                 msg
--             else
--                 Mouse.NoOp
--         )
-- e.g.
-- Mouse.onDown
--     (\event ->
--         if event.keys.alt then
--             args.mouse_handler (FocusContext.SelectMouseDown cst)
--         else
--             Debug.todo "ah"
--     )
