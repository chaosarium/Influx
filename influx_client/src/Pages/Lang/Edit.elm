module Pages.Lang.Edit exposing (Model, Msg, page)

import Api
import Api.DictionaryList
import Api.GetLanguage
import Api.LangCreate
import Api.LangDelete
import Api.LangEdit
import Bindings exposing (InfluxResourceId(..), Language, LanguageCreateRequest, ParserConfig)
import Components.FormElements exposing (SelectCOption, buttonC, inputC, selectC, stringListC)
import Components.Styles as Styles
import Components.Topbar
import Dict exposing (Dict)
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class, selected, style, value)
import Html.Events exposing (onClick, onInput)
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
    | UpdateTtsRateInput String
    | UpdateTtsPitchInput String
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
            let
                rateValue =
                    if String.isEmpty value then
                        Nothing

                    else
                        String.toFloat value
            in
            updateWorkingLanguage (\lang -> { lang | ttsRate = rateValue }) model
                |> updateFormInput (\formModel -> { formModel | ttsRateInput = value })

        UpdateTtsPitchInput value ->
            let
                pitchValue =
                    if String.isEmpty value then
                        Nothing

                    else
                        String.toFloat value
            in
            updateWorkingLanguage (\lang -> { lang | ttsPitch = pitchValue }) model
                |> updateFormInput (\formModel -> { formModel | ttsPitchInput = value })

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
        [ div [ class "outer-layout" ]
            [ Components.Topbar.view {}
            , Html.div [ class "toast-tray" ] [ Toast.render viewToast shared.toast_tray (Toast.config (SharedMsg << Shared.Msg.ToastMsg)) ]
            , Html.div [ class "layout-content" ]
                [ Html.h1 [] [ Html.text title ]
                , case model.formModel of
                    LoadingForm ->
                        div [] [ Html.text "Loading..." ]

                    ErrorForm error ->
                        div [ style "color" "red" ] [ Html.text error ]

                    EditingLanguage formModel ->
                        viewLanguageForm model.mode formModel model.isSubmitting model.availableVoices model.availableDictionaries model.dictionariesLoadStatus
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
    in
    Html.form [ Html.Events.onSubmit SubmitForm ]
        [ inputC [] "Language Name" "nameInput" UpdateNameInput workingLanguage.name
        , stringListC "Dictionary URLs" "dictsInput" UpdateDictsList UpdateDictInput workingLanguage.dicts currentDictInput
        , viewDictionarySelector selectedDictPath availableDictionaries dictionariesLoadStatus
        , Html.h3 [] [ Html.text "Text-to-Speech Settings" ]
        , inputC [] "TTS Rate (0.1-10.0)" "ttsRateInput" UpdateTtsRateInput ttsRateInput
        , inputC [] "TTS Pitch (0.0-2.0)" "ttsPitchInput" UpdateTtsPitchInput ttsPitchInput
        , viewVoiceDropdown workingLanguage.ttsVoice availableVoices
        , Html.h3 [] [ Html.text "DeepL Translation Settings" ]
        , inputC [] "DeepL Source Language Code (e.g., EN, FR, JA)" "deeplSourceInput" UpdateDeeplSourceLang (Maybe.withDefault "" workingLanguage.deeplSourceLang)
        , inputC [] "DeepL Target Language Code (e.g., EN, DE, FR)" "deeplTargetInput" UpdateDeeplTargetLang (Maybe.withDefault "" workingLanguage.deeplTargetLang)
        , Html.h3 [] [ Html.text "Parser Configuration" ]
        , viewParserDropdown workingLanguage.parserConfig.whichParser
        , if workingLanguage.parserConfig.whichParser == "base_spacy" then
            inputC [] "Custom spaCy Model (find at https://spacy.io/models)" "spacyModelInput" UpdateSpacyModel (Maybe.withDefault "" (Dict.get "spacy_model" workingLanguage.parserConfig.parserArgs))

          else
            Utils.htmlEmpty
        , div []
            [ buttonC
                [ onClick SubmitForm
                , Html.Attributes.disabled (isSubmitting || not hasChanges || not isValid)
                ]
                (if isSubmitting then
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
                )
            , buttonC
                [ onClick CancelEdit
                , Html.Attributes.disabled isSubmitting
                ]
                "Cancel"
            , if mode == EditMode then
                buttonC
                    [ onClick DeleteLanguage
                    , Html.Attributes.disabled isSubmitting
                    , Html.Attributes.style "background-color" "red"
                    , Html.Attributes.style "margin-left" "10px"
                    ]
                    "Delete"

              else
                Utils.htmlEmpty
            ]
        , if hasChanges && not isSubmitting then
            Html.div [ Html.Attributes.style "color" "orange" ]
                [ Html.text "You have unsaved changes." ]

          else if isSubmitting then
            Html.div [ Html.Attributes.style "color" "gray" ]
                [ Html.text
                    (case mode of
                        CreateMode ->
                            "Creating language..."

                        EditMode ->
                            "Saving changes..."
                    )
                ]

          else
            Utils.htmlEmpty
        ]


viewDictionarySelector : String -> List String -> DictionariesLoadStatus -> Html Msg
viewDictionarySelector selectedDictPath availableDictionaries dictionariesLoadStatus =
    Html.div []
        [ Html.h3 [] [ Html.text "Add Dictionary from Available" ]
        , case dictionariesLoadStatus of
            DictionariesLoading ->
                Html.div [] [ Html.text "Loading dictionaries..." ]

            DictionariesError errorMsg ->
                Html.div [ class "error" ] [ Html.text ("Error loading dictionaries: " ++ errorMsg) ]

            DictionariesLoadedSuccess ->
                if List.isEmpty availableDictionaries then
                    Html.div [ class "error" ]
                        [ Html.text "No dictionaries found. Please add .ifo files to the dictionaries directory." ]

                else
                    Html.div []
                        [ selectC
                            "Available Dictionaries"
                            "dict-selector"
                            DictPathChanged
                            (List.map (\dict -> { value = dict, label = dict }) availableDictionaries)
                            selectedDictPath
                        , Html.div [ Html.Attributes.style "margin-top" "10px" ]
                            [ buttonC
                                [ onClick AddSelectedDict
                                , Html.Attributes.disabled (String.isEmpty selectedDictPath)
                                ]
                                "Add Dictionary"
                            ]
                        ]

            DictionariesNotLoaded ->
                Html.div [] []
        ]


viewVoiceDropdown : Maybe String -> List Voice -> Html Msg
viewVoiceDropdown selectedVoice voices =
    Html.div []
        [ Html.label [] [ Html.text "TTS Voice" ]
        , Html.select
            [ onInput UpdateTtsVoice
            , value (Maybe.withDefault "" selectedVoice)
            ]
            (Html.option [ value "" ] [ Html.text "-- Select Voice --" ]
                :: List.map
                    (\voice ->
                        Html.option
                            [ value voice.name
                            , selected (selectedVoice == Just voice.name)
                            ]
                            [ Html.text (voice.name ++ " (" ++ voice.lang ++ ")") ]
                    )
                    voices
            )
        ]


viewParserDropdown : String -> Html Msg
viewParserDropdown selectedParser =
    Html.div []
        [ Html.label [] [ Html.text "Parser" ]
        , Html.select
            [ onInput UpdateParserType
            , value selectedParser
            ]
            [ Html.option
                [ value "base_spacy"
                , selected (selectedParser == "base_spacy")
                ]
                [ Html.text "Base (spaCy)" ]
            , Html.option
                [ value "enhanced_japanese"
                , selected (selectedParser == "enhanced_japanese")
                ]
                [ Html.text "Enhanced Japanese" ]
            ]
        ]


viewToast : List (Html.Attribute msg) -> Toast.Info String -> Html msg
viewToast attributes toast =
    Html.div (class "toast toast--spaced" :: attributes) [ Html.text toast.content ]
