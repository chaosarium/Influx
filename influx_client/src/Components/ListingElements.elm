module Components.ListingElements exposing
    ( listingCardC
    , listingTableC
    )

import Colours
import Components.Common as Common
import Components.CssExtra as CssExtra
import Css exposing (..)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css)


bascShadow =
    property "box-shadow" "0px 0px 8px 0px var(--gray-a2)"


labelColor =
    Colours.colorCss Colours.gray10


listingCardC : List (Html msg) -> Html msg
listingCardC content =
    div
        [ css
            [ border2 (px 1) solid
            , Colours.borderCss Colours.gray3
            , borderRadius Common.space8px
            , padding Common.space16px
            , margin2 Common.space16px (px 0)
            , Colours.bgCss Colours.white
            , bascShadow
            ]
        ]
        content


listingTableC : { headers : List String, rows : List (List (Html msg)) } -> Html msg
listingTableC { headers, rows } =
    let
        separator =
            hr
                [ css
                    [ CssExtra.borderNone
                    , borderBottom3 (px 1) solid (hex "#ddd")
                    , margin Common.space0px
                    ]
                ]
                []

        headerRow =
            div
                [ css
                    [ displayFlex
                    , alignItems center
                    , paddingTop Common.space8px
                    , paddingBottom Common.space8px
                    , fontWeight bold
                    , labelColor
                    ]
                ]
                (List.map
                    (\header ->
                        div
                            [ css
                                [ flex (num 1)
                                , padding2 Common.space4px Common.space8px
                                ]
                            ]
                            [ text header ]
                    )
                    headers
                )

        renderRow cells =
            div
                [ css
                    [ displayFlex
                    , alignItems center
                    , paddingTop Common.space8px
                    , paddingBottom Common.space8px
                    , hover
                        [ Colours.bgCss Colours.gray1
                        ]
                    ]
                ]
                (List.map
                    (\cell ->
                        div
                            [ css
                                [ flex (num 1)
                                , padding2 Common.space4px Common.space8px
                                ]
                            ]
                            [ cell ]
                    )
                    cells
                )

        dataRowsWithSeparators =
            List.intersperse separator (List.map renderRow rows)
    in
    div
        [ css
            [ displayFlex
            , flexDirection column
            ]
        ]
        (List.concat
            [ [ separator ]
            , [ headerRow ]
            , [ separator ]
            , dataRowsWithSeparators
            , [ separator ]
            ]
        )
