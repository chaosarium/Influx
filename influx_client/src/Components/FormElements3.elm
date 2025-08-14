module Components.FormElements3 exposing
    ( SelectCOption
    , buttonC
    , buttonRowC
    , formC
    , formSectionHr
    , inputC
    , selectC
    , stringListC
    , textareaC
    )

import Colours
import Css exposing (..)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (css, type_, value)
import Html.Styled.Events as Events exposing (onClick, onInput)
import Json.Decode as Decode


space0px =
    px 0


space2px =
    px 2


space4px =
    px 4


space8px =
    px 8


space16px =
    px 16


space32px =
    px 32


space64px =
    px 64


gap : LengthOrNumberOrAutoOrNoneOrContent compatible -> Style
gap x =
    property "gap" x.value


red =
    rgb 255 0 0


formLabelWidth =
    px 200


inputKeyValHeight =
    px 42


borderNone =
    property "border" "none"


inputKeyVal label inputEl =
    div
        [ css
            [ displayFlex
            , alignItems start
            , gap space16px
            , width (pct 100)
            , pseudoClass "focus-within"
                []
            ]
        ]
        [ div
            [ css
                [ width formLabelWidth
                , textOverflow ellipsis
                , overflow hidden
                , Colours.colorCss Colours.gray10
                , height inputKeyValHeight
                , displayFlex
                , alignItems center
                ]
            ]
            [ text label ]
        , div
            [ css [ width (pct 100) ]
            ]
            [ inputEl ]
        ]


baseInteractiveCss =
    [ fontSize (rem 1)
    , fontFamily inherit
    , Colours.colorCss Colours.black
    , Colours.bgCss Colours.white
    , padding space8px
    , border3 (px 1) solid transparent
    , borderRadius space4px
    , hover
        [ Colours.borderCss Colours.gray5
        , Colours.bgCss Colours.gray1
        ]
    , focus
        [ outline none
        , Colours.borderCss Colours.gray5
        , Colours.bgCss Colours.gray1
        ]
    ]


formElementCss additionalStyles =
    css ([ width (pct 100) ] ++ baseInteractiveCss ++ additionalStyles)


textInputCss =
    formElementCss []


inputC : { label : String, toMsg : String -> msg, value_ : String, placeholder : String } -> Html msg
inputC { label, toMsg, value_, placeholder } =
    inputKeyVal label <|
        input
            [ type_ "text"
            , value value_
            , onInput toMsg
            , Attributes.placeholder placeholder
            , textInputCss
            , css
                [ height inputKeyValHeight
                ]
            ]
            []


textareaC : { label : String, toMsg : String -> msg, value_ : String, placeholder : String } -> Html msg
textareaC { label, toMsg, value_, placeholder } =
    inputKeyVal label <|
        Html.textarea
            [ onInput toMsg
            , value value_
            , Attributes.placeholder placeholder
            , textInputCss
            , css
                [ resize none
                , minHeight (px 200)
                , focus
                    [ resize vertical
                    ]
                , hover
                    [ resize vertical
                    ]
                , display block
                ]
            ]
            []


type alias SelectCOption =
    { value : String, label : String }


selectC : { label : String, toMsg : String -> msg, options : List SelectCOption, value_ : String } -> Html msg
selectC { label, toMsg, options, value_ } =
    inputKeyVal label <|
        Html.select
            [ value value_
            , onInput toMsg
            , Attributes.required True
            , textInputCss
            ]
            (Html.option
                [ value ""
                , Attributes.disabled True
                , Attributes.selected (value_ == "")
                , Attributes.hidden True
                ]
                [ Html.text "Select a status... (or default to L1)" ]
                :: List.map
                    (\opt ->
                        Html.option
                            [ value opt.value
                            , Attributes.selected (opt.value == value_)
                            ]
                            [ Html.text opt.label ]
                    )
                    options
            )


formSectionHr : Html msg
formSectionHr =
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


formC : { rows : List (Html msg), buttons : List (Html msg), status : List (Html msg) } -> Html msg
formC { rows, buttons, status } =
    let
        fieldsDiv =
            div [ css [ margin2 space16px space0px, displayFlex, flexDirection column, gap space8px ] ] <|
                List.concat
                    [ [ formSectionHr ]
                    , List.intersperse formSectionHr rows
                    , [ formSectionHr ]
                    ]
    in
    div
        [ css [] ]
    <|
        List.concat
            [ [ fieldsDiv ]
            , [ buttonRowC buttons ]
            , status
            ]


stringListC : { label : String, items : List String, currentInput : String, onListChange : List String -> msg, onInputChange : String -> msg } -> Html msg
stringListC { label, items, currentInput, onListChange, onInputChange } =
    let
        onKeyDown =
            Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" && String.trim currentInput /= "" then
                            Decode.succeed (onListChange (items ++ [ String.trim currentInput ]))

                        else if key == "Backspace" && String.trim currentInput == "" && not (List.isEmpty items) then
                            Decode.succeed (onListChange (List.take (List.length items - 1) items))

                        else
                            Decode.fail "Not a handled key combination"
                    )
    in
    inputKeyVal label <|
        div
            [ formElementCss
                [ minHeight inputKeyValHeight
                , displayFlex
                , flexWrap wrap
                , alignItems center
                , gap space4px
                , cursor text_
                , pseudoClass "focus-within"
                    [ Colours.borderCss Colours.gray5
                    , Colours.bgCss Colours.gray1
                    ]
                ]
            ]
            (List.indexedMap
                (\index item ->
                    div
                        [ css
                            [ displayFlex
                            , alignItems center
                            , gap space4px
                            , padding2 space4px space8px
                            , Colours.bgCss Colours.gray3
                            , borderRadius space4px
                            , flexShrink (num 0)
                            ]
                        ]
                        [ span [ css [ fontSize (rem 0.75) ] ] [ text item ]
                        , button
                            [ onClick (onListChange (List.take index items ++ List.drop (index + 1) items))
                            , css
                                (buttonBaseCss
                                    ++ [ padding2 space2px space4px
                                       , width (px 16)
                                       , height (px 16)
                                       , lineHeight (num 1)
                                       , displayFlex
                                       , alignItems center
                                       , justifyContent center
                                       , fontSize (rem 0.8)
                                       ]
                                )
                            ]
                            [ text "×" ]
                        ]
                )
                items
                ++ [ input
                        [ type_ "text"
                        , value currentInput
                        , onInput onInputChange
                        , Events.on "keydown" onKeyDown
                        , Attributes.placeholder
                            (if List.isEmpty items then
                                "Add tags..."

                             else
                                ""
                            )
                        , css
                            [ border3 (px 0) solid transparent
                            , outline none
                            , backgroundColor transparent
                            , fontSize (rem 1)
                            , fontFamily inherit
                            , Colours.colorCss Colours.black
                            , padding space0px
                            , flexGrow (num 1)
                            , width (px 10)
                            ]
                        ]
                        []
                   ]
            )


buttonBaseCss =
    [ border2 (px 1) solid
    , borderRadius space4px
    , Colours.bgCss Colours.white
    , cursor pointer
    , fontSize (rem 1)
    , fontFamily inherit
    , Colours.colorCss Colours.black
    , Colours.borderCss Colours.gray5
    , hover
        [ Colours.bgCss Colours.gray1
        ]
    ]


buttonC : { label : String, onPress : Maybe msg } -> Html msg
buttonC { label, onPress } =
    button
        [ case onPress of
            Just msg ->
                onClick msg

            Nothing ->
                Attributes.disabled True
        , css
            (buttonBaseCss
                ++ [ padding2 space8px space16px
                   , disabled
                        [ cursor notAllowed
                        , opacity (num 0.5)
                        ]
                   ]
            )
        ]
        [ text label ]


buttonRowC : List (Html msg) -> Html msg
buttonRowC buttons =
    div
        [ css
            [ displayFlex
            , gap space16px
            , justifyContent flexEnd
            ]
        ]
        buttons
