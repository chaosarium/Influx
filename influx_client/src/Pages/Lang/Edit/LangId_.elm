module Pages.Lang.Edit.LangId_ exposing (Model, Msg, page)

import Api
import Api.GetLanguage
import Api.LangEdit
import Bindings exposing (InfluxResourceId(..), Language)
import Components.FormElements exposing (buttonC, inputC, stringListC)
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


page : Shared.Model -> Route { langId : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init { languageId = route.params.langId }
        , update = update
        , subscriptions = subscriptions
        , view = view shared route
        }


type alias ThisRoute =
    Route { langId : String }


type alias Voice =
    { name : String
    , lang : String
    , default : Bool
    }



-- INIT


type alias Model =
    { languageId : InfluxResourceId
    , languageData : Api.Data Language
    , formModel : FormModel
    , isSubmitting : Bool
    , availableVoices : List Voice
    }


type FormModel
    = EditingLanguage LanguageFormModel
    | LoadingForm
    | ErrorForm String


type alias LanguageFormModel =
    { originalLanguage : Language
    , workingLanguage : Language
    , currentDictInput : String
    , ttsRateInput : String
    , ttsPitchInput : String
    }


init : { languageId : String } -> () -> ( Model, Effect Msg )
init { languageId } () =
    let
        langId =
            case String.toInt languageId of
                Just id ->
                    SerialId id

                Nothing ->
                    StringId languageId
    in
    ( { languageId = langId
      , languageData = Api.Loading
      , formModel = LoadingForm
      , isSubmitting = False
      , availableVoices = []
      }
    , Effect.batch
        [ Effect.sendCmd (Api.GetLanguage.get { langId = languageId } LanguageDataResponded)
        , Effect.ttsGetVoices
        ]
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
    | LanguageEditResponded (Result Http.Error Language)
    | VoicesReceived (Maybe D.Value)
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
                        { originalLanguage = language
                        , workingLanguage = language
                        , currentDictInput = ""
                        , ttsRateInput = Maybe.withDefault "" (Maybe.map String.fromFloat language.ttsRate)
                        , ttsPitchInput = Maybe.withDefault "" (Maybe.map String.fromFloat language.ttsPitch)
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
                    ( { model | isSubmitting = True }
                    , Effect.sendCmd (Api.LangEdit.edit workingLanguage LanguageEditResponded)
                    )

                _ ->
                    ( model, Effect.none )

        CancelEdit ->
            ( model
            , Effect.pushRoutePath Route.Path.Langs
            )

        LanguageEditResponded (Ok updatedLanguage) ->
            ( { model
                | formModel =
                    EditingLanguage
                        { originalLanguage = updatedLanguage
                        , workingLanguage = updatedLanguage
                        , currentDictInput = ""
                        , ttsRateInput = Maybe.withDefault "" (Maybe.map String.fromFloat updatedLanguage.ttsRate)
                        , ttsPitchInput = Maybe.withDefault "" (Maybe.map String.fromFloat updatedLanguage.ttsPitch)
                        }
                , isSubmitting = False
              }
            , Effect.sendSharedMsg (Shared.Msg.AddToast "Language updated successfully")
            )

        LanguageEditResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to update language: " ++ Api.stringOfHttpErrMsg httpError))
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
    { title = "Edit Language"
    , body =
        [ Components.Topbar.view {}
        , Html.div [ class "toast-tray" ] [ Toast.render viewToast shared.toast_tray (Toast.config (SharedMsg << Shared.Msg.ToastMsg)) ]
        , Html.h1 [] [ Html.text "Edit Language" ]
        , case model.formModel of
            LoadingForm ->
                div [] [ Html.text "Loading..." ]

            ErrorForm error ->
                div [ style "color" "red" ] [ Html.text error ]

            EditingLanguage formModel ->
                viewLanguageForm formModel model.isSubmitting model.availableVoices
        ]
    }


viewLanguageForm : LanguageFormModel -> Bool -> List Voice -> Html Msg
viewLanguageForm { originalLanguage, workingLanguage, currentDictInput, ttsRateInput, ttsPitchInput } isSubmitting availableVoices =
    let
        hasChanges =
            originalLanguage /= workingLanguage
    in
    Html.form [ Html.Events.onSubmit SubmitForm ]
        [ inputC [] "Language Name" "nameInput" UpdateNameInput workingLanguage.name
        , stringListC "Dictionary URLs" "dictsInput" UpdateDictsList UpdateDictInput workingLanguage.dicts currentDictInput
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
                , Html.Attributes.disabled (isSubmitting || not hasChanges)
                ]
                (if isSubmitting then
                    "Saving..."

                 else
                    "Save"
                )
            , buttonC
                [ onClick CancelEdit
                , Html.Attributes.disabled isSubmitting
                ]
                "Cancel"
            ]
        , if hasChanges && not isSubmitting then
            Html.div [ Html.Attributes.style "color" "orange" ]
                [ Html.text "You have unsaved changes." ]

          else if isSubmitting then
            Html.div [ Html.Attributes.style "color" "gray" ]
                [ Html.text "Saving changes..." ]

          else
            Utils.htmlEmpty
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
