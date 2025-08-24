module Pages.Doc.Doc_ exposing (Model, Msg, page)

import Api
import Api.GetAnnotatedDoc
import Api.TermEdit
import Api.Translate
import Bindings exposing (..)
import BindingsUtils
import Components.AnnotatedText as AnnotatedText
import Components.Common exposing (..)
import Components.CssExtra exposing (..)
import Components.DbgDisplay
import Components.DictionaryLookup as DictionaryLookup
import Components.FormElements3 as FormElements3
import Components.Layout
import Components.ListingElements
import Components.TermEditForm as TermEditForm
import Components.ToastView
import Components.TtsEmitter
import Css exposing (..)
import Datastore.DictContext as DictContext
import Datastore.DocContext as DocContext
import Datastore.FocusContext as FocusContext
import Dict
import Effect exposing (Effect)
import Html as UnstyledHtml
import Html.Extra
import Html.Styled as Html exposing (Html, a, audio, br, button, div, h1, h2, h3, li, ol, p, span, strong, text, ul)
import Html.Styled.Attributes as Attributes exposing (class, controls, css, href, id, src, style)
import Html.Styled.Events exposing (onClick)
import Http
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Shared.Msg
import Toast
import Utils
import View exposing (View)


page : Shared.Model -> Route { doc : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init { documentId = route.params.doc }
        , update = update
        , subscriptions = subscriptions
        , view = view shared route
        }


type alias ThisRoute =
    Route { doc : String }



-- INIT


type LemmaEditingMode
    = EditingInflectedToken
    | EditingLemma


type alias Model =
    { get_doc_api_res : Api.Data GetDocResponse
    , working_doc : DocContext.T
    , working_dict : DictContext.T
    , focus_ctx : FocusContext.T
    , form_model : TermEditForm.Model
    , translation_result : Maybe String
    , popup_state : Maybe { position : { x : Float, y : Float }, content : AnnotatedText.PopupContent }
    , annotation_config : AnnotatedText.AnnotationConfig
    , showFurigana : Bool
    , lemma_editing_mode : LemmaEditingMode
    , dictionaryLookup : DictionaryLookup.Model
    , sidebarWidth : Int
    }


init : { documentId : String } -> () -> ( Model, Effect Msg )
init { documentId } () =
    ( { get_doc_api_res = Api.Loading
      , working_doc = DocContext.empty
      , working_dict = DictContext.empty
      , focus_ctx = FocusContext.new
      , form_model = TermEditForm.empty
      , translation_result = Nothing
      , popup_state = Nothing
      , annotation_config = { topAnnotation = AnnotatedText.Definition, bottomAnnotation = AnnotatedText.Phonetic }
      , showFurigana = False
      , lemma_editing_mode = EditingInflectedToken
      , dictionaryLookup = DictionaryLookup.init []
      , sidebarWidth = 600
      }
    , Effect.sendCmd (Api.GetAnnotatedDoc.get { filepath = documentId } ApiResponded)
    )



-- UPDATE


type Msg
    = -- Initial load...
      ApiResponded (Result Http.Error GetDocResponse)
      -- Mouse selection...
    | SelectionMouseEvent FocusContext.Msg -- will update focus context
    | NoopMouseEvent FocusContext.Msg -- for mouse events that don't change the focus context
    | CombinedMouseEnter { x : Float, y : Float } FocusContext.Msg AnnotatedText.PopupContent -- handles both focus and popup
      -- Term editor...
    | TermEditorEvent TermEditForm.Msg
      -- Lemma editing selection...
    | SwitchToLemmaEditing
    | SwitchToInflectedTokenEditing
      -- TTS controls...
    | StartTts
    | StopTts
      -- Audio controls...
    | AudioSetPlaybackPosition { playback_position : Float }
    | AudioJumpToToken SentSegV2
      -- Translation...
    | TranslateText
    | TranslationReceived (Result Http.Error Api.Translate.TranslateResponse)
      -- Popup...
    | ShowPopup { x : Float, y : Float } AnnotatedText.PopupContent
    | HidePopup
      -- Annotation configuration...
    | SetTopAnnotation AnnotatedText.AnnotationOption
    | SetBottomAnnotation AnnotatedText.AnnotationOption
      -- Furigana toggle...
    | ToggleFurigana
      -- Sidebar width...
    | SetSidebarWidth Float
      -- Shared
    | SharedMsg Shared.Msg.Msg
      -- Dictionary
    | DictionaryLookupMsg DictionaryLookup.Msg


getLemmaFromSeg : SentSegV2 -> Maybe String
getLemmaFromSeg seg =
    seg.attributes.lemma


hasLemma : SentSegV2 -> Bool
hasLemma seg =
    case seg.attributes.lemma of
        Just lemma ->
            -- Only show lemma selection if lemma differs from the token's orthography
            case seg.inner of
                TokenSeg token ->
                    lemma /= token.orthography

                _ ->
                    True

        Nothing ->
            False


createLemmaSegment : SentSegV2 -> String -> SentSegV2
createLemmaSegment originalSeg lemmaText =
    case originalSeg.inner of
        -- TODO might want to ship more lemma data over from server
        TokenSeg token ->
            { originalSeg
                | text = lemmaText
                , inner = TokenSeg { token | orthography = lemmaText }
            }

        _ ->
            originalSeg


getCurrentEditingSeg : Model -> Maybe SentSegV2
getCurrentEditingSeg model =
    case ( model.focus_ctx.segment_selection, model.lemma_editing_mode ) of
        ( Just seg, EditingLemma ) ->
            case getLemmaFromSeg seg of
                Just lemma ->
                    Just (createLemmaSegment seg lemma)

                Nothing ->
                    Just seg

        ( Just seg, EditingInflectedToken ) ->
            Just seg

        _ ->
            Nothing


updateFormBasedOnSelection : DictContext.T -> Model -> ( TermEditForm.Model, Effect TermEditForm.Msg )
updateFormBasedOnSelection dict_ctx model =
    let
        currentSeg =
            getCurrentEditingSeg model

        segSlice =
            case model.lemma_editing_mode of
                EditingInflectedToken ->
                    model.focus_ctx.segment_slice

                EditingLemma ->
                    Nothing

        -- Don't allow phrase selection when editing lemma
    in
    TermEditForm.update dict_ctx (TermEditForm.EditingSegUpdated segSlice currentSeg) model.form_model


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg sharedMsg ->
            ( model, Effect.sendSharedMsg sharedMsg )

        DictionaryLookupMsg dictionaryMsg ->
            let
                ( newDictionaryModel, effect ) =
                    DictionaryLookup.update dictionaryMsg model.dictionaryLookup
            in
            ( { model | dictionaryLookup = newDictionaryModel }
            , Effect.map DictionaryLookupMsg effect
            )

        ApiResponded (Ok res) ->
            ( { model
                | get_doc_api_res = Api.Success res
                , working_doc = DocContext.fromAnnotatedDocument res.docPackage.languageId res.annotatedDoc
                , working_dict = DictContext.fromTermDictionary res.docPackage.languageId res.termDict
                , dictionaryLookup = DictionaryLookup.init res.docPackage.language.dicts
              }
            , Effect.adjustAnnotationWidths
            )

        ApiResponded (Err httpError) ->
            ( { model | get_doc_api_res = Api.Failure httpError }, Effect.none )

        SelectionMouseEvent m ->
            let
                focus_ctx =
                    FocusContext.update model.working_doc m model.focus_ctx

                ( form_model, _ ) =
                    updateFormBasedOnSelection model.working_dict { model | focus_ctx = focus_ctx }

                -- Auto-populate dictionary query with selected text
                ( newDictionaryModel, dictEffect ) =
                    case focus_ctx.selected_text of
                        Just selectedText ->
                            if not (String.isEmpty (String.trim selectedText)) then
                                DictionaryLookup.update (DictionaryLookup.QueryChanged selectedText) model.dictionaryLookup

                            else
                                ( model.dictionaryLookup, Effect.none )

                        Nothing ->
                            ( model.dictionaryLookup, Effect.none )
            in
            ( { model
                | focus_ctx = focus_ctx
                , form_model = form_model
                , lemma_editing_mode = EditingInflectedToken -- Reset to inflected when new selection
                , dictionaryLookup = newDictionaryModel
              }
            , Effect.map DictionaryLookupMsg dictEffect
            )

        SwitchToLemmaEditing ->
            let
                ( form_model, _ ) =
                    updateFormBasedOnSelection model.working_dict { model | lemma_editing_mode = EditingLemma }
            in
            ( { model
                | lemma_editing_mode = EditingLemma
                , form_model = form_model
              }
            , Effect.none
            )

        SwitchToInflectedTokenEditing ->
            let
                ( form_model, _ ) =
                    updateFormBasedOnSelection model.working_dict { model | lemma_editing_mode = EditingInflectedToken }
            in
            ( { model
                | lemma_editing_mode = EditingInflectedToken
                , form_model = form_model
              }
            , Effect.none
            )

        TermEditorEvent formMsg ->
            case formMsg of
                TermEditForm.RequestEditTerm action term document_id ->
                    ( model
                    , Effect.sendCmd (Api.TermEdit.edit { requestedAction = action, term = term, documentId = document_id } (TermEditorEvent << TermEditForm.GotTermEditResponse))
                    )

                TermEditForm.GotUpdatedAnnotatedDoc updated_doc ->
                    ( { model | working_doc = DocContext.fromAnnotatedDocument model.working_doc.lang_id updated_doc }
                    , Effect.adjustAnnotationWidths
                    )

                TermEditForm.OverwriteTerm term ->
                    ( { model | working_dict = DictContext.overwriteTerm model.working_dict term }
                    , Effect.none
                    )

                TermEditForm.AddToast message ->
                    ( model
                    , Effect.sendSharedMsg (Shared.Msg.AddToast message)
                    )

                _ ->
                    let
                        ( form_model, child_fx ) =
                            TermEditForm.update model.working_dict formMsg model.form_model
                    in
                    ( { model | form_model = form_model }
                    , Effect.map TermEditorEvent child_fx
                    )

        NoopMouseEvent _ ->
            ( model, Effect.none )

        CombinedMouseEnter position focusMsg popupContent ->
            let
                focus_ctx =
                    FocusContext.update model.working_doc focusMsg model.focus_ctx

                ( form_model, _ ) =
                    updateFormBasedOnSelection model.working_dict { model | focus_ctx = focus_ctx }

                -- Auto-populate dictionary query with selected text
                ( newDictionaryModel, dictEffect ) =
                    case focus_ctx.selected_text of
                        Just selectedText ->
                            if not (String.isEmpty (String.trim selectedText)) then
                                DictionaryLookup.update (DictionaryLookup.QueryChanged selectedText) model.dictionaryLookup

                            else
                                ( model.dictionaryLookup, Effect.none )

                        Nothing ->
                            ( model.dictionaryLookup, Effect.none )
            in
            ( { model
                | focus_ctx = focus_ctx
                , form_model = form_model
                , popup_state = Just { position = position, content = popupContent }
                , lemma_editing_mode = EditingInflectedToken -- Reset to inflected when new selection
                , dictionaryLookup = newDictionaryModel
              }
            , Effect.map DictionaryLookupMsg dictEffect
            )

        StartTts ->
            case model.get_doc_api_res of
                Api.Success response ->
                    let
                        selectedText =
                            Maybe.withDefault "" model.focus_ctx.selected_text

                        language =
                            response.docPackage.language
                    in
                    if String.isEmpty (String.trim selectedText) then
                        ( model, Effect.none )

                    else
                        ( model
                        , Effect.ttsCancelAndSpeak
                            { text = selectedText
                            , voice = language.ttsVoice
                            , rate = language.ttsRate
                            , pitch = language.ttsPitch
                            }
                        )

                _ ->
                    ( model, Effect.none )

        StopTts ->
            ( model, Effect.ttsCancel )

        AudioSetPlaybackPosition { playback_position } ->
            ( model, Effect.audioSetPlaybackPosition { playback_position = playback_position } )

        AudioJumpToToken seg ->
            case model.get_doc_api_res of
                Api.Success response ->
                    let
                        totalTextLength =
                            String.length response.annotatedDoc.text

                        tokenStartChar =
                            seg.startChar

                        playbackRatio =
                            if totalTextLength > 0 then
                                toFloat tokenStartChar / toFloat totalTextLength

                            else
                                0.0
                    in
                    ( model, Effect.audioSetPlaybackPosition { playback_position = playbackRatio } )

                _ ->
                    ( model, Effect.none )

        TranslateText ->
            case model.get_doc_api_res of
                Api.Success response ->
                    let
                        selectedText =
                            Maybe.withDefault "" model.focus_ctx.selected_text

                        language =
                            response.docPackage.language
                    in
                    case ( language.deeplSourceLang, language.deeplTargetLang ) of
                        ( Just sourceLang, Just targetLang ) ->
                            if String.isEmpty (String.trim selectedText) then
                                ( model, Effect.none )

                            else
                                ( model
                                , Effect.sendCmd
                                    (Api.Translate.translate
                                        { fromLangId = sourceLang
                                        , toLangId = targetLang
                                        , sourceSequence = selectedText
                                        , provider = "deepl"
                                        }
                                        TranslationReceived
                                    )
                                )

                        _ ->
                            ( { model | translation_result = Just "DeepL source and target languages not configured for this language" }
                            , Effect.none
                            )

                _ ->
                    ( model, Effect.none )

        TranslationReceived (Ok response) ->
            ( { model | translation_result = Just response.translatedText }
            , Effect.none
            )

        TranslationReceived (Err httpError) ->
            ( { model | translation_result = Just ("Translation error: " ++ Api.stringOfHttpErrMsg httpError) }
            , Effect.none
            )

        ShowPopup position content ->
            ( { model | popup_state = Just { position = position, content = content } }
            , Effect.none
            )

        HidePopup ->
            ( { model | popup_state = Nothing }
            , Effect.none
            )

        SetTopAnnotation option ->
            ( { model | annotation_config = { topAnnotation = option, bottomAnnotation = model.annotation_config.bottomAnnotation } }
            , Effect.none
            )

        SetBottomAnnotation option ->
            ( { model | annotation_config = { topAnnotation = model.annotation_config.topAnnotation, bottomAnnotation = option } }
            , Effect.none
            )

        ToggleFurigana ->
            ( { model | showFurigana = not model.showFurigana }
            , Effect.none
            )

        SetSidebarWidth width ->
            ( { model | sidebarWidth = Basics.round (max 200 (min 1200 width)) }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


viewDocumentInfo : GetDocResponse -> Html msg
viewDocumentInfo response =
    let
        document =
            response.docPackage.document

        language =
            response.docPackage.language

        documentId =
            BindingsUtils.influxResourceIdToString response.docPackage.documentId

        languageId =
            case language.id of
                Just langId ->
                    BindingsUtils.influxResourceIdToString langId

                Nothing ->
                    "unknown"
    in
    div []
        [ h2 [] [ text document.title ]
        , p []
            [ text "Language: "
            , text language.name
            ]
        , p []
            [ text "Type: "
            , text document.docType
            ]
        , p []
            [ text "Tags: "
            , text (String.join ", " document.tags)
            ]
        , p []
            [ text "Created: "
            , text (String.left 10 document.createdTs)
            , text " | Updated: "
            , text (String.left 10 document.updatedTs)
            ]
        , p []
            [ a [ href ("/doc/edit?docId=" ++ documentId) ] [ text "Edit Document" ]
            , text " | "
            , a [ href ("/lang/edit?langId=" ++ languageId) ] [ text "Edit Language" ]
            ]
        ]


viewSegExtraInfo : DictContext.T -> SentSegV2 -> Html msg
viewSegExtraInfo dict seg =
    let
        orthography =
            case seg.inner of
                TokenSeg token ->
                    token.orthography

                PhraseSeg phrase ->
                    phrase.normalisedOrthography

                WhitespaceSeg ->
                    ""

                PunctuationSeg ->
                    ""

        token_info =
            case DictContext.lookupToken dict orthography of
                Just token ->
                    [ text ("token: " ++ token.orthography ++ " -> " ++ token.definition) ]

                Nothing ->
                    [ text "no token info" ]

        phrase_info =
            case DictContext.lookupPhrase dict orthography of
                Just phrase ->
                    [ text ("phrase: " ++ String.join " " phrase.orthographySeq ++ " -> " ++ phrase.definition) ]

                Nothing ->
                    [ text "no phrase info" ]
    in
    div []
        (token_info ++ phrase_info)


annotationOptionToString : AnnotatedText.AnnotationOption -> String
annotationOptionToString option =
    case option of
        AnnotatedText.None ->
            "None"

        AnnotatedText.Phonetic ->
            "Phonetic"

        AnnotatedText.Definition ->
            "Definition"

        AnnotatedText.Lemma ->
            "Lemma"

        AnnotatedText.Upos ->
            "Part of Speech (UPOS)"

        AnnotatedText.Xpos ->
            "Language-specific POS (XPOS)"


annotationOptionFromString : String -> AnnotatedText.AnnotationOption
annotationOptionFromString str =
    case str of
        "None" ->
            AnnotatedText.None

        "Phonetic" ->
            AnnotatedText.Phonetic

        "Definition" ->
            AnnotatedText.Definition

        "Lemma" ->
            AnnotatedText.Lemma

        "Part of Speech (UPOS)" ->
            AnnotatedText.Upos

        "Language-specific POS (XPOS)" ->
            AnnotatedText.Xpos

        _ ->
            AnnotatedText.None


annotationSelectOptions : List FormElements3.SelectCOption
annotationSelectOptions =
    [ AnnotatedText.None
    , AnnotatedText.Phonetic
    , AnnotatedText.Definition
    , AnnotatedText.Lemma
    , AnnotatedText.Upos
    , AnnotatedText.Xpos
    ]
        |> List.map (\option -> { value = annotationOptionToString option, label = annotationOptionToString option })


viewAnnotationControls : AnnotatedText.AnnotationConfig -> Bool -> Int -> Html Msg
viewAnnotationControls config showFurigana sidebarWidth =
    FormElements3.formC
        { sections =
            [ { title = Just "Annotation Display Settings"
              , rows =
                    [ FormElements3.selectC
                        { label = "Top annotation"
                        , toMsg = \value -> SetTopAnnotation (annotationOptionFromString value)
                        , options = annotationSelectOptions
                        , value_ = Just (annotationOptionToString config.topAnnotation)
                        , placeholder = "Select annotation"
                        , compact = True
                        }
                    , FormElements3.selectC
                        { label = "Bottom annotation"
                        , toMsg = \value -> SetBottomAnnotation (annotationOptionFromString value)
                        , options = annotationSelectOptions
                        , value_ = Just (annotationOptionToString config.bottomAnnotation)
                        , placeholder = "Select annotation"
                        , compact = True
                        }
                    , FormElements3.checkboxC
                        { label = "Furigana"
                        , toMsg = ToggleFurigana
                        , checked = showFurigana
                        , compact = True
                        }
                    ]
              , buttons = []
              }
            , { title = Just "Layout Settings"
              , rows =
                    [ FormElements3.numberInputC
                        { label = "Sidebar Width (px)"
                        , toMsg = SetSidebarWidth
                        , value_ = toFloat sidebarWidth
                        , placeholder = "600"
                        , compact = True
                        , min = 200
                        , max = 1200
                        , step = 10
                        }
                    ]
              , buttons = []
              }
            ]
        , buttons = []
        , status = []
        , compact = True
        }


viewLemmaDisplay :
    SentSegV2
    -> LemmaEditingMode
    -> DictContext.T
    -> AnnotatedText.AnnotationConfig
    -> Bool
    -> Html Msg
viewLemmaDisplay seg editingMode dict annotation_config showFurigana =
    case getLemmaFromSeg seg of
        Nothing ->
            text ""

        Just lemma ->
            let
                lemmaSegment =
                    createLemmaSegment seg lemma

                inflectedSegment =
                    seg

                -- Use NoopMouseEvent to avoid affecting focus context
                lemmaViewCtx =
                    { dict = dict
                    , modifier_state = { alt = False, ctrl = False, shift = False, meta = False }
                    , mouse_handler = NoopMouseEvent
                    , focus_predicate = \_ -> editingMode == EditingLemma
                    , seg_display_predicate = \_ -> True
                    , doc_seg_display_predicate = \_ -> True
                    , popup_state = Nothing
                    , on_hover_start = \_ _ -> HidePopup
                    , on_hover_end = HidePopup
                    , on_mouse_enter_with_position = \_ _ _ _ -> HidePopup
                    , on_token_double_click = \_ -> HidePopup
                    , annotation_config = annotation_config
                    , showFurigana = showFurigana
                    }

                inflectedViewCtx =
                    { lemmaViewCtx
                        | focus_predicate = \_ -> editingMode == EditingInflectedToken
                    }

                lemmaView =
                    Maybe.withDefault (text lemma) (AnnotatedText.viewSentenceSegment lemmaViewCtx lemmaSegment)

                inflectedView =
                    Maybe.withDefault (text seg.text) (AnnotatedText.viewSentenceSegment inflectedViewCtx inflectedSegment)
            in
            div []
                [ span []
                    [ text "inflection: " ]
                , span
                    [ style "cursor" "pointer"
                    , onClick SwitchToLemmaEditing
                    ]
                    [ lemmaView ]
                , span []
                    [ text " → " ]
                , span
                    [ style "cursor" "pointer"
                    , onClick SwitchToInflectedTokenEditing
                    ]
                    [ inflectedView ]
                ]


viewTermDetails : DictContext.T -> Maybe SentSegV2 -> Html msg
viewTermDetails dict maybeSeg =
    case maybeSeg of
        Nothing ->
            text ""

        Just seg ->
            let
                orthography =
                    case seg.inner of
                        TokenSeg token ->
                            token.orthography

                        PhraseSeg phrase ->
                            phrase.normalisedOrthography

                        WhitespaceSeg ->
                            ""

                        PunctuationSeg ->
                            ""

                maybeToken =
                    if String.isEmpty orthography then
                        Nothing

                    else
                        DictContext.lookupToken dict orthography

                maybePhrase =
                    if String.isEmpty orthography then
                        Nothing

                    else
                        DictContext.lookupPhrase dict orthography

                termInfo =
                    case ( maybeToken, maybePhrase ) of
                        ( Just token, _ ) ->
                            [ li [] [ text ("Orthography: " ++ token.orthography) ]
                            , li [] [ text ("Definition: " ++ token.definition) ]
                            , li [] [ text ("Phonetic: " ++ token.phonetic) ]
                            , li [] [ text ("Notes: " ++ token.notes) ]
                            , li [] [ text ("Original Context: " ++ token.originalContext) ]
                            , li [] [ text ("Status: " ++ tokenStatusToString token.status) ]
                            ]

                        ( Nothing, Just phrase ) ->
                            [ li [] [ text ("Phrase: " ++ String.join " " phrase.orthographySeq) ]
                            , li [] [ text ("Definition: " ++ phrase.definition) ]
                            , li [] [ text ("Notes: " ++ phrase.notes) ]
                            , li [] [ text ("Original Context: " ++ phrase.originalContext) ]
                            , li [] [ text ("Status: " ++ tokenStatusToString phrase.status) ]
                            ]

                        ( Nothing, Nothing ) ->
                            [ li [] [ text "No term information available" ] ]

                segAttributeInfo =
                    [ li [] [ text ("Text: " ++ seg.text) ]
                    , li [] [ text ("Sentence Index: " ++ String.fromInt seg.sentenceIdx) ]
                    , li [] [ text ("Start Char: " ++ String.fromInt seg.startChar) ]
                    , li [] [ text ("End Char: " ++ String.fromInt seg.endChar) ]
                    , case seg.attributes.lemma of
                        Just lemma ->
                            li [] [ text ("Lemma: " ++ lemma) ]

                        Nothing ->
                            li [] [ text "Lemma: (none)" ]
                    , case seg.attributes.upos of
                        Just upos ->
                            li [] [ text ("UPOS: " ++ upos) ]

                        Nothing ->
                            li [] [ text "UPOS: (none)" ]
                    , case seg.attributes.xpos of
                        Just xpos ->
                            li [] [ text ("XPOS: " ++ xpos) ]

                        Nothing ->
                            li [] [ text "XPOS: (none)" ]
                    , case seg.attributes.dependency of
                        Just ( parentIdx, relation ) ->
                            li [] [ text ("Dependency: " ++ String.fromInt parentIdx ++ " (" ++ relation ++ ")") ]

                        Nothing ->
                            li [] [ text "Dependency: (none)" ]
                    , case seg.attributes.conjugationChain of
                        Just conjugationSteps ->
                            li []
                                [ text "Conjugation Chain: "
                                , ol []
                                    (List.map
                                        (\step ->
                                            li []
                                                [ text
                                                    ("Step "
                                                        ++ String.fromInt step.step
                                                        ++ ": "
                                                        ++ step.form
                                                        ++ " → "
                                                        ++ step.result
                                                    )
                                                ]
                                        )
                                        conjugationSteps
                                    )
                                ]

                        Nothing ->
                            li [] [ text "Conjugation Chain: (none)" ]
                    , li []
                        [ text "Misc: "
                        , if Dict.isEmpty seg.attributes.misc then
                            text "(none)"

                          else
                            ul []
                                (Dict.toList seg.attributes.misc
                                    |> List.map (\( key, value ) -> li [] [ text (key ++ ": " ++ value) ])
                                )
                        ]
                    ]
            in
            div []
                [ h3 [] [ text "Selected Term Details" ]
                , ul []
                    (termInfo ++ segAttributeInfo)
                ]


tokenStatusToString : TokenStatus -> String
tokenStatusToString status =
    case status of
        Unmarked ->
            "Unmarked"

        Ignored ->
            "Ignored"

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
            "Known"



-- end


view : Shared.Model -> ThisRoute -> Model -> View Msg
view shared route model =
    let
        annotatedDocViewCtx =
            { dict = model.working_dict
            , modifier_state = shared.modifier_state
            , mouse_handler = SelectionMouseEvent
            , focus_predicate =
                case model.focus_ctx.slice_selection of
                    Nothing ->
                        \_ -> False

                    Just slice ->
                        FocusContext.isSentSegInSlice slice
            , seg_display_predicate = \_ -> True
            , doc_seg_display_predicate = \_ -> True
            , popup_state = model.popup_state
            , on_hover_start = ShowPopup
            , on_hover_end = HidePopup
            , on_mouse_enter_with_position =
                \x y focusMsg popupContent ->
                    CombinedMouseEnter { x = x, y = y } focusMsg popupContent
            , on_token_double_click = AudioJumpToToken
            , annotation_config = model.annotation_config
            , showFurigana = model.showFurigana
            }

        documentCard =
            case model.get_doc_api_res of
                Api.NotAsked ->
                    Components.ListingElements.listingCardC
                        [ h1 [] [ text ("Document ID: " ++ Utils.unwrappedPercentDecode route.params.doc) ]
                        , text "Not loaded"
                        ]

                Api.Loading ->
                    Components.ListingElements.listingCardC
                        [ h1 [] [ text ("Document ID: " ++ Utils.unwrappedPercentDecode route.params.doc) ]
                        , text "Loading..."
                        ]

                Api.Failure err ->
                    Components.ListingElements.listingCardC
                        [ h1 [] [ text ("Document ID: " ++ Utils.unwrappedPercentDecode route.params.doc) ]
                        , text ("Error: " ++ Api.stringOfHttpErrMsg err)
                        ]

                Api.Success response ->
                    Components.ListingElements.listingCardC
                        [ viewDocumentInfo response
                        , div
                            [ class "annotated-doc-div"
                            , class "dbg-off"
                            ]
                            (AnnotatedText.view
                                annotatedDocViewCtx
                                model.working_doc
                            )
                        ]

        termEditorCard =
            Components.ListingElements.listingCardC
                [ h3 [] [ text "Term Editor" ]
                , TermEditForm.view model.form_model
                    TermEditorEvent
                    { dict = model.working_dict
                    , document_id =
                        case String.toInt route.params.doc of
                            Just id ->
                                Just (Bindings.SerialId id)

                            Nothing ->
                                Nothing
                    }
                ]

        termDetailsCard =
            Components.ListingElements.listingCardC
                [ h3 [] [ text "Term Details" ]
                , viewTermDetails model.working_dict model.focus_ctx.segment_selection
                , case model.focus_ctx.segment_selection of
                    Just seg ->
                        if hasLemma seg then
                            viewLemmaDisplay seg model.lemma_editing_mode model.working_dict model.annotation_config model.showFurigana

                        else
                            text ""

                    Nothing ->
                        text ""
                ]

        annotationControlsCard =
            Components.ListingElements.listingCardC
                [ h3 [] [ text "Annotation Controls" ]
                , viewAnnotationControls model.annotation_config model.showFurigana model.sidebarWidth
                ]

        selectedTextCard =
            let
                selectedText =
                    Maybe.withDefault "" model.focus_ctx.selected_text

                isEmpty =
                    String.isEmpty (String.trim selectedText)
            in
            case model.get_doc_api_res of
                Api.Success response ->
                    Components.ListingElements.listingCardC
                        [ h3 [] [ text "Selected Text" ]
                        , p [] [ text ("\"" ++ selectedText ++ "\"") ]
                        , div [ css [ displayFlex, gap space8px, flexWrap wrap ] ]
                            [ FormElements3.buttonC
                                { label = "Translate"
                                , onPress =
                                    if isEmpty then
                                        Nothing

                                    else
                                        Just TranslateText
                                , compact = True
                                }
                            , FormElements3.buttonC
                                { label = "TTS"
                                , onPress =
                                    if isEmpty then
                                        Nothing

                                    else
                                        Just StartTts
                                , compact = True
                                }
                            ]
                        , case model.translation_result of
                            Just translation ->
                                div [ style "margin-top" "10px", style "padding" "10px", style "background-color" "#f0f0f0" ]
                                    [ strong [] [ text "Translation: " ]
                                    , br [] []
                                    , text translation
                                    ]

                            Nothing ->
                                text ""
                        , Html.fromUnstyled <| UnstyledHtml.map DictionaryLookupMsg (DictionaryLookup.view model.dictionaryLookup)
                        ]

                _ ->
                    Components.ListingElements.listingCardC
                        [ h3 [] [ text "Selected Text" ]
                        , text ""
                        ]

        audioCard =
            Components.ListingElements.listingCardC
                [ h3 [] [ text "Audio" ]
                , audio [ id "influx-audio-player", src "http://localhost:3000/influx_app_data/test.mp3", Attributes.controls True ]
                    []
                ]

        toastTray =
            div [ class "toast-tray" ] [ Html.fromUnstyled (Toast.render Components.ToastView.viewToast shared.toast_tray (Toast.config (SharedMsg << Shared.Msg.ToastMsg))) ]

        leftSidebar =
            div
                [ css
                    [ width (px 300) -- Fixed sidebar width
                    , height (vh 100)
                    , overflowY auto
                    , paddingRight (px 16)
                    , paddingLeft (px 16)
                    , position fixed
                    , left (px 48) -- Account for ribbon width
                    , top zero
                    , backgroundColor (hex "#FEFEFE")
                    , borderRight3 (px 1) solid (hex "#E9E9E7")
                    ]
                ]
                [ termDetailsCard
                , annotationControlsCard
                ]

        centerColumn =
            div
                [ css
                    [ width (px 800) -- Fixed center width
                    , marginLeft (px 348) -- ribbon(48) + sidebar(300)
                    , marginRight (px 316) -- sidebar(300) + padding(16)
                    , minHeight (vh 100)
                    , padding2 space0px space16px
                    ]
                ]
                [ documentCard ]

        rightSidebar =
            div
                [ css
                    [ width (px 300) -- Fixed sidebar width
                    , height (vh 100)
                    , overflowY auto
                    , paddingLeft (px 16)
                    , paddingRight (px 16)
                    , position fixed
                    , right zero
                    , top zero
                    , backgroundColor (hex "#FEFEFE")
                    , borderLeft3 (px 1) solid (hex "#E9E9E7")
                    ]
                ]
                [ termEditorCard
                , selectedTextCard
                , audioCard
                ]
    in
    { title = "Document view"
    , body =
        [ Components.Layout.ribbonDocumentLayoutC { toastTray = Just toastTray }
            leftSidebar
            centerColumn
            rightSidebar
        ]
    }
