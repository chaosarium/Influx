module Pages.Dictionary exposing (Model, Msg, page)

import Api
import Api.DictionaryLookup
import Bindings exposing (WordDefinition, WordDefinitionSegment)
import Components.FormElements exposing (buttonC, inputC)
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


type alias Model =
    { dictPath : String
    , query : String
    , lookupResult : LookupResult
    }


type LookupResult
    = NotStarted
    | Loading
    | Success (List WordDefinition)
    | Error String


init : () -> ( Model, Effect Msg )
init () =
    ( { dictPath = ""
      , query = ""
      , lookupResult = NotStarted
      }
    , Effect.none
    )


type Msg
    = DictPathChanged String
    | QueryChanged String
    | LookupClicked
    | LookupResponded (Result Http.Error (List WordDefinition))


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        DictPathChanged newPath ->
            ( { model | dictPath = newPath }, Effect.none )

        QueryChanged newQuery ->
            ( { model | query = newQuery }, Effect.none )

        LookupClicked ->
            if String.isEmpty model.dictPath || String.isEmpty model.query then
                ( { model | lookupResult = Error "Please fill in both dictionary path and query" }, Effect.none )

            else
                ( { model | lookupResult = Loading }
                , Effect.sendCmd
                    (Api.DictionaryLookup.dictionaryLookup
                        { dictPath = model.dictPath, query = model.query }
                        LookupResponded
                    )
                )

        LookupResponded (Ok definitions) ->
            ( { model | lookupResult = Success definitions }, Effect.none )

        LookupResponded (Err err) ->
            ( { model | lookupResult = Error (Api.stringOfHttpErrMsg err) }, Effect.none )


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
                , Html.div []
                    [ inputC
                        []
                        "Dictionary Path"
                        "dict-path"
                        DictPathChanged
                        model.dictPath
                    ]
                , Html.div []
                    [ inputC
                        []
                        "Query"
                        "query"
                        QueryChanged
                        model.query
                    ]
                , Html.div []
                    [ buttonC
                        [ onClick LookupClicked ]
                        "Lookup"
                    ]
                , viewLookupResult model.lookupResult
                ]
            ]
        ]
    }


viewLookupResult : LookupResult -> Html Msg
viewLookupResult result =
    case result of
        NotStarted ->
            Html.div [] []

        Loading ->
            Html.div [] [ Html.text "Loading..." ]

        Error errorMsg ->
            Html.div [ class "error" ] [ Html.text ("Error: " ++ errorMsg) ]

        Success definitions ->
            Html.div []
                [ Html.h2 [] [ Html.text "Results:" ]
                , Html.div [] (List.map viewDefinition definitions)
                ]


viewDefinition : WordDefinition -> Html Msg
viewDefinition definition =
    Html.div [ class "definition" ]
        [ Html.h3 [] [ Html.text definition.word ]
        , Html.div [] (List.map viewSegment definition.segments)
        ]


viewSegment : WordDefinitionSegment -> Html Msg
viewSegment segment =
    Html.div [ class "segment" ]
        [ Html.span [ class "segment-type" ] [ Html.text ("(" ++ segment.types ++ ") ") ]
        , Html.span [ class "segment-text" ] [ Html.text segment.text ]
        ]


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
