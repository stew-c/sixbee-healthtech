port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, button, div, form, h1, h2, input, label, p, small, span, text)
import Html.Attributes exposing (class, disabled, for, id, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Svg
import Svg.Attributes as SvgA
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Url
import Url.Parser as Parser exposing (Parser)


port saveSession : Encode.Value -> Cmd msg


port clearSession : () -> Cmd msg



-- FLAGS


type alias Flags =
    Maybe SessionData


type alias SessionData =
    { token : String
    , expiresAt : String
    , email : String
    }



-- ROUTING


type Page
    = LoginPage
    | DashboardPage
    | NotFoundPage


routeParser : Parser (Page -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map LoginPage Parser.top
        , Parser.map DashboardPage (Parser.s "dashboard")
        ]


urlToPage : Url.Url -> Page
urlToPage url =
    Parser.parse routeParser url
        |> Maybe.withDefault NotFoundPage



-- LOGIN STATE


type LoginState
    = Idle
    | Submitting
    | LoginError String



-- MODEL


type alias Model =
    { key : Nav.Key
    , page : Page
    , session : Maybe SessionData
    , email : String
    , password : String
    , loginState : LoginState
    }



-- MSG


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | UpdateEmail String
    | UpdatePassword String
    | SubmitLogin
    | GotLoginResponse (Result Http.Error LoginResponse)
    | NoOp


type alias LoginResponse =
    { token : String
    , expiresAt : String
    }



-- INIT


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        page =
            urlToPage url

        redirectedPage =
            case ( flags, page ) of
                ( Nothing, DashboardPage ) ->
                    LoginPage

                ( Just _, LoginPage ) ->
                    DashboardPage

                _ ->
                    page
    in
    ( { key = key
      , page = redirectedPage
      , session = flags
      , email = ""
      , password = ""
      , loginState = Idle
      }
    , if redirectedPage /= page then
        Nav.pushUrl key (pageToPath redirectedPage)

      else
        Cmd.none
    )


pageToPath : Page -> String
pageToPath page =
    case page of
        LoginPage ->
            "/"

        DashboardPage ->
            "/dashboard"

        NotFoundPage ->
            "/"



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


loginResponseDecoder : Decode.Decoder LoginResponse
loginResponseDecoder =
    Decode.map2 LoginResponse
        (Decode.field "token" Decode.string)
        (Decode.field "expiresAt" Decode.string)


encodeSessionData : SessionData -> Encode.Value
encodeSessionData session =
    Encode.object
        [ ( "token", Encode.string session.token )
        , ( "expiresAt", Encode.string session.expiresAt )
        , ( "email", Encode.string session.email )
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                page =
                    urlToPage url
            in
            ( { model | page = page }, Cmd.none )

        UpdateEmail email ->
            ( { model | email = email, loginState = Idle }, Cmd.none )

        UpdatePassword password ->
            ( { model | password = password, loginState = Idle }, Cmd.none )

        SubmitLogin ->
            if String.trim model.email == "" || String.trim model.password == "" then
                ( { model | loginState = LoginError "Email and password are required" }, Cmd.none )

            else
                ( { model | loginState = Submitting }
                , submitLogin model.email model.password
                )

        GotLoginResponse (Ok response) ->
            let
                sessionData =
                    { token = response.token
                    , expiresAt = response.expiresAt
                    , email = model.email
                    }
            in
            ( { model
                | session = Just sessionData
                , loginState = Idle
                , password = ""
                , page = DashboardPage
              }
            , Cmd.batch
                [ saveSession (encodeSessionData sessionData)
                , Nav.pushUrl model.key "/dashboard"
                ]
            )

        GotLoginResponse (Err err) ->
            let
                message =
                    case err of
                        Http.BadStatus 401 ->
                            "Invalid email or password"

                        _ ->
                            "Something went wrong. Please try again."
            in
            ( { model | loginState = LoginError message }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "SixBee HealthTech — Admin Portal"
    , body =
        [ case model.page of
            LoginPage ->
                viewLogin model

            DashboardPage ->
                viewDashboard

            NotFoundPage ->
                viewNotFound
        ]
    }


viewLogin : Model -> Html Msg
viewLogin model =
    let
        isSubmitting =
            model.loginState == Submitting
    in
    div [ class "min-h-screen bg-surface-primary flex items-center justify-center px-4" ]
        [ div [ class "w-full max-w-sm" ]
            [ form [ class "bg-white rounded-modal shadow-lg p-8", onSubmit SubmitLogin ]
                [ div [ class "flex flex-col items-center gap-2 mb-6" ]
                    [ div [ class "w-12 h-12 bg-surface-inverse rounded-card flex items-center justify-center" ]
                        [ heartPulseIcon ]
                    , h1 [ class "text-2xl font-bold text-foreground-primary" ]
                        [ text "Admin Login" ]
                    , p [ class "text-foreground-muted text-sm" ]
                        [ text "Sign in to manage appointments" ]
                    ]
                , viewLoginError model.loginState
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


viewLoginError : LoginState -> Html Msg
viewLoginError state =
    case state of
        LoginError message ->
            div [ class "bg-danger-light border border-danger rounded-input p-3 mb-4" ]
                [ p [ class "text-danger text-sm" ] [ text message ] ]

        _ ->
            text ""


heartPulseIcon : Html msg
heartPulseIcon =
    Svg.svg
        [ SvgA.viewBox "0 0 24 24"
        , SvgA.width "24"
        , SvgA.height "24"
        , SvgA.fill "none"
        , SvgA.stroke "currentColor"
        , SvgA.strokeWidth "2"
        , SvgA.strokeLinecap "round"
        , SvgA.strokeLinejoin "round"
        , SvgA.class "text-foreground-inverse"
        ]
        [ Svg.path [ SvgA.d "M19.5 12.572l-7.5 7.428l-7.5-7.428A5 5 0 0 1 7.5 3.5c1.76 0 3.332.91 4.5 2.37C13.168 4.41 14.74 3.5 16.5 3.5a5 5 0 0 1 3 9.072z" ] []
        , Svg.path [ SvgA.d "M5 12h2l2 3l4-6l2 3h2" ] []
        ]


viewDashboard : Html Msg
viewDashboard =
    div [ class "min-h-screen bg-surface-primary" ]
        [ div [ class "p-8" ]
            [ h1 [ class "text-2xl font-bold text-foreground-primary" ]
                [ text "Dashboard" ]
            , p [ class "text-foreground-muted mt-2" ]
                [ text "Dashboard will be built in Component 13" ]
            ]
        ]


viewNotFound : Html Msg
viewNotFound =
    div [ class "min-h-screen bg-surface-primary flex items-center justify-center" ]
        [ h1 [ class "text-xl text-foreground-muted" ] [ text "Page not found" ] ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }
