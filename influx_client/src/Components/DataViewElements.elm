module Components.DataViewElements exposing (dictKeyValueGroupC, keyValueGroupC, keyValueRowC)

import Colours
import Components.Common as Common
import Components.CssExtra exposing (borderNone, gap)
import Css exposing (..)
import Dict exposing (Dict)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css)


{-| Label width for key-value rows, matching FormElements3 design
-}
dataViewLabelWidth : Px
dataViewLabelWidth =
    px 200


{-| Label color for key-value rows, matching FormElements3 design
-}
dataViewLabelColor : Style
dataViewLabelColor =
    Colours.colorCss Colours.gray10


{-| Height for compact key-value rows
-}
dataViewRowHeight : Px
dataViewRowHeight =
    px 24


{-| Individual key-value row component that displays a label and value
Similar to inputKeyVal but optimized for read-only display
-}
keyValueRowC : { label : String, value : String } -> Html msg
keyValueRowC { label, value } =
    div
        [ css
            [ displayFlex
            , alignItems start
            , gap (px 8)
            , width (pct 100)
            , padding2 Common.space4px Common.space0px
            ]
        ]
        [ div
            [ css
                [ width dataViewLabelWidth
                , textOverflow ellipsis
                , overflow hidden
                , whiteSpace noWrap
                , dataViewLabelColor
                , height dataViewRowHeight
                , displayFlex
                , alignItems center
                , fontSize (rem 0.875)
                , fontWeight (int 500)
                ]
            ]
            [ text label ]
        , div
            [ css
                [ width (pct 100)
                , height dataViewRowHeight
                , displayFlex
                , alignItems center
                , fontSize (rem 0.875)
                , Colours.colorCss Colours.gray12
                , lineHeight (num 1.4)
                , property "word-break" "break-word"
                ]
            ]
            [ text value ]
        ]


{-| Horizontal separator matching FormElements3 style
-}
dataViewSeparator : Html msg
dataViewSeparator =
    hr
        [ css
            [ borderNone
            , borderBottom2 (px 1) solid
            , Colours.borderCss Colours.gray3
            , width (pct 100)
            , margin2 (px 0) (px 0)
            ]
        ]
        []


{-| Groups multiple key-value rows with separators between them
-}
keyValueGroupC : List { label : String, value : String } -> Html msg
keyValueGroupC rows =
    let
        rowElements =
            List.map keyValueRowC rows

        interspersedElements =
            List.concat
                [ [ dataViewSeparator ]
                , List.intersperse dataViewSeparator rowElements
                , [ dataViewSeparator ]
                ]
    in
    div
        [ css
            [ displayFlex
            , flexDirection column
            , gap (px 0)
            , width (pct 100)
            ]
        ]
        interspersedElements


{-| Groups key-value pairs from a Dict String String with separators between them
Useful for displaying misc attributes and other dictionary data
-}
dictKeyValueGroupC : Dict String String -> Html msg
dictKeyValueGroupC dict =
    let
        rows =
            Dict.toList dict
                |> List.map (\( key, value ) -> { label = key, value = value })
    in
    keyValueGroupC rows
