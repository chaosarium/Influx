module Pages.Dictionary exposing (Model, Msg, page)

import Api
import Api.DictionaryList
import Components.DictionaryLookup as DictionaryLookup
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class)
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


type alias Model =
    { dictionaryLookup : DictionaryLookup.Model
    , dictionariesLoadStatus : DictionariesLoadStatus
    }


type DictionariesLoadStatus
    = DictionariesNotLoaded
    | DictionariesLoading
    | DictionariesLoadedSuccess
    | DictionariesError String


init : () -> ( Model, Effect Msg )
init () =
    ( { dictionaryLookup = DictionaryLookup.init []
      , dictionariesLoadStatus = DictionariesLoading
      }
    , Effect.sendCmd (Api.DictionaryList.dictionaryList DictionariesLoaded)
    )


type Msg
    = DictionaryLookupMsg DictionaryLookup.Msg
    | DictionariesLoaded (Result Http.Error (List String))


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        DictionaryLookupMsg dictionaryMsg ->
            let
                ( newDictionaryModel, effect ) =
                    DictionaryLookup.update dictionaryMsg model.dictionaryLookup
            in
            ( { model | dictionaryLookup = newDictionaryModel }
            , Effect.map DictionaryLookupMsg effect
            )

        DictionariesLoaded (Ok dictionaries) ->
            ( { model
                | dictionaryLookup = DictionaryLookup.init dictionaries
                , dictionariesLoadStatus = DictionariesLoadedSuccess
              }
            , Effect.none
            )

        DictionariesLoaded (Err err) ->
            ( { model
                | dictionariesLoadStatus = DictionariesError (Api.stringOfHttpErrMsg err)
              }
            , Effect.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> View Msg
view model =
    { title = "Dictionary Lookup"
    , body =
        [ Html.div [ class "layout-outer" ]
            [ Components.Topbar.view {}
            , Html.div [ class "layout-content" ]
                [ Html.h1 [] [ Html.text "Dictionary Lookup" ]
                , Html.map DictionaryLookupMsg (DictionaryLookup.view model.dictionaryLookup)
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
