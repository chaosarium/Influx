module Components.ResizableSidebar exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events
import Json.Decode as Decode


{-| A resizable sidebar component with collapse functionality.

Usage:
ResizableSidebar.view
{ width = 400
, isCollapsed = False
, title = "Sidebar Title"
, onStartResize = StartResize
, onToggleCollapse = ToggleSidebar
, content = [ ... ]
}

-}
view :
    { width : Float
    , isCollapsed : Bool
    , title : String
    , onStartResize : Float -> msg
    , onToggleCollapse : msg
    , content : List (Html msg)
    }
    -> Html msg
view config =
    if config.isCollapsed then
        div
            [ class "resizable-sidebar--collapsed" ]
            [ button
                [ class "resizable-sidebar__toggle-btn"
                , Html.Events.onClick config.onToggleCollapse
                ]
                [ text "◀" ]
            ]

    else
        div
            [ class "resizable-sidebar"
            , style "width" (String.fromFloat config.width ++ "px")
            ]
            [ div
                [ class "resizable-sidebar__resize-handle"
                , Html.Events.on "mousedown"
                    (Decode.map config.onStartResize (Decode.field "clientX" Decode.float))
                ]
                []
            , div [ class "resizable-sidebar__content" ]
                [ div [ class "resizable-sidebar__header" ]
                    [ span [ class "resizable-sidebar__title" ] [ text config.title ]
                    , button
                        [ class "resizable-sidebar__toggle-btn"
                        , Html.Events.onClick config.onToggleCollapse
                        ]
                        [ text "▶" ]
                    ]
                , div [ class "resizable-sidebar__sections" ] config.content
                ]
            ]
