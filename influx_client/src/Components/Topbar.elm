module Components.Topbar exposing (view)

import Components.Common exposing (..)
import Css exposing (..)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css, href)


view : {} -> Html msg
view props =
    nav
        [ css
            [ height (px 32)
            , backgroundColor (hex "#FCFCFC") -- $bgColorSubtle ($gray-2)
            , borderBottom3 (px 1) solid (hex "#E9E9E7") -- $borderSubtle ($gray-6)
            , displayFlex
            , alignItems center
            , padding2 zero (px 8)
            , property "flex-shrink" "0"
            , fontSize (Css.em 0.875)
            ]
        ]
        [ ul
            [ css
                [ listStyleType none
                , padding zero
                , margin zero
                , displayFlex
                , alignItems center
                ]
            ]
            [ li [] [ a [ href "/", css linkStyles ] [ text "Home" ] ]
            , li [] [ a [ href "/langs", css linkStyles ] [ text "Languages" ] ]
            , li [] [ a [ href "/docs", css linkStyles ] [ text "Documents" ] ]
            , li [] [ a [ href "/dictionary", css linkStyles ] [ text "Dictionary" ] ]
            ]
        ]


linkStyles : List Style
linkStyles =
    [ textDecoration none
    , color (hex "#1C1917") -- $gray-9
    , fontWeight (int 400)
    , borderRadius (px 4)
    , padding2 (px 2) (px 8)
    , hover
        [ color (hex "#0C0A09") -- $gray-10
        , backgroundColor (hex "#F5F5F4") -- $gray-3
        ]
    ]
