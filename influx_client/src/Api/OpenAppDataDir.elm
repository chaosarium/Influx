module Api.OpenAppDataDir exposing (openAppDataDir)

import Http
import Json.Decode as Decode
import Url.Builder


openAppDataDir : (Result Http.Error () -> msg) -> Cmd msg
openAppDataDir toMsg =
    Http.get
        { url =
            Url.Builder.crossOrigin
                "http://127.0.0.1:3000"
                [ "open_influx_app_data_dir" ]
                []
        , expect = Http.expectJson toMsg (Decode.succeed ())
        }
