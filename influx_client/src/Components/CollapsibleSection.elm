module Components.CollapsibleSection exposing (view)

import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events


{-| A collapsible section component that displays a header with toggle functionality
and optionally shows content when expanded.

Usage:
    CollapsibleSection.view
        { sectionId = "mySection"
        , title = "My Section"
        , isExpanded = True
        , onToggle = ToggleSection "mySection"
        , content = myContent
        }
-}
view :
    { sectionId : String
    , title : String
    , isExpanded : Bool
    , onToggle : msg
    , content : Html msg
    }
    -> Html msg
view config =
    div [ style "border" "1px solid #ddd", style "margin-bottom" "8px" ]
        [ div
            [ style "background-color" "#f5f5f5"
            , style "padding" "8px 12px"
            , style "cursor" "pointer"
            , style "border-bottom" (if config.isExpanded then "1px solid #ddd" else "none")
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "space-between"
            , Html.Events.onClick config.onToggle
            ]
            [ span [ style "font-weight" "bold", style "font-size" "14px" ] [ text config.title ]
            , span [ style "font-size" "12px" ] [ text (if config.isExpanded then "▼" else "▶") ]
            ]
        , if config.isExpanded then
            div [ style "padding" "12px" ] [ config.content ]
          else
            text ""
        ]