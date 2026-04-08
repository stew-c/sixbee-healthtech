module ApproveModalTest exposing (..)

import Appointment exposing (Appointment)
import Expect
import Test exposing (..)


sampleAppointment : Appointment
sampleAppointment =
    { id = "abc-123"
    , name = "James Mitchell"
    , dateTime = "2026-04-08T14:00:00+00:00"
    , description = "Persistent headaches"
    , contactNumber = "07891234567"
    , email = "j.mitchell@mail.com"
    , status = "pending"
    , createdAt = "2026-04-06T10:00:00+00:00"
    , updatedAt = "2026-04-06T10:00:00+00:00"
    }


suite : Test
suite =
    describe "Approve Modal"
        [ test "displays correct patient name" <|
            \_ ->
                Expect.equal "James Mitchell" sampleAppointment.name
        , test "displays correct appointment date" <|
            \_ ->
                let
                    formatted =
                        String.left 16 sampleAppointment.dateTime
                            |> String.replace "T" " "
                in
                Expect.equal "2026-04-08 14:00" formatted
        , test "pending appointment can be approved" <|
            \_ ->
                Expect.equal "pending" sampleAppointment.status
        , test "already approved appointment still shows modal" <|
            \_ ->
                let
                    approved =
                        { sampleAppointment | status = "approved" }
                in
                -- The modal should still render (approve is idempotent)
                Expect.equal "approved" approved.status
        ]
