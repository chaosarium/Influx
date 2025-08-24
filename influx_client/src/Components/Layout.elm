module Components.Layout exposing (documentLayoutC, pageLayoutC, ribbonDocumentLayoutC)

import Colours exposing (..)
import Components.RibbonNav
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
            , bgCss gray2
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


documentLayoutC : { toastTray : Maybe (Html msg) } -> List (Html msg) -> Html msg -> List (Html msg)
documentLayoutC { toastTray } leftPanelContent rightPanel =
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
                                , left (px 8)
                                , bottom (px 8)
                                , zIndex (int 9999)
                                ]
                            ]
                            [ toastElement ]
                        ]

                    Nothing ->
                        []
               )
            ++ [ div
                    [ css
                        [ displayFlex
                        , flex (int 1)
                        ]
                    ]
                    [ div
                        [ css
                            [ flex (int 1)
                            , overflowY auto
                            ]
                        ]
                        [ div
                            [ css
                                [ maxWidth (px 1000)
                                , padding2 (px 32) (px 16)
                                , margin2 zero auto
                                ]
                            ]
                            leftPanelContent
                        ]
                    , rightPanel
                    ]
               ]
        )
    ]


ribbonDocumentLayoutC : { toastTray : Maybe (Html msg) } -> Html msg -> Html msg -> Html msg -> Html msg
ribbonDocumentLayoutC { toastTray } leftSidebar centerColumn rightSidebar =
    div
        [ css
            [ height (vh 100)
            , displayFlex
            , backgroundColor (hex "#FEFEFE")
            ]
        ]
        [ Components.RibbonNav.view {}
        , div
            [ css
                [ displayFlex
                , flex (int 1)
                , marginLeft (px 48) -- Account for ribbon width
                ]
            ]
            [ leftSidebar
            , centerColumn
            , rightSidebar
            ]
        , case toastTray of
            Just toastElement ->
                div
                    [ css
                        [ position fixed
                        , left (px 56) -- Account for ribbon + some margin
                        , bottom (px 8)
                        , zIndex (int 9999)
                        ]
                    ]
                    [ toastElement ]

            Nothing ->
                text ""
        ]
