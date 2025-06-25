module Components.TermEditForm exposing (..)

import Bindings exposing (..)
import BindingsUtils exposing (getSentenceConstituentOrthography)
import Components.Styles as Styles
import Datastore.DictContext as DictContext
import Effect exposing (Effect)
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, disabled, style)
import Html.Events exposing (onClick, onInput, onMouseDown, onMouseEnter, onMouseOver, onMouseUp, onSubmit)
import Http
import Utils exposing (rb, rt, rtc, ruby, unreachableHtml)



-- MODEL


type WriteAction
    = Create
    | Update


type alias TermFormModel =
    { orig_term : Token
    , working_term : Token
    , write_action : WriteAction
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
      -- upward propagation
    | RequestCreateToken Token
    | RequestUpdateToken Token
    | RequestDeleteToken Token
    | OverwriteToken Token
      -- downward propagation
    | EditingConUpdated (Maybe SentenceConstituent)
    | GotCreateTermResponse (Result Http.Error Token)
    | GotUpdateTermResponse (Result Http.Error Token)
    | GotDeleteTermResponse (Result Http.Error Token)



-- UPDATE


updateTermForm : FormMsg -> TermFormModel -> TermFormModel
updateTermForm msg form =
    let
        working_term =
            form.working_term

        working_term2 =
            case msg of
                UpdateOrthographyInput value ->
                    { working_term | orthography = value }

                UpdateDefinitionInput value ->
                    { working_term | definition = value }

                UpdatePhoneticInput value ->
                    { working_term | phonetic = value }

                UpdateStatusInput status ->
                    { working_term | status = status }

                UpdateNotesInput value ->
                    { working_term | notes = value }

                UpdateContextInput value ->
                    -- TODO modify the context
                    working_term
    in
    { form | working_term = working_term2 }


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
            Maybe.map BindingsUtils.termDefaultUnmarkedToL1 (DictContext.lookupTerm dict_ctx orthography)
    in
    case term_to_edit of
        Just term ->
            TermForm
                { orig_term = BindingsUtils.termDefaultUnmarkedToL1 term
                , working_term = BindingsUtils.termDefaultUnmarkedToL1 term
                , write_action = Utils.maybeSelect term.id Update Create
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


handleGotTermEditAck : Model -> String -> Result Http.Error Token -> ( Model, Effect Msg )
handleGotTermEditAck model label res =
    case res of
        Ok token ->
            let
                _ =
                    Debug.log (label ++ ": Success") token
            in
            ( { model
                | form_model =
                    case model.form_model of
                        TermForm { orig_term, working_term } ->
                            if token.orthography == working_term.orthography then
                                TermForm
                                    { orig_term = token
                                    , write_action = Utils.maybeSelect token.id Update Create
                                    , working_term = { working_term | id = token.id, langId = token.langId }
                                    }

                            else
                                model.form_model

                        _ ->
                            model.form_model
              }
            , Effect.sendMsg <| OverwriteToken token
            )

        Err err ->
            let
                _ =
                    Debug.log (label ++ ": Error") err
            in
            ( model, Effect.none )


update : DictContext.T -> Msg -> Model -> ( Model, Effect Msg )
update dict_ctx msg model =
    case msg of
        InputChanged formMsg ->
            ( { model | form_model = updateForm formMsg model.form_model }, Effect.none )

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

                        ( Just non_phrase_tkn, TermForm { working_term } ) ->
                            if getSentenceConstituentOrthography non_phrase_tkn == working_term.orthography then
                                model.form_model

                            else
                                switchToTermEdit dict_ctx (getSentenceConstituentOrthography non_phrase_tkn)

                        ( Just non_phrase_tkn, _ ) ->
                            switchToTermEdit dict_ctx (getSentenceConstituentOrthography non_phrase_tkn)
            in
            ( { model
                | con_to_edit = con_opt
                , form_model = form2
              }
            , Effect.none
            )

        -- downward propagation
        GotCreateTermResponse res ->
            handleGotTermEditAck model "create" res

        GotUpdateTermResponse res ->
            handleGotTermEditAck model "update" res

        GotDeleteTermResponse res ->
            handleGotTermEditAck model "delete" res

        _ ->
            ( model, Effect.none )



-- VIEW
-- start component lib


inputC : List (Html.Attribute msg) -> String -> String -> (String -> msg) -> String -> Html msg
inputC attrs label id toMsg value =
    div []
        [ Html.label [ Html.Attributes.for id ] [ Html.text label ]
        , Html.input
            (attrs
                ++ [ Html.Attributes.type_ "text"
                   , Html.Attributes.id id
                   , Html.Events.onInput toMsg
                   , Html.Attributes.value value
                   ]
            )
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
            , Html.Attributes.required True
            ]
            (Html.option
                [ Html.Attributes.value ""
                , Html.Attributes.disabled True
                , Html.Attributes.selected (selectedValue == "")
                , Html.Attributes.hidden True
                ]
                [ Html.text "Select a status... (or default to L1)" ]
                :: List.map
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


tokenStatusOptions : List SelectCOption
tokenStatusOptions =
    [ { value = "L1", label = "L1" }
    , { value = "L2", label = "L2" }
    , { value = "L3", label = "L3" }
    , { value = "L4", label = "L4" }
    , { value = "L5", label = "L5" }
    , { value = "KNOWN", label = "KNOWN" }
    , { value = "IGNORED", label = "IGNORED" }
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
        [ inputC [ disabled True ] "Orthography" "orthographyInput" (lift << InputChanged << UpdateOrthographyInput) form.working_term.orthography
        , inputC [] "Definition" "definitionInput" (lift << InputChanged << UpdateDefinitionInput) form.working_term.definition
        , inputC [] "Phonetic" "phoneticInput" (lift << InputChanged << UpdatePhoneticInput) form.working_term.phonetic
        , selectC
            "Status"
            "statusInput"
            (lift << InputChanged << UpdateStatusInput << tokenStatusOfStringExn)
            tokenStatusOptions
            -- (tokenStatusToString form.working_term.status)
            (case form.write_action of
                Create ->
                    ""

                Update ->
                    tokenStatusToString form.working_term.status
            )
        , textboxC "Notes" "notesInput" (lift << InputChanged << UpdateNotesInput) form.working_term.notes
        , Utils.htmlIf (form.write_action == Create) <|
            Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Create"
                , Html.Events.onClick (lift (RequestCreateToken form.working_term))
                ]
                []
        , Utils.htmlIf (form.write_action == Update) <|
            Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Update"
                , Html.Events.onClick (lift (RequestUpdateToken form.working_term))
                ]
                []
        , Utils.htmlIf (form.write_action == Update) <|
            Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Delete"
                , Html.Events.onClick (lift (RequestDeleteToken form.working_term))
                ]
                []
        , if form.working_term /= form.orig_term then
            div [ style "color" "orange", style "margin-top" "8px" ]
                [ Html.text "You have unsaved changes." ]

          else
            Utils.htmlEmpty
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
            Utils.todoHtml "Phrase editing not implemented yet"

        _ ->
            div [] [ Html.text "No constituent selected for editing." ]
