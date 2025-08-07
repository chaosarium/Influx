port module Effect exposing
    ( Effect
    , none, batch
    , sendCmd, sendMsg
    , pushRoute, replaceRoute
    , pushRoutePath, replaceRoutePath
    , loadExternalUrl, back
    , map, toCmd
    , adjustAnnotationWidths, audioSetPlaybackPosition, injectHtml, jsIncoming, openWindowDialog, sendSharedMsg, ttsCancel, ttsCancelAndSpeak, ttsGetVoices, ttsSpeak
    )

{-|

@docs Effect

@docs none, batch
@docs sendCmd, sendMsg

@docs pushRoute, replaceRoute
@docs pushRoutePath, replaceRoutePath
@docs loadExternalUrl, back

@docs map, toCmd

-}

import Browser.Navigation
import Dict exposing (Dict)
import Json.Decode
import Json.Encode
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg
import Task
import Url exposing (Url)


type Effect msg
    = -- BASICS
      None
    | Batch (List (Effect msg))
    | SendCmd (Cmd msg)
      -- ROUTING
    | PushUrl String
    | ReplaceUrl String
    | LoadExternalUrl String
    | Back
      -- SHARED
    | SendSharedMsg Shared.Msg.Msg
      -- INTEROP
    | SendMessageToJavaScript
        { tag : String
        , data : Json.Encode.Value
        }



-- BASICS


{-| Don't send any effect.
-}
none : Effect msg
none =
    None


{-| Send multiple effects at once.
-}
batch : List (Effect msg) -> Effect msg
batch =
    Batch


{-| Send a normal `Cmd msg` as an effect, something like `Http.get` or `Random.generate`.
-}
sendCmd : Cmd msg -> Effect msg
sendCmd =
    SendCmd


{-| Send a message as an effect. Useful when emitting events from UI components.
-}
sendMsg : msg -> Effect msg
sendMsg msg =
    Task.succeed msg
        |> Task.perform identity
        |> SendCmd


{-| Send a message to the shared state.
-}
sendSharedMsg : Shared.Msg.Msg -> Effect msg
sendSharedMsg sharedMsg =
    SendSharedMsg sharedMsg



-- ROUTING


{-| Set the new route, and make the back button go back to the current route.
-}
pushRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
pushRoute route =
    PushUrl (Route.toString route)


{-| Same as `Effect.pushRoute`, but without `query` or `hash` support
-}
pushRoutePath : Route.Path.Path -> Effect msg
pushRoutePath path =
    PushUrl (Route.Path.toString path)


{-| Set the new route, but replace the previous one, so clicking the back
button **won't** go back to the previous route.
-}
replaceRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
replaceRoute route =
    ReplaceUrl (Route.toString route)


{-| Same as `Effect.replaceRoute`, but without `query` or `hash` support
-}
replaceRoutePath : Route.Path.Path -> Effect msg
replaceRoutePath path =
    ReplaceUrl (Route.Path.toString path)


{-| Redirect users to a new URL, somewhere external to your web application.
-}
loadExternalUrl : String -> Effect msg
loadExternalUrl =
    LoadExternalUrl


{-| Navigate back one page
-}
back : Effect msg
back =
    Back



-- INTEROP


port outgoing : { tag : String, data : Json.Encode.Value } -> Cmd msg


port jsIncoming : (Json.Decode.Value -> msg) -> Sub msg


openWindowDialog : String -> Effect msg
openWindowDialog question =
    SendMessageToJavaScript
        { tag = "OPEN_WINDOW_DIALOG"
        , data = Json.Encode.string question
        }


ttsGetVoices : Effect msg
ttsGetVoices =
    SendMessageToJavaScript
        { tag = "GET_VOICES"
        , data = Json.Encode.null
        }


ttsSpeak : { text : String, voice : Maybe String, rate : Maybe Float, pitch : Maybe Float } -> Effect msg
ttsSpeak options =
    SendMessageToJavaScript
        { tag = "SPEAK"
        , data =
            Json.Encode.object
                [ ( "text", Json.Encode.string options.text )
                , ( "voice", Maybe.withDefault Json.Encode.null (Maybe.map Json.Encode.string options.voice) )
                , ( "rate", Maybe.withDefault Json.Encode.null (Maybe.map Json.Encode.float options.rate) )
                , ( "pitch", Maybe.withDefault Json.Encode.null (Maybe.map Json.Encode.float options.pitch) )
                ]
        }


audioSetPlaybackPosition : { playback_position : Float } -> Effect msg
audioSetPlaybackPosition options =
    SendMessageToJavaScript
        { tag = "SET_AUDIO_PLAYBACK_POSITION"
        , data =
            Json.Encode.object
                [ ( "playback_position", Json.Encode.float options.playback_position ) ]
        }


ttsCancel : Effect msg
ttsCancel =
    SendMessageToJavaScript
        { tag = "CANCEL"
        , data = Json.Encode.null
        }


ttsCancelAndSpeak : { text : String, voice : Maybe String, rate : Maybe Float, pitch : Maybe Float } -> Effect msg
ttsCancelAndSpeak options =
    SendMessageToJavaScript
        { tag = "CANCEL_AND_SPEAK"
        , data =
            Json.Encode.object
                [ ( "text", Json.Encode.string options.text )
                , ( "voice", Maybe.withDefault Json.Encode.null (Maybe.map Json.Encode.string options.voice) )
                , ( "rate", Maybe.withDefault Json.Encode.null (Maybe.map Json.Encode.float options.rate) )
                , ( "pitch", Maybe.withDefault Json.Encode.null (Maybe.map Json.Encode.float options.pitch) )
                ]
        }


adjustAnnotationWidths : Effect msg
adjustAnnotationWidths =
    SendMessageToJavaScript
        { tag = "ADJUST_ANNOTATION_WIDTHS"
        , data = Json.Encode.null
        }


injectHtml : { elementId : String, htmlContent : String, dictName : String } -> Effect msg
injectHtml options =
    SendMessageToJavaScript
        { tag = "INJECT_HTML"
        , data =
            Json.Encode.object
                [ ( "elementId", Json.Encode.string options.elementId )
                , ( "htmlContent", Json.Encode.string options.htmlContent )
                , ( "dictName", Json.Encode.string options.dictName )
                ]
        }



-- INTERNALS


{-| Elm Land depends on this function to connect pages and layouts
together into the overall app.
-}
map : (msg1 -> msg2) -> Effect msg1 -> Effect msg2
map fn effect =
    case effect of
        None ->
            None

        Batch list ->
            Batch (List.map (map fn) list)

        SendCmd cmd ->
            SendCmd (Cmd.map fn cmd)

        PushUrl url ->
            PushUrl url

        ReplaceUrl url ->
            ReplaceUrl url

        Back ->
            Back

        LoadExternalUrl url ->
            LoadExternalUrl url

        SendSharedMsg sharedMsg ->
            SendSharedMsg sharedMsg

        SendMessageToJavaScript message ->
            SendMessageToJavaScript message


{-| Elm Land depends on this function to perform your effects.
-}
toCmd :
    { key : Browser.Navigation.Key
    , url : Url
    , shared : Shared.Model.Model
    , fromSharedMsg : Shared.Msg.Msg -> msg
    , batch : List msg -> msg
    , toCmd : msg -> Cmd msg
    }
    -> Effect msg
    -> Cmd msg
toCmd options effect =
    case effect of
        None ->
            Cmd.none

        Batch list ->
            Cmd.batch (List.map (toCmd options) list)

        SendCmd cmd ->
            cmd

        PushUrl url ->
            Browser.Navigation.pushUrl options.key url

        ReplaceUrl url ->
            Browser.Navigation.replaceUrl options.key url

        Back ->
            Browser.Navigation.back options.key 1

        LoadExternalUrl url ->
            Browser.Navigation.load url

        SendSharedMsg sharedMsg ->
            Task.succeed sharedMsg
                |> Task.perform options.fromSharedMsg

        SendMessageToJavaScript message ->
            outgoing message
