module Components.TtsEmitter exposing (view)

import Bindings exposing (LanguageEntry)
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (disabled, style)
import Html.Events exposing (onClick)


{-| A stateless component that provides TTS controls for a given text and language.
Takes a text string and language entry, and provides start/stop TTS buttons.
-}
view :
    { text : String
    , language : LanguageEntry
    , onStartTts : msg
    , onStopTts : msg
    }
    -> Html msg
view config =
    let
        hasText =
            not (String.isEmpty (String.trim config.text))

        startButton =
            button
                [ onClick config.onStartTts
                , disabled (not hasText)
                ]
                [ text "Start TTS" ]

        stopButton =
            button
                [ onClick config.onStopTts
                ]
                [ text "Stop TTS" ]
    in
    if hasText then
        div []
            [ startButton
            , stopButton
            ]

    else
        text ""
