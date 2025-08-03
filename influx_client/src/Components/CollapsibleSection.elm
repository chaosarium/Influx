module Components.CollapsibleSection exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class)
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
    div [ class "collapsible-section" ]
        [ div
            [ class
                (if config.isExpanded then
                    "collapsible-section__header collapsible-section__header--expanded"

                 else
                    "collapsible-section__header"
                )
            , Html.Events.onClick config.onToggle
            ]
            [ span [ class "collapsible-section__title" ] [ text config.title ]
            , span [ class "collapsible-section__toggle-icon" ]
                [ text
                    (if config.isExpanded then
                        "▼"

                     else
                        "▶"
                    )
                ]
            ]
        , if config.isExpanded then
            div [ class "collapsible-section__content" ] [ config.content ]

          else
            text ""
        ]
