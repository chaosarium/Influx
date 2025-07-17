module Pages.Doc.Doc_ exposing (Model, Msg, page)

import Api
import Api.GetAnnotatedDoc
import Api.TermEdit
import Bindings exposing (..)
import Components.AnnotatedText as AnnotatedText
import Components.DbgDisplay
import Components.TermEditForm as TermEditForm
import Components.Topbar
import Datastore.DictContext as DictContext
import Datastore.DocContext as DocContext
import Datastore.FocusContext as FocusContext
import Dict
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events
import Html.Extra
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Toast
import Utils
import Utils.ModifierState as ModifierState
import View exposing (View)


page : Shared.Model -> Route { doc : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init { documentId = route.params.doc }
        , update = update
        , subscriptions = subscriptions
        , view = view route
        }


type alias ThisRoute =
    Route { doc : String }



-- INIT


type alias Model =
    { get_doc_api_res : Api.Data GetDocResponse
    , working_doc : DocContext.T
    , working_dict : DictContext.T
    , focus_ctx : FocusContext.T
    , form_model : TermEditForm.Model
    , modifier_state : ModifierState.Model
    , toast_tray : Toast.Tray String
    }


init : { documentId : String } -> () -> ( Model, Effect Msg )
init { documentId } () =
    ( { get_doc_api_res = Api.Loading
      , working_doc = DocContext.empty
      , working_dict = DictContext.empty
      , focus_ctx = FocusContext.new
      , form_model = TermEditForm.empty
      , modifier_state = ModifierState.init
      , toast_tray = Toast.tray
      }
    , Effect.sendCmd (Api.GetAnnotatedDoc.get { filepath = documentId } ApiResponded)
    )



-- UPDATE


type Msg
    = -- Initial load...
      ApiResponded (Result Http.Error GetDocResponse)
      -- Mouse selection...
    | SelectionMouseEvent FocusContext.Msg -- will update focus context
    | NoopMouseEvent FocusContext.Msg -- for mouse events that don't change the focus context
      -- Term editor...
    | TermEditorEvent TermEditForm.Msg
      -- Shared
    | ModifierStateMsg ModifierState.Msg
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

        ApiResponded (Ok res) ->
            let
                _ =
                    Effect.none
            in
            ( { model
                | get_doc_api_res = Api.Success res
                , working_doc = DocContext.fromAnnotatedDocument res.docPackage.languageId res.annotatedDoc
                , working_dict = DictContext.fromTermDictionary res.docPackage.languageId res.termDict
              }
            , Effect.none
            )

        ModifierStateMsg m ->
            ( { model | modifier_state = ModifierState.update m model.modifier_state }, Effect.none )

        ApiResponded (Err httpError) ->
            ( { model | get_doc_api_res = Api.Failure httpError }, Effect.none )

        SelectionMouseEvent m ->
            let
                focus_ctx =
                    FocusContext.update model.working_doc m model.focus_ctx

                ( form_model, _ ) =
                    TermEditForm.update model.working_dict (TermEditForm.EditingSegUpdated focus_ctx.segment_slice focus_ctx.segment_selection) model.form_model
            in
            ( { model
                | focus_ctx = focus_ctx
                , form_model = form_model
              }
            , Effect.none
            )

        TermEditorEvent formMsg ->
            case formMsg of
                TermEditForm.RequestEditTerm action term doc_path ->
                    let
                        documentId =
                            case doc_path of
                                Just path ->
                                    case String.toInt path.file of
                                        Just id ->
                                            Just (Bindings.SerialId id)

                                        Nothing ->
                                            Nothing

                                Nothing ->
                                    Nothing
                    in
                    ( model
                    , Effect.sendCmd (Api.TermEdit.edit { requestedAction = action, term = term, documentId = documentId } (TermEditorEvent << TermEditForm.GotTermEditResponse))
                    )

                TermEditForm.GotUpdatedAnnotatedDoc updated_doc ->
                    ( { model | working_doc = DocContext.fromAnnotatedDocument model.working_doc.lang_id updated_doc }
                    , Effect.none
                    )

                TermEditForm.OverwriteTerm term ->
                    ( { model | working_dict = DictContext.overwriteTerm model.working_dict term }
                    , Effect.none
                    )

                TermEditForm.AddToast message ->
                    let
                        ( toast_tray, toast_cmd ) =
                            Toast.add model.toast_tray (Toast.expireIn 5000 message)
                    in
                    ( { model | toast_tray = toast_tray }
                    , Effect.sendCmd (Cmd.map ToastMsg toast_cmd)
                    )

                _ ->
                    let
                        ( form_model, child_fx ) =
                            TermEditForm.update model.working_dict formMsg model.form_model
                    in
                    ( { model | form_model = form_model }
                    , Effect.map TermEditorEvent child_fx
                    )

        AddToast message ->
            let
                ( toast_tray, toast_cmd ) =
                    Toast.add model.toast_tray (Toast.expireIn 1000 message)
            in
            ( { model | toast_tray = toast_tray }
            , Effect.sendCmd (Cmd.map ToastMsg toast_cmd)
            )

        _ ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ ModifierState.subscriptions ModifierStateMsg
        ]



-- VIEW


viewSegExtraInfo : DictContext.T -> SentSegV2 -> Html msg
viewSegExtraInfo dict seg =
    let
        orthography =
            case seg.inner of
                TokenSeg token ->
                    token.orthography

                PhraseSeg phrase ->
                    phrase.normalisedOrthography

                WhitespaceSeg ->
                    ""

                PunctuationSeg ->
                    ""

        token_info =
            case DictContext.lookupToken dict orthography of
                Just token ->
                    [ Html.text ("token: " ++ token.orthography ++ " -> " ++ token.definition) ]

                Nothing ->
                    [ Html.text "no token info" ]

        phrase_info =
            case DictContext.lookupPhrase dict orthography of
                Just phrase ->
                    [ Html.text ("phrase: " ++ String.join " " phrase.orthographySeq ++ " -> " ++ phrase.definition) ]

                Nothing ->
                    [ Html.text "no phrase info" ]
    in
    Html.div []
        (token_info ++ phrase_info)



-- end


view : ThisRoute -> Model -> View Msg
view route model =
    let
        annotatedDocViewCtx =
            { dict = model.working_dict
            , modifier_state = model.modifier_state
            , mouse_handler = SelectionMouseEvent
            , focus_predicate =
                case model.focus_ctx.slice_selection of
                    Nothing ->
                        \_ -> False

                    Just slice ->
                        FocusContext.isSentSegInSlice slice
            , seg_display_predicate = \_ -> True
            , doc_seg_display_predicate = \_ -> True
            }
    in
    let
        selectedSegViewCtx =
            { dict = model.working_dict
            , modifier_state = model.modifier_state
            , mouse_handler = NoopMouseEvent
            , focus_predicate = \_ -> False
            , seg_display_predicate =
                case model.focus_ctx.slice_selection of
                    Nothing ->
                        \_ -> False

                    Just slice ->
                        FocusContext.isSentSegInSlice slice
            , doc_seg_display_predicate =
                case model.focus_ctx.slice_selection of
                    Nothing ->
                        \_ -> False

                    Just slice ->
                        FocusContext.isDocSegInSlice slice
            }
    in
    { title = "Document view"
    , body =
        [ Components.Topbar.view {}
        , Html.div [ class "toast-tray" ] [ Toast.render viewToast model.toast_tray (Toast.config ToastMsg) ]
        , Html.h1 [] [ Html.text ("Document ID: " ++ Utils.unwrappedPercentDecode route.params.doc) ]
        , case model.get_doc_api_res of
            Api.Loading ->
                Html.text "Loading..."

            Api.Failure err ->
                Html.text ("Error: " ++ Api.stringOfHttpErrMsg err)

            Api.Success _ ->
                div [ class "annotated-doc-div", class "dbg-on" ]
                    (AnnotatedText.view
                        annotatedDocViewCtx
                        model.working_doc
                    )

        -- for debugging check focus context model
        , Components.DbgDisplay.view "model.focus_ctx.last_hovered_at" model.focus_ctx.last_hovered_at
        , Components.DbgDisplay.view "model.focus_ctx.mouse_down_at" model.focus_ctx.mouse_down_at
        , Components.DbgDisplay.view "model.focus_ctx.last_mouse_down_at" model.focus_ctx.last_mouse_down_at
        , Components.DbgDisplay.view "model.focus_ctx.slice_selection" model.focus_ctx.slice_selection
        , Components.DbgDisplay.view "model.focus_ctx.selected_text" model.focus_ctx.selected_text
        , Components.DbgDisplay.view "model.focus_ctx.segment_selection" model.focus_ctx.segment_selection
        , Components.DbgDisplay.view "model.focus_ctx.segment_slice" model.focus_ctx.segment_slice

        -- selected text
        , div []
            [ Html.text
                ("selected text: "
                    ++ Maybe.withDefault "" model.focus_ctx.selected_text
                )
            ]

        -- selected segment
        , div []
            [ span []
                [ Html.text "selected seg: " ]
            , Maybe.withDefault
                (Html.text "")
                (Maybe.andThen (AnnotatedText.viewSentenceSegment selectedSegViewCtx) model.focus_ctx.segment_selection)
            , Html.Extra.viewMaybe (\seg -> viewSegExtraInfo model.working_dict seg) model.focus_ctx.segment_selection
            ]
        , TermEditForm.view model.form_model
            TermEditorEvent
            { dict = model.working_dict
            , doc_path =
                Just
                    { lang =
                        String.fromInt
                            (case model.working_doc.lang_id of
                                Bindings.SerialId id ->
                                    id

                                Bindings.StringId id ->
                                    0
                            )
                    , file = route.params.doc
                    }
            }
        ]
    }


viewToast : List (Html.Attribute msg) -> Toast.Info String -> Html msg
viewToast attributes toast =
    Html.div (class "toast toast--spaced" :: attributes) [ Html.text toast.content ]
