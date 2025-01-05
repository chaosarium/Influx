module Pages.Home_ exposing (page)

import Components.Sidebar
import Html
import View exposing (View)


page : View msg
page =
  Components.Sidebar.view
    { title = "Homepage"
    , body = [ Html.text "Hello, world!" ]
    }
