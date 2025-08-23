module Components.Layout exposing (pageLayoutC)

import Components.Topbar
import Css exposing (..)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css)


pageLayoutC : List (Html msg) -> List (Html msg)
pageLayoutC content =
    [ div
        [ css
            [ height (vh 100)
            , displayFlex
            , flexDirection column
            , backgroundColor (hex "#FEFEFE")
            ]
        ]
        [ Html.fromUnstyled (Components.Topbar.view {})
        , div
            [ css
                [ width (px 1000)
                , margin2 zero auto
                , padding2 (px 32) (px 16)
                ]
            ]
            content
        ]
    ]
