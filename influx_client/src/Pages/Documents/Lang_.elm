module Pages.Documents.Lang_ exposing (Model, Msg, page)

import Api
import Api.GetDocuments
import Bindings exposing (DocEntry)
import Components.DbgDisplay
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Shared.Model -> Route { lang : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init route.params.lang
        , update = update
        , subscriptions = subscriptions
        , view = view route
        }


type alias ThisRoute =
    Route { lang : String }



-- INIT


type alias Model =
    { docData : Api.Data (List DocEntry) }


init : String -> () -> ( Model, Effect Msg )
init lang () =
    ( { docData = Api.Loading }
    , Effect.sendCmd (Api.GetDocuments.get { languageId = lang } ApiResponded)
    )



-- UPDATE


type Msg
    = ApiResponded (Result Http.Error (List DocEntry))


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiResponded (Ok res) ->
            let
                _ =
                    Debug.log "ApiResponded" res
            in
            ( { model | docData = Api.Success res }, Effect.none )

        ApiResponded (Err httpError) ->
            ( { model | docData = Api.Failure httpError }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewDocEntry : String -> DocEntry -> Html.Html msg
viewDocEntry lang document =
    Html.li []
        [ Html.span [] [ Html.text document.metadata.title ]
        , Html.text " "
        , Html.a [ Html.Attributes.href ("/documents/" ++ lang ++ "/" ++ document.filename) ]
            [ Html.text document.filename ]
        ]


view : ThisRoute -> Model -> View Msg
view route model =
    { title = "Document listing"
    , body =
        [ Components.Topbar.view {}
        , Components.DbgDisplay.view "route" route
        , Html.h1 [] [ Html.text ("document listing, " ++ "lang: " ++ route.params.lang) ]
        , case model.docData of
            Api.Loading ->
                div [] [ Html.text "Loading..." ]

            Api.Failure httpError ->
                div [] [ Html.text "Error: ", Html.text (Api.stringOfHttpErrMsg httpError) ]

            Api.Success documents ->
                div []
                    [ Html.ul []
                        (List.map (viewDocEntry route.params.lang) documents)
                    ]
        ]
    }
