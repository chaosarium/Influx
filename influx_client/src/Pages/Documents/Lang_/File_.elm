module Pages.Documents.Lang_.File_ exposing (Model, Msg, page)

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


page : Shared.Model -> Route { lang : String, file : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init { languageId = route.params.lang, filepath = route.params.file }
        , update = update
        , subscriptions = subscriptions
        , view = view route
        }


type alias ThisRoute =
    Route { lang : String, file : String }



-- INIT


type alias Model =
    { get_doc_api_res : Api.Data GetDocResponse
    , modifier_state : ModifierState.Model
    , working_doc : DocContext.T
    , working_dict : DictContext.T
    , focus_ctx : FocusContext.T
    , form_model : TermEditForm.Model
    , toast_tray : Toast.Tray String
    }


init :
    { languageId : String
    , filepath : String
    }
    -> ()
    -> ( Model, Effect Msg )
init args () =
    ( { get_doc_api_res = Api.Loading
      , modifier_state = ModifierState.init
      , working_doc = DocContext.empty
      , working_dict = DictContext.empty
      , focus_ctx = FocusContext.new
      , form_model = TermEditForm.empty
      , toast_tray = Toast.tray
      }
    , Effect.sendCmd (Api.GetAnnotatedDoc.get args ApiResponded)
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
                , working_doc = DocContext.fromAnnotatedDocument res.langId res.annotatedDoc
                , working_dict = DictContext.fromAnnotatedDocument res.langId res.annotatedDoc
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
                TermEditForm.RequestEditTerm action term ->
                    ( model
                    , Effect.sendCmd (Api.TermEdit.edit { requestedAction = action, term = term } (TermEditorEvent << TermEditForm.GotTermEditResponse))
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
    ModifierState.subscriptions ModifierStateMsg



-- Annotated Text view
-- VIEW
-- start TODO put in component


viewSegExtraInfo : DictContext.T -> SentSegV2 -> Html Msg
viewSegExtraInfo dict seg =
    case seg.inner of
        TokenSeg { orthography } ->
            Utils.htmlIf (Maybe.withDefault "" seg.attributes.lemma /= orthography) <| Html.span [] [ Html.text (" (lemma is " ++ Maybe.withDefault "" seg.attributes.lemma ++ ")") ]

        PhraseSeg { normalisedOrthography, components } ->
            Html.span []
                [ Html.text "=  "
                , AnnotatedText.viewRegisteredPhrase
                    { dict = dict, modifier_state = ModifierState.init, mouse_handler = NoopMouseEvent, focus_predicate = \_ -> False, seg_display_predicate = \_ -> True, doc_seg_display_predicate = \_ -> True }
                    []
                    (Maybe.withDefault { id = Nothing, langId = Bindings.SerialId -1, orthographySeq = [], definition = "", notes = "", originalContext = "", status = Bindings.Unmarked } (Dict.get normalisedOrthography dict.phraseDict))
                    seg
                    components
                ]

        WhitespaceSeg ->
            Html.Extra.nothing



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
    { title = "File view"
    , body =
        [ Components.Topbar.view {}
        , Html.div [ class "toast-tray" ] [ Toast.render viewToast model.toast_tray (Toast.config ToastMsg) ]
        , Html.h1 [] [ Html.text ("lang: " ++ route.params.lang ++ ", file: " ++ Utils.unwrappedPercentDecode route.params.file) ]
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
            }

        -- for debugging. click to toast a message
        , Html.button
            [ Html.Events.onClick (AddToast "Test toast")
            ]
            [ Html.text "Test toast" ]
        ]
    }


viewToast : List (Html.Attribute msg) -> Toast.Info String -> Html msg
viewToast attributes toast =
    Html.div (class "toast toast--spaced" :: attributes) [ Html.text toast.content ]
