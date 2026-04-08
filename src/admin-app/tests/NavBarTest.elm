module NavBarTest exposing (..)

import Expect
import Session exposing (Session(..))
import Test exposing (..)


suite : Test
suite =
    describe "Nav Bar"
        [ test "renders email from session" <|
            \_ ->
                Session.login "token" "2026-12-31T00:00:00Z" "admin@sixbee.co.uk"
                    |> Session.getEmail
                    |> Expect.equal (Just "admin@sixbee.co.uk")
        , test "hidden when logged out (getEmail returns Nothing)" <|
            \_ ->
                Session.getEmail LoggedOut
                    |> Expect.equal Nothing
        , test "logout produces LoggedOut session" <|
            \_ ->
                Session.login "token" "2026-12-31T00:00:00Z" "admin@sixbee.co.uk"
                    |> Session.logout
                    |> Session.isLoggedIn
                    |> Expect.equal False
        ]
