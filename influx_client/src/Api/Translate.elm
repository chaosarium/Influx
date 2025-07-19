module Api.Translate exposing (TranslateRequest, TranslateResponse, translate)

import Http
import Json.Decode as Decode
import Json.Encode as Encode


type alias TranslateResponse =
    { translatedText : String
    }


type alias TranslateRequest =
    { fromLangId : String
    , toLangId : String
    , sourceSequence : String
    , provider : String
    }


translate : TranslateRequest -> (Result Http.Error TranslateResponse -> msg) -> Cmd msg
translate request toMsg =
    Http.post
        { url = "http://127.0.0.1:3000/extern/translate"
        , body = Http.jsonBody (encodeTranslateRequest request)
        , expect = Http.expectJson toMsg decodeTranslateResponse
        }


encodeTranslateRequest : TranslateRequest -> Encode.Value
encodeTranslateRequest request =
    Encode.object
        [ ( "from_lang_id", Encode.string request.fromLangId )
        , ( "to_lang_id", Encode.string request.toLangId )
        , ( "source_sequence", Encode.string request.sourceSequence )
        , ( "provider", Encode.string request.provider )
        ]


decodeTranslateResponse : Decode.Decoder TranslateResponse
decodeTranslateResponse =
    Decode.map TranslateResponse
        (Decode.field "translated_text" Decode.string)
