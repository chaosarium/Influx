module Components.DbgDisplay exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode exposing (decodeString, value)
import Json.Encode exposing (encode)


enableDebug : Bool
enableDebug =
    True


view : String -> a -> Html msg
view title props =
    if enableDebug then
        div [ class "dbg-container-div" ]
            [ details []
                [ summary []
                    [ Html.b [] [ Html.text title ] ]
                , pre [ class "dbg-json-pre" ]
                    [ Html.text (Debug.toString props) ]
                ]
            ]

    else
        text ""
