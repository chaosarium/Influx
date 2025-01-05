module Pages.User_.Repo_ exposing (page)

import Html exposing (..)
import View exposing (View)


page : { user : String, repo : String } -> View msg
page params =
    { title = "Pages.User_.Repo_"
    , body =
        [ text ("/" ++ params.user ++ "/" ++ params.repo)
        ]
    }