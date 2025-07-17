module Components.FormElements exposing (SelectCOption, buttonC, inputC, selectC, stringListC, textboxC)

import Html exposing (Html, div)
import Html.Attributes exposing (class, disabled, for, hidden, id, selected, type_, value)
import Html.Events exposing (onClick, onInput)


inputC : List (Html.Attribute msg) -> String -> String -> (String -> msg) -> String -> Html msg
inputC attrs label id_ toMsg value_ =
    div []
        [ Html.label [ for id_ ] [ Html.text label ]
        , Html.input
            (attrs
                ++ [ type_ "text"
                   , id id_
                   , onInput toMsg
                   , value value_
                   ]
            )
            []
        ]


textboxC : String -> String -> (String -> msg) -> String -> Html msg
textboxC label id_ toMsg value_ =
    div []
        [ Html.label [ for id_ ] [ Html.text label ]
        , Html.textarea
            [ id id_
            , onInput toMsg
            , value value_
            ]
            []
        ]


type alias SelectCOption =
    { value : String, label : String }


selectC : String -> String -> (String -> msg) -> List SelectCOption -> String -> Html msg
selectC label id_ toMsg options selectedValue =
    div []
        [ Html.label [ for id_ ] [ Html.text label ]
        , Html.select
            [ id id_
            , value selectedValue
            , onInput toMsg
            , Html.Attributes.required True
            ]
            (Html.option
                [ value ""
                , disabled True
                , selected (selectedValue == "")
                , hidden True
                ]
                [ Html.text "Select a status... (or default to L1)" ]
                :: List.map
                    (\opt ->
                        Html.option
                            [ value opt.value
                            , selected (opt.value == selectedValue)
                            ]
                            [ Html.text opt.label ]
                    )
                    options
            )
        ]


stringListC : String -> String -> (List String -> msg) -> (String -> msg) -> List String -> String -> Html msg
stringListC label id_ onListChange onInputChange items currentInput =
    div []
        [ Html.label [ for id_ ] [ Html.text label ]
        , div []
            (List.indexedMap
                (\index item ->
                    div []
                        [ Html.span [] [ Html.text item ]
                        , Html.button
                            [ type_ "button"
                            , onClick (onListChange (List.take index items ++ List.drop (index + 1) items))
                            ]
                            [ Html.text "×" ]
                        ]
                )
                items
            )
        , div []
            [ Html.input
                [ type_ "text"
                , id id_
                , onInput onInputChange
                , value currentInput
                , Html.Attributes.placeholder "Add new tag..."
                ]
                []
            , Html.button
                [ type_ "button"
                , onClick (onListChange (items ++ [ String.trim currentInput ]))
                , disabled (String.trim currentInput == "")
                ]
                [ Html.text "Add" ]
            ]
        ]


buttonC : List (Html.Attribute msg) -> String -> Html msg
buttonC attrs label =
    Html.input
        (attrs
            ++ [ type_ "button"
               , value label
               ]
        )
        []
