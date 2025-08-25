module Components.Popover exposing (Config, popoverField, view, viewPhrasePopover, viewTokenPopover)

import Bindings exposing (Phrase, SentSegV2, Token)
import Css exposing (..)
import Html.Styled as Html exposing (Attribute, Html, div, span, text)
import Html.Styled.Attributes as Attributes exposing (class, css)


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
        [ css
            [ position relative
            , display inlineBlock
            ]
        , class "popover-container"
        ]
        [ -- Trigger element
          span
            ([ css
                [ display inlineBlock
                , cursor pointer
                ]
             , class "popover-trigger"
             ]
                ++ config.triggerAttributes
            )
            config.triggerContent

        -- , -- Bridge area to prevent popover disappearing when moving mouse to content
        --   div
        --     [ css
        --         [ position absolute
        --         , top (pct 100)
        --         , left (px 0)
        --         , width (pct 100)
        --         , height (px 8) -- 8px gap coverage
        --         , zIndex (int 999)
        --         , opacity (int 0)
        --         , pointerEvents none
        --         ]
        --     , class "popover-bridge"
        --     ]
        --     []
        , -- Popover content
          div
            [ css
                [ position absolute
                , top (calc (pct 100) plus (px 0)) -- 8px spacing from trigger
                , left (px 0)
                , zIndex (int 1000)
                , opacity (int 0)
                , visibility hidden
                , pointerEvents none
                , transform (translateY (px 5))
                , backgroundColor (hex "#ffffff")
                , border3 (px 1) solid (hex "#d1d5db")
                , borderRadius (px 6)
                , boxShadow5 (px 0) (px 4) (px 6) (px -1) (rgba 0 0 0 0.1)
                , padding2 (px 8) (px 12)
                , width (px 300) -- Fixed width at 300px
                , fontSize (px 14)
                , lineHeight (num 1.4)
                , Css.property "user-select" "text" -- Make text selectable
                , Css.property "cursor" "text" -- Show text cursor when hovering over content
                ]
            , class "popover-content"
            ]
            config.content
        ]


{-| Helper function to create popover fields with consistent styling
-}
popoverField : String -> List (Html msg) -> Html msg
popoverField label content =
    div
        [ css
            [ marginBottom (px 4)
            , lastChild [ marginBottom (px 0) ]
            ]
        , class "popover-field"
        ]
        [ div
            [ css
                [ fontWeight bold
                , color (hex "#6b7280")
                , fontSize (px 12)
                , textTransform uppercase
                , Css.property "letter-spacing" "0.5px"
                ]
            , class "popover-label"
            ]
            [ text label ]
        , div
            [ css
                [ color (hex "#1f2937")
                , marginTop (px 2)
                , Css.property "user-select" "text" -- Make field content selectable
                ]
            , class "popover-value"
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
            [ css [ color (hex "#8b5cf6"), fontWeight (int 500) ] ]
            [ text token.definition ]
        ]
    , popoverField "Phonetic" [ text token.phonetic ]
    ]
        ++ (case seg.attributes.lemma of
                Just lemma ->
                    [ popoverField "Lemma"
                        [ span
                            [ css [ color (hex "#10b981") ] ]
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
                            [ css [ color (hex "#f59e0b"), fontStyle italic ] ]
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
            [ css [ color (hex "#8b5cf6"), fontWeight (int 500) ] ]
            [ text phrase.definition ]
        ]
    ]
