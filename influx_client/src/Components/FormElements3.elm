module Components.FormElements3 exposing
    ( FormSection
    , SelectCOption
    , buttonC
    , buttonRowC
    , checkboxC
    , formC
    , formSectionC
    , formSectionHr
    , inputC
    , inputWithTooltipC
    , numberInputC
    , selectC
    , stringListC
    , termStatusSelectC
    , textareaC
    )

import Bindings exposing (TokenStatus(..))
import Colours
import Components.StatusColours as StatusColours
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


inputKeyValHeightCompact =
    px 32


getKeyValHeight compact =
    if compact then
        inputKeyValHeightCompact

    else
        inputKeyValHeight


getGapSize compact =
    if compact then
        space8px

    else
        space16px


getPaddingXSize compact =
    if compact then
        space4px

    else
        space8px


getPaddingYSize compact =
    if compact then
        space2px

    else
        space8px


getFormGapSize compact =
    if compact then
        space4px

    else
        space8px


borderNone =
    property "border" "none"


labelColor =
    Colours.colorCss Colours.gray10


bascShadow =
    property "box-shadow" "0px 0px 8px 0px var(--gray-a2)"


inputKeyVal compact label inputEl =
    div
        [ css
            [ displayFlex
            , alignItems start
            , gap (getGapSize compact)
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
                , height (getKeyValHeight compact)
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


inputKeyValWithTooltip : Bool -> String -> String -> Html msg -> Html msg
inputKeyValWithTooltip compact label tooltip inputEl =
    div
        [ css
            [ displayFlex
            , alignItems start
            , gap (getGapSize compact)
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
                    , height (getKeyValHeight compact)
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


baseInteractiveCss compact =
    [ fontSize (rem 1)
    , fontFamily inherit
    , Colours.colorCss Colours.black
    , Colours.bgCss Colours.white
    , padding2 (getPaddingYSize compact) (getPaddingXSize compact)
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


formElementCss compact additionalStyles =
    css ([ width (pct 100) ] ++ baseInteractiveCss compact ++ additionalStyles)


textInputCss compact =
    formElementCss compact []


inputC : { label : String, toMsg : Maybe (String -> msg), value_ : String, placeholder : String, compact : Bool } -> Html msg
inputC { label, toMsg, value_, placeholder, compact } =
    inputKeyVal compact label <|
        input
            ([ type_ "text"
             , value value_
             , Attributes.placeholder placeholder
             , textInputCss compact
             , css
                [ height (getKeyValHeight compact)
                ]
             ]
                ++ (case toMsg of
                        Just msg ->
                            [ onInput msg ]

                        Nothing ->
                            [ Attributes.disabled True
                            , css
                                [ Colours.bgCss Colours.gray2
                                , Colours.colorCss Colours.gray9
                                , cursor notAllowed
                                ]
                            ]
                   )
            )
            []


inputWithTooltipC : { label : String, tooltip : String, toMsg : String -> msg, value_ : String, placeholder : String, compact : Bool } -> Html msg
inputWithTooltipC { label, tooltip, toMsg, value_, placeholder, compact } =
    inputKeyValWithTooltip compact label tooltip <|
        input
            [ type_ "text"
            , value value_
            , onInput toMsg
            , Attributes.placeholder placeholder
            , textInputCss compact
            , css
                [ height (getKeyValHeight compact)
                ]
            ]
            []


numberInputC : { label : String, toMsg : Float -> msg, value_ : Float, min : Float, max : Float, step : Float, placeholder : String, compact : Bool } -> Html msg
numberInputC { label, toMsg, value_, min, max, step, placeholder, compact } =
    inputKeyVal compact label <|
        input
            [ type_ "number"
            , Attributes.min (String.fromFloat min)
            , Attributes.max (String.fromFloat max)
            , Attributes.step (String.fromFloat step)
            , value (String.fromFloat value_)
            , onInput (\val -> toMsg (Maybe.withDefault value_ (String.toFloat val)))
            , Attributes.placeholder placeholder
            , textInputCss compact
            , css
                [ height (getKeyValHeight compact)
                ]
            ]
            []


checkboxC : { label : String, toMsg : msg, checked : Bool, compact : Bool } -> Html msg
checkboxC { label, toMsg, checked, compact } =
    inputKeyVal compact label <|
        Html.label
            [ css
                [ displayFlex
                , alignItems center
                , cursor pointer
                , height (getKeyValHeight compact)
                , padding2 (getPaddingYSize compact) (getPaddingXSize compact)
                , fontSize (rem 1)
                , Colours.bgCss Colours.white
                , border3 (px 1) solid transparent
                , borderRadius space4px
                , hover
                    [ Colours.borderCss Colours.gray5
                    , Colours.bgCss Colours.gray1
                    ]
                ]
            ]
            [ div
                [ css
                    [ position relative
                    , width (px 16)
                    , height (px 16)
                    , marginRight (getPaddingXSize compact)
                    , border3 (px 1) solid transparent
                    , borderRadius space2px
                    , cursor pointer
                    , displayFlex
                    , alignItems center
                    , justifyContent center
                    , if checked then
                        batch
                            [ Colours.borderCss Colours.gray9
                            , Colours.bgCss Colours.gray9
                            ]

                      else
                        batch
                            [ Colours.borderCss Colours.gray6
                            , Colours.bgCss Colours.white
                            ]
                    ]
                ]
                [ if checked then
                    div
                        [ css
                            [ Colours.colorCss Colours.white
                            , fontSize (px 12)
                            , fontWeight bold
                            , lineHeight (num 1)
                            ]
                        ]
                        [ text "✓" ]

                  else
                    text ""
                ]
            , input
                [ type_ "checkbox"
                , Attributes.checked checked
                , onClick toMsg
                , css
                    [ position absolute
                    , opacity (num 0)
                    , width (px 0)
                    , height (px 0)
                    ]
                ]
                []
            ]


textareaC : { label : String, toMsg : Maybe (String -> msg), value_ : String, placeholder : String, minHeight : Float, compact : Bool } -> Html msg
textareaC { label, toMsg, value_, placeholder, minHeight, compact } =
    inputKeyVal compact label <|
        Html.textarea
            ([ value value_
             , Attributes.placeholder placeholder
             , textInputCss compact
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
                ++ (case toMsg of
                        Just msg ->
                            [ onInput msg ]

                        Nothing ->
                            [ Attributes.disabled True
                            , css
                                [ Colours.bgCss Colours.gray2
                                , Colours.colorCss Colours.gray9
                                , cursor notAllowed
                                ]
                            ]
                   )
            )
            []


type alias SelectCOption =
    { value : String, label : String }


type alias FormSection msg =
    { title : Maybe String, rows : List (Html msg), buttons : List (Html msg) }


selectC : { label : String, toMsg : String -> msg, options : List SelectCOption, value_ : Maybe String, placeholder : String, compact : Bool } -> Html msg
selectC { label, toMsg, options, value_, placeholder, compact } =
    inputKeyVal compact label <|
        Html.select
            [ value (Maybe.withDefault "" value_)
            , onInput toMsg
            , Attributes.required True
            , textInputCss compact
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


formSectionHr : Bool -> Html msg
formSectionHr compact =
    let
        marginSize =
            if compact then
                px 0

            else
                px 0
    in
    hr
        [ css
            [ borderNone
            , borderBottom2 (px 1) solid
            , Colours.borderCss Colours.gray3
            , width (pct 100)
            , margin2 marginSize marginSize
            ]
        ]
        []


formC : { sections : List (FormSection msg), buttons : List (Html msg), status : List (Html msg), compact : Bool } -> Html msg
formC { sections, buttons, status, compact } =
    let
        renderSection section =
            let
                sectionContent =
                    div
                        [ css
                            [ displayFlex
                            , flexDirection column
                            , gap (getFormGapSize compact)
                            ]
                        ]
                        (List.concat
                            [ [ formSectionHr compact ]
                            , List.intersperse (formSectionHr compact) section.rows
                            , [ formSectionHr compact ]
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


stringListC : { label : String, items : List String, currentInput : String, onListChange : List String -> msg, onInputChange : String -> msg, compact : Bool } -> Html msg
stringListC { label, items, currentInput, onListChange, onInputChange, compact } =
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
    inputKeyVal compact label <|
        div
            [ formElementCss compact
                [ minHeight (getKeyValHeight compact)
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


termStatusSelectC : { label : String, toMsg : TokenStatus -> msg, selectedStatus : TokenStatus, compact : Bool } -> Html msg
termStatusSelectC { label, toMsg, selectedStatus, compact } =
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
                        StatusColours.statusFillColor selectedStatus

                    else
                        Colours.gray2

                borderColor =
                    if isGrayedOut status then
                        Colours.gray6

                    else if isSelected status then
                        StatusColours.statusBorderColor selectedStatus

                    else
                        Colours.gray5

                hoverBackgroundColor =
                    if isGrayedOut status then
                        Colours.gray6

                    else
                        StatusColours.statusFillColor selectedStatus

                hoverBorderColor =
                    if isGrayedOut status then
                        Colours.gray6

                    else
                        StatusColours.statusBorderColor selectedStatus
            in
            button
                [ onClick (toMsg status)
                , css
                    [ width (px 16)
                    , height (px 16)
                    , border2 (px 1) solid
                    , Colours.borderCss borderColor
                    , borderRadius space4px
                    , Colours.bgCss backgroundColor
                    , cursor pointer
                    , padding space0px
                    , hover
                        [ Colours.bgCss hoverBackgroundColor
                        , Colours.borderCss hoverBorderColor
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
                    , height (getKeyValHeight compact)
                    ]
                ]
                (List.map statusSquare statuses)
    in
    inputKeyVal compact label statusSquares
