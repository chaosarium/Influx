module Pages.Lang.Edit.LangId_ exposing (Model, Msg, page)

import Api
import Api.GetLanguage
import Api.LangEdit
import Bindings exposing (InfluxResourceId(..), LanguageEntry)
import Components.FormElements exposing (buttonC, inputC, stringListC)
import Components.Styles as Styles
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Http
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



-- INIT


type alias Model =
    { languageId : InfluxResourceId
    , languageData : Api.Data LanguageEntry
    , formModel : FormModel
    , isSubmitting : Bool
    }


type FormModel
    = EditingLanguage LanguageFormModel
    | LoadingForm
    | ErrorForm String


type alias LanguageFormModel =
    { originalLanguage : LanguageEntry
    , workingLanguage : LanguageEntry
    , currentDictInput : String
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
      }
    , Effect.sendCmd (Api.GetLanguage.get { langId = languageId } LanguageDataResponded)
    )



-- UPDATE


type Msg
    = LanguageDataResponded (Result Http.Error (Maybe LanguageEntry))
    | UpdateCodeInput String
    | UpdateNameInput String
    | UpdateDictsList (List String)
    | UpdateDictInput String
    | SubmitForm
    | CancelEdit
    | LanguageEditResponded (Result Http.Error LanguageEntry)
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

        UpdateCodeInput value ->
            updateWorkingLanguage (\lang -> { lang | code = value }) model

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
                        }
                , isSubmitting = False
              }
            , Effect.sendSharedMsg (Shared.Msg.AddToast "Language updated successfully")
            )

        LanguageEditResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to update language: " ++ Api.stringOfHttpErrMsg httpError))
            )


updateWorkingLanguage : (LanguageEntry -> LanguageEntry) -> Model -> ( Model, Effect Msg )
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



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
                viewLanguageForm formModel model.isSubmitting
        ]
    }


viewLanguageForm : LanguageFormModel -> Bool -> Html Msg
viewLanguageForm { originalLanguage, workingLanguage, currentDictInput } isSubmitting =
    let
        hasChanges =
            originalLanguage /= workingLanguage
    in
    Html.form [ Html.Events.onSubmit SubmitForm ]
        [ inputC [] "Language Code" "codeInput" UpdateCodeInput workingLanguage.code
        , inputC [] "Language Name" "nameInput" UpdateNameInput workingLanguage.name
        , stringListC "Dictionary URLs" "dictsInput" UpdateDictsList UpdateDictInput workingLanguage.dicts currentDictInput
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


viewToast : List (Html.Attribute msg) -> Toast.Info String -> Html msg
viewToast attributes toast =
    Html.div (class "toast toast--spaced" :: attributes) [ Html.text toast.content ]
