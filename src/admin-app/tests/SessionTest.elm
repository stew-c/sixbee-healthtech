module SessionTest exposing (..)

import Expect
import Session exposing (Session(..))
import Test exposing (..)
import Time


suite : Test
suite =
    describe "Session"
        [ describe "login"
            [ test "creates LoggedIn session" <|
                \_ ->
                    Session.login "abc123" "2026-12-31T00:00:00Z" "admin@test.com"
                        |> Session.isLoggedIn
                        |> Expect.equal True
            , test "stores the token" <|
                \_ ->
                    Session.login "abc123" "2026-12-31T00:00:00Z" "admin@test.com"
                        |> Session.getToken
                        |> Expect.equal (Just "abc123")
            , test "stores the email" <|
                \_ ->
                    Session.login "abc123" "2026-12-31T00:00:00Z" "admin@test.com"
                        |> Session.getEmail
                        |> Expect.equal (Just "admin@test.com")
            , test "invalid expiry returns LoggedOut" <|
                \_ ->
                    Session.login "abc123" "not-a-date" "admin@test.com"
                        |> Session.isLoggedIn
                        |> Expect.equal False
            ]
        , describe "logout"
            [ test "returns LoggedOut" <|
                \_ ->
                    Session.login "abc123" "2026-12-31T00:00:00Z" "admin@test.com"
                        |> Session.logout
                        |> Session.isLoggedIn
                        |> Expect.equal False
            , test "getToken returns Nothing after logout" <|
                \_ ->
                    Session.login "abc123" "2026-12-31T00:00:00Z" "admin@test.com"
                        |> Session.logout
                        |> Session.getToken
                        |> Expect.equal Nothing
            ]
        , describe "isExpired"
            [ test "future expiry returns False" <|
                \_ ->
                    let
                        session =
                            Session.login "abc123" "2026-12-31T00:00:00Z" "admin@test.com"

                        now =
                            Time.millisToPosix 1000000000000
                    in
                    Session.isExpired session now
                        |> Expect.equal False
            , test "past expiry returns True" <|
                \_ ->
                    let
                        session =
                            Session.login "abc123" "2020-01-01T00:00:00Z" "admin@test.com"

                        now =
                            Time.millisToPosix 2000000000000
                    in
                    Session.isExpired session now
                        |> Expect.equal True
            , test "LoggedOut is always expired" <|
                \_ ->
                    Session.isExpired LoggedOut (Time.millisToPosix 0)
                        |> Expect.equal True
            ]
        , describe "getToken"
            [ test "returns Nothing when LoggedOut" <|
                \_ ->
                    Session.getToken LoggedOut
                        |> Expect.equal Nothing
            , test "returns Just token when LoggedIn" <|
                \_ ->
                    Session.login "mytoken" "2026-12-31T00:00:00Z" "user@test.com"
                        |> Session.getToken
                        |> Expect.equal (Just "mytoken")
            ]
        ]
