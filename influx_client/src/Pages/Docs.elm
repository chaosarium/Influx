module Pages.Docs exposing (Model, Msg, page)

import Api
import Api.GetDocuments
import Bindings exposing (DocPackage, InfluxResourceId(..))
import BindingsUtils
import Components.DbgDisplay
import Components.FormElements3 exposing (buttonC)
import Components.Layout
import Css exposing (..)
import Dict
import Effect exposing (Effect)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css, href)
import Html.Styled.Events as Events
import Http
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init route
        , update = update
        , subscriptions = subscriptions
        , view = view route
        }


type alias ThisRoute =
    Route ()



-- INIT


type alias Model =
    { docData : Api.Data (List DocPackage) }


init : Route () -> () -> ( Model, Effect Msg )
init route () =
    let
        languageId =
            case Dict.get "lang" route.query of
                Just langIdString ->
                    case String.toInt langIdString of
                        Just intId ->
                            Just (SerialId intId)

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing
    in
    ( { docData = Api.Loading }
    , Effect.sendCmd (Api.GetDocuments.get { languageId = languageId } ApiResponded)
    )



-- UPDATE


type Msg
    = ApiResponded (Result Http.Error (List DocPackage))
    | AddDocument


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiResponded (Ok res) ->
            ( { model | docData = Api.Success res }, Effect.none )

        ApiResponded (Err httpError) ->
            ( { model | docData = Api.Failure httpError }, Effect.none )

        AddDocument ->
            ( model, Effect.pushRoute { path = Route.Path.Doc_Edit, query = Dict.empty, hash = Nothing } )



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
    Html.table
        [ css
            [ Css.borderCollapse Css.collapse
            , Css.width (Css.pct 100)
            ]
        ]
        [ thead []
            [ tr []
                [ th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Title" ]
                , th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Language" ]
                , th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Tags" ]
                , th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Type" ]
                , th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Created" ]
                , th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Modified" ]
                , th [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8), Css.textAlign Css.left ] ] [ text "Actions" ]
                ]
            ]
        , Html.tbody []
            (List.map
                (\docPackage ->
                    tr [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd") ] ]
                        [ td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ Html.a [ href ("/doc/" ++ BindingsUtils.influxResourceIdToString docPackage.documentId) ]
                                [ text docPackage.document.title ]
                            ]
                        , td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ text docPackage.language.name ]
                        , td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ text (String.join ", " docPackage.document.tags) ]
                        , td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ text (docTypeToString docPackage.document.docType) ]
                        , td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ text (formatDate docPackage.document.createdTs) ]
                        , td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ text (formatDate docPackage.document.updatedTs) ]
                        , td [ css [ Css.border3 (Css.px 1) Css.solid (Css.hex "#ddd"), Css.padding (Css.px 8) ] ]
                            [ Html.a
                                [ href ("/doc/edit?docId=" ++ BindingsUtils.influxResourceIdToString docPackage.documentId)
                                ]
                                [ text "Edit" ]
                            ]
                        ]
                )
                docPackages
            )
        ]


viewDocs model =
    case model.docData of
        Api.NotAsked ->
            div [] [ text "Documents not loaded" ]

        Api.Loading ->
            div [] [ text "Loading..." ]

        Api.Failure httpError ->
            div [] [ text "Error: ", text (Api.stringOfHttpErrMsg httpError) ]

        Api.Success docPackages ->
            div []
                [ div [ css [ Css.marginBottom (Css.px 20) ] ]
                    [ buttonC
                        { label = "Add Document"
                        , onPress = Just AddDocument
                        }
                    ]
                , viewDocumentsTable docPackages
                ]


view : ThisRoute -> Model -> View Msg
view route model =
    { title = "All Documents"
    , body =
        Components.Layout.pageLayoutC { toastTray = Nothing }
            [ h1 [] [ text "All Documents" ]
            , viewDocs model
            ]
    }
