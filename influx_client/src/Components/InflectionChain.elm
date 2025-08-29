module Components.InflectionChain exposing (inflectionChainC)

import Bindings exposing (ConjugationStep)
import Components.CssExtra exposing (gap)
import Css exposing (..)
import Html.Styled as Html exposing (Html, div, span, text)
import Html.Styled.Attributes as Attributes exposing (css)


{-| Display an inflection chain as a clean horizontal flow with transformation steps.
-}
inflectionChainC : List ConjugationStep -> Html msg
inflectionChainC conjugationSteps =
    case conjugationSteps of
        [] ->
            text ""

        firstStep :: remainingSteps ->
            div
                [ css
                    [ displayFlex
                    , alignItems center
                    , flexWrap wrap
                    , gap (px 16)
                    , padding2 (px 16) (px 20)
                    , backgroundColor (hex "#F8F9FA")
                    , borderRadius (px 6)
                    , border3 (px 1) solid (hex "#E9ECEF")
                    , fontSize (px 14)
                    , lineHeight (num 1.5)
                    ]
                ]
                (termC firstStep.result :: List.map stepToArrowAndTerm remainingSteps)


{-| Render a term in the chain with consistent styling.
-}
termC : String -> Html msg
termC term =
    span
        [ css
            [ fontSize (px 16)
            , fontWeight (int 600)
            , color (hex "#1a202c")
            , padding2 (px 6) (px 12)
            , backgroundColor (hex "#ffffff")
            , borderRadius (px 4)
            , border3 (px 1) solid (hex "#cbd5e0")
            , minHeight (px 32)
            , displayFlex
            , alignItems center
            ]
        ]
        [ text term ]


{-| Convert a conjugation step to an arrow with label plus the resulting term.
-}
stepToArrowAndTerm : ConjugationStep -> Html msg
stepToArrowAndTerm step =
    div
        [ css
            [ displayFlex
            , alignItems center
            , gap (px 16)
            ]
        ]
        [ arrowWithLabelC step.form
        , termC step.result
        ]


{-| Render a clean arrow with transformation label above it.
-}
arrowWithLabelC : String -> Html msg
arrowWithLabelC label =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , alignItems center
            , gap (px 6)
            ]
        ]
        [ -- Transformation label
          span
            [ css
                [ fontSize (px 11)
                , color (hex "#6b7280")
                , fontWeight (int 500)
                , textAlign center
                , maxWidth (px 100)
                , lineHeight (num 1.3)
                ]
            ]
            [ text label ]
        , -- Clean arrow
          div
            [ css
                [ displayFlex
                , alignItems center
                ]
            ]
            [ div
                [ css
                    [ width (px 24)
                    , height (px 2)
                    , backgroundColor (hex "#9ca3af")
                    , borderRadius (px 1)
                    ]
                ]
                []
            , div
                [ css
                    [ width (px 0)
                    , height (px 0)
                    , borderLeft3 (px 6) solid (hex "#9ca3af")
                    , borderTop3 (px 4) solid transparent
                    , borderBottom3 (px 4) solid transparent
                    , marginLeft (px -1)
                    ]
                ]
                []
            ]
        ]
