module Components.StatusColours exposing (statusBorderColor, statusFillColor)

import Bindings exposing (TokenStatus(..))
import Colours


statusFillColor : TokenStatus -> String
statusFillColor status =
    case status of
        L1 ->
            Colours.red9

        L2 ->
            Colours.orange9

        L3 ->
            Colours.amber9

        L4 ->
            Colours.lime9

        L5 ->
            Colours.green9

        Known ->
            Colours.gray9

        Ignored ->
            Colours.violet9

        Unmarked ->
            Colours.gray9


statusBorderColor : TokenStatus -> String
statusBorderColor status =
    case status of
        L1 ->
            Colours.red10

        L2 ->
            Colours.orange10

        L3 ->
            Colours.amber10

        L4 ->
            Colours.lime10

        L5 ->
            Colours.green10

        Known ->
            Colours.gray10

        Ignored ->
            Colours.violet10

        Unmarked ->
            Colours.gray10
