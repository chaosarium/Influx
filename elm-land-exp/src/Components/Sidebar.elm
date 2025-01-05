module Components.Sidebar exposing (view)

import Html exposing (..)

import Html.Attributes exposing (..)
import View exposing (View)


view : { title : String, body : List (Html msg) } -> View msg
view props =
  { title = props.title
  , body =
    [ div [ class "layout" ]
      [ aside [ class "sidebar" ]
        [ a [ href "/" ] [ text "Home" ]
        , a [ href "elm-land" ] [ text "User" ]
        , a [ href "/elm-land/vscode" ] [ text "Repo" ]
        , a [ href "/settings/account" ] [ text "Settings" ]
        ]
        , div [ class "page" ] props.body
      ]
    ]
  }
