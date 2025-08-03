module Components.ResizableSidebar exposing (view)

import Html exposing (..)
import Html.Attributes exposing (style)
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
            [ style "width" "40px"
            , style "background-color" "#fafafa"
            , style "border-left" "1px solid #ddd"
            , style "display" "flex"
            , style "align-items" "flex-start"
            , style "padding" "12px 8px"
            ]
            [ button
                [ style "background" "none"
                , style "border" "none"
                , style "cursor" "pointer"
                , style "font-size" "16px"
                , style "color" "#666"
                , Html.Events.onClick config.onToggleCollapse
                ]
                [ text "◀" ]
            ]
    else
        div
            [ style "width" (String.fromFloat config.width ++ "px")
            , style "min-width" "200px"
            , style "max-width" "800px"
            , style "background-color" "#fafafa"
            , style "border-left" "1px solid #ddd"
            , style "overflow-y" "auto"
            , style "position" "relative"
            ]
            [ div
                [ style "position" "absolute"
                , style "left" "0"
                , style "top" "0"
                , style "width" "4px"
                , style "height" "100%"
                , style "background-color" "#ccc"
                , style "cursor" "col-resize"
                , Html.Events.on "mousedown" 
                    (Decode.map config.onStartResize (Decode.field "clientX" Decode.float))
                ]
                []
            , div [ style "padding" "12px" ] 
                [ div 
                    [ style "display" "flex"
                    , style "justify-content" "space-between"
                    , style "align-items" "center"
                    , style "margin-bottom" "12px"
                    , style "padding-bottom" "8px"
                    , style "border-bottom" "1px solid #ddd"
                    ]
                    [ span [ style "font-weight" "bold", style "color" "#333" ] [ text config.title ]
                    , button
                        [ style "background" "none"
                        , style "border" "none"
                        , style "cursor" "pointer"
                        , style "font-size" "16px"
                        , style "color" "#666"
                        , Html.Events.onClick config.onToggleCollapse
                        ]
                        [ text "▶" ]
                    ]
                , div [] config.content
                ]
            ]