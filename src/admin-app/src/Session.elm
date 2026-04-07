module Session exposing (Session(..), getEmail, getToken, isExpired, isLoggedIn, login, logout)

import Iso8601
import Time


type Session
    = LoggedOut
    | LoggedIn
        { token : String
        , expiresAt : Time.Posix
        , email : String
        }


login : String -> String -> String -> Session
login token expiresAtIso email =
    case Iso8601.toTime expiresAtIso of
        Ok posix ->
            LoggedIn
                { token = token
                , expiresAt = posix
                , email = email
                }

        Err _ ->
            LoggedOut


logout : Session -> Session
logout _ =
    LoggedOut


isLoggedIn : Session -> Bool
isLoggedIn session =
    case session of
        LoggedIn _ ->
            True

        LoggedOut ->
            False


getToken : Session -> Maybe String
getToken session =
    case session of
        LoggedIn data ->
            Just data.token

        LoggedOut ->
            Nothing


isExpired : Session -> Time.Posix -> Bool
isExpired session now =
    case session of
        LoggedOut ->
            True

        LoggedIn data ->
            Time.posixToMillis data.expiresAt <= Time.posixToMillis now


getEmail : Session -> Maybe String
getEmail session =
    case session of
        LoggedIn data ->
            Just data.email

        LoggedOut ->
            Nothing
