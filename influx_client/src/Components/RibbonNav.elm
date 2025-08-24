module Components.RibbonNav exposing (view)

import Components.Common exposing (..)
import Components.CssExtra exposing (..)
import Css exposing (..)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css, href)


view : {} -> Html msg
view props =
    nav
        [ css
            [ position fixed
            , left zero
            , top zero
            , height (vh 100)
            , width (px 48)
            , backgroundColor (hex "#FCFCFC") -- $bgColorSubtle ($gray-2)
            , borderRight3 (px 1) solid (hex "#E9E9E7") -- $borderSubtle ($gray-6)
            , displayFlex
            , flexDirection column
            , alignItems center
            , padding2 (px 8) zero
            , property "flex-shrink" "0"
            , fontSize (Css.em 0.875)
            , zIndex (int 1000)
            ]
        ]
        [ ul
            [ css
                [ listStyleType none
                , padding zero
                , margin zero
                , displayFlex
                , flexDirection column
                , alignItems center
                , gap (px 8)
                ]
            ]
            [ li [] [ a [ href "/", css linkStyles ] [ text "Home" ] ]
            , li [] [ a [ href "/langs", css linkStyles ] [ text "Langs" ] ]
            , li [] [ a [ href "/docs", css linkStyles ] [ text "Docs" ] ]
            , li [] [ a [ href "/dictionary", css linkStyles ] [ text "Dict" ] ]
            ]
        ]


linkStyles : List Style
linkStyles =
    [ textDecoration none
    , color (hex "#1C1917") -- $gray-9
    , fontWeight (int 400)
    , borderRadius (px 4)
    , padding2 (px 6) (px 4)
    , display block
    , textAlign center
    , minWidth (px 40)
    , hover
        [ color (hex "#0C0A09") -- $gray-10
        , backgroundColor (hex "#F5F5F4") -- $gray-3
        ]
    ]
