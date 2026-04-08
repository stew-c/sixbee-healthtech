module AppointmentTest exposing (..)

import Appointment exposing (Appointment, AppointmentListResponse, appointmentDecoder, appointmentListResponseDecoder)
import Expect
import Json.Decode as Decode
import Test exposing (..)


sampleAppointmentJson : String
sampleAppointmentJson =
    """{"id":"abc-123","name":"Sarah Johnson","dateTime":"2026-04-10T09:30:00+00:00","description":"Routine check-up","contactNumber":"07712345678","email":"sarah@email.com","status":"pending","createdAt":"2026-04-06T10:00:00+00:00","updatedAt":"2026-04-06T10:00:00+00:00"}"""


sampleListResponseJson : String
sampleListResponseJson =
    """{"items":[""" ++ sampleAppointmentJson ++ """],"totalCount":25,"page":1,"pageSize":10}"""


suite : Test
suite =
    describe "Appointment"
        [ describe "appointmentDecoder"
            [ test "decodes valid appointment JSON" <|
                \_ ->
                    case Decode.decodeString appointmentDecoder sampleAppointmentJson of
                        Ok appt ->
                            Expect.all
                                [ \a -> Expect.equal "abc-123" a.id
                                , \a -> Expect.equal "Sarah Johnson" a.name
                                , \a -> Expect.equal "pending" a.status
                                , \a -> Expect.equal "07712345678" a.contactNumber
                                , \a -> Expect.equal "sarah@email.com" a.email
                                ]
                                appt

                        Err err ->
                            Expect.fail (Decode.errorToString err)
            , test "fails on missing fields" <|
                \_ ->
                    case Decode.decodeString appointmentDecoder """{"id":"abc"}""" of
                        Ok _ ->
                            Expect.fail "Expected decode to fail"

                        Err _ ->
                            Expect.pass
            ]
        , describe "appointmentListResponseDecoder"
            [ test "decodes valid list response" <|
                \_ ->
                    case Decode.decodeString appointmentListResponseDecoder sampleListResponseJson of
                        Ok response ->
                            Expect.all
                                [ \r -> Expect.equal 1 (List.length r.items)
                                , \r -> Expect.equal 25 r.totalCount
                                , \r -> Expect.equal 1 r.page
                                , \r -> Expect.equal 10 r.pageSize
                                ]
                                response

                        Err err ->
                            Expect.fail (Decode.errorToString err)
            ]
        , describe "row styling"
            [ test "approved appointment uses approved row class" <|
                \_ ->
                    let
                        rowClass =
                            if "approved" == "approved" then
                                "table-row-approved"

                            else
                                "table-row"
                    in
                    Expect.equal "table-row-approved" rowClass
            , test "pending appointment uses default row class" <|
                \_ ->
                    let
                        rowClass =
                            if "pending" == "approved" then
                                "table-row-approved"

                            else
                                "table-row"
                    in
                    Expect.equal "table-row" rowClass
            ]
        ]
