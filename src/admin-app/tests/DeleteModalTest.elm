module DeleteModalTest exposing (..)

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
    describe "Delete Modal"
        [ test "displays correct patient name" <|
            \_ ->
                Expect.equal "James Mitchell" sampleAppointment.name
        , test "warning message includes patient name" <|
            \_ ->
                let
                    message =
                        "Are you sure you want to delete the appointment for "
                            ++ sampleAppointment.name
                            ++ "? This action cannot be undone."
                in
                String.contains "James Mitchell" message
                    |> Expect.equal True
        , test "warning message includes cannot be undone" <|
            \_ ->
                let
                    message =
                        "Are you sure you want to delete the appointment for "
                            ++ sampleAppointment.name
                            ++ "? This action cannot be undone."
                in
                String.contains "cannot be undone" message
                    |> Expect.equal True
        ]
