module Pages.Langs exposing (Model, Msg, page)

import Api
import Api.GetLanguages
import Bindings exposing (InfluxResourceId(..), LanguageEntry)
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (href, style)
import Http
import Page exposing (Page)
import Route exposing (Route)
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
    { langData : Api.Data (List LanguageEntry) }


init : () -> ( Model, Effect Msg )
init () =
    ( { langData = Api.Loading }
    , Effect.sendCmd (Api.GetLanguages.get {} ApiResponded)
    )



-- UPDATE


type Msg
    = ApiResponded (Result Http.Error (List LanguageEntry))


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiResponded (Ok res) ->
            ( { model | langData = Api.Success res }, Effect.none )

        ApiResponded (Err httpError) ->
            ( { model | langData = Api.Failure httpError }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


languageIdToString : InfluxResourceId -> String
languageIdToString id =
    case id of
        SerialId intId ->
            String.fromInt intId

        StringId stringId ->
            stringId


viewLanguagesTable : List LanguageEntry -> Html msg
viewLanguagesTable languages =
    table [ style "border-collapse" "collapse", style "width" "100%" ]
        [ thead []
            [ tr []
                [ th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Name" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Code" ]
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
                            [ text language.code ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ text (String.join ", " language.dicts) ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ case language.id of
                                Just langId ->
                                    a
                                        [ href ("/lang/edit/" ++ languageIdToString langId) ]
                                        [ text "Edit" ]

                                Nothing ->
                                    text "No ID"
                            ]
                        ]
                )
                languages
            )
        ]


view : Model -> View Msg
view model =
    { title = "Languages"
    , body =
        [ Components.Topbar.view {}
        , Html.h1 [] [ Html.text "Languages" ]
        , case model.langData of
            Api.Loading ->
                div [] [ Html.text "Loading..." ]

            Api.Failure httpError ->
                div [] [ Html.text "Error: ", Html.text (Api.stringOfHttpErrMsg httpError) ]

            Api.Success languages ->
                div []
                    [ viewLanguagesTable languages ]
        ]
    }
