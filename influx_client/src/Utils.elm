module Utils exposing (..)

import Url


unwrappedPercentDecode : String -> String
unwrappedPercentDecode s =
    case Url.percentDecode s of
        Just r ->
            r

        Nothing ->
            "error: can't percent decode"


percentEncode : String -> String
percentEncode s =
    Url.percentEncode s
