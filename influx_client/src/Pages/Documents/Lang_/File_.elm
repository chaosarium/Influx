module Pages.Documents.Lang_.File_ exposing (Model, Msg, page)

import Api
import Api.LanguageList
import Bindings exposing (LanguageEntry)
import Components.DbgDisplay
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (alt, class, src, style)
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Shared.Model -> Route { lang : String, file : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view route
        }


type alias ThisRoute =
    Route { lang : String, file : String }



-- INIT


type alias Model =
    { langData : Api.Data (List LanguageEntry) }


init : () -> ( Model, Effect Msg )
init () =
    ( { langData = Api.Loading }
    , Effect.sendCmd (Api.LanguageList.getLanguages { onResponse = ApiResponded })
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


view : ThisRoute -> Model -> View Msg
view route model =
    { title = "Pages.Languages"
    , body =
        [ Components.Topbar.view {}
        , Components.DbgDisplay.view "route" route
        , Html.h1 [] [ Html.text ("lang: " ++ route.params.lang ++ ", file: " ++ route.params.file) ]
        ]
    }
