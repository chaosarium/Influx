module Pages.Home_ exposing (Model, Msg, page)

import Components.Topbar
import Effect exposing (Effect)
import Html
import Html.Events
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init () =
    ( {}
    , Effect.none
    )


type Msg
    = Noop


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> View Msg
view model =
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


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
