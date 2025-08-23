module Components.CssExtra exposing
    ( borderNone
    , gap
    )

import Css exposing (..)


gap : LengthOrNumberOrAutoOrNoneOrContent compatible -> Style
gap x =
    property "gap" x.value


borderNone =
    property "border" "none"
