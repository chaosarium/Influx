module Pages.Doc.Doc_ exposing (Model, Msg, page)

import Api
import Api.GetAnnotatedDoc
import Api.TermEdit
import Api.Translate
import Bindings exposing (..)
import BindingsUtils
import Browser.Events
import Components.AnnotatedText as AnnotatedText
import Components.CollapsibleSection
import Components.DbgDisplay
import Components.ResizableSidebar
import Components.TermEditForm as TermEditForm
import Components.Topbar
import Components.TtsEmitter
import Datastore.DictContext as DictContext
import Datastore.DocContext as DocContext
import Datastore.FocusContext as FocusContext
import Dict
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class, draggable, href, style)
import Html.Events
import Html.Extra
import Http
import Json.Decode as Decode
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Shared.Msg
import Toast
import Utils
import Utils.ModifierState as ModifierState
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
    , rightPanelWidth : Float
    , sectionStates : SectionStates
    , isResizing : Bool
    , resizeStartX : Float
    , resizeStartWidth : Float
    , sidebarCollapsed : Bool
    }


type alias SectionStates =
    { termEditor : Bool
    , termDetails : Bool
    , annotationControls : Bool
    , translation : Bool
    , tts : Bool
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
      , rightPanelWidth = 400
      , sectionStates =
            { termEditor = True
            , termDetails = True
            , annotationControls = False
            , translation = False
            , tts = False
            }
      , isResizing = False
      , resizeStartX = 0
      , resizeStartWidth = 0
      , sidebarCollapsed = False
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
      -- Panel management...
    | StartResize Float
    | StopResize
    | ResizeMove Float
    | ToggleSidebar
    | ToggleSection String
      -- Shared
    | SharedMsg Shared.Msg.Msg


updateSectionStates : String -> SectionStates -> SectionStates
updateSectionStates sectionName sectionStates =
    case sectionName of
        "termEditor" ->
            { sectionStates | termEditor = not sectionStates.termEditor }

        "termDetails" ->
            { sectionStates | termDetails = not sectionStates.termDetails }

        "annotationControls" ->
            { sectionStates | annotationControls = not sectionStates.annotationControls }

        "translation" ->
            { sectionStates | translation = not sectionStates.translation }

        "tts" ->
            { sectionStates | tts = not sectionStates.tts }

        _ ->
            sectionStates


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

        ApiResponded (Ok res) ->
            ( { model
                | get_doc_api_res = Api.Success res
                , working_doc = DocContext.fromAnnotatedDocument res.docPackage.languageId res.annotatedDoc
                , working_dict = DictContext.fromTermDictionary res.docPackage.languageId res.termDict
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
            in
            ( { model
                | focus_ctx = focus_ctx
                , form_model = form_model
                , lemma_editing_mode = EditingInflectedToken -- Reset to inflected when new selection
              }
            , Effect.none
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
            in
            ( { model
                | focus_ctx = focus_ctx
                , form_model = form_model
                , popup_state = Just { position = position, content = popupContent }
                , lemma_editing_mode = EditingInflectedToken -- Reset to inflected when new selection
              }
            , Effect.none
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

        StartResize startX ->
            ( { model
                | isResizing = True
                , resizeStartX = startX
                , resizeStartWidth = model.rightPanelWidth
              }
            , Effect.none
            )

        StopResize ->
            ( { model | isResizing = False }
            , Effect.none
            )

        ResizeMove clientX ->
            if model.isResizing then
                let
                    -- Calculate how much the mouse has moved to the left (negative) or right (positive)
                    deltaX =
                        model.resizeStartX - clientX

                    -- Moving left (positive deltaX) should increase panel width
                    -- Moving right (negative deltaX) should decrease panel width
                    newWidth =
                        max 200 (min 800 (model.resizeStartWidth + deltaX))
                in
                ( { model | rightPanelWidth = newWidth }
                , Effect.none
                )

            else
                ( model, Effect.none )

        ToggleSidebar ->
            ( { model | sidebarCollapsed = not model.sidebarCollapsed }
            , Effect.none
            )

        ToggleSection sectionName ->
            ( { model | sectionStates = updateSectionStates sectionName model.sectionStates }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.isResizing then
        Sub.batch
            [ Browser.Events.onMouseMove (Decode.map ResizeMove (Decode.field "clientX" Decode.float))
            , Browser.Events.onMouseUp (Decode.succeed StopResize)
            ]

    else
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
            [ a [ href ("/doc/edit/" ++ documentId) ] [ text "Edit Document" ]
            , text " | "
            , a [ href ("/lang/edit/" ++ languageId) ] [ text "Edit Language" ]
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
                    [ Html.text ("token: " ++ token.orthography ++ " -> " ++ token.definition) ]

                Nothing ->
                    [ Html.text "no token info" ]

        phrase_info =
            case DictContext.lookupPhrase dict orthography of
                Just phrase ->
                    [ Html.text ("phrase: " ++ String.join " " phrase.orthographySeq ++ " -> " ++ phrase.definition) ]

                Nothing ->
                    [ Html.text "no phrase info" ]
    in
    Html.div []
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


viewAnnotationSelector : String -> AnnotatedText.AnnotationOption -> (AnnotatedText.AnnotationOption -> Msg) -> Html Msg
viewAnnotationSelector label currentOption onSelect =
    let
        options =
            [ AnnotatedText.None
            , AnnotatedText.Definition
            , AnnotatedText.Phonetic
            , AnnotatedText.Lemma
            , AnnotatedText.Upos
            , AnnotatedText.Xpos
            ]

        optionView option =
            Html.option
                [ Html.Attributes.value (annotationOptionToString option)
                , Html.Attributes.selected (option == currentOption)
                ]
                [ Html.text (annotationOptionToString option) ]
    in
    div []
        [ Html.label [] [ Html.text (label ++ ": ") ]
        , Html.select
            [ Html.Events.on "change"
                (Decode.map
                    (\value ->
                        case value of
                            "None" ->
                                onSelect AnnotatedText.None

                            "Phonetic" ->
                                onSelect AnnotatedText.Phonetic

                            "Definition" ->
                                onSelect AnnotatedText.Definition

                            "Lemma" ->
                                onSelect AnnotatedText.Lemma

                            "Part of Speech (UPOS)" ->
                                onSelect AnnotatedText.Upos

                            "Language-specific POS (XPOS)" ->
                                onSelect AnnotatedText.Xpos

                            _ ->
                                onSelect AnnotatedText.None
                    )
                    (Decode.at [ "target", "value" ] Decode.string)
                )
            ]
            (List.map optionView options)
        ]


viewAnnotationControls : AnnotatedText.AnnotationConfig -> Bool -> Html Msg
viewAnnotationControls config showFurigana =
    div []
        [ h3 [] [ Html.text "Annotation Display Settings" ]
        , p [] [ Html.text "Choose what to display above and below the text:" ]
        , div []
            [ viewAnnotationSelector "Top annotation" config.topAnnotation SetTopAnnotation
            , viewAnnotationSelector "Bottom annotation" config.bottomAnnotation SetBottomAnnotation
            ]
        , div [ style "margin-top" "10px" ]
            [ Html.label []
                [ Html.input
                    [ Html.Attributes.type_ "checkbox"
                    , Html.Attributes.checked showFurigana
                    , Html.Events.onClick ToggleFurigana
                    , style "margin-right" "5px"
                    ]
                    []
                , Html.text "Show furigana (Japanese reading annotations)"
                ]
            ]
        ]


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
            Html.text ""

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
                    Maybe.withDefault (Html.text lemma) (AnnotatedText.viewSentenceSegment lemmaViewCtx lemmaSegment)

                inflectedView =
                    Maybe.withDefault (Html.text seg.text) (AnnotatedText.viewSentenceSegment inflectedViewCtx inflectedSegment)
            in
            Html.div []
                [ Html.span []
                    [ Html.text "inflection: " ]
                , Html.span
                    [ Html.Attributes.style "cursor" "pointer"
                    , Html.Events.onClick SwitchToLemmaEditing
                    ]
                    [ lemmaView ]
                , Html.span []
                    [ Html.text " → " ]
                , Html.span
                    [ Html.Attributes.style "cursor" "pointer"
                    , Html.Events.onClick SwitchToInflectedTokenEditing
                    ]
                    [ inflectedView ]
                ]


viewTermDetails : DictContext.T -> Maybe SentSegV2 -> Html msg
viewTermDetails dict maybeSeg =
    case maybeSeg of
        Nothing ->
            Html.text ""

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
                            [ li [] [ Html.text ("Orthography: " ++ token.orthography) ]
                            , li [] [ Html.text ("Definition: " ++ token.definition) ]
                            , li [] [ Html.text ("Phonetic: " ++ token.phonetic) ]
                            , li [] [ Html.text ("Notes: " ++ token.notes) ]
                            , li [] [ Html.text ("Original Context: " ++ token.originalContext) ]
                            , li [] [ Html.text ("Status: " ++ tokenStatusToString token.status) ]
                            ]

                        ( Nothing, Just phrase ) ->
                            [ li [] [ Html.text ("Phrase: " ++ String.join " " phrase.orthographySeq) ]
                            , li [] [ Html.text ("Definition: " ++ phrase.definition) ]
                            , li [] [ Html.text ("Notes: " ++ phrase.notes) ]
                            , li [] [ Html.text ("Original Context: " ++ phrase.originalContext) ]
                            , li [] [ Html.text ("Status: " ++ tokenStatusToString phrase.status) ]
                            ]

                        ( Nothing, Nothing ) ->
                            [ li [] [ Html.text "No term information available" ] ]

                segAttributeInfo =
                    [ li [] [ Html.text ("Text: " ++ seg.text) ]
                    , li [] [ Html.text ("Sentence Index: " ++ String.fromInt seg.sentenceIdx) ]
                    , li [] [ Html.text ("Start Char: " ++ String.fromInt seg.startChar) ]
                    , li [] [ Html.text ("End Char: " ++ String.fromInt seg.endChar) ]
                    , case seg.attributes.lemma of
                        Just lemma ->
                            li [] [ Html.text ("Lemma: " ++ lemma) ]

                        Nothing ->
                            li [] [ Html.text "Lemma: (none)" ]
                    , case seg.attributes.upos of
                        Just upos ->
                            li [] [ Html.text ("UPOS: " ++ upos) ]

                        Nothing ->
                            li [] [ Html.text "UPOS: (none)" ]
                    , case seg.attributes.xpos of
                        Just xpos ->
                            li [] [ Html.text ("XPOS: " ++ xpos) ]

                        Nothing ->
                            li [] [ Html.text "XPOS: (none)" ]
                    , case seg.attributes.dependency of
                        Just ( parentIdx, relation ) ->
                            li [] [ Html.text ("Dependency: " ++ String.fromInt parentIdx ++ " (" ++ relation ++ ")") ]

                        Nothing ->
                            li [] [ Html.text "Dependency: (none)" ]
                    , case seg.attributes.conjugationChain of
                        Just conjugationSteps ->
                            li []
                                [ Html.text "Conjugation Chain: "
                                , ol []
                                    (List.map
                                        (\step ->
                                            li []
                                                [ Html.text
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
                            li [] [ Html.text "Conjugation Chain: (none)" ]
                    , li []
                        [ Html.text "Misc: "
                        , if Dict.isEmpty seg.attributes.misc then
                            Html.text "(none)"

                          else
                            ul []
                                (Dict.toList seg.attributes.misc
                                    |> List.map (\( key, value ) -> li [] [ Html.text (key ++ ": " ++ value) ])
                                )
                        ]
                    ]
            in
            div []
                [ h3 [] [ Html.text "Selected Term Details" ]
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

        leftPanelContent =
            case model.get_doc_api_res of
                Api.Loading ->
                    [ Html.h1 [] [ Html.text ("Document ID: " ++ Utils.unwrappedPercentDecode route.params.doc) ]
                    , Html.text "Loading..."
                    ]

                Api.Failure err ->
                    [ Html.h1 [] [ Html.text ("Document ID: " ++ Utils.unwrappedPercentDecode route.params.doc) ]
                    , Html.text ("Error: " ++ Api.stringOfHttpErrMsg err)
                    ]

                Api.Success response ->
                    [ viewDocumentInfo response
                    , div [ class "annotated-doc-div", class "dbg-off" ]
                        (AnnotatedText.view
                            annotatedDocViewCtx
                            model.working_doc
                        )
                    ]

        rightPanelContent =
            [ Components.CollapsibleSection.view
                { sectionId = "termEditor"
                , title = "Term Editor"
                , isExpanded = model.sectionStates.termEditor
                , onToggle = ToggleSection "termEditor"
                , content =
                    TermEditForm.view model.form_model
                        TermEditorEvent
                        { dict = model.working_dict
                        , document_id =
                            case String.toInt route.params.doc of
                                Just id ->
                                    Just (Bindings.SerialId id)

                                Nothing ->
                                    Nothing
                        }
                }
            , Components.CollapsibleSection.view
                { sectionId = "termDetails"
                , title = "Term Details"
                , isExpanded = model.sectionStates.termDetails
                , onToggle = ToggleSection "termDetails"
                , content =
                    div []
                        [ viewTermDetails model.working_dict model.focus_ctx.segment_selection
                        , case model.focus_ctx.segment_selection of
                            Just seg ->
                                if hasLemma seg then
                                    viewLemmaDisplay seg model.lemma_editing_mode model.working_dict model.annotation_config model.showFurigana

                                else
                                    Html.text ""

                            Nothing ->
                                Html.text ""
                        ]
                }
            , Components.CollapsibleSection.view
                { sectionId = "annotationControls"
                , title = "Annotation Controls"
                , isExpanded = model.sectionStates.annotationControls
                , onToggle = ToggleSection "annotationControls"
                , content = viewAnnotationControls model.annotation_config model.showFurigana
                }
            , Components.CollapsibleSection.view
                { sectionId = "translation"
                , title = "Translation"
                , isExpanded = model.sectionStates.translation
                , onToggle = ToggleSection "translation"
                , content =
                    div []
                        [ Html.text
                            ("Selected text: "
                                ++ Maybe.withDefault "" model.focus_ctx.selected_text
                            )
                        , Html.br [] []
                        , Html.button
                            [ Html.Events.onClick TranslateText
                            , Html.Attributes.disabled (String.isEmpty (String.trim (Maybe.withDefault "" model.focus_ctx.selected_text)))
                            ]
                            [ Html.text "Translate with DeepL" ]
                        , case model.translation_result of
                            Just translation ->
                                Html.div [ Html.Attributes.style "margin-top" "10px", Html.Attributes.style "padding" "10px", Html.Attributes.style "background-color" "#f0f0f0" ]
                                    [ Html.strong [] [ Html.text "Translation: " ]
                                    , Html.br [] []
                                    , Html.text translation
                                    ]

                            Nothing ->
                                Html.text ""
                        ]
                }
            , Components.CollapsibleSection.view
                { sectionId = "tts"
                , title = "Text-to-Speech"
                , isExpanded = model.sectionStates.tts
                , onToggle = ToggleSection "tts"
                , content =
                    case model.get_doc_api_res of
                        Api.Success response ->
                            Components.TtsEmitter.view
                                { text = Maybe.withDefault "" model.focus_ctx.selected_text
                                , language = response.docPackage.language
                                , onStartTts = StartTts
                                , onStopTts = StopTts
                                }

                        _ ->
                            text ""
                }
            , Components.CollapsibleSection.view
                { sectionId = "audio"
                , title = "Audio"
                , isExpanded = True
                , onToggle = ToggleSection "audio"
                , content =
                    div []
                        [ audio [ Html.Attributes.id "influx-audio-player", Html.Attributes.src "http://localhost:8000/test.mp3", Html.Attributes.controls True, Html.Attributes.attribute "crossorigin" "anonymous" ]
                            []
                        ]
                }
            , Components.CollapsibleSection.view
                { sectionId = "debug-info"
                , title = "Debug Info"
                , isExpanded = True
                , onToggle = ToggleSection "debug-info"
                , content =
                    div []
                        [ -- for debugging check focus context model
                          Components.DbgDisplay.view "model.focus_ctx.last_hovered_at" model.focus_ctx.last_hovered_at
                        , Components.DbgDisplay.view "model.focus_ctx.mouse_down_at" model.focus_ctx.mouse_down_at
                        , Components.DbgDisplay.view "model.focus_ctx.last_mouse_down_at" model.focus_ctx.last_mouse_down_at
                        , Components.DbgDisplay.view "model.focus_ctx.slice_selection" model.focus_ctx.slice_selection
                        , Components.DbgDisplay.view "model.focus_ctx.selected_text" model.focus_ctx.selected_text
                        , Components.DbgDisplay.view "model.focus_ctx.segment_selection" model.focus_ctx.segment_selection
                        , Components.DbgDisplay.view "model.focus_ctx.segment_slice" model.focus_ctx.segment_slice
                        ]
                }
            ]
    in
    { title = "Document view"
    , body =
        [ div [ class "outer-layout" ]
            [ Components.Topbar.view {}
            , Html.div [ class "toast-tray" ] [ Toast.render viewToast shared.toast_tray (Toast.config (SharedMsg << Shared.Msg.ToastMsg)) ]
            , div
                [ class "document-layout" ]
                [ div
                    [ class "document-layout__left-panel" ]
                    leftPanelContent
                , Components.ResizableSidebar.view
                    { width = model.rightPanelWidth
                    , isCollapsed = model.sidebarCollapsed
                    , title = "Document Tools"
                    , onStartResize = StartResize
                    , onToggleCollapse = ToggleSidebar
                    , content = rightPanelContent
                    }
                ]
            ]
        ]
    }


viewToast : List (Html.Attribute msg) -> Toast.Info String -> Html msg
viewToast attributes toast =
    Html.div (class "toast toast--spaced" :: attributes) [ Html.text toast.content ]
