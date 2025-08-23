module Pages.Langs exposing (Model, Msg, page)

import Api
import Api.GetLanguages
import Bindings exposing (InfluxResourceId(..), Language)
import BindingsUtils
import Components.FormElements3 exposing (buttonC)
import Components.Layout
import Css exposing (..)
import Dict
import Effect exposing (Effect)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css, href)
import Html.Styled.Events as Events
import Http
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { langData : Api.Data (List Language) }


init : () -> ( Model, Effect Msg )
init () =
    ( { langData = Api.Loading }
    , Effect.sendCmd (Api.GetLanguages.get {} ApiResponded)
    )



-- UPDATE


type Msg
    = ApiResponded (Result Http.Error (List Language))
    | AddLanguage


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiResponded (Ok res) ->
            ( { model | langData = Api.Success res }, Effect.none )

        ApiResponded (Err httpError) ->
            ( { model | langData = Api.Failure httpError }, Effect.none )

        AddLanguage ->
            ( model, Effect.pushRoutePath Route.Path.Lang_Edit )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewLanguagesTable : List Language -> Html msg
viewLanguagesTable languages =
    Html.table
        [ css
            [ Css.borderCollapse Css.collapse
            , Css.width (Css.pct 100)
            ]
        ]
        [ thead []
            [ tr []
                [ th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Name" ]
                , th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Dictionary URLs" ]
                , th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Actions" ]
                ]
            ]
        , tbody []
            (List.map
                (\language ->
                    tr [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd") ] ]
                        [ td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ text language.name ]
                        , td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ text (String.join ", " language.dicts) ]
                        , td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ case language.id of
                                Just langId ->
                                    div []
                                        [ a
                                            [ href ("/lang/edit?langId=" ++ BindingsUtils.influxResourceIdToString langId) ]
                                            [ text "Edit" ]
                                        , text " | "
                                        , a
                                            [ href ("/docs?lang=" ++ BindingsUtils.influxResourceIdToString langId) ]
                                            [ text "View Docs" ]
                                        ]

                                Nothing ->
                                    text "No ID"
                            ]
                        ]
                )
                languages
            )
        ]


viewLangs model =
    case model.langData of
        Api.NotAsked ->
            div [] [ text "Languages not loaded" ]

        Api.Loading ->
            div [] [ text "Loading..." ]

        Api.Failure httpError ->
            div [] [ text "Error: ", text (Api.stringOfHttpErrMsg httpError) ]

        Api.Success languages ->
            div []
                [ div [ css [ Css.marginBottom (Css.px 20) ] ]
                    [ buttonC
                        { label = "Add Language"
                        , onPress = Just AddLanguage
                        }
                    ]
                , viewLanguagesTable languages
                ]


view : Model -> View Msg
view model =
    { title = "Languages"
    , body =
        Components.Layout.pageLayoutC { toastTray = Nothing }
            [ h1 [] [ text "Languages" ]
            , viewLangs model
            ]
    }
