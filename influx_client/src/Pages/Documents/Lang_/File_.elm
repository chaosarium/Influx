module Pages.Documents.Lang_.File_ exposing (Model, Msg, page)

import Api
import Api.GetAnnotatedDoc
import Api.TermEdit
import Bindings exposing (..)
import Browser.Events exposing (onMouseUp)
import Components.AnnotatedText as AnnotatedText
import Components.DbgDisplay
import Components.TermEditForm as TermEditForm
import Components.Topbar
import Datastore.DictContext as DictContext
import Datastore.DocContext as DocContext
import Datastore.FocusContext as FocusContext
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (alt, class, src)
import Html.Extra
import Http
import Json.Decode
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
    -- base event handling
    case msg of
        ApiResponded (Ok res) ->
            let
                _ =
                    Debug.log "ApiResponded" res
            in
            ( { model
                | get_doc_api_res = Api.Success res
                , working_doc = DocContext.fromAnnotatedDocument res.annotatedDoc
                , working_dict = DictContext.fromAnnotatedDocument res.annotatedDoc
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
                    FocusContext.update model.working_doc.text m model.focus_ctx

                ( form_model, _ ) =
                    TermEditForm.update model.working_dict (TermEditForm.EditingConUpdated model.focus_ctx.constituent_selection) model.form_model
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


viewConExtraInfo : SentenceConstituent -> Html msg
viewConExtraInfo con =
    case con of
        Bindings.CompositToken { shadows } ->
            Html.span [] [ Html.text "=  ", AnnotatedText.viewCompositTokenShadows shadows ]

        Bindings.SubwordToken { orthography, lemma } ->
            Utils.htmlIf (orthography /= lemma) <| Html.span [] [ Html.text (" (lemma is " ++ lemma ++ ")") ]

        Bindings.SingleToken { orthography, lemma } ->
            Utils.htmlIf (orthography /= lemma) <| Html.span [] [ Html.text (" (lemma is " ++ lemma ++ ")") ]

        Bindings.SentenceWhitespace _ ->
            Html.Extra.nothing

        Bindings.PhraseToken _ ->
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
                        FocusContext.isCstInSlice slice
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
                        FocusContext.isCstInSlice slice
            , doc_cst_display_predicate =
                case model.focus_ctx.slice_selection of
                    Nothing ->
                        \_ -> False

                    Just slice ->
                        FocusContext.isDocCstInSlice slice
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
                div [ class "annotated-doc-div dbg-off" ]
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

        -- selected constituent
        , div []
            [ span []
                [ Html.text "selected const: " ]
            , Maybe.withDefault
                (Html.text "")
                (Maybe.andThen (AnnotatedText.viewSentenceConstituent { selectedConstViewCtx | bypass_shadowned = False }) model.focus_ctx.constituent_selection)
            , Html.Extra.viewMaybe (\con -> viewConExtraInfo con) model.focus_ctx.constituent_selection
            ]

        , TermEditForm.view model.form_model
            TermEditorEvent
            { dict = model.working_dict
            }
        , Components.DbgDisplay.view "model.focus_ctx" model.focus_ctx
        ]
    }