module Pages.Documents.Lang_.File_ exposing (Model, Msg, page)

import Api
import Api.GetAnnotatedDoc
import Bindings exposing (GetDocResponse, LanguageEntry)
import Browser.Events exposing (onMouseUp)
import Components.AnnotatedText
import Components.DbgDisplay
import Components.Topbar
import Datastore.DictContext
import Datastore.DocContext
import Datastore.FocusContext
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (alt, class, src)
import Http
import Json.Decode
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Utils
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
    , working_doc : Datastore.DocContext.T
    , working_dict : Datastore.DictContext.T
    , focus_ctx : Datastore.FocusContext.T
    }


init :
    { languageId : String
    , filepath : String
    }
    -> ()
    -> ( Model, Effect Msg )
init args () =
    ( { get_doc_api_res = Api.Loading
      , working_doc = Datastore.DocContext.empty
      , working_dict = Datastore.DictContext.empty
      , focus_ctx = Datastore.FocusContext.new
      }
      -- TODO combine working_doc and focus_ctx into some module?
    , Effect.sendCmd (Api.GetAnnotatedDoc.get args ApiResponded)
    )



-- UPDATE


type Msg
    = ApiResponded (Result Http.Error GetDocResponse)
    | SelectionMouseEvent Datastore.FocusContext.Msg


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
                , working_doc = Datastore.DocContext.fromAnnotatedDocument res.annotatedDoc
                , working_dict = Datastore.DictContext.fromAnnotatedDocument res.annotatedDoc
              }
            , Effect.none
            )

        ApiResponded (Err httpError) ->
            ( { model | get_doc_api_res = Api.Failure httpError }, Effect.none )

        SelectionMouseEvent m ->
            ( { model | focus_ctx = Datastore.FocusContext.update model.working_doc.text m model.focus_ctx }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    onMouseUp (Json.Decode.succeed (SelectionMouseEvent (Datastore.FocusContext.SelectMouseUp ())))



-- Annotated Text view
-- VIEW


view : ThisRoute -> Model -> View Msg
view route model =
    let
        viewContext =
            { dict = model.working_dict
            , mouse_handler = SelectionMouseEvent
            , focus_predicate =
                case model.focus_ctx.slice_selection of
                    Nothing ->
                        \_ -> False

                    Just slice ->
                        Datastore.FocusContext.isCstInSlice slice
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
                Components.AnnotatedText.view
                    viewContext
                    model.working_doc

        -- , Components.DbgDisplay.view "model" model
        , div []
            [ Html.text
                ("selected text: "
                    ++ Maybe.withDefault "" model.focus_ctx.selected_text
                )
            ]
        , div []
            [ span []
                [ Html.text "selected const: " ]
            , Maybe.withDefault
                (Html.text "")
                (Maybe.andThen (Components.AnnotatedText.viewSentenceConstituent viewContext) model.focus_ctx.constituent_selection)
            ]
        , Components.DbgDisplay.view "focus_ctx.last_hovered_at" model.focus_ctx.last_hovered_at
        , Components.DbgDisplay.view "focus_ctx.mouse_down_at" model.focus_ctx.mouse_down_at
        , Components.DbgDisplay.view "focus_ctx.last_mouse_down_at" model.focus_ctx.last_mouse_down_at
        , Components.DbgDisplay.view "focus_ctx.slice_selection" model.focus_ctx.slice_selection
        , Components.DbgDisplay.view "focus_ctx.selected_text" model.focus_ctx.selected_text
        , Components.DbgDisplay.view "focus_ctx.constituent_selection" model.focus_ctx.constituent_selection
        ]
    }
