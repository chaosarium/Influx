module Components.TermEditForm exposing (..)

import Bindings exposing (..)
import BindingsUtils exposing (getSentenceSegmentOrthography)
import Components.FormElements3 exposing (buttonC, buttonRowC, formC, inputC, inputDisabledC, termStatusSelectC, textareaC)
import Components.Styles as Styles
import Datastore.DictContext as DictContext
import Datastore.FocusContext as FocusContext
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Styled
import Html.Styled.Attributes exposing (style)
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
    | RequestEditTerm TermEditAction Term (Maybe InfluxResourceId)
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
        , document_id : Maybe InfluxResourceId
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
    Html.Styled.toUnstyled <|
        formC
            { sections =
                [ { title = Just ("Editing " ++ form_data.token_or_phrase)
                  , rows =
                        List.filterMap identity
                            [ Just (inputDisabledC { label = "Orthography", value_ = form_data.orthography })
                            , Just (inputC { label = "Definition", toMsg = lift << InputChanged << UpdateDefinitionInput, value_ = form_data.definition, placeholder = "Definition..." })
                            , case form_data.phonetic of
                                Just p ->
                                    Just (inputC { label = "Phonetic", toMsg = lift << InputChanged << UpdatePhoneticInput, value_ = p, placeholder = "Phonetic..." })

                                Nothing ->
                                    Nothing
                            , Just (termStatusSelectC { label = "Status", toMsg = lift << InputChanged << UpdateStatusInput, selectedStatus = form_data.status })
                            , Just (textareaC { label = "Notes", toMsg = lift << InputChanged << UpdateNotesInput, value_ = form_data.notes, placeholder = "Notes...", minHeight = 80 })
                            ]
                  , buttons =
                        List.filterMap identity
                            [ if form.write_action == Create then
                                Just (buttonC { label = "Create", onPress = Just (lift (RequestEditTerm CreateTerm form.working_term args.document_id)) })

                              else
                                Nothing
                            , if form.write_action == Update then
                                Just (buttonC { label = "Update", onPress = Just (lift (RequestEditTerm UpdateTerm form.working_term args.document_id)) })

                              else
                                Nothing
                            , if form.write_action == Update then
                                Just (buttonC { label = "Delete", onPress = Just (lift (RequestEditTerm DeleteTerm form.working_term args.document_id)) })

                              else
                                Nothing
                            ]
                  }
                ]
            , buttons = []
            , status =
                [ if form.working_term /= form.orig_term then
                    Html.Styled.div [ style "color" "orange", style "margin-top" "8px" ]
                        [ Html.Styled.text "You have unsaved changes." ]

                  else
                    Html.Styled.text ""
                ]
            }


view :
    Model
    -> (Msg -> msg)
    ->
        { dict : DictContext.T
        , document_id : Maybe InfluxResourceId
        }
    -> Html msg
view model lift { dict, document_id } =
    case model.form_model of
        TermForm term_form ->
            viewTermForm term_form lift { dict = dict, document_id = document_id }

        _ ->
            Html.div [] [ Html.text "No segment selected for editing." ]
