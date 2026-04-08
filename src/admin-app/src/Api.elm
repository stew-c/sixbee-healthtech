module Api exposing (authDelete, authGet, authPatch, authPut)

import Http
import Session exposing (Session)


authGet : Session -> { url : String, expect : Http.Expect msg } -> Cmd msg
authGet session config =
    authRequest session
        { method = "GET"
        , url = config.url
        , body = Http.emptyBody
        , expect = config.expect
        }


authDelete : Session -> { url : String, expect : Http.Expect msg } -> Cmd msg
authDelete session config =
    authRequest session
        { method = "DELETE"
        , url = config.url
        , body = Http.emptyBody
        , expect = config.expect
        }


authPatch : Session -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
authPatch session config =
    authRequest session
        { method = "PATCH"
        , url = config.url
        , body = config.body
        , expect = config.expect
        }


authPut : Session -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
authPut session config =
    authRequest session
        { method = "PUT"
        , url = config.url
        , body = config.body
        , expect = config.expect
        }


authRequest : Session -> { method : String, url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
authRequest session config =
    case Session.getToken session of
        Just token ->
            Http.request
                { method = config.method
                , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
                , url = config.url
                , body = config.body
                , expect = config.expect
                , timeout = Nothing
                , tracker = Nothing
                }

        Nothing ->
            Cmd.none
