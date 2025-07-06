module Utils.ModifierState exposing
    ( Model
    , Msg(..)
    , init
    , isAlt
    , isCtrl
    , isMeta
    , isShift
    , subscriptions
    , update
    )

import Browser.Events
import Json.Decode as Decode
import Platform.Sub exposing (Sub)


type alias Model =
    { alt : Bool
    , ctrl : Bool
    , shift : Bool
    , meta : Bool
    }


init : Model
init =
    { alt = False, ctrl = False, shift = False, meta = False }


type Msg
    = KeyChanged { alt : Bool, ctrl : Bool, shift : Bool, meta : Bool }


subscriptions : (Msg -> msg) -> Sub msg
subscriptions tagger =
    let
        decoder =
            Decode.map4 (\a c s m -> { alt = a, ctrl = c, shift = s, meta = m })
                (Decode.field "altKey" Decode.bool)
                (Decode.field "ctrlKey" Decode.bool)
                (Decode.field "shiftKey" Decode.bool)
                (Decode.field "metaKey" Decode.bool)
    in
    Sub.batch
        [ Browser.Events.onKeyDown (Decode.map KeyChanged decoder |> Decode.map tagger)
        , Browser.Events.onKeyUp (Decode.map KeyChanged decoder |> Decode.map tagger)
        ]


update : Msg -> Model -> Model
update (KeyChanged keys) _ =
    keys


isAlt : Model -> Bool
isAlt m =
    m.alt


isCtrl : Model -> Bool
isCtrl m =
    m.ctrl


isShift : Model -> Bool
isShift m =
    m.shift


isMeta : Model -> Bool
isMeta m =
    m.meta
