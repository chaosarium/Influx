module Components.DictionaryLookup exposing (Model, Msg(..), init, update, view)

import Api.DictionaryList
import Api.DictionaryLookup
import Bindings exposing (StardictType(..), WordDefinition, WordDefinitionSegment)
import Components.FormElements exposing (SelectCOption, buttonC, inputC, selectC)
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Http


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
    | LoadingWithPrevious (List WordDefinition)
    | Success (List WordDefinition)
    | Error String


type DictionariesLoadStatus
    = DictionariesNotLoaded
    | DictionariesLoading
    | DictionariesLoadedSuccess
    | DictionariesError String


init : List String -> Model
init availableDictionaries =
    { dictPath = ""
    , query = ""
    , lookupResult = NotStarted
    , availableDictionaries = availableDictionaries
    , dictionariesLoadStatus =
        if List.isEmpty availableDictionaries then
            DictionariesNotLoaded

        else
            DictionariesLoadedSuccess
    }


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
                let
                    newLookupResult =
                        case model.lookupResult of
                            Success previousDefinitions ->
                                LoadingWithPrevious previousDefinitions

                            _ ->
                                Loading
                in
                ( { model | lookupResult = newLookupResult }
                , Effect.sendCmd
                    (Api.DictionaryLookup.dictionaryLookup
                        { dictPath = model.dictPath, query = model.query }
                        LookupResponded
                    )
                )

        LookupResponded (Ok definitions) ->
            ( { model | lookupResult = Success definitions }, Effect.none )

        LookupResponded (Err err) ->
            ( { model | lookupResult = Error (httpErrorToString err) }, Effect.none )

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


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Request timeout"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus status ->
            "Bad status: " ++ String.fromInt status

        Http.BadBody body ->
            "Bad body: " ++ body


view : Model -> Html Msg
view model =
    Html.div []
        [ viewDictionarySelector model
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
                (Just LookupClicked)
                "Lookup"
            ]
        , viewLookupResult model.lookupResult
        ]


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

        LoadingWithPrevious definitions ->
            Html.div []
                [ Html.h3 [] [ Html.text "Results:" ]
                , Html.div [] (List.indexedMap viewDefinition definitions)
                ]

        Error errorMsg ->
            Html.div [ class "error" ] [ Html.text ("Error: " ++ errorMsg) ]

        Success definitions ->
            Html.div []
                [ Html.h3 [] [ Html.text "Results:" ]
                , Html.div [] (List.indexedMap viewDefinition definitions)
                ]


viewDefinition : Int -> WordDefinition -> Html Msg
viewDefinition defIndex definition =
    Html.div [ class "definition" ]
        [ Html.h4 [] [ Html.text definition.word ]
        , Html.div [] (List.indexedMap (viewSegment definition) definition.segments)
        ]


viewSegment : WordDefinition -> Int -> WordDefinitionSegment -> Html Msg
viewSegment definition segIndex segment =
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
                    [ Html.node "shadow-element"
                        [ attribute "inner-html" segment.text
                        , attribute "base-url" definition.dictionaryInfo.baseUrl
                        , class "html-content-shadow"
                        ]
                        []
                    ]

                Other _ ->
                    [ Html.text segment.text ]
    in
    Html.div [ class "segment" ]
        [ Html.span [ class "segment-type" ] [ Html.text typeDisplay ]
        , Html.span [ class "segment-text" ] contentDisplay
        ]
