module Datastore.FocusContext exposing (..)

import Bindings exposing (DocSegV2, DocSegVariants(..), InfluxResourceId(..), Phrase, SentSegV2, SentSegVariants(..), TokenStatus(..))
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
    { last_hovered_at : Maybe SentSegV2
    , mouse_down_at : Maybe SentSegV2
    , last_mouse_down_at : Maybe SentSegV2
    , slice_selection : Maybe SliceSelection
    , selected_text : Maybe String
    , segment_selection : Maybe SentSegV2
    , segment_slice : Maybe (List SentSegV2)
    }


new : T
new =
    { last_hovered_at = Nothing
    , slice_selection = Nothing
    , mouse_down_at = Nothing
    , last_mouse_down_at = Nothing
    , selected_text = Nothing
    , segment_selection = Nothing
    , segment_slice = Nothing
    }


type Msg
    = SelectMouseDown SentSegV2
    | SelectMouseEnter SentSegV2
      -- | SelectMouseOut SentSegV2
    | SelectMouseUp ()


listLast list =
    List.head (List.reverse list)


getFirstLastIds : List SentSegV2 -> ( Maybe Int, Maybe Int )
getFirstLastIds list =
    case ( List.head list, listLast list ) of
        ( Just first, Just last ) ->
            let
                firstId =
                    case first.inner of
                        TokenSeg { idx } ->
                            Just idx

                        _ ->
                            Nothing

                lastId =
                    case last.inner of
                        TokenSeg { idx } ->
                            Just idx

                        _ ->
                            Nothing
            in
            ( firstId, lastId )

        _ ->
            ( Nothing, Nothing )


getStartEndIdxs : SentSegV2 -> ( SliceSelecting, SliceSelecting )
getStartEndIdxs cst =
    case cst.inner of
        TokenSeg { idx } ->
            ( { s = cst.sentenceIdx, t = idx, c = cst.startChar }, { s = cst.sentenceIdx, t = idx, c = cst.endChar } )

        PhraseSeg { components } ->
            case getFirstLastIds components of
                ( Just firstId, Just lastId ) ->
                    ( { s = cst.sentenceIdx, t = firstId, c = cst.startChar }, { s = cst.sentenceIdx, t = lastId, c = cst.endChar } )

                _ ->
                    Debug.todo "unreachable, first or last token of components should have id"

        WhitespaceSeg ->
            Debug.todo "unreachable, should not have listened to mouse events on whitespace"


sliceBetween : SentSegV2 -> SentSegV2 -> SliceSelection
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
                , segment_selection = Just down_at
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
                        , segment_selection =
                            if down_at == last_hovered_at then
                                Just down_at

                            else
                                Nothing
                    }

                _ ->
                    { t
                        | mouse_down_at = Nothing
                    }


filterSentSegsInSlice :
    SliceSelection
    -> List SentSegV2
    -> List SentSegV2
filterSentSegsInSlice slice segments =
    List.concatMap
        (\cst ->
            if isSentSegInSlice slice cst then
                [ cst ]

            else
                case cst.inner of
                    PhraseSeg { components } ->
                        filterSentSegsInSlice slice components

                    _ ->
                        []
        )
        segments


update : DocContext.T -> Msg -> T -> T
update doc_ctx msg t =
    let
        t_ =
            mouseEventUpdate msg t

        segment_slice =
            Maybe.map
                (\slice ->
                    doc_ctx.segments
                        |> List.filter (isDocSegInSlice slice)
                        |> List.concatMap
                            (\doc_seg ->
                                case doc_seg.inner of
                                    Sentence { segments } ->
                                        segments

                                    _ ->
                                        []
                            )
                        |> filterSentSegsInSlice slice
                )
                t_.slice_selection
    in
    { t_
        | selected_text =
            Maybe.map
                (\{ sc, ec } ->
                    String.slice sc ec doc_ctx.text
                )
                t_.slice_selection
        , segment_slice = segment_slice
    }


isSentSegInSlice : SliceSelection -> SentSegV2 -> Bool
isSentSegInSlice slice seg =
    seg.startChar >= slice.sc && seg.endChar <= slice.ec


isDocSegInSlice : SliceSelection -> DocSegV2 -> Bool
isDocSegInSlice slice seg =
    case seg.inner of
        Sentence { segments } ->
            case List.head segments of
                Just first_seg ->
                    first_seg.sentenceIdx
                        >= slice.ss
                        && first_seg.sentenceIdx
                        <= slice.es

                Nothing ->
                    False

        DocumentWhitespace ->
            seg.startChar >= slice.sc && seg.endChar <= slice.ec


getPhraseFromSegmentSlice : InfluxResourceId -> List SentSegV2 -> Maybe Phrase
getPhraseFromSegmentSlice langId segments =
    let
        orthography_seq =
            List.concatMap
                (\cst ->
                    case cst.inner of
                        TokenSeg { orthography } ->
                            [ orthography ]

                        PhraseSeg { components } ->
                            List.concatMap
                                (\c ->
                                    case c.inner of
                                        TokenSeg { orthography } ->
                                            [ orthography ]

                                        _ ->
                                            []
                                )
                                components

                        _ ->
                            []
                )
                segments
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
