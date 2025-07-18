module Components.Topbar exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)


view : {} -> Html msg
view props =
    div [ class "layout" ]
        [ nav [ class "navbar" ]
            [ ul []
                [ li [] [ a [ href "/" ] [ text "Home" ] ]
                , li [] [ a [ href "/langs" ] [ text "Languages" ] ]
                , li [] [ a [ href "/docs" ] [ text "Documents" ] ]
                , li [] [ a [ href "/ttstest" ] [ text "TTSTest" ] ]
                ]
            ]
        ]
