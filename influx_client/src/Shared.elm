module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    , addToast, getModifierState, isAltPressed, isCtrlPressed, isMetaPressed, isShiftPressed, showToast
    )

{-|

@docs Flags, decoder
@docs Model, Msg
@docs init, update, subscriptions

-}

import Effect exposing (Effect)
import Json.Decode
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg
import Toast
import Utils
import Utils.ModifierState



-- FLAGS


type alias Flags =
    { message : String
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.map Flags
        (Json.Decode.field "message" Json.Decode.string)



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult route =
    let
        _ =
            Utils.dbgLog "FLAGS" flagsResult
    in
    ( { toast_tray = Toast.tray
      , modifier_state = Utils.ModifierState.init
      }
    , Effect.none
    )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        Shared.Msg.NoOp ->
            ( model
            , Effect.none
            )

        Shared.Msg.ToastMsg tmsg ->
            let
                ( toast_tray, toast_cmd ) =
                    Toast.update tmsg model.toast_tray
            in
            ( { model | toast_tray = toast_tray }
            , Effect.sendCmd (Cmd.map Shared.Msg.ToastMsg toast_cmd)
            )

        Shared.Msg.ModifierStateMsg m ->
            ( { model | modifier_state = Utils.ModifierState.update m model.modifier_state }
            , Effect.none
            )

        Shared.Msg.AddToast message ->
            let
                ( toast_tray, toast_cmd ) =
                    Toast.add model.toast_tray (Toast.expireIn 5000 message)
            in
            ( { model | toast_tray = toast_tray }
            , Effect.sendCmd (Cmd.map Shared.Msg.ToastMsg toast_cmd)
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions route model =
    Sub.batch
        [ Utils.ModifierState.subscriptions Shared.Msg.ModifierStateMsg
        ]



-- HELPER FUNCTIONS


{-| Add a toast message with default expiration time (5 seconds)
-}
addToast : String -> Effect Msg
addToast message =
    Effect.sendSharedMsg (Shared.Msg.AddToast message)


{-| Add a toast message with custom expiration time (in milliseconds)
Note: Currently uses the same 5-second default as addToast.
Custom duration support can be added by extending the Shared.Msg type.
-}
showToast : String -> Int -> Effect Msg
showToast message duration =
    -- For now, we'll use the same mechanism as addToast since the duration
    -- will be handled in the shared state update function
    Effect.sendSharedMsg (Shared.Msg.AddToast message)


{-| Get the current modifier state from shared model
-}
getModifierState : Model -> Utils.ModifierState.Model
getModifierState model =
    model.modifier_state


{-| Check if Alt key is currently pressed
-}
isAltPressed : Model -> Bool
isAltPressed model =
    Utils.ModifierState.isAlt (getModifierState model)


{-| Check if Ctrl key is currently pressed
-}
isCtrlPressed : Model -> Bool
isCtrlPressed model =
    Utils.ModifierState.isCtrl (getModifierState model)


{-| Check if Shift key is currently pressed
-}
isShiftPressed : Model -> Bool
isShiftPressed model =
    Utils.ModifierState.isShift (getModifierState model)


{-| Check if Meta key is currently pressed
-}
isMetaPressed : Model -> Bool
isMetaPressed model =
    Utils.ModifierState.isMeta (getModifierState model)
