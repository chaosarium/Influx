module Components.DbgDisplay exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)


view : String -> a -> Html msg
view title props =
    div [ class "dbg-container-div" ]
        [ pre [ class "dbg-json-pre" ]
            [ Html.b []
                [ Html.text (title ++ ": ") ]
            , Html.text (Debug.toString props)
            ]
        ]
