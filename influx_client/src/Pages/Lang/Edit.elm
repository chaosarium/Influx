module Pages.Lang.Edit exposing (Model, Msg, page)

import Api
import Api.DictionaryList
import Api.GetLanguage
import Api.LangCreate
import Api.LangDelete
import Api.LangEdit
import Bindings exposing (InfluxResourceId(..), Language, LanguageCreateRequest, ParserConfig)
import Components.FormElements3 as FormElements3 exposing (FormSection, SelectCOption, buttonC, buttonRowC, formC, formSectionC, inputC, inputWithTooltipC, numberInputC, selectC, stringListC)
import Components.Styles as Styles
import Components.ToastView
import Components.Topbar
import Dict exposing (Dict)
import Effect exposing (Effect)
import Html
import Html.Attributes
import Html.Styled exposing (Html, div, h1, hr, span, text)
import Html.Styled.Attributes as Attributes exposing (class, style)
import Html.Styled.Events as Events exposing (onClick)
import Http
import Json.Decode as D
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import Shared.Msg
import Toast
import Utils
import View exposing (View)


type alias SelectCOption =
    FormElements3.SelectCOption


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init route
        , update = update
        , subscriptions = subscriptions
        , view = view shared route
        }


type alias ThisRoute =
    Route ()


type alias Voice =
    { name : String
    , lang : String
    , default : Bool
    }



-- INIT


type alias Model =
    { languageId : Maybe InfluxResourceId
    , languageData : Api.Data Language
    , formModel : FormModel
    , isSubmitting : Bool
    , mode : EditMode
    , availableVoices : List Voice
    , availableDictionaries : List String
    , dictionariesLoadStatus : DictionariesLoadStatus
    }


type EditMode
    = CreateMode
    | EditMode


type FormModel
    = EditingLanguage LanguageFormModel
    | LoadingForm
    | ErrorForm String


type alias LanguageFormModel =
    { originalLanguage : Maybe Language
    , workingLanguage : Language
    , currentDictInput : String
    , ttsRateInput : String
    , ttsPitchInput : String
    , selectedDictPath : String
    }


type DictionariesLoadStatus
    = DictionariesNotLoaded
    | DictionariesLoading
    | DictionariesLoadedSuccess
    | DictionariesError String


emptyLanguage : Language
emptyLanguage =
    { id = Nothing
    , name = ""
    , dicts = []
    , ttsRate = Nothing
    , ttsPitch = Nothing
    , ttsVoice = Nothing
    , deeplSourceLang = Nothing
    , deeplTargetLang = Nothing
    , parserConfig = { whichParser = "base_spacy", parserArgs = Dict.empty }
    }


init : Route () -> () -> ( Model, Effect Msg )
init route () =
    let
        langId =
            case Dict.get "langId" route.query of
                Just langIdString ->
                    case String.toInt langIdString of
                        Just id ->
                            Just (SerialId id)

                        Nothing ->
                            Just (StringId langIdString)

                Nothing ->
                    Nothing

        ( mode, initialLanguageData, effects ) =
            case langId of
                Just id ->
                    ( EditMode
                    , Api.Loading
                    , [ Effect.sendCmd
                            (Api.GetLanguage.get
                                { langId =
                                    String.fromInt
                                        (case id of
                                            SerialId i ->
                                                i

                                            StringId s ->
                                                0
                                        )
                                }
                                LanguageDataResponded
                            )
                      ]
                    )

                Nothing ->
                    ( CreateMode
                    , Api.NotAsked
                    , []
                    )
    in
    ( { languageId = langId
      , languageData = initialLanguageData
      , formModel =
            if mode == CreateMode then
                EditingLanguage
                    { originalLanguage = Nothing
                    , workingLanguage = emptyLanguage
                    , currentDictInput = ""
                    , ttsRateInput = ""
                    , ttsPitchInput = ""
                    , selectedDictPath = ""
                    }

            else
                LoadingForm
      , isSubmitting = False
      , mode = mode
      , availableVoices = []
      , availableDictionaries = []
      , dictionariesLoadStatus = DictionariesLoading
      }
    , Effect.batch
        (effects
            ++ [ Effect.ttsGetVoices
               , Effect.sendCmd (Api.DictionaryList.dictionaryList DictionariesLoaded)
               ]
        )
    )



-- UPDATE


type Msg
    = LanguageDataResponded (Result Http.Error (Maybe Language))
    | UpdateNameInput String
    | UpdateDictsList (List String)
    | UpdateDictInput String
    | UpdateTtsRateInput Float
    | UpdateTtsPitchInput Float
    | UpdateTtsVoice String
    | UpdateDeeplSourceLang String
    | UpdateDeeplTargetLang String
    | UpdateParserType String
    | UpdateSpacyModel String
    | SubmitForm
    | CancelEdit
    | LanguageCreateResponded (Result Http.Error Language)
    | LanguageEditResponded (Result Http.Error Language)
    | DeleteLanguage
    | LanguageDeleteResponded (Result Http.Error ())
    | VoicesReceived (Maybe D.Value)
    | DictionariesLoaded (Result Http.Error (List String))
    | DictPathChanged String
    | AddSelectedDict
    | SharedMsg Shared.Msg.Msg


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg sharedMsg ->
            ( model, Effect.sendSharedMsg sharedMsg )

        LanguageDataResponded (Ok (Just language)) ->
            ( { model
                | languageData = Api.Success language
                , formModel =
                    EditingLanguage
                        { originalLanguage = Just language
                        , workingLanguage = language
                        , currentDictInput = ""
                        , ttsRateInput = Maybe.withDefault "" (Maybe.map String.fromFloat language.ttsRate)
                        , ttsPitchInput = Maybe.withDefault "" (Maybe.map String.fromFloat language.ttsPitch)
                        , selectedDictPath = ""
                        }
              }
            , Effect.none
            )

        LanguageDataResponded (Ok Nothing) ->
            ( { model
                | languageData = Api.Failure (Http.BadStatus 404)
                , formModel = ErrorForm "Language not found"
              }
            , Effect.none
            )

        LanguageDataResponded (Err httpError) ->
            ( { model
                | languageData = Api.Failure httpError
                , formModel = ErrorForm ("Failed to load language: " ++ Api.stringOfHttpErrMsg httpError)
              }
            , Effect.none
            )

        UpdateNameInput value ->
            updateWorkingLanguage (\lang -> { lang | name = value }) model

        UpdateDictsList newDicts ->
            updateWorkingLanguage (\lang -> { lang | dicts = newDicts }) model

        UpdateDictInput value ->
            case model.formModel of
                EditingLanguage formModel ->
                    ( { model
                        | formModel =
                            EditingLanguage
                                { formModel | currentDictInput = value }
                      }
                    , Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        DictPathChanged value ->
            case model.formModel of
                EditingLanguage formModel ->
                    ( { model
                        | formModel =
                            EditingLanguage
                                { formModel | selectedDictPath = value }
                      }
                    , Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        AddSelectedDict ->
            case model.formModel of
                EditingLanguage formModel ->
                    if String.isEmpty formModel.selectedDictPath then
                        ( model, Effect.none )

                    else
                        let
                            updatedDicts =
                                if List.member formModel.selectedDictPath formModel.workingLanguage.dicts then
                                    formModel.workingLanguage.dicts

                                else
                                    formModel.workingLanguage.dicts ++ [ formModel.selectedDictPath ]
                        in
                        let
                            workingLanguage =
                                formModel.workingLanguage

                            updatedWorkingLanguage =
                                { workingLanguage | dicts = updatedDicts }
                        in
                        ( { model
                            | formModel =
                                EditingLanguage
                                    { formModel
                                        | workingLanguage = updatedWorkingLanguage
                                        , selectedDictPath = ""
                                    }
                          }
                        , Effect.none
                        )

                _ ->
                    ( model, Effect.none )

        UpdateTtsRateInput value ->
            updateWorkingLanguage (\lang -> { lang | ttsRate = Just value }) model

        UpdateTtsPitchInput value ->
            updateWorkingLanguage (\lang -> { lang | ttsPitch = Just value }) model

        UpdateTtsVoice value ->
            let
                voiceValue =
                    if String.isEmpty value then
                        Nothing

                    else
                        Just value
            in
            updateWorkingLanguage (\lang -> { lang | ttsVoice = voiceValue }) model

        UpdateDeeplSourceLang value ->
            let
                sourceLangValue =
                    if String.isEmpty value then
                        Nothing

                    else
                        Just value
            in
            updateWorkingLanguage (\lang -> { lang | deeplSourceLang = sourceLangValue }) model

        UpdateDeeplTargetLang value ->
            let
                targetLangValue =
                    if String.isEmpty value then
                        Nothing

                    else
                        Just value
            in
            updateWorkingLanguage (\lang -> { lang | deeplTargetLang = targetLangValue }) model

        UpdateParserType newValue ->
            updateWorkingLanguage
                (\lang ->
                    { lang
                        | parserConfig =
                            { whichParser = newValue
                            , parserArgs = lang.parserConfig.parserArgs
                            }
                    }
                )
                model

        UpdateSpacyModel newValue ->
            updateWorkingLanguage
                (\lang ->
                    { lang
                        | parserConfig =
                            { whichParser = lang.parserConfig.whichParser
                            , parserArgs =
                                if String.isEmpty newValue then
                                    Dict.remove "spacy_model" lang.parserConfig.parserArgs

                                else
                                    Dict.insert "spacy_model" newValue lang.parserConfig.parserArgs
                            }
                    }
                )
                model

        SubmitForm ->
            case model.formModel of
                EditingLanguage { workingLanguage } ->
                    case model.mode of
                        CreateMode ->
                            let
                                createRequest : LanguageCreateRequest
                                createRequest =
                                    { name = workingLanguage.name
                                    , dicts = workingLanguage.dicts
                                    , ttsRate = workingLanguage.ttsRate
                                    , ttsPitch = workingLanguage.ttsPitch
                                    , ttsVoice = workingLanguage.ttsVoice
                                    , deeplSourceLang = workingLanguage.deeplSourceLang
                                    , deeplTargetLang = workingLanguage.deeplTargetLang
                                    , parserConfig = workingLanguage.parserConfig
                                    }
                            in
                            ( { model | isSubmitting = True }
                            , Effect.sendCmd (Api.LangCreate.create createRequest LanguageCreateResponded)
                            )

                        EditMode ->
                            ( { model | isSubmitting = True }
                            , Effect.sendCmd (Api.LangEdit.edit workingLanguage LanguageEditResponded)
                            )

                _ ->
                    ( model, Effect.none )

        CancelEdit ->
            ( model
            , Effect.pushRoutePath Route.Path.Langs
            )

        LanguageCreateResponded (Ok createdLanguage) ->
            ( { model | isSubmitting = False }
            , Effect.batch
                [ Effect.sendSharedMsg (Shared.Msg.AddToast "Language created successfully")
                , Effect.pushRoutePath Route.Path.Langs
                ]
            )

        LanguageCreateResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to create language: " ++ Api.stringOfHttpErrMsg httpError))
            )

        LanguageEditResponded (Ok updatedLanguage) ->
            ( { model
                | formModel =
                    EditingLanguage
                        { originalLanguage = Just updatedLanguage
                        , workingLanguage = updatedLanguage
                        , currentDictInput = ""
                        , ttsRateInput = Maybe.withDefault "" (Maybe.map String.fromFloat updatedLanguage.ttsRate)
                        , ttsPitchInput = Maybe.withDefault "" (Maybe.map String.fromFloat updatedLanguage.ttsPitch)
                        , selectedDictPath = ""
                        }
                , isSubmitting = False
              }
            , Effect.sendSharedMsg (Shared.Msg.AddToast "Language updated successfully")
            )

        LanguageEditResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to update language: " ++ Api.stringOfHttpErrMsg httpError))
            )

        DeleteLanguage ->
            case model.languageId of
                Just langId ->
                    let
                        idString =
                            case langId of
                                SerialId id ->
                                    String.fromInt id

                                StringId s ->
                                    s
                    in
                    ( { model | isSubmitting = True }
                    , Effect.sendCmd (Api.LangDelete.delete idString LanguageDeleteResponded)
                    )

                Nothing ->
                    ( model, Effect.none )

        LanguageDeleteResponded (Ok ()) ->
            ( model
            , Effect.batch
                [ Effect.sendSharedMsg (Shared.Msg.AddToast "Language deleted successfully")
                , Effect.pushRoutePath Route.Path.Langs
                ]
            )

        LanguageDeleteResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to delete language: " ++ Api.stringOfHttpErrMsg httpError))
            )

        VoicesReceived maybeValue ->
            let
                voices =
                    case maybeValue of
                        Just value ->
                            D.decodeValue (D.list voiceDecoder) value
                                |> Result.withDefault []

                        Nothing ->
                            []
            in
            ( { model | availableVoices = voices }
            , Effect.none
            )

        DictionariesLoaded (Ok dictionaries) ->
            ( { model
                | availableDictionaries = dictionaries
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


updateWorkingLanguage : (Language -> Language) -> Model -> ( Model, Effect Msg )
updateWorkingLanguage updateFn model =
    case model.formModel of
        EditingLanguage formModel ->
            ( { model
                | formModel =
                    EditingLanguage
                        { formModel | workingLanguage = updateFn formModel.workingLanguage }
              }
            , Effect.none
            )

        _ ->
            ( model, Effect.none )


updateFormInput : (LanguageFormModel -> LanguageFormModel) -> ( Model, Effect Msg ) -> ( Model, Effect Msg )
updateFormInput updateFn ( model, effect ) =
    case model.formModel of
        EditingLanguage formModel ->
            ( { model
                | formModel = EditingLanguage (updateFn formModel)
              }
            , effect
            )

        _ ->
            ( model, effect )


voiceDecoder : D.Decoder Voice
voiceDecoder =
    D.map3 Voice
        (D.field "name" D.string)
        (D.field "lang" D.string)
        (D.field "default" D.bool)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Effect.jsIncoming
        (\value ->
            let
                maybeMsg =
                    case D.decodeValue (D.field "tag" D.string) value of
                        Ok "VOICES_LIST" ->
                            D.decodeValue (D.field "data" D.value) value
                                |> Result.toMaybe
                                |> VoicesReceived
                                |> Just

                        _ ->
                            Nothing
            in
            case maybeMsg of
                Just msg ->
                    msg

                Nothing ->
                    D.decodeValue (D.field "tag" D.string) value
                        |> Result.withDefault ""
                        |> Utils.dbgLog "Unhandled incoming port"
                        |> always Nothing
                        |> Maybe.withDefault (SharedMsg (Shared.Msg.AddToast "Unknown message"))
        )



-- VIEW


view : Shared.Model -> ThisRoute -> Model -> View Msg
view shared route model =
    let
        title =
            case model.mode of
                CreateMode ->
                    "Create Language"

                EditMode ->
                    "Edit Language"
    in
    { title = title
    , body =
        List.map Html.Styled.fromUnstyled <|
            [ Html.div [ Html.Attributes.class "outer-layout" ]
                [ Components.Topbar.view {}
                , Html.div [ Html.Attributes.class "toast-tray" ] [ Toast.render Components.ToastView.viewToast shared.toast_tray (Toast.config (SharedMsg << Shared.Msg.ToastMsg)) ]
                , Html.div [ Html.Attributes.class "layout-content" ]
                    [ Html.h1 [] [ Html.text title ]
                    , case model.formModel of
                        LoadingForm ->
                            Html.div [] [ Html.text "Loading..." ]

                        ErrorForm error ->
                            Html.div [ Html.Attributes.style "color" "red" ] [ Html.text error ]

                        EditingLanguage formModel ->
                            Html.Styled.toUnstyled (viewLanguageForm model.mode formModel model.isSubmitting model.availableVoices model.availableDictionaries model.dictionariesLoadStatus)
                    ]
                ]
            ]
    }


viewLanguageForm : EditMode -> LanguageFormModel -> Bool -> List Voice -> List String -> DictionariesLoadStatus -> Html Msg
viewLanguageForm mode { originalLanguage, workingLanguage, currentDictInput, ttsRateInput, ttsPitchInput, selectedDictPath } isSubmitting availableVoices availableDictionaries dictionariesLoadStatus =
    let
        hasChanges =
            case originalLanguage of
                Just orig ->
                    orig /= workingLanguage

                Nothing ->
                    True

        isValid =
            not (String.isEmpty workingLanguage.name)

        statusMessages =
            if hasChanges && not isSubmitting then
                [ div [ style "color" "orange" ]
                    [ text "You have unsaved changes." ]
                ]

            else if isSubmitting then
                [ div [ style "color" "gray" ]
                    [ text
                        (case mode of
                            CreateMode ->
                                "Creating language..."

                            EditMode ->
                                "Saving changes..."
                        )
                    ]
                ]

            else
                []

        buttons =
            List.filterMap identity
                [ Just
                    (buttonC
                        { label =
                            if isSubmitting then
                                case mode of
                                    CreateMode ->
                                        "Creating..."

                                    EditMode ->
                                        "Saving..."

                            else
                                case mode of
                                    CreateMode ->
                                        "Create"

                                    EditMode ->
                                        "Save"
                        , onPress =
                            if isSubmitting || not hasChanges || not isValid then
                                Nothing

                            else
                                Just SubmitForm
                        }
                    )
                , Just
                    (buttonC
                        { label = "Cancel"
                        , onPress =
                            if isSubmitting then
                                Nothing

                            else
                                Just CancelEdit
                        }
                    )
                , if mode == EditMode then
                    Just
                        (buttonC
                            { label = "Delete"
                            , onPress =
                                if isSubmitting then
                                    Nothing

                                else
                                    Just DeleteLanguage
                            }
                        )

                  else
                    Nothing
                ]
    in
    formC
        { sections =
            [ { title = Just "Basic Information"
              , rows =
                    [ inputC
                        { label = "Language Name"
                        , toMsg = UpdateNameInput
                        , value_ = workingLanguage.name
                        , placeholder = "Enter language name..."
                        }
                    , stringListC
                        { label = "Dictionaries"
                        , items = workingLanguage.dicts
                        , currentInput = currentDictInput
                        , onListChange = UpdateDictsList
                        , onInputChange = UpdateDictInput
                        }
                    ]
              , buttons = []
              }
            , { title = Just "Add Dictionary from Available"
              , rows = viewDictionarySelectorRows selectedDictPath availableDictionaries dictionariesLoadStatus
              , buttons = []
              }
            , { title = Just "Text-to-Speech Settings"
              , rows =
                    [ numberInputC
                        { label = "TTS Rate"
                        , toMsg = UpdateTtsRateInput
                        , min = 0.1
                        , max = 10.0
                        , value_ = Maybe.withDefault 1.0 workingLanguage.ttsRate
                        , step = 0.1
                        , placeholder = "1.0"
                        }
                    , numberInputC
                        { label = "TTS Pitch"
                        , toMsg = UpdateTtsPitchInput
                        , min = 0.0
                        , max = 2.0
                        , value_ = Maybe.withDefault 1.0 workingLanguage.ttsPitch
                        , step = 0.1
                        , placeholder = "1.0"
                        }
                    , viewVoiceDropdown workingLanguage.ttsVoice availableVoices
                    ]
              , buttons = []
              }
            , { title = Just "DeepL Settings"
              , rows =
                    [ inputWithTooltipC
                        { label = "Source Language"
                        , tooltip = "DeepL Source Language Code (e.g., EN, FR, JA)"
                        , toMsg = UpdateDeeplSourceLang
                        , value_ = Maybe.withDefault "" workingLanguage.deeplSourceLang
                        , placeholder = "EN, FR, JA..."
                        }
                    , inputWithTooltipC
                        { label = "Target Language"
                        , tooltip = "DeepL Target Language Code (e.g., EN, DE, FR)"
                        , toMsg = UpdateDeeplTargetLang
                        , value_ = Maybe.withDefault "" workingLanguage.deeplTargetLang
                        , placeholder = "EN, DE, FR..."
                        }
                    ]
              , buttons = []
              }
            , { title = Just "Parser Configuration"
              , rows =
                    List.concat
                        [ [ viewParserDropdown workingLanguage.parserConfig.whichParser ]
                        , if workingLanguage.parserConfig.whichParser == "base_spacy" then
                            [ inputWithTooltipC
                                { label = "SpaCy Model"
                                , tooltip = "SpaCy Model (find models at https://spacy.io/models)"
                                , toMsg = UpdateSpacyModel
                                , value_ = Maybe.withDefault "" (Dict.get "spacy_model" workingLanguage.parserConfig.parserArgs)
                                , placeholder = "e.g. en_core_web_sm"
                                }
                            ]

                          else
                            []
                        ]
              , buttons = []
              }
            ]
        , buttons = buttons
        , status = statusMessages
        }


viewDictionarySelectorRows : String -> List String -> DictionariesLoadStatus -> List (Html Msg)
viewDictionarySelectorRows selectedDictPath availableDictionaries dictionariesLoadStatus =
    [ case dictionariesLoadStatus of
        DictionariesLoading ->
            div [] [ text "Loading dictionaries..." ]

        DictionariesError errorMsg ->
            div [ class "error" ] [ text ("Error loading dictionaries: " ++ errorMsg) ]

        DictionariesLoadedSuccess ->
            if List.isEmpty availableDictionaries then
                div [ class "error" ]
                    [ text "No dictionaries found. Please add .ifo files to the dictionaries directory." ]

            else
                div []
                    [ selectC
                        { label = "Available Dictionaries"
                        , toMsg = DictPathChanged
                        , options = List.map (\dict -> { value = dict, label = dict }) availableDictionaries
                        , value_ = if String.isEmpty selectedDictPath then Nothing else Just selectedDictPath
                        , placeholder = "Select a dictionary..."
                        }
                    , div [ style "margin-top" "16px" ]
                        [ buttonC
                            { label = "Add Dictionary"
                            , onPress =
                                if String.isEmpty selectedDictPath then
                                    Nothing

                                else
                                    Just AddSelectedDict
                            }
                        ]
                    ]

        DictionariesNotLoaded ->
            div [] []
    ]


viewDictionarySelector : String -> List String -> DictionariesLoadStatus -> Html Msg
viewDictionarySelector selectedDictPath availableDictionaries dictionariesLoadStatus =
    formSectionC
        { title = "Add Dictionary from Available"
        , rows = viewDictionarySelectorRows selectedDictPath availableDictionaries dictionariesLoadStatus
        }


viewVoiceDropdown : Maybe String -> List Voice -> Html Msg
viewVoiceDropdown selectedVoice voices =
    selectC
        { label = "TTS Voice"
        , toMsg = UpdateTtsVoice
        , options = List.map (\voice -> { value = voice.name, label = voice.name ++ " (" ++ voice.lang ++ ")" }) voices
        , value_ = selectedVoice
        , placeholder = "Select a voice..."
        }


viewParserDropdown : String -> Html Msg
viewParserDropdown selectedParser =
    selectC
        { label = "Parser"
        , toMsg = UpdateParserType
        , options =
            [ { value = "base_spacy", label = "Plain spaCy" }
            , { value = "enhanced_japanese", label = "Enhanced Japanese" }
            ]
        , value_ = if String.isEmpty selectedParser then Nothing else Just selectedParser
        , placeholder = "Select a parser..."
        }
