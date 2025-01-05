module Pages.User_.Repo_.Tree.Branch_.ALL_ exposing (page)

import Html exposing (Html)
import View exposing (View)


page : { user : String, repo : String, branch : String, all_ : List String } -> View msg
page params =
    { title = "Pages.User_.Repo_.Tree.Branch_.ALL_"
    , body = [ Html.text (params.user ++ params.repo ++ "/tree/" ++ params.branch ++ String.join "/" params.all_) ]
    }
