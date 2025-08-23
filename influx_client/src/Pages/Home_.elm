module Pages.Home_ exposing (Model, Msg, page)

import Api.OpenAppDataDir
import Components.Layout
import Css
import Effect exposing (Effect)
import Html.Styled as Html exposing (Html, button, div, h1, p, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events
import Http
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
    = OpenAppDataDir
    | OpenAppDataDirCompleted (Result Http.Error ())


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        OpenAppDataDir ->
            ( model
            , Effect.sendCmd (Api.OpenAppDataDir.openAppDataDir OpenAppDataDirCompleted)
            )

        OpenAppDataDirCompleted result ->
            case result of
                Ok () ->
                    ( model, Effect.none )

                Err _ ->
                    ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> View Msg
view model =
    { title = "Homepage"
    , body =
        Components.Layout.pageLayoutC
            { toastTray = Nothing }
            [ h1 [] [ text "Home" ]
            , p []
                [ text "This is the home page. There's nothing here yet"
                ]
            , button
                [ Html.Styled.Events.onClick OpenAppDataDir
                , css
                    [ Css.backgroundColor (Css.hex "#007bff")
                    , Css.border (Css.px 0)
                    , Css.borderRadius (Css.px 4)
                    , Css.color (Css.hex "#ffffff")
                    , Css.cursor Css.pointer
                    , Css.fontSize (Css.px 14)
                    , Css.padding2 (Css.px 8) (Css.px 16)
                    , Css.hover
                        [ Css.backgroundColor (Css.hex "#0056b3")
                        ]
                    ]
                ]
                [ text "Open App Data Directory" ]
            , p []
                [ text "Amet deserunt sunt do proident voluptate magna voluptate aliqua consectetur. Aliqua deserunt incididunt occaecat cupidatat officia eiusmod dolore in do et proident nisi esse. Cillum non sit do deserunt non et aliqua fugiat nisi. Nulla eiusmod reprehenderit nulla incididunt. Est Lorem proident ex minim dolor aliquip cupidatat commodo adipisicing. Fugiat et mollit elit do voluptate dolore Lorem. Eiusmod magna sunt ipsum dolor excepteur magna mollit esse labore non eiusmod pariatur.\n\nAmet aute laborum mollit irure non sit sit nisi. Cupidatat ea laboris cupidatat aliquip laboris in ex adipisicing eu id excepteur sint et labore. Tempor fugiat quis veniam ex reprehenderit occaecat sit. Dolore non eu Lorem cupidatat ea quis culpa deserunt do amet consequat id velit.\n\nAnim ea reprehenderit elit dolor mollit magna tempor tempor excepteur ad tempor minim magna. Ea culpa do tempor eu mollit mollit laborum adipisicing. Magna sit reprehenderit enim. Excepteur aute occaecat anim ad. Nostrud elit irure fugiat consectetur ipsum culpa fugiat. Minim cillum ipsum Lorem amet sit reprehenderit ex qui exercitation labore ullamco fugiat non. Lorem dolor laboris laboris incididunt velit excepteur quis sit Lorem consequat qui.\n\nMollit ex nisi nisi labore ipsum incididunt voluptate. Mollit aliqua ad ea. Pariatur dolore occaecat do. Veniam non cupidatat excepteur nisi pariatur occaecat nostrud quis enim labore consectetur fugiat sint aute non. Officia culpa ad aliqua officia aliqua elit do ad qui ad veniam laboris. Sunt exercitation culpa in velit tempor mollit pariatur."
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
