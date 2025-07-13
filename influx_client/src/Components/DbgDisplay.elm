module Components.DbgDisplay exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode exposing (decodeString, value)
import Json.Encode exposing (encode)
import Utils


enableDebug : Bool
enableDebug =
    False


view : String -> a -> Html msg
view title props =
    if enableDebug then
        div [ class "dbg-container-div" ]
            [ details []
                [ summary []
                    [ Html.b [] [ Html.text title ] ]
                , pre [ class "dbg-json-pre" ]
                    [ Html.text (Utils.dbgToString props) ]
                ]
            ]

    else
        text ""
