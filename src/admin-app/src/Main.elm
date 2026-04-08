port module Main exposing (Model, Msg(..), Page(..), init, main, update)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, button, div, h1, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Icons
import Json.Decode as Decode
import Json.Encode as Encode
import Page.Dashboard as Dashboard
import Page.Login as Login
import Session exposing (Session)
import Url
import Url.Parser as Parser exposing (Parser)


port saveSession : Encode.Value -> Cmd msg


port clearSession : () -> Cmd msg



-- FLAGS


type alias Flags =
    Decode.Value



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



-- MODEL


type alias Model =
    { key : Nav.Key
    , page : Page
    , session : Session
    , login : Login.Model
    , dashboard : Dashboard.Model
    }



-- MSG


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | LoginMsg Login.Msg
    | DashboardMsg Dashboard.Msg
    | Logout
    | NoOp



-- INIT


flagsDecoder : Decode.Decoder { token : String, expiresAt : String, email : String }
flagsDecoder =
    Decode.map3 (\t e em -> { token = t, expiresAt = e, email = em })
        (Decode.field "token" Decode.string)
        (Decode.field "expiresAt" Decode.string)
        (Decode.field "email" Decode.string)


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        session =
            case Decode.decodeValue flagsDecoder flags of
                Ok data ->
                    Session.login data.token data.expiresAt data.email

                Err _ ->
                    Session.LoggedOut

        page =
            urlToPage url

        isAuthenticated =
            Session.isLoggedIn session

        redirectedPage =
            case ( isAuthenticated, page ) of
                ( False, DashboardPage ) ->
                    LoginPage

                ( True, LoginPage ) ->
                    DashboardPage

                _ ->
                    page
    in
    let
        initialCmd =
            if redirectedPage /= page then
                Nav.pushUrl key (pageToPath redirectedPage)

            else
                Cmd.none

        fetchCmd =
            if redirectedPage == DashboardPage then
                Cmd.map DashboardMsg (Dashboard.initialFetch session)

            else
                Cmd.none
    in
    ( { key = key
      , page = redirectedPage
      , session = session
      , login = Login.init
      , dashboard = Dashboard.init
      }
    , Cmd.batch [ initialCmd, fetchCmd ]
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

                isAuthenticated =
                    Session.isLoggedIn model.session
            in
            case ( isAuthenticated, page ) of
                ( False, DashboardPage ) ->
                    ( { model | page = LoginPage }, Nav.pushUrl model.key "/" )

                ( True, LoginPage ) ->
                    ( { model | page = DashboardPage }, Nav.pushUrl model.key "/dashboard" )

                _ ->
                    ( { model | page = page }, Cmd.none )

        LoginMsg loginMsg ->
            let
                result =
                    Login.update loginMsg model.login
            in
            case result.loginSuccess of
                Just credentials ->
                    let
                        session =
                            Session.login credentials.token credentials.expiresAt credentials.email
                    in
                    ( { model
                        | login = result.model
                        , session = session
                        , page = DashboardPage
                      }
                    , Cmd.batch
                        [ Cmd.map LoginMsg result.cmd
                        , saveSession
                            (Encode.object
                                [ ( "token", Encode.string credentials.token )
                                , ( "expiresAt", Encode.string credentials.expiresAt )
                                , ( "email", Encode.string credentials.email )
                                ]
                            )
                        , Nav.pushUrl model.key "/dashboard"
                        , Cmd.map DashboardMsg (Dashboard.initialFetch session)
                        ]
                    )

                Nothing ->
                    ( { model | login = result.model }
                    , Cmd.map LoginMsg result.cmd
                    )

        DashboardMsg dashboardMsg ->
            let
                result =
                    Dashboard.update dashboardMsg model.dashboard model.session
            in
            if result.unauthorized then
                ( { model
                    | session = Session.logout model.session
                    , page = LoginPage
                  }
                , Cmd.batch
                    [ clearSession ()
                    , Nav.pushUrl model.key "/"
                    ]
                )

            else
                ( { model | dashboard = result.model }
                , Cmd.map DashboardMsg result.cmd
                )

        Logout ->
            ( { model
                | session = Session.logout model.session
                , page = LoginPage
                , login = Login.init
              }
            , Cmd.batch
                [ clearSession ()
                , Nav.pushUrl model.key "/"
                ]
            )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "SixBee HealthTech — Admin Portal"
    , body =
        [ div []
            [ viewNavBar model.session
            , case model.page of
                LoginPage ->
                    Html.map LoginMsg (Login.view model.login)

                DashboardPage ->
                    Html.map DashboardMsg (Dashboard.view model.dashboard)

                NotFoundPage ->
                    viewNotFound
            ]
        ]
    }


viewNavBar : Session -> Html Msg
viewNavBar session =
    case Session.getEmail session of
        Nothing ->
            text ""

        Just email ->
            div [ class "nav-bar" ]
                [ div [ class "flex items-center gap-3" ]
                    [ div [ class "text-surface-secondary" ] [ Icons.heartPulse ]
                    , span [ class "text-white font-semibold text-sm" ]
                        [ text "SixBee HealthTech" ]
                    ]
                , div [ class "flex items-center gap-4" ]
                    [ span [ class "text-surface-secondary text-sm" ]
                        [ text email ]
                    , button
                        [ class "flex items-center gap-1.5 h-8 px-3 bg-accent-primary text-white text-sm font-medium rounded-md cursor-pointer hover:opacity-90"
                        , onClick Logout
                        ]
                        [ Icons.logout
                        , text "Logout"
                        ]
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
