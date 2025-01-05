module Pages.Counter exposing (Model, Msg, page)

import Html exposing (Html)
import Page exposing (Page)
import View exposing (View)
import Html.Events

page : Page Model Msg
page =
    Page.sandbox
        { init = init
        , update = update
        , view = view
        }



-- INIT


type alias Model =
    {counter: Int}


init : Model
init =
    {counter = 0}



-- UPDATE


type Msg
    = UserClickedIncrement
    | UserClickedDecrement


update : Msg -> Model -> Model
update msg model =
    case msg of
        UserClickedIncrement ->
            { model | counter = model.counter + 1 }

        UserClickedDecrement ->
            { model | counter = model.counter - 1 }


-- VIEW


view : Model -> View Msg
view model =
    { title = "Counter" 
    , body =
        [ Html.button 
            [ Html.Events.onClick UserClickedIncrement ]
            [ Html.text "+" ]
        , Html.div [] 
            [ Html.text (String.fromInt model.counter) ]
        , Html.button 
            [ Html.Events.onClick UserClickedDecrement ]
            [ Html.text "-" ]
        ]
    }