module Components.TermEditForm exposing (..)

import Bindings exposing (..)
import BindingsUtils exposing (getSentenceConstituentOrthography)
import Components.Styles as Styles
import Datastore.DictContext as DictContext
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, onInput, onMouseDown, onMouseEnter, onMouseOver, onMouseUp, onSubmit)
import Http
import Utils exposing (rb, rt, rtc, ruby, unreachableHtml)



-- MODEL


type alias TermFormModel =
    { orthographyInput : String
    , definitionInput : String
    , phoneticInput : String
    , statusInput : TokenStatus
    , notesInput : String
    , contextInput : String
    }


type alias PhraseFormModel =
    { normalisedOrthographyInput : String
    , definitionInput : String
    , statusInput : TokenStatus
    , notesInput : String
    , contextInput : String
    }


type FormModel
    = TermForm TermFormModel
    | PhraseForm PhraseFormModel
    | NothingForm
    | ErrorForm String


type alias Model =
    { form_model : FormModel
    , con_to_edit : Maybe SentenceConstituent
    }


empty : Model
empty =
    { form_model = NothingForm
    , con_to_edit = Nothing
    }



-- MSG


type FormMsg
    = UpdateOrthographyInput String
    | UpdateDefinitionInput String
    | UpdatePhoneticInput String
    | UpdateStatusInput TokenStatus
    | UpdateNotesInput String
    | UpdateContextInput String


type Msg
    = InputChanged FormMsg
    | EditingConUpdated (Maybe SentenceConstituent)
    | Submit
    | GotResponse (Result Http.Error String)



-- UPDATE


updateTermForm : FormMsg -> TermFormModel -> TermFormModel
updateTermForm msg form =
    case msg of
        UpdateOrthographyInput value ->
            { form | orthographyInput = value }

        UpdateDefinitionInput value ->
            { form | definitionInput = value }

        UpdatePhoneticInput value ->
            { form | phoneticInput = value }

        UpdateStatusInput status ->
            { form | statusInput = status }

        UpdateNotesInput value ->
            { form | notesInput = value }

        UpdateContextInput value ->
            { form | contextInput = value }


updatePhraseForm : FormMsg -> PhraseFormModel -> PhraseFormModel
updatePhraseForm msg form =
    case msg of
        UpdateOrthographyInput value ->
            { form | normalisedOrthographyInput = value }

        UpdateDefinitionInput value ->
            { form | definitionInput = value }

        UpdateStatusInput status ->
            { form | statusInput = status }

        UpdateNotesInput value ->
            { form | notesInput = value }

        UpdateContextInput value ->
            { form | contextInput = value }

        _ ->
            form


updateForm : FormMsg -> FormModel -> FormModel
updateForm msg formModel =
    case formModel of
        TermForm termForm ->
            TermForm (updateTermForm msg termForm)

        PhraseForm phraseForm ->
            PhraseForm (updatePhraseForm msg phraseForm)

        _ ->
            formModel


switchToTermEdit : DictContext.T -> String -> FormModel
switchToTermEdit dict_ctx orthography =
    let
        term_to_edit =
            DictContext.lookupTerm dict_ctx orthography
    in
    case term_to_edit of
        Just term ->
            TermForm
                { orthographyInput = term.orthography
                , definitionInput = term.definition
                , phoneticInput = term.phonetic
                , statusInput = term.status
                , notesInput = term.notes
                , contextInput = ""
                }

        Nothing ->
            ErrorForm ("Term not found: " ++ orthography)


switchToPhraseEdit : DictContext.T -> String -> FormModel
switchToPhraseEdit dict_ctx normalised_orthography =
    let
        phrase_to_edit =
            DictContext.lookupPhrase dict_ctx normalised_orthography
    in
    case phrase_to_edit of
        Just phrase ->
            PhraseForm
                { normalisedOrthographyInput = normalised_orthography
                , definitionInput = phrase.definition
                , statusInput = phrase.status
                , notesInput = phrase.notes
                , contextInput = ""
                }

        Nothing ->
            ErrorForm ("Phrase not found: " ++ normalised_orthography)


update : DictContext.T -> Msg -> Model -> Model
update dict_ctx msg model =
    case msg of
        InputChanged formMsg ->
            { model | form_model = updateForm formMsg model.form_model }

        EditingConUpdated con_opt ->
            let
                form2 =
                    case ( con_opt, model.form_model ) of
                        ( Nothing, _ ) ->
                            NothingForm

                        ( Just (PhraseToken { normalisedOrthography }), PhraseForm { normalisedOrthographyInput } ) ->
                            if normalisedOrthography == normalisedOrthographyInput then
                                model.form_model

                            else
                                switchToPhraseEdit dict_ctx normalisedOrthography

                        ( Just (PhraseToken { normalisedOrthography }), _ ) ->
                            switchToPhraseEdit dict_ctx normalisedOrthography

                        ( Just non_phrase_tkn, TermForm { orthographyInput } ) ->
                            if getSentenceConstituentOrthography non_phrase_tkn == orthographyInput then
                                model.form_model

                            else
                                switchToTermEdit dict_ctx (getSentenceConstituentOrthography non_phrase_tkn)

                        ( Just non_phrase_tkn, _ ) ->
                            switchToTermEdit dict_ctx (getSentenceConstituentOrthography non_phrase_tkn)
            in
            { model
                | con_to_edit = con_opt
                , form_model = form2
            }

        _ ->
            model



-- VIEW
-- start component lib


inputC : String -> String -> (String -> msg) -> String -> Html msg
inputC label id toMsg value =
    div []
        [ Html.label [ Html.Attributes.for id ] [ Html.text label ]
        , Html.input
            [ Html.Attributes.type_ "text"
            , Html.Attributes.id id
            , Html.Events.onInput toMsg
            , Html.Attributes.value value
            ]
            []
        ]


textboxC : String -> String -> (String -> msg) -> String -> Html msg
textboxC label id toMsg value =
    div []
        [ Html.label [ Html.Attributes.for id ] [ Html.text label ]
        , Html.textarea
            [ Html.Attributes.id id
            , Html.Events.onInput toMsg
            , Html.Attributes.value value
            ]
            []
        ]


type alias SelectCOption =
    { value : String, label : String }


selectC : String -> String -> (String -> msg) -> List SelectCOption -> String -> Html msg
selectC label id toMsg options selectedValue =
    div []
        [ Html.label [ Html.Attributes.for id ] [ Html.text label ]
        , Html.select
            [ Html.Attributes.id id
            , Html.Attributes.value selectedValue
            , Html.Events.onInput toMsg
            ]
            (List.map
                (\opt ->
                    Html.option
                        [ Html.Attributes.value opt.value
                        , Html.Attributes.selected (opt.value == selectedValue)
                        ]
                        [ Html.text opt.label ]
                )
                options
            )
        ]



-- end component lib


tokenStatusOptions =
    [ { value = "L1", label = "L1" }
    , { value = "L2", label = "L2" }
    , { value = "L3", label = "L3" }
    , { value = "L4", label = "L4" }
    , { value = "L5", label = "L5" }
    , { value = "KNOWN", label = "KNOWN" }
    , { value = "IGNORED", label = "IGNORED" }
    , { value = "UNMARKED", label = "UNMARKED" }
    ]


tokenStatusOfStringExn : String -> TokenStatus
tokenStatusOfStringExn str =
    case str of
        "L1" ->
            L1

        "L2" ->
            L2

        "L3" ->
            L3

        "L4" ->
            L4

        "L5" ->
            L5

        "KNOWN" ->
            Known

        "IGNORED" ->
            Ignored

        "UNMARKED" ->
            Unmarked

        _ ->
            Debug.todo ("tokenStatusOfStringExn: unknown token status: " ++ str)


tokenStatusToString : TokenStatus -> String
tokenStatusToString status =
    case status of
        L1 ->
            "L1"

        L2 ->
            "L2"

        L3 ->
            "L3"

        L4 ->
            "L4"

        L5 ->
            "L5"

        Known ->
            "KNOWN"

        Ignored ->
            "IGNORED"

        Unmarked ->
            "UNMARKED"


viewTermForm :
    TermFormModel
    -> (Msg -> msg)
    ->
        { dict : DictContext.T
        }
    -> Html msg
viewTermForm form lift args =
    Html.form
        [ -- onSubmit (Debug.todo "handle submit (create or update token)")
          Styles.bgGrey
        ]
        [ inputC "Orthography" "orthographyInput" (lift << InputChanged << UpdateOrthographyInput) form.orthographyInput
        , inputC "Definition" "definitionInput" (lift << InputChanged << UpdateDefinitionInput) form.definitionInput
        , inputC "Phonetic" "phoneticInput" (lift << InputChanged << UpdatePhoneticInput) form.phoneticInput
        , selectC
            "Status"
            "statusInput"
            (lift << InputChanged << UpdateStatusInput << tokenStatusOfStringExn)
            tokenStatusOptions
            (tokenStatusToString form.statusInput)
        , textboxC "Notes" "notesInput" (lift << InputChanged << UpdateNotesInput) form.notesInput

        -- Buttons (placeholders for create/update/delete)
        , Html.input
            [ Html.Attributes.type_ "submit"
            , Html.Attributes.value "Update Token"
            ]
            []
        , Html.input
            [ Html.Attributes.type_ "button"
            , Html.Attributes.value "Delete Token"

            -- , Html.Events.onClick (Debug.todo "handle delete token")
            ]
            []
        ]


view :
    Model
    -> (Msg -> msg)
    ->
        { dict : DictContext.T
        }
    -> Html msg
view model lift { dict } =
    case model.form_model of
        TermForm term_form ->
            viewTermForm term_form lift { dict = dict }

        PhraseForm phrase_form ->
            div [] [ Html.text "TODO edit the phrase." ]

        _ ->
            div [] [ Html.text "No constituent selected for editing." ]
