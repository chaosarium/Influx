module Components.Popover exposing (Config, popoverField, view, viewPhrasePopover, viewTokenPopover)

import Bindings exposing (Phrase, SentSegV2, Token)
import Html.Styled as Html exposing (Attribute, Html, div, span, text)
import Html.Styled.Attributes as Attributes exposing (class)


{-| Configuration for the popover component
-}
type alias Config msg =
    { content : List (Html msg)
    , triggerContent : List (Html msg)
    , triggerAttributes : List (Attribute msg)
    }


{-| CSS-based popover component that shows content on hover
The popover will remain visible when hovering over either the trigger or the popover content
-}
view : Config msg -> Html msg
view config =
    div
        [ class "popover-container"
        ]
        [ -- Trigger element
          span
            ([ class "popover-trigger"
             ]
                ++ config.triggerAttributes
            )
            config.triggerContent
        , -- Popover content
          div
            [ class "popover-content"
            ]
            config.content
        ]


{-| Helper function to create popover fields with consistent styling
-}
popoverField : String -> List (Html msg) -> Html msg
popoverField label content =
    div
        [ class "popover-field"
        ]
        [ div
            [ class "popover-label"
            ]
            [ text label ]
        , div
            [ class "popover-value"
            ]
            content
        ]


{-| Create popover content for a token
-}
viewTokenPopover : Token -> SentSegV2 -> List (Html msg)
viewTokenPopover token seg =
    [ popoverField "Word" [ text token.orthography ]
    , popoverField "Definition"
        [ span
            [ class "popover-definition" ]
            [ text token.definition ]
        ]
    , popoverField "Phonetic" [ text token.phonetic ]
    ]
        ++ (case seg.attributes.lemma of
                Just lemma ->
                    [ popoverField "Lemma"
                        [ span
                            [ class "popover-lemma" ]
                            [ text lemma ]
                        ]
                    ]

                Nothing ->
                    []
           )
        ++ (case seg.attributes.upos of
                Just pos ->
                    [ popoverField "Part of Speech"
                        [ span
                            [ class "popover-pos" ]
                            [ text pos ]
                        ]
                    ]

                Nothing ->
                    []
           )


{-| Create popover content for a phrase
-}
viewPhrasePopover : Phrase -> SentSegV2 -> List (Html msg)
viewPhrasePopover phrase seg =
    [ popoverField "Phrase" [ text (String.join " " phrase.orthographySeq) ]
    , popoverField "Definition"
        [ span
            [ class "popover-definition" ]
            [ text phrase.definition ]
        ]
    ]
