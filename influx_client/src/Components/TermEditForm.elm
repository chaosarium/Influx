module Components.TermEditForm exposing (..)

import Bindings exposing (..)
import BindingsUtils exposing (getSentenceSegmentOrthography)
import Components.Styles as Styles
import Datastore.DictContext as DictContext
import Datastore.FocusContext as FocusContext
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
    { orig_term : Term
    , working_term : Term
    , write_action : WriteAction
    }


type FormModel
    = TermForm TermFormModel
    | NothingForm
    | ErrorForm String


type alias Model =
    { form_model : FormModel
    , seg_to_edit : Maybe SentSegV2
    }


empty : Model
empty =
    { form_model = NothingForm
    , seg_to_edit = Nothing
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
    | RequestEditTerm TermEditAction Term (Maybe DocPath)
    | OverwriteTerm Term
    | AddToast String
    | GotUpdatedAnnotatedDoc AnnotatedDocV2
      -- downward propagation
    | EditingSegUpdated (Maybe (List SentSegV2)) (Maybe SentSegV2)
    | GotTermEditResponse (Result Http.Error TermEditResponse)



-- UPDATE


updateTermForm : FormMsg -> TermFormModel -> TermFormModel
updateTermForm msg form =
    let
        working_term =
            form.working_term

        working_term2 =
            case ( msg, working_term ) of
                ( UpdateOrthographyInput value, TokenTerm token ) ->
                    TokenTerm { token | orthography = value }

                ( UpdateDefinitionInput value, TokenTerm token ) ->
                    TokenTerm { token | definition = value }

                ( UpdatePhoneticInput value, TokenTerm token ) ->
                    TokenTerm { token | phonetic = value }

                ( UpdateStatusInput status, TokenTerm token ) ->
                    TokenTerm { token | status = status }

                ( UpdateNotesInput value, TokenTerm token ) ->
                    TokenTerm { token | notes = value }

                ( UpdateContextInput value, TokenTerm token ) ->
                    -- TODO modify the context
                    TokenTerm token

                ( UpdateOrthographyInput value, PhraseTerm phrase ) ->
                    PhraseTerm { phrase | orthographySeq = String.split " " value }

                ( UpdateDefinitionInput value, PhraseTerm phrase ) ->
                    PhraseTerm { phrase | definition = value }

                ( UpdateStatusInput status, PhraseTerm phrase ) ->
                    PhraseTerm { phrase | status = status }

                ( UpdateNotesInput value, PhraseTerm phrase ) ->
                    PhraseTerm { phrase | notes = value }

                ( UpdateContextInput value, PhraseTerm phrase ) ->
                    -- TODO modify the context
                    PhraseTerm phrase

                _ ->
                    working_term
    in
    { form | working_term = working_term2 }


updateForm : FormMsg -> FormModel -> FormModel
updateForm msg formModel =
    case formModel of
        TermForm termForm ->
            TermForm (updateTermForm msg termForm)

        _ ->
            formModel


switchToTokenEdit : DictContext.T -> String -> FormModel
switchToTokenEdit dict_ctx orthography =
    let
        token_to_edit =
            Maybe.map BindingsUtils.tokenDefaultUnmarkedToL1 (DictContext.lookupToken dict_ctx orthography)
    in
    case token_to_edit of
        Just token ->
            TermForm
                { orig_term = TokenTerm token
                , working_term = TokenTerm token
                , write_action = Utils.maybeSelect token.id Update Create
                }

        Nothing ->
            ErrorForm ("Token not found: " ++ orthography)


switchToPhraseEdit : DictContext.T -> String -> FormModel
switchToPhraseEdit dict_ctx normalised_orthography =
    let
        phrase_to_edit =
            Maybe.map BindingsUtils.phraseDefaultUnmarkedToL1 (DictContext.lookupPhrase dict_ctx normalised_orthography)
    in
    case phrase_to_edit of
        Just phrase ->
            TermForm
                { orig_term = PhraseTerm phrase
                , working_term = PhraseTerm phrase
                , write_action = Utils.maybeSelect phrase.id Update Create
                }

        Nothing ->
            ErrorForm ("Phrase not found: " ++ normalised_orthography)


switchToPossiblyNewPhraseEdit : DictContext.T -> Phrase -> FormModel
switchToPossiblyNewPhraseEdit dict_ctx phrase =
    let
        normalized_orthography =
            BindingsUtils.orthographySeqToNormalized phrase.orthographySeq
    in
    -- try switch to phrase in dictionary, if not found, create a new one
    case switchToPhraseEdit dict_ctx normalized_orthography of
        ErrorForm _ ->
            TermForm
                { orig_term = PhraseTerm (BindingsUtils.phraseDefaultUnmarkedToL1 phrase)
                , working_term = PhraseTerm (BindingsUtils.phraseDefaultUnmarkedToL1 phrase)
                , write_action = Create
                }

        x ->
            x


handleGotTermEditAck : Model -> String -> Result Http.Error TermEditResponse -> ( Model, Effect Msg )
handleGotTermEditAck model label res =
    case res of
        Ok response ->
            let
                updated_term =
                    response.term
            in
            ( { model
                | form_model =
                    case ( model.form_model, updated_term ) of
                        ( TermForm { orig_term, working_term }, TokenTerm token ) ->
                            if token.orthography == (getTermOrthography working_term |> Maybe.withDefault "") then
                                TermForm
                                    { orig_term = TokenTerm token
                                    , write_action = Utils.maybeSelect token.id Update Create
                                    , working_term = TokenTerm { token | id = token.id, langId = token.langId }
                                    }

                            else
                                model.form_model

                        ( TermForm { orig_term, working_term }, PhraseTerm phrase ) ->
                            if BindingsUtils.orthographySeqToNormalized phrase.orthographySeq == (getTermOrthography working_term |> Maybe.withDefault "") then
                                TermForm
                                    { orig_term = PhraseTerm phrase
                                    , write_action = Utils.maybeSelect phrase.id Update Create
                                    , working_term = PhraseTerm { phrase | id = phrase.id, langId = phrase.langId }
                                    }

                            else
                                model.form_model

                        _ ->
                            model.form_model
              }
            , Effect.batch
                ([ Effect.sendMsg <| OverwriteTerm updated_term
                 , Effect.sendMsg <| AddToast (label ++ ": Success")
                 ]
                    ++ (case response.updatedAnnotatedDoc of
                            Just doc ->
                                [ Effect.sendMsg <| GotUpdatedAnnotatedDoc doc ]

                            Nothing ->
                                []
                       )
                )
            )

        Err err ->
            let
                _ =
                    Effect.sendMsg <| AddToast (label ++ ": Error: " ++ "Term edit failed.")
            in
            ( model, Effect.none )


getTermOrthography : Term -> Maybe String
getTermOrthography term =
    case term of
        TokenTerm token ->
            Just token.orthography

        PhraseTerm phrase ->
            Just (BindingsUtils.orthographySeqToNormalized phrase.orthographySeq)


update : DictContext.T -> Msg -> Model -> ( Model, Effect Msg )
update dict_ctx msg model =
    case msg of
        InputChanged formMsg ->
            ( { model | form_model = updateForm formMsg model.form_model }, Effect.none )

        EditingSegUpdated seg_slice_opt seg_opt ->
            let
                form2 =
                    case ( seg_slice_opt, seg_opt, model.form_model ) of
                        ( _, Just seg, _ ) ->
                            case seg.inner of
                                PhraseSeg { normalisedOrthography } ->
                                    switchToPhraseEdit dict_ctx normalisedOrthography

                                TokenSeg { orthography } ->
                                    switchToTokenEdit dict_ctx orthography

                                WhitespaceSeg ->
                                    NothingForm

                                PunctuationSeg ->
                                    NothingForm

                        ( Just seg_slice, Nothing, _ ) ->
                            case FocusContext.getPhraseFromSegmentSlice dict_ctx.lang_id seg_slice of
                                Just phrase ->
                                    switchToPossiblyNewPhraseEdit dict_ctx phrase

                                Nothing ->
                                    NothingForm

                        _ ->
                            NothingForm
            in
            ( { model
                | seg_to_edit = seg_opt
                , form_model = form2
              }
            , Effect.none
            )

        -- downward propagation
        GotTermEditResponse res ->
            handleGotTermEditAck model "edit" res

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
            Utils.dbgLog "unrecognised input, defaulting to Unmarked" Unmarked


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
        , doc_path : Maybe DocPath
        }
    -> Html msg
viewTermForm form lift args =
    let
        form_data =
            case form.working_term of
                TokenTerm token ->
                    { token_or_phrase = "Token"
                    , orthography = token.orthography
                    , definition = token.definition
                    , phonetic = Just token.phonetic
                    , status = token.status
                    , notes = token.notes
                    }

                PhraseTerm phrase ->
                    { token_or_phrase = "Phrase"
                    , orthography = BindingsUtils.orthographySeqToNormalized phrase.orthographySeq
                    , definition = phrase.definition
                    , phonetic = Nothing
                    , status = phrase.status
                    , notes = phrase.notes
                    }
    in
    Html.form
        [ Styles.bgGrey ]
        [ Html.text ("Editing " ++ form_data.token_or_phrase)
        , inputC [ disabled True ] "Orthography" "orthographyInput" (lift << InputChanged << UpdateOrthographyInput) form_data.orthography
        , inputC [] "Definition" "definitionInput" (lift << InputChanged << UpdateDefinitionInput) form_data.definition
        , case form_data.phonetic of
            Just p ->
                inputC [] "Phonetic" "phoneticInput" (lift << InputChanged << UpdatePhoneticInput) p

            Nothing ->
                Utils.htmlEmpty
        , selectC
            "Status"
            "statusInput"
            (lift << InputChanged << UpdateStatusInput << tokenStatusOfStringExn)
            tokenStatusOptions
            (case form.write_action of
                Create ->
                    ""

                Update ->
                    tokenStatusToString form_data.status
            )
        , textboxC "Notes" "notesInput" (lift << InputChanged << UpdateNotesInput) form_data.notes
        , Utils.htmlIf (form.write_action == Create) <|
            Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Create"
                , Html.Events.onClick (lift (RequestEditTerm CreateTerm form.working_term args.doc_path))
                ]
                []
        , Utils.htmlIf (form.write_action == Update) <|
            Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Update"
                , Html.Events.onClick (lift (RequestEditTerm UpdateTerm form.working_term args.doc_path))
                ]
                []
        , Utils.htmlIf (form.write_action == Update) <|
            Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Delete"
                , Html.Events.onClick (lift (RequestEditTerm DeleteTerm form.working_term args.doc_path))
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
        , doc_path : Maybe DocPath
        }
    -> Html msg
view model lift { dict, doc_path } =
    case model.form_model of
        TermForm term_form ->
            viewTermForm term_form lift { dict = dict, doc_path = doc_path }

        _ ->
            div [] [ Html.text "No segment selected for editing." ]
