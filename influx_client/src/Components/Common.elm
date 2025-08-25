module Components.Common exposing (..)

import Css exposing (..)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (..)


space0px =
    px 0


space2px =
    px 2


space4px =
    px 4


space8px =
    px 8


space16px =
    px 16


space32px =
    px 32


space64px =
    px 64


bascShadow =
    Css.property "box-shadow" "0px 0px 8px 0px var(--gray-a2)"



-- form stuff


inputKeyValHeight =
    px 42


inputKeyValHeightCompact =
    px 32


getKeyValHeight compact =
    if compact then
        inputKeyValHeightCompact

    else
        inputKeyValHeight


getGapSize compact =
    if compact then
        space8px

    else
        space16px


getPaddingXSize compact =
    if compact then
        space4px

    else
        space8px


getPaddingYSize compact =
    if compact then
        space2px

    else
        space8px


getFormGapSize compact =
    if compact then
        space4px

    else
        space8px
