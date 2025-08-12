module Pages.Langs exposing (Model, Msg, page)

import Api
import Api.GetLanguages
import Bindings exposing (InfluxResourceId(..), Language)
import BindingsUtils
import Components.FormElements exposing (buttonC)
import Components.Topbar
import Dict
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class, href, style)
import Html.Events
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
    table [ style "border-collapse" "collapse", style "width" "100%" ]
        [ thead []
            [ tr []
                [ th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Name" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Dictionary URLs" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Actions" ]
                ]
            ]
        , tbody []
            (List.map
                (\language ->
                    tr [ style "border" "1px solid #ddd" ]
                        [ td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ text language.name ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ text (String.join ", " language.dicts) ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ case language.id of
                                Just langId ->
                                    div []
                                        [ a
                                            [ href ("/lang/edit?langId=" ++ BindingsUtils.influxResourceIdToString langId) ]
                                            [ text "Edit" ]
                                        , text " | "
                                        , a
                                            [ Route.href
                                                { path = Route.Path.Docs
                                                , query = Dict.fromList [ ( "lang", BindingsUtils.influxResourceIdToString langId ) ]
                                                , hash = Nothing
                                                }
                                            ]
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
            div [] [ Html.text "Languages not loaded" ]

        Api.Loading ->
            div [] [ Html.text "Loading..." ]

        Api.Failure httpError ->
            div [] [ Html.text "Error: ", Html.text (Api.stringOfHttpErrMsg httpError) ]

        Api.Success languages ->
            div []
                [ div [ style "margin-bottom" "20px" ]
                    [ buttonC
                        [ Html.Events.onClick AddLanguage
                        , style "background-color" "#28a745"
                        , style "color" "white"
                        ]
                        "Add Language"
                    ]
                , viewLanguagesTable languages
                ]


view : Model -> View Msg
view model =
    { title = "Languages"
    , body =
        [ Html.div [ class "layout-outer" ]
            [ Components.Topbar.view {}
            , Html.div [ class "layout-content" ]
                [ -- the main content of the page
                  Html.h1 [] [ Html.text "Languages" ]
                , viewLangs model
                ]
            ]
        ]
    }
