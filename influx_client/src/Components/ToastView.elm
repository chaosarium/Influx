module Components.ToastView exposing (..)

import Html
import Html.Attributes
import Toast


viewToast : List (Html.Attribute msg) -> Toast.Info String -> Html.Html msg
viewToast attributes toast =
    Html.div
        (Html.Attributes.class "toast-entry" :: attributes)
        [ Html.text toast.content ]
