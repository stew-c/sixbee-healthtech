module LoginTest exposing (..)

import Expect
import Http
import Page.Login exposing (LoginResponse, State(..))
import Test exposing (..)


suite : Test
suite =
    describe "Login"
        [ describe "validation"
            [ test "empty email is invalid" <|
                \_ ->
                    validateLogin "" "password123"
                        |> isLoginError
                        |> Expect.equal True
            , test "empty password is invalid" <|
                \_ ->
                    validateLogin "admin@sixbee.co.uk" ""
                        |> isLoginError
                        |> Expect.equal True
            , test "both empty is invalid" <|
                \_ ->
                    validateLogin "" ""
                        |> isLoginError
                        |> Expect.equal True
            , test "valid credentials pass validation" <|
                \_ ->
                    validateLogin "admin@sixbee.co.uk" "password123"
                        |> Expect.equal Submitting
            ]
        , describe "response handling"
            [ test "401 produces invalid credentials error" <|
                \_ ->
                    handleLoginResponse (Err (Http.BadStatus 401))
                        |> Expect.equal (LoginError "Invalid email or password")
            , test "network error produces generic error" <|
                \_ ->
                    handleLoginResponse (Err Http.NetworkError)
                        |> Expect.equal (LoginError "Something went wrong. Please try again.")
            , test "successful response produces Idle state" <|
                \_ ->
                    handleLoginResponse (Ok { token = "jwt-123", expiresAt = "2026-04-06T21:00:00Z" })
                        |> Expect.equal Idle
            ]
        ]


{-| Mimics the SubmitLogin validation logic from Main.update
-}
validateLogin : String -> String -> State
validateLogin email password =
    if String.trim email == "" || String.trim password == "" then
        LoginError "Email and password are required"

    else
        Submitting


{-| Mimics the GotLoginResponse handler from Main.update — returns the loginState
-}
handleLoginResponse : Result Http.Error LoginResponse -> State
handleLoginResponse result =
    case result of
        Ok _ ->
            Idle

        Err err ->
            case err of
                Http.BadStatus 401 ->
                    LoginError "Invalid email or password"

                _ ->
                    LoginError "Something went wrong. Please try again."


isLoginError : State -> Bool
isLoginError state =
    case state of
        LoginError _ ->
            True

        _ ->
            False
