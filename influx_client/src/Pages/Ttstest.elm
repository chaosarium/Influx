module Pages.Ttstest exposing (Model, Msg, page)

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
    = UserClickedButton


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        UserClickedButton ->
            ( model
            , Effect.openWindowDialog "Hello, from Elm!"
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> View Msg
view model =
    { title = "TTS Testing Page"
    , body =
        [ Html.div []
            [ Html.h1 [] [ Html.text "TTS Testing Page" ]

            -- this button shows how to do JS interop
            , Html.button
                [ Html.Events.onClick UserClickedButton
                ]
                [ Html.text "invoke javascript" ]

            -- TODO say hello world using tts
            , Html.button
                []
                [ Html.text "Speak" ]

            -- TODO stop the TTS
            , Html.button
                []
                [ Html.text "Stop speaking" ]

            -- TODO run javascript, get back a list of available tts voices on the current system, and print them to the console"
            , Html.button
                []
                [ Html.text "get voices" ]
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
