module Appointment exposing (Appointment, AppointmentListResponse, appointmentDecoder, appointmentListResponseDecoder)

import Json.Decode as Decode exposing (Decoder)


type alias Appointment =
    { id : String
    , name : String
    , dateTime : String
    , description : String
    , contactNumber : String
    , email : String
    , status : String
    , createdAt : String
    , updatedAt : String
    }


type alias AppointmentListResponse =
    { items : List Appointment
    , totalCount : Int
    , page : Int
    , pageSize : Int
    }


appointmentDecoder : Decoder Appointment
appointmentDecoder =
    Decode.succeed Appointment
        |> required "id"
        |> required "name"
        |> required "dateTime"
        |> required "description"
        |> required "contactNumber"
        |> required "email"
        |> required "status"
        |> required "createdAt"
        |> required "updatedAt"


appointmentListResponseDecoder : Decoder AppointmentListResponse
appointmentListResponseDecoder =
    Decode.succeed AppointmentListResponse
        |> requiredWith "items" (Decode.list appointmentDecoder)
        |> requiredInt "totalCount"
        |> requiredInt "page"
        |> requiredInt "pageSize"



-- Pipeline helpers (avoiding external dependency)


required : String -> Decoder (String -> b) -> Decoder b
required field decoder =
    Decode.map2 (\f v -> f v) decoder (Decode.field field Decode.string)


requiredWith : String -> Decoder a -> Decoder (a -> b) -> Decoder b
requiredWith field valueDecoder decoder =
    Decode.map2 (\f v -> f v) decoder (Decode.field field valueDecoder)


requiredInt : String -> Decoder (Int -> b) -> Decoder b
requiredInt field decoder =
    Decode.map2 (\f v -> f v) decoder (Decode.field field Decode.int)
