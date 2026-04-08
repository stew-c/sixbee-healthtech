module EditModalTest exposing (..)

import Appointment exposing (Appointment)
import Expect
import Page.Dashboard exposing (EditModalState, Field(..))
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


initEditState : EditModalState
initEditState =
    { appointment = sampleAppointment
    , name = sampleAppointment.name
    , dateTime = "2026-04-08T14:00"
    , description = sampleAppointment.description
    , contactNumber = sampleAppointment.contactNumber
    , email = sampleAppointment.email
    , saving = False
    , error = Nothing
    }


suite : Test
suite =
    describe "Edit Modal"
        [ test "initialises with appointment field values" <|
            \_ ->
                Expect.all
                    [ \s -> Expect.equal "James Mitchell" s.name
                    , \s -> Expect.equal "Persistent headaches" s.description
                    , \s -> Expect.equal "07891234567" s.contactNumber
                    , \s -> Expect.equal "j.mitchell@mail.com" s.email
                    ]
                    initEditState
        , test "EditField updates name" <|
            \_ ->
                let
                    updated =
                        applyEditField Name "James P Mitchell" initEditState
                in
                Expect.equal "James P Mitchell" updated.name
        , test "EditField updates email" <|
            \_ ->
                let
                    updated =
                        applyEditField Email "new@email.com" initEditState
                in
                Expect.equal "new@email.com" updated.email
        , test "EditField does not change other fields" <|
            \_ ->
                let
                    updated =
                        applyEditField Name "Changed" initEditState
                in
                Expect.equal initEditState.email updated.email
        , test "saving state sets saving to True" <|
            \_ ->
                Expect.equal True { initEditState | saving = True }.saving
        ]


{-| Mimics the EditField handler logic from Main.update
-}
applyEditField : Field -> String -> EditModalState -> EditModalState
applyEditField field val state =
    case field of
        Name ->
            { state | name = val }

        DateTime ->
            { state | dateTime = val }

        Description ->
            { state | description = val }

        ContactNumber ->
            { state | contactNumber = val }

        Email ->
            { state | email = val }
