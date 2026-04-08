module Page.Login exposing (LoginResponse, Model, Msg(..), State(..), init, loginResponseDecoder, update, view)

import Html exposing (Html, button, div, form, h1, input, label, p, text)
import Html.Attributes exposing (class, disabled, for, id, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Icons
import Json.Decode as Decode
import Json.Encode as Encode


type alias Model =
    { email : String
    , password : String
    , state : State
    }


type State
    = Idle
    | Submitting
    | LoginError String


type Msg
    = UpdateEmail String
    | UpdatePassword String
    | SubmitLogin
    | GotLoginResponse (Result Http.Error LoginResponse)


type alias LoginResponse =
    { token : String
    , expiresAt : String
    }


init : Model
init =
    { email = ""
    , password = ""
    , state = Idle
    }


loginResponseDecoder : Decode.Decoder LoginResponse
loginResponseDecoder =
    Decode.map2 LoginResponse
        (Decode.field "token" Decode.string)
        (Decode.field "expiresAt" Decode.string)



-- HTTP


submitLogin : String -> String -> Cmd Msg
submitLogin email password =
    Http.post
        { url = "/api/auth/login"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "email", Encode.string email )
                    , ( "password", Encode.string password )
                    ]
                )
        , expect = Http.expectJson GotLoginResponse loginResponseDecoder
        }



-- UPDATE


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , loginSuccess : Maybe { token : String, expiresAt : String, email : String }
    }


update : Msg -> Model -> UpdateResult
update msg model =
    case msg of
        UpdateEmail email ->
            { model = { model | email = email, state = Idle }
            , cmd = Cmd.none
            , loginSuccess = Nothing
            }

        UpdatePassword password ->
            { model = { model | password = password, state = Idle }
            , cmd = Cmd.none
            , loginSuccess = Nothing
            }

        SubmitLogin ->
            if String.trim model.email == "" || String.trim model.password == "" then
                { model = { model | state = LoginError "Email and password are required" }
                , cmd = Cmd.none
                , loginSuccess = Nothing
                }

            else
                { model = { model | state = Submitting }
                , cmd = submitLogin model.email model.password
                , loginSuccess = Nothing
                }

        GotLoginResponse (Ok response) ->
            { model = { model | state = Idle, password = "" }
            , cmd = Cmd.none
            , loginSuccess = Just { token = response.token, expiresAt = response.expiresAt, email = model.email }
            }

        GotLoginResponse (Err err) ->
            let
                message =
                    case err of
                        Http.BadStatus 401 ->
                            "Invalid email or password"

                        _ ->
                            "Something went wrong. Please try again."
            in
            { model = { model | state = LoginError message }
            , cmd = Cmd.none
            , loginSuccess = Nothing
            }



-- VIEW


view : Model -> Html Msg
view model =
    let
        isSubmitting =
            model.state == Submitting
    in
    div [ class "min-h-screen bg-surface-primary flex items-center justify-center px-4" ]
        [ div [ class "w-full max-w-sm" ]
            [ form [ class "bg-white rounded-modal shadow-lg p-8", onSubmit SubmitLogin ]
                [ div [ class "flex flex-col items-center gap-2 mb-6" ]
                    [ div [ class "w-12 h-12 bg-surface-inverse rounded-card flex items-center justify-center" ]
                        [ Icons.heartPulse ]
                    , h1 [ class "text-2xl font-bold text-foreground-primary" ]
                        [ text "Admin Login" ]
                    , p [ class "text-foreground-muted text-sm" ]
                        [ text "Sign in to manage appointments" ]
                    ]
                , viewLoginError model.state
                , div [ class "flex flex-col gap-4 mb-6" ]
                    [ div [ class "flex flex-col gap-1" ]
                        [ label [ class "input-label", for "email" ]
                            [ text "Email Address" ]
                        , input
                            [ class "input-field"
                            , type_ "email"
                            , id "email"
                            , placeholder "admin@sixbee.co.uk"
                            , value model.email
                            , onInput UpdateEmail
                            ]
                            []
                        ]
                    , div [ class "flex flex-col gap-1" ]
                        [ label [ class "input-label", for "password" ]
                            [ text "Password" ]
                        , input
                            [ class "input-field"
                            , type_ "password"
                            , id "password"
                            , placeholder "••••••••"
                            , value model.password
                            , onInput UpdatePassword
                            ]
                            []
                        ]
                    ]
                , button
                    [ class
                        ("btn-primary w-full"
                            ++ (if isSubmitting then
                                    " opacity-75 cursor-not-allowed"

                                else
                                    ""
                               )
                        )
                    , type_ "submit"
                    , disabled isSubmitting
                    ]
                    [ text
                        (if isSubmitting then
                            "Signing in..."

                         else
                            "Sign In"
                        )
                    ]
                ]
            , p [ class "text-center text-foreground-muted text-xs mt-6" ]
                [ text "SixBee HealthTech — Staff Portal" ]
            ]
        ]


viewLoginError : State -> Html Msg
viewLoginError state =
    case state of
        LoginError message ->
            div [ class "bg-danger-light border border-danger rounded-input p-3 mb-4" ]
                [ p [ class "text-danger text-sm" ] [ text message ] ]

        _ ->
            text ""
