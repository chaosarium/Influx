module Pages.User_ exposing (page)

import Html exposing (Html)
import View exposing (View)


page : { user : String } -> View msg
page params =
    { title = "Pages.User_"
    , body = [  Html.text ("the user is " ++ params.user) ]
    }
