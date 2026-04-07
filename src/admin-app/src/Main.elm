port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (class)
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



-- MODEL


type alias Model =
    { key : Nav.Key
    , page : Page
    , session : Maybe SessionData
    }



-- MSG


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOp



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

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "SixBee HealthTech — Admin Portal"
    , body =
        [ case model.page of
            LoginPage ->
                viewLogin

            DashboardPage ->
                viewDashboard

            NotFoundPage ->
                viewNotFound
        ]
    }


viewLogin : Html Msg
viewLogin =
    div [ class "min-h-screen bg-surface-primary flex items-center justify-center" ]
        [ div [ class "text-center" ]
            [ h1 [ class "text-2xl font-bold text-foreground-primary" ]
                [ text "Admin Login" ]
            , p [ class "text-foreground-muted mt-2" ]
                [ text "Login form will be built in Task 11.2" ]
            ]
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
