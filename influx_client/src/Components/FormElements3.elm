module Components.FormElements3 exposing
    ( FormSection
    , SelectCOption
    , buttonC
    , buttonRowC
    , formC
    , formSectionC
    , formSectionHr
    , inputC
    , inputDisabledC
    , inputWithTooltipC
    , numberInputC
    , selectC
    , stringListC
    , termStatusSelectC
    , textareaC
    )

import Bindings exposing (TokenStatus(..))
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


labelColor =
    Colours.colorCss Colours.gray10


bascShadow =
    property "box-shadow" "0px 0px 8px 0px var(--gray-a2)"


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
                , whiteSpace noWrap
                , labelColor
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


inputKeyValWithTooltip : String -> String -> Html msg -> Html msg
inputKeyValWithTooltip label tooltip inputEl =
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
                , position relative
                ]
            ]
            [ div
                [ css
                    [ textOverflow ellipsis
                    , overflow hidden
                    , whiteSpace noWrap
                    , labelColor
                    , height inputKeyValHeight
                    , displayFlex
                    , alignItems center
                    , cursor help
                    , hover
                        [ after
                            [ property "content" ("\"" ++ tooltip ++ "\"")
                            , position absolute
                            , bottom (pct 100)
                            , left (px 0)
                            , Colours.bgCss Colours.gray1
                            , padding2 space4px space8px
                            , border2 (px 1) solid
                            , Colours.borderCss Colours.gray5
                            , borderRadius space4px
                            , fontSize (rem 0.875)
                            , whiteSpace normal
                            , zIndex (int 1000)
                            , width (px 200)
                            , marginBottom space4px
                            ]
                        ]
                    ]
                ]
                [ text label ]
            ]
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


inputDisabledC : { label : String, value_ : String } -> Html msg
inputDisabledC { label, value_ } =
    inputKeyVal label <|
        input
            [ type_ "text"
            , value value_
            , Attributes.disabled True
            , textInputCss
            , css
                [ height inputKeyValHeight
                , Colours.bgCss Colours.gray2
                , Colours.colorCss Colours.gray9
                , cursor notAllowed
                ]
            ]
            []


inputWithTooltipC : { label : String, tooltip : String, toMsg : String -> msg, value_ : String, placeholder : String } -> Html msg
inputWithTooltipC { label, tooltip, toMsg, value_, placeholder } =
    inputKeyValWithTooltip label tooltip <|
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


numberInputC : { label : String, toMsg : Float -> msg, value_ : Float, min : Float, max : Float, step : Float, placeholder : String } -> Html msg
numberInputC { label, toMsg, value_, min, max, step, placeholder } =
    inputKeyVal label <|
        input
            [ type_ "number"
            , Attributes.min (String.fromFloat min)
            , Attributes.max (String.fromFloat max)
            , Attributes.step (String.fromFloat step)
            , value (String.fromFloat value_)
            , onInput (\val -> toMsg (Maybe.withDefault value_ (String.toFloat val)))
            , Attributes.placeholder placeholder
            , textInputCss
            , css
                [ height inputKeyValHeight
                ]
            ]
            []


textareaC : { label : String, toMsg : String -> msg, value_ : String, placeholder : String, minHeight : Float } -> Html msg
textareaC { label, toMsg, value_, placeholder, minHeight } =
    inputKeyVal label <|
        Html.textarea
            [ onInput toMsg
            , value value_
            , Attributes.placeholder placeholder
            , textInputCss
            , css
                [ resize none
                , Css.minHeight (px minHeight)
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


type alias FormSection msg =
    { title : Maybe String, rows : List (Html msg), buttons : List (Html msg) }


selectC : { label : String, toMsg : String -> msg, options : List SelectCOption, value_ : Maybe String, placeholder : String } -> Html msg
selectC { label, toMsg, options, value_, placeholder } =
    inputKeyVal label <|
        Html.select
            [ value (Maybe.withDefault "" value_)
            , onInput toMsg
            , Attributes.required True
            , textInputCss
            ]
            (Html.option
                [ value ""
                , Attributes.disabled True
                , Attributes.selected (value_ == Nothing)
                ]
                [ Html.text placeholder ]
                :: List.map
                    (\opt ->
                        Html.option
                            [ value opt.value
                            , Attributes.selected (Just opt.value == value_)
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


formC : { sections : List (FormSection msg), buttons : List (Html msg), status : List (Html msg) } -> Html msg
formC { sections, buttons, status } =
    let
        renderSection section =
            let
                sectionContent =
                    div
                        [ css
                            [ displayFlex
                            , flexDirection column
                            , gap space8px
                            ]
                        ]
                        (List.concat
                            [ [ formSectionHr ]
                            , List.intersperse formSectionHr section.rows
                            , [ formSectionHr ]
                            ]
                        )

                sectionHeader =
                    case section.title of
                        Just title ->
                            [ h3
                                [ css
                                    [ fontSize (rem 1)
                                    , fontWeight bold
                                    , margin2 space0px space0px
                                    , marginBottom space16px
                                    , labelColor
                                    ]
                                ]
                                [ text title ]
                            ]

                        Nothing ->
                            []

                sectionButtons =
                    if List.isEmpty section.buttons then
                        []

                    else
                        [ buttonRowC section.buttons ]
            in
            div
                [ css
                    [ border2 (px 1) solid
                    , Colours.borderCss Colours.gray3
                    , borderRadius space8px
                    , padding space16px
                    , margin2 space16px space0px
                    , Colours.bgCss Colours.white
                    , bascShadow
                    ]
                ]
                (List.concat
                    [ sectionHeader
                    , [ sectionContent ]
                    , sectionButtons
                    ]
                )

        formButtons =
            if List.isEmpty buttons then
                []

            else
                [ buttonRowC buttons ]
    in
    div
        [ css [] ]
    <|
        List.concat
            [ List.map renderSection sections
            , formButtons
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


formSectionC : { title : String, rows : List (Html msg) } -> Html msg
formSectionC { title, rows } =
    div
        [ css
            [ margin2 space16px space0px
            ]
        ]
        [ h3
            [ css
                [ fontWeight bold
                , margin2 space0px space0px
                , marginBottom space16px
                , labelColor
                ]
            ]
            [ text title ]
        , div
            [ css
                [ displayFlex
                , flexDirection column
                , gap space16px
                ]
            ]
            rows
        ]


statusToColor : TokenStatus -> String
statusToColor status =
    case status of
        L1 ->
            Colours.red4

        L2 ->
            Colours.orange4

        L3 ->
            Colours.amber4

        L4 ->
            Colours.lime4

        L5 ->
            Colours.green4

        Known ->
            Colours.gray6

        Ignored ->
            Colours.violet4

        Unmarked ->
            Colours.gray3


termStatusSelectC : { label : String, toMsg : TokenStatus -> msg, selectedStatus : TokenStatus } -> Html msg
termStatusSelectC { label, toMsg, selectedStatus } =
    let
        statuses =
            [ L1, L2, L3, L4, L5, Known, Ignored ]

        isSelected status =
            case ( selectedStatus, status ) of
                ( L1, L1 ) ->
                    True

                ( L2, L1 ) ->
                    True

                ( L2, L2 ) ->
                    True

                ( L3, L1 ) ->
                    True

                ( L3, L2 ) ->
                    True

                ( L3, L3 ) ->
                    True

                ( L4, L1 ) ->
                    True

                ( L4, L2 ) ->
                    True

                ( L4, L3 ) ->
                    True

                ( L4, L4 ) ->
                    True

                ( L5, L1 ) ->
                    True

                ( L5, L2 ) ->
                    True

                ( L5, L3 ) ->
                    True

                ( L5, L4 ) ->
                    True

                ( L5, L5 ) ->
                    True

                ( Known, Known ) ->
                    True

                ( Ignored, Ignored ) ->
                    True

                ( Unmarked, _ ) ->
                    False

                _ ->
                    False

        isGrayedOut status =
            case ( selectedStatus, status ) of
                ( Known, L1 ) ->
                    True

                ( Known, L2 ) ->
                    True

                ( Known, L3 ) ->
                    True

                ( Known, L4 ) ->
                    True

                ( Known, L5 ) ->
                    True

                _ ->
                    False

        statusSquare status =
            let
                backgroundColor =
                    if isGrayedOut status then
                        Colours.gray5

                    else if isSelected status then
                        statusToColor selectedStatus

                    else
                        Colours.gray2

                hoverBackgroundColor =
                    if isGrayedOut status then
                        Colours.gray6

                    else
                        statusToColor selectedStatus
            in
            button
                [ onClick (toMsg status)
                , css
                    [ width (px 16)
                    , height (px 16)
                    , border2 (px 1) solid
                    , Colours.borderCss Colours.gray5
                    , borderRadius space4px
                    , Colours.bgCss backgroundColor
                    , cursor pointer
                    , padding space0px
                    , hover
                        [ Colours.bgCss hoverBackgroundColor
                        ]
                    , margin space2px
                    ]
                ]
                []

        statusSquares =
            div
                [ css
                    [ displayFlex
                    , gap space2px
                    , alignItems center
                    , height inputKeyValHeight
                    ]
                ]
                (List.map statusSquare statuses)
    in
    inputKeyVal label statusSquares
