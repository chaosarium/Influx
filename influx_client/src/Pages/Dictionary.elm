module Pages.Dictionary exposing (Model, Msg, page)

import Api
import Api.DictionaryList
import Api.DictionaryLookup
import Bindings exposing (StardictType(..), WordDefinition, WordDefinitionSegment)
import Components.FormElements exposing (SelectCOption, buttonC, inputC, selectC)
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class, id, placeholder, value)
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
    , availableDictionaries : List String
    , dictionariesLoadStatus : DictionariesLoadStatus
    }


type LookupResult
    = NotStarted
    | Loading
    | Success (List WordDefinition)
    | Error String


type DictionariesLoadStatus
    = DictionariesNotLoaded
    | DictionariesLoading
    | DictionariesLoadedSuccess
    | DictionariesError String


init : () -> ( Model, Effect Msg )
init () =
    ( { dictPath = ""
      , query = ""
      , lookupResult = NotStarted
      , availableDictionaries = []
      , dictionariesLoadStatus = DictionariesLoading
      }
    , Effect.sendCmd (Api.DictionaryList.dictionaryList DictionariesLoaded)
    )


type Msg
    = DictPathChanged String
    | QueryChanged String
    | LookupClicked
    | LookupResponded (Result Http.Error (List WordDefinition))
    | DictionariesLoaded (Result Http.Error (List String))


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
            let
                htmlInjectionEffects =
                    definitions
                        |> List.indexedMap
                            (\defIndex definition ->
                                definition.segments
                                    |> List.indexedMap
                                        (\segIndex segment ->
                                            case segment.types of
                                                Html ->
                                                    [ Effect.injectHtml
                                                        { elementId = "html-segment-" ++ String.fromInt defIndex ++ "-" ++ String.fromInt segIndex
                                                        , htmlContent = segment.text
                                                        }
                                                    ]

                                                Other _ ->
                                                    []
                                        )
                                    |> List.concat
                            )
                        |> List.concat
                        |> Effect.batch
            in
            ( { model | lookupResult = Success definitions }, htmlInjectionEffects )

        LookupResponded (Err err) ->
            ( { model | lookupResult = Error (Api.stringOfHttpErrMsg err) }, Effect.none )

        DictionariesLoaded (Ok dictionaries) ->
            ( { model
                | availableDictionaries = dictionaries
                , dictionariesLoadStatus = DictionariesLoadedSuccess
              }
            , Effect.none
            )

        DictionariesLoaded (Err err) ->
            ( { model
                | dictionariesLoadStatus = DictionariesError (httpErrorToString err)
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
                , viewDictionarySelector model
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


viewDictionarySelector : Model -> Html Msg
viewDictionarySelector model =
    case model.dictionariesLoadStatus of
        DictionariesLoading ->
            Html.div [] [ Html.text "Loading dictionaries..." ]

        DictionariesError errorMsg ->
            Html.div [ class "error" ] [ Html.text ("Error loading dictionaries: " ++ errorMsg) ]

        DictionariesLoadedSuccess ->
            if List.isEmpty model.availableDictionaries then
                Html.div [ class "error" ]
                    [ Html.text "No dictionaries found. Please add .ifo files to the dictionaries directory." ]

            else
                Html.div []
                    [ selectC
                        "Dictionary"
                        "dict-selector"
                        DictPathChanged
                        (List.map (\dict -> { value = dict, label = dict }) model.availableDictionaries)
                        model.dictPath
                    ]

        DictionariesNotLoaded ->
            Html.div [] []


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
                , Html.div [] (List.indexedMap viewDefinition definitions)
                ]


viewDefinition : Int -> WordDefinition -> Html Msg
viewDefinition defIndex definition =
    Html.div [ class "definition" ]
        [ Html.h3 [] [ Html.text definition.word ]
        , Html.div [] (List.indexedMap (viewSegment defIndex) definition.segments)
        ]


viewSegment : Int -> Int -> WordDefinitionSegment -> Html Msg
viewSegment defIndex segIndex segment =
    let
        typeDisplay =
            case segment.types of
                Html ->
                    "(html) "

                Other typeStr ->
                    "(" ++ typeStr ++ ") "

        contentDisplay =
            case segment.types of
                Html ->
                    [ Html.div
                        [ id ("html-segment-" ++ String.fromInt defIndex ++ "-" ++ String.fromInt segIndex)
                        , class "html-content-placeholder"
                        ]
                        [ Html.text "Loading HTML content..." ]
                    ]

                Other _ ->
                    [ Html.text segment.text ]
    in
    Html.div [ class "segment" ]
        [ Html.span [ class "segment-type" ] [ Html.text typeDisplay ]
        , Html.span [ class "segment-text" ] contentDisplay
        ]


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
