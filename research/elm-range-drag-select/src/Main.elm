-- experiment created with help of copilot
-- run me with `elm reactor`


module Main exposing (main)

import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onMouseDown, onMouseOver, onMouseUp)


type alias Model =
    { selecting : Maybe Int
    , selection : Maybe ( Int, Int )
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { selecting = Nothing, selection = Nothing }, Cmd.none )


type Msg
    = StartSelect Int
    | OverBox Int
    | EndSelect


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartSelect i ->
            ( { model | selecting = Just i, selection = Just ( i, i + 1 ) }, Cmd.none )

        OverBox i ->
            case model.selecting of
                Just start ->
                    let
                        lo =
                            min start i

                        hi =
                            max start i + 1
                    in
                    ( { model | selection = Just ( lo, hi ) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        EndSelect ->
            ( { model | selecting = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        ( start, end ) =
            case model.selection of
                Just ( s, e ) ->
                    ( s, e )

                Nothing ->
                    ( 0, 0 )

        boxView i =
            let
                isSelected =
                    case model.selection of
                        Just ( s, e ) ->
                            i >= s && i < e

                        Nothing ->
                            False

                boxStyle =
                    [ style "display" "inline-block"
                    , style "width" "40px"
                    , style "height" "40px"
                    , style "margin" "4px"
                    , style "line-height" "40px"
                    , style "text-align" "center"
                    , style "user-select" "none"
                    , style "border" "1px solid #333"
                    , style "background"
                        (if isSelected then
                            "#8cf"

                         else
                            "#eee"
                        )
                    , style "cursor" "pointer"
                    ]
            in
            div
                (boxStyle
                    ++ [ onMouseDown (StartSelect i)
                       , onMouseOver (OverBox i)
                       , onMouseUp EndSelect
                       ]
                )
                [ text (String.fromInt i) ]
    in
    div []
        [ div [] (List.map boxView (List.range 0 9))
        , div [ style "margin-top" "20px" ]
            [ text ("Selected: start = " ++ String.fromInt start ++ ", end = " ++ String.fromInt end) ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
