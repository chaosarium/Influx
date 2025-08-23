module Components.Layout exposing (pageLayoutC)

import Components.Topbar
import Css exposing (..)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css)


pageLayoutC : { toastTray : Maybe (Html msg) } -> List (Html msg) -> List (Html msg)
pageLayoutC { toastTray } content =
    [ div
        [ css
            [ height (vh 100)
            , displayFlex
            , flexDirection column
            , backgroundColor (hex "#FEFEFE")
            ]
        ]
        ([ Components.Topbar.view {} ]
            ++ (case toastTray of
                    Just toastElement ->
                        [ div
                            [ css
                                [ position fixed
                                , top (px 70)
                                , right (px 16)
                                , zIndex (int 1000)
                                ]
                            ]
                            [ toastElement ]
                        ]

                    Nothing ->
                        []
               )
            ++ [ div
                    [ css
                        [ width (px 1000)
                        , margin2 zero auto
                        , padding2 (px 32) (px 16)
                        ]
                    ]
                    content
               ]
        )
    ]
