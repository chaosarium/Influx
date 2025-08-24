module Pages.Docs exposing (Model, Msg, page)

import Api
import Api.GetDocuments
import Bindings exposing (DocPackage, InfluxResourceId(..))
import BindingsUtils
import Components.DbgDisplay
import Components.FormElements3 exposing (buttonC)
import Components.Layout
import Components.ListingElements
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


viewDocumentsTable : List DocPackage -> Html msg
viewDocumentsTable docPackages =
    let
        headers =
            [ "Title", "Language", "Tags", "Type", "Created", "Modified", "Actions" ]

        documentRows =
            List.map
                (\docPackage ->
                    let
                        documentId =
                            BindingsUtils.influxResourceIdToString docPackage.documentId

                        tagsString =
                            String.join ", " docPackage.document.tags
                    in
                    [ a [ href ("/doc/" ++ documentId) ]
                        [ text docPackage.document.title ]
                    , text docPackage.language.name
                    , text tagsString
                    , text (docTypeToString docPackage.document.docType)
                    , text (formatDate docPackage.document.createdTs)
                    , text (formatDate docPackage.document.updatedTs)
                    , a
                        [ href ("/doc/edit?docId=" ++ documentId)
                        ]
                        [ text "Edit" ]
                    ]
                )
                docPackages
    in
    Components.ListingElements.listingCardC
        [ Components.ListingElements.listingTableC
            { headers = headers
            , rows = documentRows
            }
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
                        , compact = False
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
