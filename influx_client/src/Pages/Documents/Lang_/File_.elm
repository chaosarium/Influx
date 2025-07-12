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
import Html.Extra
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
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


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiResponded (Ok res) ->
            let
                _ =
                    Debug.log "ApiResponded" res
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
                    TermEditForm.update model.working_dict (TermEditForm.EditingConUpdated focus_ctx.segment_slice focus_ctx.segment_selection) model.form_model
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

                _ ->
                    let
                        ( form_model, child_fx ) =
                            TermEditForm.update model.working_dict formMsg model.form_model
                    in
                    ( { model | form_model = form_model }
                    , Effect.map TermEditorEvent child_fx
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


viewConExtraInfo : DictContext.T -> SentSegV2 -> Html Msg
viewConExtraInfo dict con =
    case con.inner of
        TokenSeg { orthography } ->
            Utils.htmlIf (Maybe.withDefault "" con.attributes.lemma /= orthography) <| Html.span [] [ Html.text (" (lemma is " ++ Maybe.withDefault "" con.attributes.lemma ++ ")") ]

        PhraseSeg { normalisedOrthography, components } ->
            Html.span []
                [ Html.text "=  "
                , AnnotatedText.viewRegisteredPhrase
                    { dict = dict, bypass_shadowned = True, modifier_state = ModifierState.init, mouse_handler = NoopMouseEvent, focus_predicate = \_ -> False, cst_display_predicate = \_ -> True, doc_cst_display_predicate = \_ -> True }
                    []
                    (Maybe.withDefault { id = Nothing, langId = Bindings.SerialId -1, orthographySeq = [], definition = "", notes = "", originalContext = "", status = Bindings.Unmarked } (Dict.get normalisedOrthography dict.phraseDict))
                    con
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
            , bypass_shadowned = True
            , modifier_state = model.modifier_state
            , mouse_handler = SelectionMouseEvent
            , focus_predicate =
                case model.focus_ctx.slice_selection of
                    Nothing ->
                        \_ -> False

                    Just slice ->
                        FocusContext.isSentSegInSlice slice
            , cst_display_predicate = \_ -> True
            , doc_cst_display_predicate = \_ -> True
            }
    in
    let
        selectedConstViewCtx =
            { dict = model.working_dict
            , bypass_shadowned = True
            , modifier_state = model.modifier_state
            , mouse_handler = NoopMouseEvent
            , focus_predicate = \_ -> False
            , cst_display_predicate =
                case model.focus_ctx.slice_selection of
                    Nothing ->
                        \_ -> False

                    Just slice ->
                        FocusContext.isSentSegInSlice slice
            , doc_cst_display_predicate =
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
        , Components.DbgDisplay.view "route" route
        , Html.h1 [] [ Html.text ("lang: " ++ route.params.lang ++ ", file: " ++ Utils.unwrappedPercentDecode route.params.file) ]
        , case model.get_doc_api_res of
            Api.Loading ->
                Html.text "Loading..."

            Api.Failure err ->
                Html.text ("Error: " ++ Api.stringOfHttpErrMsg err)

            Api.Success _ ->
                div [ class "annotated-doc-div dbg-on" ]
                    (AnnotatedText.view
                        annotatedDocViewCtx
                        model.working_doc
                    )

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
                (Maybe.andThen (AnnotatedText.viewSentenceSegment { selectedConstViewCtx | bypass_shadowned = False }) model.focus_ctx.segment_selection)
            , Html.Extra.viewMaybe (\con -> viewConExtraInfo model.working_dict con) model.focus_ctx.segment_selection
            ]
        , TermEditForm.view model.form_model
            TermEditorEvent
            { dict = model.working_dict
            }
        , Components.DbgDisplay.view "model.focus_ctx" model.focus_ctx
        ]
    }
