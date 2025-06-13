module Components.TermEditForm exposing (..)

import Bindings exposing (..)
import Datastore.DictContext
import Datastore.DocContext
import Datastore.FocusContext
import Html exposing (Html, div, span)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onMouseDown, onMouseEnter, onMouseOver, onMouseUp)
import Utils exposing (rb, rt, rtc, ruby, unreachableHtml)


view :
    { dict : Datastore.DictContext.T
    , focus_context : Datastore.FocusContext.T
    , focus_predicate : SentenceConstituent -> Bool
    }
    -> Html msg
view args =
    div [] []
