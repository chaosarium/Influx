module Components.InflectionChain exposing (inflectionChainC)

import Bindings exposing (ConjugationStep)
import Components.CssExtra exposing (gap)
import Css exposing (..)
import Html.Styled as Html exposing (Html, div, span, text)
import Html.Styled.Attributes as Attributes exposing (css)


inflectionChainC : List ConjugationStep -> Html msg
inflectionChainC conjugationSteps =
    case conjugationSteps of
        [] ->
            text ""

        _ ->
            div
                [ css
                    [ displayFlex
                    , alignItems center
                    , flexWrap wrap
                    , gap (px 8)
                    , padding2 (px 24) (px 12)
                    , paddingBottom (px 12)
                    , backgroundColor (hex "#F8F9FA")
                    , borderRadius (px 6)
                    , border3 (px 1) solid (hex "#E9ECEF")
                    , fontSize (Css.em 0.9)
                    , position relative
                    ]
                ]
                (buildChainElements conjugationSteps)


buildChainElements : List ConjugationStep -> List (Html msg)
buildChainElements steps =
    case steps of
        [] ->
            []

        firstStep :: remainingSteps ->
            let
                startForm =
                    span
                        [ css
                            [ fontWeight (int 500)
                            , color (hex "#2D3748")
                            ]
                        ]
                        [ text firstStep.form ]

                chainElements =
                    List.concatMap stepToElements (firstStep :: remainingSteps)
            in
            [ startForm ] ++ chainElements


stepToElements : ConjugationStep -> List (Html msg)
stepToElements step =
    [ arrowWithLabel step.form
    , span
        [ css
            [ fontWeight (int 500)
            , color (hex "#2D3748")
            ]
        ]
        [ text step.result ]
    ]


arrowWithLabel : String -> Html msg
arrowWithLabel label =
    div
        [ css
            [ position relative
            , displayFlex
            , alignItems center
            , margin2 zero (px 4)
            , minWidth (px (max 60 (toFloat (String.length label) * 7 + 16)))
            ]
        ]
        [ span
            [ css
                [ position absolute
                , top (px -20)
                , left (pct 50)
                , transform (translateX (pct -50))
                , fontSize (Css.em 0.75)
                , color (hex "#6B7280")
                , whiteSpace noWrap
                , backgroundColor (hex "#FFFFFF")
                , padding2 (px 2) (px 4)
                , borderRadius (px 3)
                , border3 (px 1) solid (hex "#E5E7EB")
                , zIndex (int 1)
                ]
            ]
            [ text label ]
        , div
            [ css
                [ width (pct 100)
                , height (px 1)
                , backgroundColor (hex "#9CA3AF")
                , position relative
                ]
            ]
            []
        , span
            [ css
                [ position absolute
                , right (px -2)
                , fontSize (Css.em 1.2)
                , color (hex "#9CA3AF")
                ]
            ]
            [ text "→" ]
        ]
