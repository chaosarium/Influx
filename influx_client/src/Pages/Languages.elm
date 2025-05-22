module Pages.Languages exposing (Model, Msg, page)

import Api
import Api.GetLanguages
import Bindings exposing (LanguageEntry)
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (alt, class, src, style)
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
    , Effect.sendCmd (Api.GetLanguages.get { onResponse = ApiResponded })
    )



-- UPDATE


type Msg
    = ApiResponded (Result Http.Error (List LanguageEntry))


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiResponded (Ok res) ->
            let
                _ =
                    Debug.log "ApiResponded" res
            in
            ( { model | langData = Api.Success res }, Effect.none )

        ApiResponded (Err httpError) ->
            ( { model | langData = Api.Failure httpError }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewLanguage : LanguageEntry -> Html.Html msg
viewLanguage language =
    Html.li []
        [ Html.span [] [ Html.text language.name ]
        , Html.text " "
        , Html.span [] [ Html.text ("[" ++ language.identifier ++ "]") ]
        , Html.text " "
        , Html.span [] [ Html.a [ Html.Attributes.href ("/documents/" ++ language.identifier) ] [ Html.text "documents" ] ]
        ]


view : Model -> View Msg
view model =
    { title = "Language listing"
    , body =
        [ Components.Topbar.view {}
        , case model.langData of
            Api.Loading ->
                div [] [ Html.text "Loading..." ]

            Api.Failure httpError ->
                div [] [ Html.text "Error: ", Html.text (Api.stringOfHttpErrMsg httpError) ]

            Api.Success languages ->
                div []
                    [ Html.h1 [] [ text "Languages" ]
                    , Html.ul [] (List.map viewLanguage languages)
                    ]
        ]
    }
