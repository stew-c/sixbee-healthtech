module MainTest exposing (..)

import Dict
import Expect
import Http
import Main exposing (FormFields, Model, Msg(..), SubmitState(..), init, update)
import Test exposing (..)
import Tuple


validFields : FormFields
validFields =
    { name = "Sarah Johnson"
    , dateTime = "2026-04-10T09:30"
    , description = "Routine check-up"
    , contactNumber = "07712345678"
    , email = "sarah@email.com"
    }


modelWithFields : FormFields -> Model
modelWithFields fields =
    { formFields = fields
    , fieldErrors = Dict.empty
    , submitState = NotSubmitted
    }


suite : Test
suite =
    describe "State Transitions"
        [ test "Submit with valid fields sets submitState to Submitting" <|
            \_ ->
                modelWithFields validFields
                    |> update Submit
                    |> Tuple.first
                    |> .submitState
                    |> Expect.equal Submitting
        , test "GotResponse Ok sets submitState to Success" <|
            \_ ->
                { formFields = validFields
                , fieldErrors = Dict.empty
                , submitState = Submitting
                }
                    |> update (GotResponse (Ok ()))
                    |> Tuple.first
                    |> .submitState
                    |> Expect.equal Success
        , test "GotResponse Err sets submitState to Error" <|
            \_ ->
                let
                    result =
                        { formFields = validFields
                        , fieldErrors = Dict.empty
                        , submitState = Submitting
                        }
                            |> update (GotResponse (Err Http.NetworkError))
                            |> Tuple.first
                            |> .submitState
                in
                case result of
                    Error _ ->
                        Expect.pass

                    _ ->
                        Expect.fail "Expected Error state"
        , test "Submit with invalid fields does not change submitState" <|
            \_ ->
                let
                    invalidFields =
                        { validFields | name = "" }
                in
                modelWithFields invalidFields
                    |> update Submit
                    |> Tuple.first
                    |> .submitState
                    |> Expect.equal NotSubmitted
        , test "Submit with invalid fields populates fieldErrors" <|
            \_ ->
                let
                    invalidFields =
                        { validFields | name = "" }
                in
                modelWithFields invalidFields
                    |> update Submit
                    |> Tuple.first
                    |> .fieldErrors
                    |> Dict.isEmpty
                    |> Expect.equal False -- "Expected fieldErrors to be non-empty"
        , test "DismissError resets submitState to NotSubmitted" <|
            \_ ->
                { formFields = validFields
                , fieldErrors = Dict.empty
                , submitState = Error "Some error"
                }
                    |> update DismissError
                    |> Tuple.first
                    |> .submitState
                    |> Expect.equal NotSubmitted
        ]
