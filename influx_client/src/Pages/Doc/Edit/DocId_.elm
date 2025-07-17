module Pages.Doc.Edit.DocId_ exposing (Model, Msg, page)

import Api
import Api.DocEdit
import Api.GetAnnotatedDoc
import Api.GetLanguages
import Bindings exposing (Document, InfluxResourceId(..), LanguageEntry)
import Components.FormElements exposing (SelectCOption, buttonC, inputC, selectC, stringListC, textboxC)
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
import Toast
import Utils
import View exposing (View)


page : Shared.Model -> Route { docId : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init { documentId = route.params.docId }
        , update = update
        , subscriptions = subscriptions
        , view = view route
        }


type alias ThisRoute =
    Route { docId : String }



-- INIT


type alias Model =
    { documentId : InfluxResourceId
    , documentData : Api.Data Document
    , languagesData : Api.Data (List LanguageEntry)
    , formModel : FormModel
    , toast_tray : Toast.Tray String
    , isSubmitting : Bool
    }


type FormModel
    = EditingDocument DocumentFormModel
    | LoadingForm
    | ErrorForm String


type alias DocumentFormModel =
    { originalDocument : Document
    , workingDocument : Document
    , currentTagInput : String
    }


init : { documentId : String } -> () -> ( Model, Effect Msg )
init { documentId } () =
    let
        docId =
            case String.toInt documentId of
                Just id ->
                    SerialId id

                Nothing ->
                    StringId documentId
    in
    ( { documentId = docId
      , documentData = Api.Loading
      , languagesData = Api.Loading
      , formModel = LoadingForm
      , toast_tray = Toast.tray
      , isSubmitting = False
      }
    , Effect.batch
        [ Effect.sendCmd (Api.GetAnnotatedDoc.get { filepath = documentId } DocumentDataResponded)
        , Effect.sendCmd (Api.GetLanguages.get {} LanguagesDataResponded)
        ]
    )



-- UPDATE


type Msg
    = DocumentDataResponded (Result Http.Error Bindings.GetDocResponse)
    | LanguagesDataResponded (Result Http.Error (List LanguageEntry))
    | UpdateTitleInput String
    | UpdateContentInput String
    | UpdateDocTypeInput String
    | UpdateTagsList (List String)
    | UpdateTagInput String
    | UpdateLanguageInput String
    | SubmitForm
    | CancelEdit
    | DocumentEditResponded (Result Http.Error Document)
    | ToastMsg Toast.Msg
    | AddToast String


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ToastMsg tmsg ->
            let
                ( toast_tray, toast_cmd ) =
                    Toast.update tmsg model.toast_tray
            in
            ( { model | toast_tray = toast_tray }
            , Effect.sendCmd (Cmd.map ToastMsg toast_cmd)
            )

        AddToast message ->
            let
                ( toast_tray, toast_cmd ) =
                    Toast.add model.toast_tray (Toast.expireIn 5000 message)
            in
            ( { model | toast_tray = toast_tray }
            , Effect.sendCmd (Cmd.map ToastMsg toast_cmd)
            )

        DocumentDataResponded (Ok res) ->
            let
                document =
                    res.docPackage.document
            in
            ( { model
                | documentData = Api.Success document
                , formModel =
                    EditingDocument
                        { originalDocument = document
                        , workingDocument = document
                        , currentTagInput = ""
                        }
              }
            , Effect.none
            )

        DocumentDataResponded (Err httpError) ->
            ( { model
                | documentData = Api.Failure httpError
                , formModel = ErrorForm ("Failed to load document: " ++ Api.stringOfHttpErrMsg httpError)
              }
            , Effect.none
            )

        LanguagesDataResponded (Ok languages) ->
            ( { model | languagesData = Api.Success languages }
            , Effect.none
            )

        LanguagesDataResponded (Err httpError) ->
            ( { model | languagesData = Api.Failure httpError }
            , Effect.sendMsg (AddToast ("Failed to load languages: " ++ Api.stringOfHttpErrMsg httpError))
            )

        UpdateTitleInput value ->
            updateWorkingDocument (\doc -> { doc | title = value }) model

        UpdateContentInput value ->
            updateWorkingDocument (\doc -> { doc | content = value }) model

        UpdateDocTypeInput value ->
            updateWorkingDocument (\doc -> { doc | docType = value }) model

        UpdateTagsList newTags ->
            updateWorkingDocument (\doc -> { doc | tags = newTags }) model

        UpdateTagInput value ->
            case model.formModel of
                EditingDocument formModel ->
                    ( { model
                        | formModel =
                            EditingDocument
                                { formModel | currentTagInput = value }
                      }
                    , Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        UpdateLanguageInput value ->
            case String.toInt value of
                Just langId ->
                    updateWorkingDocument (\doc -> { doc | langId = SerialId langId }) model

                Nothing ->
                    ( model, Effect.sendMsg (AddToast "Invalid language selection") )

        SubmitForm ->
            case model.formModel of
                EditingDocument { workingDocument } ->
                    ( { model | isSubmitting = True }
                    , Effect.sendCmd (Api.DocEdit.edit workingDocument DocumentEditResponded)
                    )

                _ ->
                    ( model, Effect.none )

        CancelEdit ->
            ( model
            , Effect.pushRoutePath Route.Path.Docs
            )

        DocumentEditResponded (Ok updatedDocument) ->
            ( { model
                | formModel =
                    EditingDocument
                        { originalDocument = updatedDocument
                        , workingDocument = updatedDocument
                        , currentTagInput = ""
                        }
                , isSubmitting = False
              }
            , Effect.sendMsg (AddToast "Document updated successfully")
            )

        DocumentEditResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendMsg (AddToast ("Failed to update document: " ++ Api.stringOfHttpErrMsg httpError))
            )


updateWorkingDocument : (Document -> Document) -> Model -> ( Model, Effect Msg )
updateWorkingDocument updateFn model =
    case model.formModel of
        EditingDocument formModel ->
            ( { model
                | formModel =
                    EditingDocument
                        { formModel | workingDocument = updateFn formModel.workingDocument }
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


languageOptions : List LanguageEntry -> List SelectCOption
languageOptions languages =
    List.map
        (\lang ->
            { value =
                case lang.id of
                    Just (SerialId id) ->
                        String.fromInt id

                    Just (StringId id) ->
                        id

                    Nothing ->
                        ""
            , label = lang.name
            }
        )
        languages


view : ThisRoute -> Model -> View Msg
view route model =
    { title = "Edit Document"
    , body =
        [ Components.Topbar.view {}
        , Html.div [ class "toast-tray" ] [ Toast.render viewToast model.toast_tray (Toast.config ToastMsg) ]
        , Html.h1 [] [ Html.text "Edit Document" ]
        , case model.formModel of
            LoadingForm ->
                div [] [ Html.text "Loading..." ]

            ErrorForm error ->
                div [ style "color" "red" ] [ Html.text error ]

            EditingDocument formModel ->
                viewDocumentForm formModel model.languagesData model.isSubmitting
        ]
    }


viewDocumentForm : DocumentFormModel -> Api.Data (List LanguageEntry) -> Bool -> Html Msg
viewDocumentForm { originalDocument, workingDocument, currentTagInput } languagesData isSubmitting =
    let
        hasChanges =
            originalDocument /= workingDocument
    in
    Html.form [ Html.Events.onSubmit SubmitForm ]
        [ inputC [] "Title" "titleInput" UpdateTitleInput workingDocument.title
        , textboxC "Content" "contentInput" UpdateContentInput workingDocument.content
        , inputC [] "Document Type" "docTypeInput" UpdateDocTypeInput workingDocument.docType
        , stringListC "Tags" "tagsInput" UpdateTagsList UpdateTagInput workingDocument.tags currentTagInput
        , case languagesData of
            Api.Success languages ->
                selectC
                    "Language"
                    "languageInput"
                    UpdateLanguageInput
                    (languageOptions languages)
                    (case workingDocument.langId of
                        SerialId id ->
                            String.fromInt id

                        StringId id ->
                            id
                    )

            Api.Loading ->
                div [] [ Html.text "Loading languages..." ]

            Api.Failure _ ->
                div [] [ Html.text "Failed to load languages" ]
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
