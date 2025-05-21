module Pages.Home_ exposing (page)

import Components.Topbar
import Html
import View exposing (View)


page : View msg
page =
    { title = "Homepage"
    , body =
        [ Components.Topbar.view {}
        , Html.div []
            [ Html.h1 [] [ Html.text "Home" ]
            , Html.p []
                [ Html.text "This is the home page. There's nothing here yet"
                ]
            ]
        ]
    }
