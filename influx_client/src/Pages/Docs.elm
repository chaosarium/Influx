module Pages.Docs exposing (Model, Msg, page)

import Api
import Api.GetDocuments
import Bindings exposing (DocPackage, InfluxResourceId(..))
import BindingsUtils
import Components.DbgDisplay
import Components.Topbar
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (href, style)
import Html.Events
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view route
        }


type alias ThisRoute =
    Route ()



-- INIT


type alias Model =
    { docData : Api.Data (List DocPackage) }


init : () -> ( Model, Effect Msg )
init () =
    ( { docData = Api.Loading }
    , Effect.sendCmd (Api.GetDocuments.get { languageId = Nothing } ApiResponded)
    )



-- UPDATE


type Msg
    = ApiResponded (Result Http.Error (List DocPackage))


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiResponded (Ok res) ->
            ( { model | docData = Api.Success res }, Effect.none )

        ApiResponded (Err httpError) ->
            ( { model | docData = Api.Failure httpError }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


docTypeToString : String -> String
docTypeToString docType =
    docType


formatDate : String -> String
formatDate dateString =
    -- Simple date formatting - you could enhance this
    String.left 10 dateString


viewDocumentRow : DocPackage -> Html msg
viewDocumentRow docPackage =
    let
        documentId =
            BindingsUtils.influxResourceIdToString docPackage.documentId

        tagsString =
            String.join ", " docPackage.document.tags
    in
    tr []
        [ td []
            [ a [ href ("/documents/" ++ documentId) ]
                [ text docPackage.document.title ]
            ]
        , td [] [ text tagsString ]
        , td [] [ text (docTypeToString docPackage.document.docType) ]
        , td [] [ text (formatDate docPackage.document.createdTs) ]
        , td [] [ text (formatDate docPackage.document.updatedTs) ]
        ]


viewDocumentsTable : List DocPackage -> Html msg
viewDocumentsTable docPackages =
    table [ style "border-collapse" "collapse", style "width" "100%" ]
        [ thead []
            [ tr []
                [ th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Title" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Language" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Tags" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Type" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Created" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Modified" ]
                , th [ style "border" "1px solid #ddd", style "padding" "8px", style "text-align" "left" ] [ text "Actions" ]
                ]
            ]
        , tbody []
            (List.map
                (\docPackage ->
                    tr [ style "border" "1px solid #ddd" ]
                        [ td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ a [ href ("/doc/" ++ BindingsUtils.influxResourceIdToString docPackage.documentId) ]
                                [ text docPackage.document.title ]
                            ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ text docPackage.language.name ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ text (String.join ", " docPackage.document.tags) ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ text (docTypeToString docPackage.document.docType) ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ text (formatDate docPackage.document.createdTs) ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ text (formatDate docPackage.document.updatedTs) ]
                        , td [ style "border" "1px solid #ddd", style "padding" "8px" ]
                            [ a
                                [ href ("/doc/edit/" ++ BindingsUtils.influxResourceIdToString docPackage.documentId)
                                ]
                                [ text "Edit" ]
                            ]
                        ]
                )
                docPackages
            )
        ]


view : ThisRoute -> Model -> View Msg
view route model =
    { title = "All Documents"
    , body =
        [ Components.Topbar.view {}
        , Html.h1 [] [ Html.text "All Documents" ]
        , case model.docData of
            Api.Loading ->
                div [] [ Html.text "Loading..." ]

            Api.Failure httpError ->
                div [] [ Html.text "Error: ", Html.text (Api.stringOfHttpErrMsg httpError) ]

            Api.Success docPackages ->
                div []
                    [ viewDocumentsTable docPackages ]
        ]
    }
