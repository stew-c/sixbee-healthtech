module ValidationTest exposing (..)

import Dict
import Expect
import Main exposing (FormFields, validate)
import Test exposing (..)


validFields : FormFields
validFields =
    { name = "Sarah Johnson"
    , dateTime = "2026-04-10T09:30"
    , description = "Routine check-up"
    , contactNumber = "07712345678"
    , email = "sarah@email.com"
    }


suite : Test
suite =
    describe "Form Validation"
        [ describe "required fields"
            [ test "empty name produces error" <|
                \_ ->
                    validate { validFields | name = "" }
                        |> Dict.member "name"
                        |> Expect.equal True -- "Expected name error"
            , test "empty dateTime produces error" <|
                \_ ->
                    validate { validFields | dateTime = "" }
                        |> Dict.member "dateTime"
                        |> Expect.equal True -- "Expected dateTime error"
            , test "empty description produces error" <|
                \_ ->
                    validate { validFields | description = "" }
                        |> Dict.member "description"
                        |> Expect.equal True -- "Expected description error"
            , test "empty contactNumber produces error" <|
                \_ ->
                    validate { validFields | contactNumber = "" }
                        |> Dict.member "contactNumber"
                        |> Expect.equal True -- "Expected contactNumber error"
            , test "empty email produces error" <|
                \_ ->
                    validate { validFields | email = "" }
                        |> Dict.member "email"
                        |> Expect.equal True -- "Expected email error"
            ]
        , describe "phone format"
            [ test "non-UK number produces error" <|
                \_ ->
                    validate { validFields | contactNumber = "12345" }
                        |> Dict.member "contactNumber"
                        |> Expect.equal True -- "Expected contactNumber error"
            , test "number not starting with 07 produces error" <|
                \_ ->
                    validate { validFields | contactNumber = "08712345678" }
                        |> Dict.member "contactNumber"
                        |> Expect.equal True -- "Expected contactNumber error"
            , test "valid UK number produces no error" <|
                \_ ->
                    validate { validFields | contactNumber = "07712345678" }
                        |> Dict.member "contactNumber"
                        |> Expect.equal False -- "Expected no contactNumber error"
            ]
        , describe "email format"
            [ test "email without @ produces error" <|
                \_ ->
                    validate { validFields | email = "notanemail" }
                        |> Dict.member "email"
                        |> Expect.equal True -- "Expected email error"
            , test "email without domain dot produces error" <|
                \_ ->
                    validate { validFields | email = "user@domain" }
                        |> Dict.member "email"
                        |> Expect.equal True -- "Expected email error"
            , test "valid email produces no error" <|
                \_ ->
                    validate { validFields | email = "sarah@email.com" }
                        |> Dict.member "email"
                        |> Expect.equal False -- "Expected no email error"
            ]
        , test "all valid fields produce no errors" <|
            \_ ->
                validate validFields
                    |> Dict.isEmpty
                    |> Expect.equal True -- "Expected no validation errors"
        ]
