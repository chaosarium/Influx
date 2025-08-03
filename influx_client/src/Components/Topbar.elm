module Components.Topbar exposing (view)

import Components.Common exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)


view : {} -> Html msg
view props =
    nav [ class "navbar" ]
        [ ul []
            [ li [] [ a [ href "/" ] [ text "Home" ] ]
            , li [] [ a [ href "/langs" ] [ text "Languages" ] ]
            , li [] [ a [ href "/docs" ] [ text "Documents" ] ]
            ]
        ]
