module Pages.Doc.Edit exposing (Model, Msg, page)

import Api
import Api.DocCreate
import Api.DocDelete
import Api.DocEdit
import Api.GetAnnotatedDoc
import Api.GetLanguages
import Bindings exposing (Document, InfluxResourceId(..), Language)
import BindingsUtils
import Colours
import Components.FormElements3 exposing (FormSection, SelectCOption, buttonC, buttonRowC, formC, inputC, selectC, stringListC, textareaC)
import Components.ToastView
import Components.Topbar
import Css exposing (marginTop)
import Dict
import Effect exposing (Effect)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (class, css, style)
import Html.Styled.Events exposing (onClick)
import Http
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



-- INIT


type alias Model =
    { documentId : Maybe InfluxResourceId
    , documentData : Api.Data Document
    , languagesData : Api.Data (List Language)
    , formModel : FormModel
    , isSubmitting : Bool
    , mode : EditMode
    , selectedLanguageId : Maybe InfluxResourceId
    }


type EditMode
    = CreateMode
    | EditMode


type FormModel
    = EditingDocument DocumentFormModel
    | LoadingForm
    | ErrorForm String


type alias DocumentFormModel =
    { originalDocument : Maybe Document
    , workingDocument : Document
    , currentTagInput : String
    }


emptyDocument : InfluxResourceId -> Document
emptyDocument langId =
    { id = Nothing
    , title = ""
    , content = ""
    , docType = ""
    , tags = []
    , langId = langId
    , createdTs = ""
    , updatedTs = ""
    }


init : Route () -> () -> ( Model, Effect Msg )
init route () =
    let
        docId =
            case Dict.get "docId" route.query of
                Just docIdString ->
                    case String.toInt docIdString of
                        Just id ->
                            Just (SerialId id)

                        Nothing ->
                            Just (StringId docIdString)

                Nothing ->
                    Nothing

        selectedLangId =
            case Dict.get "lang" route.query of
                Just langIdString ->
                    case String.toInt langIdString of
                        Just id ->
                            Just (SerialId id)

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        mode =
            case docId of
                Just _ ->
                    EditMode

                Nothing ->
                    CreateMode

        initEffects =
            case mode of
                EditMode ->
                    case docId of
                        Just docIdVal ->
                            [ Effect.sendCmd (Api.GetAnnotatedDoc.get { filepath = BindingsUtils.influxResourceIdToString docIdVal } DocumentDataResponded)
                            , Effect.sendCmd (Api.GetLanguages.get {} LanguagesDataResponded)
                            ]

                        Nothing ->
                            [ Effect.sendCmd (Api.GetLanguages.get {} LanguagesDataResponded) ]

                CreateMode ->
                    [ Effect.sendCmd (Api.GetLanguages.get {} LanguagesDataResponded) ]
    in
    ( { documentId = docId
      , documentData =
            case mode of
                EditMode ->
                    Api.Loading

                CreateMode ->
                    Api.NotAsked
      , languagesData = Api.Loading
      , formModel = LoadingForm
      , isSubmitting = False
      , mode = mode
      , selectedLanguageId = selectedLangId
      }
    , Effect.batch initEffects
    )



-- UPDATE


type Msg
    = DocumentDataResponded (Result Http.Error Bindings.GetDocResponse)
    | LanguagesDataResponded (Result Http.Error (List Language))
    | UpdateTitleInput String
    | UpdateContentInput String
    | UpdateDocTypeInput String
    | UpdateTagsList (List String)
    | UpdateTagInput String
    | UpdateLanguageInput String
    | SubmitForm
    | CancelEdit
    | DocumentCreateResponded (Result Http.Error Document)
    | DocumentEditResponded (Result Http.Error Document)
    | DeleteDocument
    | DocumentDeleteResponded (Result Http.Error ())
    | SharedMsg Shared.Msg.Msg


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg sharedMsg ->
            ( model, Effect.sendSharedMsg sharedMsg )

        DocumentDataResponded (Ok res) ->
            let
                document =
                    res.docPackage.document
            in
            ( { model
                | documentData = Api.Success document
                , formModel =
                    EditingDocument
                        { originalDocument = Just document
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
            let
                newFormModel =
                    case model.mode of
                        CreateMode ->
                            let
                                defaultLangId =
                                    case model.selectedLanguageId of
                                        Just langId ->
                                            langId

                                        Nothing ->
                                            case List.head languages of
                                                Just lang ->
                                                    case lang.id of
                                                        Just id ->
                                                            id

                                                        Nothing ->
                                                            SerialId 1

                                                Nothing ->
                                                    SerialId 1
                            in
                            EditingDocument
                                { originalDocument = Nothing
                                , workingDocument = emptyDocument defaultLangId
                                , currentTagInput = ""
                                }

                        EditMode ->
                            model.formModel
            in
            ( { model
                | languagesData = Api.Success languages
                , formModel = newFormModel
              }
            , Effect.none
            )

        LanguagesDataResponded (Err httpError) ->
            ( { model | languagesData = Api.Failure httpError }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to load languages: " ++ Api.stringOfHttpErrMsg httpError))
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
                    ( model, Effect.sendSharedMsg (Shared.Msg.AddToast "Invalid language selection") )

        SubmitForm ->
            case model.formModel of
                EditingDocument { workingDocument } ->
                    case model.mode of
                        CreateMode ->
                            let
                                createRequest =
                                    { langId = workingDocument.langId
                                    , title = workingDocument.title
                                    , content = workingDocument.content
                                    , docType = workingDocument.docType
                                    , tags = workingDocument.tags
                                    }
                            in
                            ( { model | isSubmitting = True }
                            , Effect.sendCmd (Api.DocCreate.create createRequest DocumentCreateResponded)
                            )

                        EditMode ->
                            ( { model | isSubmitting = True }
                            , Effect.sendCmd (Api.DocEdit.edit workingDocument DocumentEditResponded)
                            )

                _ ->
                    ( model, Effect.none )

        CancelEdit ->
            ( model
            , Effect.pushRoutePath Route.Path.Docs
            )

        DocumentCreateResponded (Ok createdDocument) ->
            ( { model | isSubmitting = False }
            , Effect.batch
                [ Effect.sendSharedMsg (Shared.Msg.AddToast "Document created successfully")
                , Effect.pushRoutePath Route.Path.Docs
                ]
            )

        DocumentCreateResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to create document: " ++ Api.stringOfHttpErrMsg httpError))
            )

        DocumentEditResponded (Ok updatedDocument) ->
            ( { model
                | formModel =
                    EditingDocument
                        { originalDocument = Just updatedDocument
                        , workingDocument = updatedDocument
                        , currentTagInput = ""
                        }
                , isSubmitting = False
              }
            , Effect.sendSharedMsg (Shared.Msg.AddToast "Document updated successfully")
            )

        DocumentEditResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to update document: " ++ Api.stringOfHttpErrMsg httpError))
            )

        DeleteDocument ->
            case model.documentId of
                Just docId ->
                    ( { model | isSubmitting = True }
                    , Effect.sendCmd (Api.DocDelete.delete (BindingsUtils.influxResourceIdToString docId) DocumentDeleteResponded)
                    )

                Nothing ->
                    ( model, Effect.sendSharedMsg (Shared.Msg.AddToast "Cannot delete document: No document ID") )

        DocumentDeleteResponded (Ok ()) ->
            ( { model | isSubmitting = False }
            , Effect.batch
                [ Effect.sendSharedMsg (Shared.Msg.AddToast "Document deleted successfully")
                , Effect.pushRoutePath Route.Path.Docs
                ]
            )

        DocumentDeleteResponded (Err httpError) ->
            ( { model | isSubmitting = False }
            , Effect.sendSharedMsg (Shared.Msg.AddToast ("Failed to delete document: " ++ Api.stringOfHttpErrMsg httpError))
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


languageOptions : List Language -> List SelectCOption
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


view : Shared.Model -> ThisRoute -> Model -> View Msg
view shared route model =
    let
        title =
            case model.mode of
                CreateMode ->
                    "Create Document"

                EditMode ->
                    "Edit Document"
    in
    { title = title
    , body =
        [ Html.div [ class "layout-outer" ]
            [ Html.fromUnstyled <| Components.Topbar.view {}
            , Html.div [ class "toast-tray" ] [ Html.fromUnstyled <| Toast.render Components.ToastView.viewToast shared.toast_tray (Toast.config (SharedMsg << Shared.Msg.ToastMsg)) ]
            , Html.div [ class "layout-content" ]
                [ Html.h1 [] [ Html.text title ]
                , case model.formModel of
                    LoadingForm ->
                        div [] [ Html.text "Loading..." ]

                    ErrorForm error ->
                        div [ style "color" "red" ] [ Html.text error ]

                    EditingDocument formModel ->
                        viewDocumentForm formModel model.languagesData model.isSubmitting model.mode
                ]
            ]
        ]
    }


viewDocumentForm : DocumentFormModel -> Api.Data (List Language) -> Bool -> EditMode -> Html Msg
viewDocumentForm { originalDocument, workingDocument, currentTagInput } languagesData isSubmitting mode =
    let
        hasChanges =
            case originalDocument of
                Just original ->
                    original /= workingDocument

                Nothing ->
                    -- In create mode, consider there are changes if any field is filled
                    workingDocument.title /= "" || workingDocument.content /= ""

        submitButtonText =
            case mode of
                CreateMode ->
                    if isSubmitting then
                        "Creating..."

                    else
                        "Create"

                EditMode ->
                    if isSubmitting then
                        "Saving..."

                    else
                        "Save"
    in
    formC
        { sections =
            [ { title = Nothing
              , rows =
                    [ inputC { label = "Title", toMsg = UpdateTitleInput, value_ = workingDocument.title, placeholder = "Edit title..." }
                    , textareaC { label = "Content", toMsg = UpdateContentInput, value_ = workingDocument.content, placeholder = "Edit content..." }
                    , inputC { label = "Document Type", toMsg = UpdateDocTypeInput, value_ = workingDocument.docType, placeholder = "Edit document type..." }
                    , stringListC { label = "Tags", items = workingDocument.tags, currentInput = currentTagInput, onListChange = UpdateTagsList, onInputChange = UpdateTagInput }
                    , case languagesData of
                        Api.Success languages ->
                            selectC
                                { label = "Language"
                                , toMsg = UpdateLanguageInput
                                , options = languageOptions languages
                                , value_ =
                                    case workingDocument.langId of
                                        SerialId id ->
                                            Just (String.fromInt id)

                                        StringId id ->
                                            Just id
                                , placeholder = "Select a language..."
                                }

                        Api.Loading ->
                            Html.div [] [ Html.text "Loading languages..." ]

                        Api.Failure _ ->
                            Html.div [] [ Html.text "Failed to load languages" ]

                        Api.NotAsked ->
                            Html.div [] [ Html.text "Languages not loaded" ]
                    ]
              , buttons = []
              }
            ]
        , buttons =
            List.filterMap identity
                [ Just
                    (buttonC
                        { onPress =
                            if isSubmitting || not hasChanges then
                                Nothing

                            else
                                Just SubmitForm
                        , label = submitButtonText
                        }
                    )
                , Just
                    (buttonC
                        { onPress =
                            if isSubmitting then
                                Nothing

                            else
                                Just CancelEdit
                        , label = "Cancel"
                        }
                    )
                , case mode of
                    EditMode ->
                        Just
                            (buttonC
                                { onPress =
                                    if isSubmitting then
                                        Nothing

                                    else
                                        Just DeleteDocument
                                , label =
                                    if isSubmitting then
                                        "Deleting..."

                                    else
                                        "Delete"
                                }
                            )

                    CreateMode ->
                        Nothing
                ]
        , status =
            [ if hasChanges && not isSubmitting then
                Html.div [ css [ Colours.colorCss Colours.orange9, marginTop (Css.px 8) ] ]
                    [ Html.text
                        (case mode of
                            CreateMode ->
                                "Fill in the form to create a new document."

                            EditMode ->
                                "You have unsaved changes."
                        )
                    ]

              else if isSubmitting then
                Html.div [ css [ Colours.colorCss Colours.orange9, marginTop (Css.px 8) ] ]
                    [ Html.text
                        (case mode of
                            CreateMode ->
                                "Creating document..."

                            EditMode ->
                                "Saving changes..."
                        )
                    ]

              else
                Html.text ""
            ]
        }
