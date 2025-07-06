module Datastore.FocusContext exposing (..)

import Api.GetAnnotatedDoc exposing (get)
import Bindings exposing (..)
import Datastore.DocContext as DocContext


type alias SliceSelection =
    { ss : Int -- start sentence (inclusive)
    , es : Int -- end sentence (inclusive)
    , st : Int -- start token (inclusive)
    , et : Int -- end token (inclusive)
    , sc : Int -- start character (inclusive)
    , ec : Int -- end character (inclusive)
    }


type alias SliceSelecting =
    { s : Int -- which sentence
    , t : Int -- which token
    , c : Int -- which character
    }


type alias T =
    { last_hovered_at : Maybe SentenceConstituent
    , mouse_down_at : Maybe SentenceConstituent
    , last_mouse_down_at : Maybe SentenceConstituent
    , slice_selection : Maybe SliceSelection
    , selected_text : Maybe String
    , constituent_selection : Maybe SentenceConstituent
    , constituent_slice : Maybe (List SentenceConstituent)
    }


new : T
new =
    { last_hovered_at = Nothing
    , slice_selection = Nothing
    , mouse_down_at = Nothing
    , last_mouse_down_at = Nothing
    , selected_text = Nothing
    , constituent_selection = Nothing
    , constituent_slice = Nothing
    }


type Msg
    = SelectMouseDown SentenceConstituent
    | SelectMouseEnter SentenceConstituent
      -- | SelectMouseOut SentenceConstituent
    | SelectMouseUp ()


listLast list =
    List.head (List.reverse list)


getFirstLastIds : List SentenceConstituent -> ( Maybe Int, Maybe Int )
getFirstLastIds list =
    case ( List.head list, listLast list ) of
        ( Just first, Just last ) ->
            let
                firstId =
                    case first of
                        Bindings.SingleToken { id } ->
                            Just id

                        Bindings.SubwordToken { id } ->
                            Just id

                        _ ->
                            Nothing

                lastId =
                    case last of
                        Bindings.SingleToken { id } ->
                            Just id

                        Bindings.SubwordToken { id } ->
                            Just id

                        _ ->
                            Nothing
            in
            ( firstId, lastId )

        _ ->
            ( Nothing, Nothing )


getStartEndIdxs : SentenceConstituent -> ( SliceSelecting, SliceSelecting )
getStartEndIdxs cst =
    case cst of
        Bindings.SingleToken { sentenceId, id, startChar, endChar } ->
            ( { s = sentenceId, t = id, c = startChar }, { s = sentenceId, t = id, c = endChar } )

        Bindings.SubwordToken _ ->
            Debug.todo "unreachable, subword should never be selectable"

        Bindings.PhraseToken { sentenceId, shadows, startChar, endChar } ->
            case getFirstLastIds shadows of
                ( Just firstId, Just lastId ) ->
                    ( { s = sentenceId, t = firstId, c = startChar }, { s = sentenceId, t = lastId, c = endChar } )

                _ ->
                    Debug.todo "unreachable, first or last token of shadows should have id"

        Bindings.MultiwordToken { sentenceId, shadows, startChar, endChar } ->
            case getFirstLastIds shadows of
                ( Just firstId, Just lastId ) ->
                    ( { s = sentenceId, t = firstId, c = startChar }, { s = sentenceId, t = lastId, c = endChar } )

                _ ->
                    Debug.todo "unreachable, first or last token of shadows should have id"

        Bindings.SentenceWhitespace _ ->
            Debug.todo "unreachable, should not have listened to mouse events on whitespace"


sliceBetween : SentenceConstituent -> SentenceConstituent -> SliceSelection
sliceBetween cst1 cst2 =
    let
        ( ( start1, end1 ), ( start2, end2 ) ) =
            ( getStartEndIdxs cst1, getStartEndIdxs cst2 )
    in
    { ss = min start1.s start2.s
    , es = max end1.s end2.s
    , st =
        case compare start1.s start2.s of
            LT ->
                start1.t

            GT ->
                start2.t

            EQ ->
                min start1.t start2.t
    , et =
        case compare end1.s end2.s of
            LT ->
                end2.t

            GT ->
                end1.t

            EQ ->
                max end1.t end2.t
    , sc = min start1.c start2.c
    , ec = max end1.c end2.c
    }


mouseEventUpdate : Msg -> T -> T
mouseEventUpdate msg t =
    case msg of
        SelectMouseDown down_at ->
            { t
                | mouse_down_at = Just down_at
                , last_mouse_down_at = Just down_at
                , slice_selection = Just (sliceBetween down_at down_at)
                , constituent_selection = Just down_at
            }

        SelectMouseEnter cst ->
            case ( t.mouse_down_at, cst ) of
                ( Just down_at, last_hovered_at ) ->
                    { t
                        | last_hovered_at = Just last_hovered_at
                        , slice_selection = Just (sliceBetween down_at last_hovered_at)
                    }

                _ ->
                    { t
                        | last_hovered_at = Just cst
                    }

        SelectMouseUp _ ->
            case ( t.mouse_down_at, t.last_hovered_at ) of
                ( Just down_at, Just last_hovered_at ) ->
                    { t
                        | mouse_down_at = Nothing
                        , slice_selection = Just (sliceBetween down_at last_hovered_at)
                        , constituent_selection =
                            if down_at == last_hovered_at then
                                Just down_at

                            else
                                Nothing
                    }

                _ ->
                    { t
                        | mouse_down_at = Nothing
                    }


update : DocContext.T -> Msg -> T -> T
update doc_ctx msg t =
    let
        tt =
            mouseEventUpdate msg t

        constituent_slice =
            Maybe.map
                (\slice ->
                    doc_ctx.constituents
                        |> List.filter (isDocCstInSlice slice)
                        |> List.concatMap
                            (\doc_cst ->
                                case doc_cst of
                                    Sentence { constituents } ->
                                        constituents

                                    _ ->
                                        []
                            )
                        |> List.filter (isCstInSlice slice)
                )
                tt.slice_selection
    in
    { tt
        | selected_text =
            Maybe.map
                (\{ sc, ec } ->
                    String.slice sc ec doc_ctx.text
                )
                tt.slice_selection
        , constituent_slice = constituent_slice
    }


isCstInSlice : SliceSelection -> SentenceConstituent -> Bool
isCstInSlice slice con =
    case con of
        Bindings.SingleToken { sentenceId, id } ->
            ((sentenceId == slice.ss && id >= slice.st) || sentenceId > slice.ss)
                && ((sentenceId == slice.es && id <= slice.et) || sentenceId < slice.es)

        Bindings.SubwordToken { sentenceId, id } ->
            ((sentenceId == slice.ss && id >= slice.st) || sentenceId > slice.ss)
                && ((sentenceId == slice.es && id <= slice.et) || sentenceId < slice.es)

        Bindings.PhraseToken { startChar, endChar } ->
            startChar >= slice.sc && endChar <= slice.ec

        Bindings.MultiwordToken { startChar, endChar } ->
            startChar >= slice.sc && endChar <= slice.ec

        Bindings.SentenceWhitespace { startChar, endChar } ->
            startChar >= slice.sc && endChar <= slice.ec


isDocCstInSlice : SliceSelection -> DocumentConstituent -> Bool
isDocCstInSlice slice con =
    case con of
        Bindings.Sentence { id } ->
            id >= slice.ss && id <= slice.es

        Bindings.DocumentWhitespace { startChar, endChar } ->
            startChar >= slice.sc && endChar <= slice.ec


getPhraseFromConstituentSlice : InfluxResourceId -> List SentenceConstituent -> Maybe Phrase
getPhraseFromConstituentSlice langId constituents =
    let
        orthography_seq =
            constituents
                |> List.filterMap
                    (\cst ->
                        case cst of
                            SingleToken { orthography } ->
                                Just orthography

                            MultiwordToken { orthography } ->
                                Just orthography

                            _ ->
                                Nothing
                    )
    in
    if List.length orthography_seq > 1 then
        Just
            { id = Nothing
            , langId = langId
            , orthographySeq = orthography_seq
            , definition = ""
            , notes = ""
            , originalContext = ""
            , status = Unmarked
            }

    else
        Nothing
