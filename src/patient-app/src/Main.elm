module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Html exposing (Html, button, div, form, h1, h2, input, label, p, small, span, text, textarea)
import Html.Attributes exposing (class, disabled, for, id, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Encode as Encode


type SubmitState
    = NotSubmitted
    | Submitting
    | Success
    | Error String


type alias FormFields =
    { name : String
    , dateTime : String
    , description : String
    , contactNumber : String
    , email : String
    }


type alias Model =
    { formFields : FormFields
    , fieldErrors : Dict String String
    , submitState : SubmitState
    }


type Msg
    = UpdateField String String
    | Submit
    | GotResponse (Result Http.Error ())


init : () -> ( Model, Cmd Msg )
init _ =
    ( { formFields =
            { name = ""
            , dateTime = ""
            , description = ""
            , contactNumber = ""
            , email = ""
            }
      , fieldErrors = Dict.empty
      , submitState = NotSubmitted
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateField field value ->
            ( { model
                | formFields = setField field value model.formFields
                , fieldErrors = Dict.remove field model.fieldErrors
              }
            , Cmd.none
            )

        Submit ->
            let
                errors =
                    validate model.formFields
            in
            if Dict.isEmpty errors then
                ( { model | fieldErrors = Dict.empty, submitState = Submitting }
                , submitAppointment model.formFields
                )

            else
                ( { model | fieldErrors = errors }, Cmd.none )

        GotResponse (Ok _) ->
            ( { model | submitState = Success }, Cmd.none )

        GotResponse (Err err) ->
            let
                message =
                    case err of
                        Http.BadStatus 400 ->
                            "Please check your details and try again."

                        _ ->
                            "Something went wrong. Please try again."
            in
            ( { model | submitState = Error message }, Cmd.none )


setField : String -> String -> FormFields -> FormFields
setField field value fields =
    case field of
        "name" ->
            { fields | name = value }

        "dateTime" ->
            { fields | dateTime = value }

        "description" ->
            { fields | description = value }

        "contactNumber" ->
            { fields | contactNumber = value }

        "email" ->
            { fields | email = value }

        _ ->
            fields


validate : FormFields -> Dict String String
validate fields =
    Dict.fromList
        (List.filterMap identity
            [ validateRequired "name" "Full name is required" fields.name
            , validateRequired "dateTime" "Appointment date and time is required" fields.dateTime
            , validateRequired "description" "Description is required" fields.description
            , validatePhone fields.contactNumber
            , validateEmail fields.email
            ]
        )


validateRequired : String -> String -> String -> Maybe ( String, String )
validateRequired fieldName message fieldValue =
    if String.trim fieldValue == "" then
        Just ( fieldName, message )

    else
        Nothing


validatePhone : String -> Maybe ( String, String )
validatePhone phone =
    let
        trimmed =
            String.trim phone

        digitsOnly =
            String.filter Char.isDigit trimmed
    in
    if trimmed == "" then
        Just ( "contactNumber", "Contact number is required" )

    else if not (String.startsWith "07" digitsOnly) || String.length digitsOnly /= 11 then
        Just ( "contactNumber", "A valid UK phone number is required (e.g., 07712345678)" )

    else
        Nothing


validateEmail : String -> Maybe ( String, String )
validateEmail email =
    let
        trimmed =
            String.trim email
    in
    if trimmed == "" then
        Just ( "email", "Email address is required" )

    else
        case String.split "@" trimmed of
            [ before, after ] ->
                if before /= "" && String.contains "." after && not (String.endsWith "." after) then
                    Nothing

                else
                    Just ( "email", "A valid email address is required" )

            _ ->
                Just ( "email", "A valid email address is required" )


submitAppointment : FormFields -> Cmd Msg
submitAppointment fields =
    Http.request
        { method = "POST"
        , headers = []
        , url = "/api/appointments"
        , body = Http.jsonBody (encodeAppointment fields)
        , expect = Http.expectWhatever GotResponse
        , timeout = Nothing
        , tracker = Nothing
        }


encodeAppointment : FormFields -> Encode.Value
encodeAppointment fields =
    let
        isoDateTime =
            if String.contains "Z" fields.dateTime then
                fields.dateTime

            else if String.length fields.dateTime == 16 then
                fields.dateTime ++ ":00Z"

            else
                fields.dateTime ++ "Z"
    in
    Encode.object
        [ ( "name", Encode.string fields.name )
        , ( "dateTime", Encode.string isoDateTime )
        , ( "description", Encode.string fields.description )
        , ( "contactNumber", Encode.string fields.contactNumber )
        , ( "email", Encode.string fields.email )
        ]


view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-surface-primary" ]
        [ viewHeader
        , div [ class "max-w-lg mx-auto px-4 py-8" ]
            [ viewContent model ]
        , viewFooter
        ]


viewHeader : Html Msg
viewHeader =
    div [ class "bg-surface-inverse px-8 py-6" ]
        [ small [ class "text-surface-secondary text-sm font-semibold" ]
            [ text "SixBee HealthTech" ]
        , h1 [ class "text-foreground-inverse text-2xl font-bold mt-1" ]
            [ text "Book an Appointment" ]
        , p [ class "text-foreground-muted text-sm mt-2" ]
            [ text "Fill in the form below and we'll get back to you to confirm your appointment." ]
        ]


viewFooter : Html Msg
viewFooter =
    div [ class "text-center py-4 text-foreground-muted text-xs" ]
        [ text "By booking, you agree to our terms and privacy policy." ]


viewContent : Model -> Html Msg
viewContent model =
    case model.submitState of
        Success ->
            div [ class "bg-green-50 border border-green-200 rounded-lg p-6" ]
                [ h2 [ class "text-xl font-semibold text-green-800 mb-2" ]
                    [ text "Booking Submitted" ]
                , p [ class "text-green-700" ]
                    [ text "Your appointment request has been submitted successfully. We will review it shortly." ]
                ]

        Error errMsg ->
            div []
                [ div [ class "bg-red-50 border border-red-200 rounded-lg p-4 mb-6" ]
                    [ p [ class "text-red-700" ] [ text errMsg ] ]
                , viewForm model
                ]

        _ ->
            viewForm model


viewForm : Model -> Html Msg
viewForm model =
    let
        isSubmitting =
            model.submitState == Submitting
    in
    form [ class "flex flex-col gap-5", onSubmit Submit ]
        [ viewField "name" "Full Name *" "text" "Enter your full name" model
        , viewDateField model
        , viewTextarea model
        , viewField "contactNumber" "Contact Number *" "text" "07xxx xxx xxx" model
        , viewField "email" "Email Address *" "email" "you@example.com" model
        , button
            [ class "btn-primary w-full"
            , type_ "submit"
            , disabled isSubmitting
            ]
            [ text
                (if isSubmitting then
                    "Submitting..."
                 else
                    "Book Appointment"
                )
            ]
        ]


viewField : String -> String -> String -> String -> Model -> Html Msg
viewField fieldName labelText inputType placeholderText model =
    let
        fieldValue =
            getFieldValue fieldName model.formFields

        errorText =
            Dict.get fieldName model.fieldErrors
    in
    div [ class "flex flex-col gap-1" ]
        [ label [ class "input-label", for fieldName ]
            [ text labelText ]
        , input
            [ class "input-field"
            , type_ inputType
            , id fieldName
            , placeholder placeholderText
            , value fieldValue
            , onInput (UpdateField fieldName)
            ]
            []
        , viewFieldError errorText
        ]


viewDateField : Model -> Html Msg
viewDateField model =
    let
        errorText =
            Dict.get "dateTime" model.fieldErrors
    in
    div [ class "flex flex-col gap-1" ]
        [ label [ class "input-label", for "dateTime" ]
            [ text "Appointment Date & Time *" ]
        , input
            [ class "input-field"
            , type_ "datetime-local"
            , id "dateTime"
            , value model.formFields.dateTime
            , onInput (UpdateField "dateTime")
            ]
            []
        , viewFieldError errorText
        ]


viewTextarea : Model -> Html Msg
viewTextarea model =
    let
        errorText =
            Dict.get "description" model.fieldErrors
    in
    div [ class "flex flex-col gap-1" ]
        [ label [ class "input-label", for "description" ]
            [ text "Description *" ]
        , textarea
            [ class "input-textarea"
            , id "description"
            , placeholder "Describe your symptoms or reason for visit"
            , value model.formFields.description
            , onInput (UpdateField "description")
            ]
            []
        , viewFieldError errorText
        ]


viewFieldError : Maybe String -> Html Msg
viewFieldError maybeError =
    case maybeError of
        Just error ->
            p [ class "text-danger text-xs mt-0.5" ] [ text error ]

        Nothing ->
            text ""


getFieldValue : String -> FormFields -> String
getFieldValue field fields =
    case field of
        "name" ->
            fields.name

        "dateTime" ->
            fields.dateTime

        "description" ->
            fields.description

        "contactNumber" ->
            fields.contactNumber

        "email" ->
            fields.email

        _ ->
            ""


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
