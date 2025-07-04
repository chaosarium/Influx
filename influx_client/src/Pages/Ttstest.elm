module Pages.Ttstest exposing (Model, Msg, page)

import Components.Topbar
import Effect exposing (Effect)
import Html
import Html.Events
import Json.Decode as D
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


type alias Voice =
    { name : String
    , lang : String
    , default : Bool
    }


type alias Model =
    { voices : List Voice
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { voices = [] }
    , Effect.none
    )


type Msg
    = UserClickedButton
    | GetVoices
    | Speak
    | Stop
    | VoicesReceived (Maybe D.Value)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        UserClickedButton ->
            ( model
            , Effect.openWindowDialog "Hello, from Elm!"
            )

        GetVoices ->
            ( model, Effect.ttsGetVoices )

        Speak ->
            ( model, Effect.ttsSpeak { text = "hello world this is somethign long", voice = Nothing, rate = Nothing, pitch = Nothing } )

        Stop ->
            ( model, Effect.ttsCancel )

        VoicesReceived maybeValue ->
            let
                voices =
                    case maybeValue of
                        Just value ->
                            D.decodeValue (D.list voiceDecoder) value
                                |> Result.withDefault []

                        Nothing ->
                            []
            in
            ( { model | voices = voices }
            , Effect.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Effect.jsIncoming
        (\value ->
            let
                maybeMsg =
                    case D.decodeValue (D.field "tag" D.string) value of
                        Ok "VOICES_LIST" ->
                            D.decodeValue (D.field "data" D.value) value
                                |> Result.toMaybe
                                |> VoicesReceived
                                |> Just

                        _ ->
                            Nothing
            in
            case maybeMsg of
                Just msg ->
                    msg

                Nothing ->
                    D.decodeValue (D.field "tag" D.string) value
                        |> Result.withDefault ""
                        |> Debug.log "Unhandled incoming port"
                        |> always Nothing
                        |> Maybe.withDefault UserClickedButton
        )


voiceDecoder : D.Decoder Voice
voiceDecoder =
    D.map3 Voice
        (D.field "name" D.string)
        (D.field "lang" D.string)
        (D.field "default" D.bool)


view : Model -> View Msg
view model =
    { title = "TTS Testing Page"
    , body =
        [ Html.div []
            [ Html.h1 [] [ Html.text "TTS Testing Page" ]
            , Html.button
                [ Html.Events.onClick UserClickedButton
                ]
                [ Html.text "invoke javascript" ]
            , Html.button
                [ Html.Events.onClick Speak
                ]
                [ Html.text "Speak" ]
            , Html.button
                [ Html.Events.onClick Stop
                ]
                [ Html.text "Stop speaking" ]
            , Html.button
                [ Html.Events.onClick GetVoices
                ]
                [ Html.text "get voices" ]
            , Html.ul []
                (List.map
                    (\voice ->
                        Html.li [] [ Html.text (voice.name ++ " (" ++ voice.lang ++ ")") ]
                    )
                    model.voices
                )
            ]
        ]
    }


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
