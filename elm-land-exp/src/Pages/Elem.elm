-- pokemon thing https://elm.land/guide/rest-apis.html


module Pages.Elem exposing (Model, Msg, page)

import Api
import Api.PokemonList
import Html exposing (Html)
import Html.Attributes exposing (alt, class, src, style)
import Http
import Page exposing (Page)
import View exposing (View)


page : Page Model Msg
page =
    Page.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { pokemonData : Api.Data (List Pokemon) }


type alias Pokemon =
    { name : String }


init : ( Model, Cmd Msg )
init =
    ( { pokemonData = Api.Loading }
    , Api.PokemonList.getFirst150 { onResponse = PokeApiResponded }
    )



-- UPDATE


type Msg
    = PokeApiResponded (Result Http.Error (List Pokemon))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PokeApiResponded (Ok listOfPokemon) ->
            ( { model | pokemonData = Api.Success listOfPokemon }, Cmd.none )

        PokeApiResponded (Err httpError) ->
            ( { model | pokemonData = Api.Failure httpError }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Pokemon"
    , body =
        case model.pokemonData of
            Api.Loading ->
                [ Html.text "loading..." ]

            Api.Success listOfPokemon ->
                [ viewPokemonList listOfPokemon ]

            Api.Failure httpError ->
                [ Html.text (Api.toUserFriendlyMessage httpError) ]
    }


viewPokemonList : List Pokemon -> Html Msg
viewPokemonList listOfPokemon =
    Html.div [ class "container py-6 p-5" ]
        [ Html.div [ class "columns is-multiline" ]
            (List.indexedMap viewPokemon listOfPokemon)
        ]


viewPokemon : Int -> Pokemon -> Html Msg
viewPokemon index pokemon =
    let
        pokedexNumber : Int
        pokedexNumber =
            index + 1

        pokemonImageUrl : String
        pokemonImageUrl =
            "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/"
                ++ String.fromInt pokedexNumber
                ++ ".png"
    in
    Html.div [ class "column is-4-desktop is-6-tablet" ]
        [ Html.div [ class "card" ]
            [ Html.div [ class "card-content" ]
                [ Html.div [ class "media" ]
                    [ Html.div [ class "media-left" ]
                        [ Html.figure [ class "image is-64x64" ]
                            [ Html.img [ src pokemonImageUrl, alt pokemon.name, style "width" "40px" ] []
                            ]
                        ]
                    , Html.div [ class "media-content" ]
                        [ Html.p [ class "title is-4" ] [ Html.text pokemon.name ]
                        , Html.p [ class "subtitle is-6" ] [ Html.text ("No. " ++ String.fromInt pokedexNumber) ]
                        ]
                    ]
                ]
            ]
        ]
