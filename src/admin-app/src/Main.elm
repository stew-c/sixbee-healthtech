port module Main exposing (EditModalState, LoginResponse, LoginState(..), Model, Msg(..), Page(..), init, main, update)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, button, div, form, h1, h2, input, label, p, small, span, table, tbody, td, text, textarea, th, thead, tr)
import Html.Attributes exposing (class, disabled, for, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Icons
import Api
import Appointment exposing (Appointment, AppointmentListResponse, appointmentListResponseDecoder)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Pagination
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



-- LOGIN STATE


type LoginState
    = Idle
    | Submitting
    | LoginError String



-- MODEL


type alias Model =
    { key : Nav.Key
    , page : Page
    , session : Session
    , email : String
    , password : String
    , loginState : LoginState
    , appointments : List Appointment
    , pagination : Pagination.Model
    , dashboardError : Maybe String
    , editModal : Maybe EditModalState
    , approveModal : Maybe Appointment
    , approving : Bool
    , deleteModal : Maybe Appointment
    , deleting : Bool
    }


type alias EditModalState =
    { appointment : Appointment
    , name : String
    , dateTime : String
    , description : String
    , contactNumber : String
    , email : String
    , saving : Bool
    , error : Maybe String
    }



-- MSG


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | UpdateEmail String
    | UpdatePassword String
    | SubmitLogin
    | GotLoginResponse (Result Http.Error LoginResponse)
    | GotAppointments (Result Http.Error AppointmentListResponse)
    | OpenApproveModal Appointment
    | OpenEditModal Appointment
    | CloseEditModal
    | EditField String String
    | SaveEdit
    | GotSaveEditResponse (Result Http.Error ())
    | CloseApproveModal
    | ConfirmApprove
    | GotApproveResponse (Result Http.Error ())
    | OpenDeleteModal Appointment
    | CloseDeleteModal
    | ConfirmDelete
    | GotDeleteResponse (Result Http.Error ())
    | PaginationMsg Pagination.Msg
    | Logout
    | NoOp


type alias LoginResponse =
    { token : String
    , expiresAt : String
    }



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
                fetchAppointments session 1 10

            else
                Cmd.none
    in
    ( { key = key
      , page = redirectedPage
      , session = session
      , email = ""
      , password = ""
      , loginState = Idle
      , appointments = []
      , pagination = Pagination.init
      , dashboardError = Nothing
      , editModal = Nothing
      , approveModal = Nothing
      , approving = False
      , deleteModal = Nothing
      , deleting = False
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


fetchAppointments : Session -> Int -> Int -> Cmd Msg
fetchAppointments session page pageSize =
    Api.authGet session
        { url = "/api/appointments?page=" ++ String.fromInt page ++ "&pageSize=" ++ String.fromInt pageSize
        , expect = Http.expectJson GotAppointments appointmentListResponseDecoder
        }


deleteAppointment : Session -> String -> Cmd Msg
deleteAppointment session appointmentId =
    Api.authDelete session
        { url = "/api/appointments/" ++ appointmentId
        , expect = Http.expectWhatever GotDeleteResponse
        }


approveAppointment : Session -> String -> Cmd Msg
approveAppointment session appointmentId =
    Api.authPatch session
        { url = "/api/appointments/" ++ appointmentId ++ "/approve"
        , body = Http.emptyBody
        , expect = Http.expectWhatever GotApproveResponse
        }


saveAppointment : Session -> EditModalState -> Cmd Msg
saveAppointment session state =
    let
        isoDateTime =
            if String.contains "Z" state.dateTime || String.contains "+" state.dateTime then
                state.dateTime

            else if String.length state.dateTime == 16 then
                state.dateTime ++ ":00Z"

            else
                state.dateTime ++ "Z"
    in
    Api.authPut session
        { url = "/api/appointments/" ++ state.appointment.id
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "name", Encode.string state.name )
                    , ( "dateTime", Encode.string isoDateTime )
                    , ( "description", Encode.string state.description )
                    , ( "contactNumber", Encode.string state.contactNumber )
                    , ( "email", Encode.string state.email )
                    ]
                )
        , expect = Http.expectWhatever GotSaveEditResponse
        }



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
                session =
                    Session.login response.token response.expiresAt model.email
            in
            ( { model
                | session = session
                , loginState = Idle
                , password = ""
                , page = DashboardPage
              }
            , Cmd.batch
                [ saveSession
                    (Encode.object
                        [ ( "token", Encode.string response.token )
                        , ( "expiresAt", Encode.string response.expiresAt )
                        , ( "email", Encode.string model.email )
                        ]
                    )
                , Nav.pushUrl model.key "/dashboard"
                , fetchAppointments session 1 10
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

        GotAppointments (Ok response) ->
            let
                pag =
                    model.pagination
            in
            ( { model
                | appointments = response.items
                , pagination = { pag | totalCount = response.totalCount, currentPage = response.page }
                , dashboardError = Nothing
              }
            , Cmd.none
            )

        GotAppointments (Err err) ->
            case err of
                Http.BadStatus 401 ->
                    ( { model
                        | session = Session.logout model.session
                        , page = LoginPage
                      }
                    , Cmd.batch
                        [ clearSession ()
                        , Nav.pushUrl model.key "/"
                        ]
                    )

                _ ->
                    ( { model | dashboardError = Just "Failed to load appointments." }, Cmd.none )

        OpenApproveModal appointment ->
            ( { model | approveModal = Just appointment, approving = False }, Cmd.none )

        CloseApproveModal ->
            ( { model | approveModal = Nothing, approving = False }, Cmd.none )

        ConfirmApprove ->
            case model.approveModal of
                Just appointment ->
                    ( { model | approving = True }
                    , approveAppointment model.session appointment.id
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotApproveResponse (Ok _) ->
            ( { model | approveModal = Nothing, approving = False }
            , fetchAppointments model.session model.pagination.currentPage model.pagination.pageSize
            )

        GotApproveResponse (Err _) ->
            ( { model | approveModal = Nothing, approving = False, dashboardError = Just "Failed to approve appointment." }
            , fetchAppointments model.session model.pagination.currentPage model.pagination.pageSize
            )

        OpenEditModal appointment ->
            ( { model
                | editModal =
                    Just
                        { appointment = appointment
                        , name = appointment.name
                        , dateTime = String.left 16 appointment.dateTime
                        , description = appointment.description
                        , contactNumber = appointment.contactNumber
                        , email = appointment.email
                        , saving = False
                        , error = Nothing
                        }
              }
            , Cmd.none
            )

        CloseEditModal ->
            ( { model | editModal = Nothing }, Cmd.none )

        EditField field val ->
            case model.editModal of
                Just state ->
                    let
                        updated =
                            case field of
                                "name" ->
                                    { state | name = val }

                                "dateTime" ->
                                    { state | dateTime = val }

                                "description" ->
                                    { state | description = val }

                                "contactNumber" ->
                                    { state | contactNumber = val }

                                "email" ->
                                    { state | email = val }

                                _ ->
                                    state
                    in
                    ( { model | editModal = Just updated }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveEdit ->
            case model.editModal of
                Just state ->
                    ( { model | editModal = Just { state | saving = True, error = Nothing } }
                    , saveAppointment model.session state
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotSaveEditResponse (Ok _) ->
            ( { model | editModal = Nothing }
            , fetchAppointments model.session model.pagination.currentPage model.pagination.pageSize
            )

        GotSaveEditResponse (Err err) ->
            case model.editModal of
                Just state ->
                    let
                        message =
                            case err of
                                Http.BadStatus 400 ->
                                    "Please check your details and try again."

                                Http.BadStatus 404 ->
                                    "Appointment not found — it may have been deleted."

                                _ ->
                                    "Something went wrong. Please try again."
                    in
                    ( { model | editModal = Just { state | saving = False, error = Just message } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        OpenDeleteModal appointment ->
            ( { model | deleteModal = Just appointment, deleting = False }, Cmd.none )

        CloseDeleteModal ->
            ( { model | deleteModal = Nothing, deleting = False }, Cmd.none )

        ConfirmDelete ->
            case model.deleteModal of
                Just appointment ->
                    ( { model | deleting = True }
                    , deleteAppointment model.session appointment.id
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotDeleteResponse (Ok _) ->
            ( { model | deleteModal = Nothing, deleting = False }
            , fetchAppointments model.session model.pagination.currentPage model.pagination.pageSize
            )

        GotDeleteResponse (Err _) ->
            ( { model | deleteModal = Nothing, deleting = False, dashboardError = Just "Failed to delete appointment." }
            , fetchAppointments model.session model.pagination.currentPage model.pagination.pageSize
            )

        Logout ->
            ( { model
                | session = Session.logout model.session
                , page = LoginPage
                , email = ""
                , password = ""
                , loginState = Idle
              }
            , Cmd.batch
                [ clearSession ()
                , Nav.pushUrl model.key "/"
                ]
            )

        PaginationMsg paginationMsg ->
            let
                newPagination =
                    Pagination.update paginationMsg model.pagination
            in
            ( { model | pagination = newPagination }
            , fetchAppointments model.session newPagination.currentPage newPagination.pageSize
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
                    viewLogin model

                DashboardPage ->
                    viewDashboard model

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
                        [ Icons.heartPulse ]
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


viewDashboard : Model -> Html Msg
viewDashboard model =
    div [ class "min-h-screen bg-surface-primary" ]
        [ div [ class "page-container" ]
            [ viewDashboardHeader model
            , viewDashboardError model.dashboardError
            , viewAppointmentsTable model.appointments
            , Html.map PaginationMsg (Pagination.view model.pagination)
            ]
        , viewEditModal model.editModal
        , viewApproveModal model.approveModal model.approving
        , viewDeleteModal model.deleteModal model.deleting
        ]


viewEditModal : Maybe EditModalState -> Html Msg
viewEditModal maybeState =
    case maybeState of
        Nothing ->
            text ""

        Just state ->
            div [ class "modal-overlay z-50" ]
                [ div [ class "modal-card max-w-lg w-full mx-4" ]
                    [ viewEditModalHeader
                    , viewEditModalError state.error
                    , viewEditModalForm state
                    , viewEditModalFooter state.saving
                    ]
                ]


viewEditModalHeader : Html Msg
viewEditModalHeader =
    div [ class "flex justify-between items-center mb-4" ]
        [ h2 [ class "text-xl font-semibold text-foreground-primary" ]
            [ text "Edit Appointment" ]
        , button
            [ class "btn-icon text-foreground-muted hover:text-foreground-primary"
            , onClick CloseEditModal
            ]
            [ Icons.close 18 ]
        ]


viewEditModalError : Maybe String -> Html Msg
viewEditModalError maybeError =
    case maybeError of
        Just error ->
            div [ class "bg-danger-light border border-danger rounded-input p-3 mb-4" ]
                [ p [ class "text-danger text-sm" ] [ text error ] ]

        Nothing ->
            text ""


viewEditModalForm : EditModalState -> Html Msg
viewEditModalForm state =
    div [ class "flex flex-col gap-4" ]
        [ viewEditField "name" "Full Name *" "text" state.name
        , viewEditField "dateTime" "Appointment Date & Time *" "datetime-local" state.dateTime
        , div [ class "flex flex-col gap-1" ]
            [ label [ class "input-label" ] [ text "Description *" ]
            , textarea
                [ class "input-textarea"
                , value state.description
                , onInput (EditField "description")
                ]
                []
            ]
        , viewEditField "contactNumber" "Contact Number *" "tel" state.contactNumber
        , viewEditField "email" "Email Address *" "email" state.email
        ]


viewEditField : String -> String -> String -> String -> Html Msg
viewEditField fieldName labelText inputType fieldValue =
    div [ class "flex flex-col gap-1" ]
        [ label [ class "input-label" ] [ text labelText ]
        , input
            [ class "input-field-filled"
            , type_ inputType
            , value fieldValue
            , onInput (EditField fieldName)
            ]
            []
        ]


viewEditModalFooter : Bool -> Html Msg
viewEditModalFooter saving =
    div [ class "flex justify-end gap-3 mt-6" ]
        [ button
            [ class "btn-secondary"
            , onClick CloseEditModal
            ]
            [ text "Cancel" ]
        , button
            [ class
                ("btn-primary"
                    ++ (if saving then
                            " opacity-75 cursor-not-allowed"

                        else
                            ""
                       )
                )
            , onClick SaveEdit
            , disabled saving
            ]
            [ text
                (if saving then
                    "Saving..."

                 else
                    "Save Changes"
                )
            ]
        ]


viewApproveModal : Maybe Appointment -> Bool -> Html Msg
viewApproveModal maybeAppointment approving =
    case maybeAppointment of
        Nothing ->
            text ""

        Just appointment ->
            div [ class "modal-overlay z-50" ]
                [ div [ class "modal-card max-w-sm w-full mx-4 text-center" ]
                    [ div [ class "flex flex-col items-center gap-3 mb-4" ]
                        [ div [ class "w-12 h-12 bg-approved rounded-full flex items-center justify-center text-accent-primary" ]
                            [ Icons.approveCheck 22 ]
                        , h2 [ class "text-lg font-bold text-foreground-primary" ]
                            [ text "Approve Appointment" ]
                        , p [ class "text-sm text-foreground-secondary" ]
                            [ text ("Are you sure you want to approve the appointment for " ++ appointment.name ++ " on " ++ formatDateTime appointment.dateTime ++ "?") ]
                        ]
                    , div [ class "flex gap-3 justify-center" ]
                        [ button
                            [ class "btn-secondary"
                            , onClick CloseApproveModal
                            ]
                            [ text "Cancel" ]
                        , button
                            [ class
                                ("btn-primary"
                                    ++ (if approving then
                                            " opacity-75 cursor-not-allowed"

                                        else
                                            ""
                                       )
                                )
                            , onClick ConfirmApprove
                            , disabled approving
                            ]
                            [ text
                                (if approving then
                                    "Approving..."

                                 else
                                    "Approve"
                                )
                            ]
                        ]
                    ]
                ]


viewDeleteModal : Maybe Appointment -> Bool -> Html Msg
viewDeleteModal maybeAppointment deleting =
    case maybeAppointment of
        Nothing ->
            text ""

        Just appointment ->
            div [ class "modal-overlay z-50" ]
                [ div [ class "modal-card max-w-sm w-full mx-4 text-center" ]
                    [ div [ class "flex flex-col items-center gap-3 mb-4" ]
                        [ div [ class "w-12 h-12 bg-danger-light rounded-full flex items-center justify-center text-danger" ]
                            [ Icons.deleteTrash 22 ]
                        , h2 [ class "text-lg font-bold text-foreground-primary" ]
                            [ text "Delete Appointment" ]
                        , p [ class "text-sm text-foreground-secondary" ]
                            [ text ("Are you sure you want to delete the appointment for " ++ appointment.name ++ "? This action cannot be undone.") ]
                        ]
                    , div [ class "flex gap-3 justify-center" ]
                        [ button
                            [ class "btn-secondary"
                            , onClick CloseDeleteModal
                            ]
                            [ text "Cancel" ]
                        , button
                            [ class
                                ("btn-danger"
                                    ++ (if deleting then
                                            " opacity-75 cursor-not-allowed"

                                        else
                                            ""
                                       )
                                )
                            , onClick ConfirmDelete
                            , disabled deleting
                            ]
                            [ text
                                (if deleting then
                                    "Deleting..."

                                 else
                                    "Delete"
                                )
                            ]
                        ]
                    ]
                ]


viewDashboardHeader : Model -> Html Msg
viewDashboardHeader model =
    div [ class "flex justify-between items-center" ]
        [ h1 [ class "text-2xl font-bold text-foreground-primary" ]
            [ text "Appointments" ]
        , span [ class "badge-count" ]
            [ text (String.fromInt model.pagination.totalCount ++ " appointments") ]
        ]


viewDashboardError : Maybe String -> Html Msg
viewDashboardError maybeError =
    case maybeError of
        Just error ->
            div [ class "bg-danger-light border border-danger rounded-input p-3" ]
                [ p [ class "text-danger text-sm" ] [ text error ] ]

        Nothing ->
            text ""


viewAppointmentsTable : List Appointment -> Html Msg
viewAppointmentsTable appointments =
    div [ class "bg-white rounded-card border border-gray-200 overflow-hidden" ]
        [ table [ class "w-full" ]
            [ thead []
                [ tr [ class "bg-surface-primary text-xs font-bold text-foreground-secondary uppercase border-b border-gray-200" ]
                    [ th [ class "text-left px-4 py-3 w-36" ] [ text "Name" ]
                    , th [ class "text-left px-4 py-3 w-40" ] [ text "Date & Time" ]
                    , th [ class "text-left px-4 py-3" ] [ text "Description" ]
                    , th [ class "text-left px-4 py-3 w-32" ] [ text "Phone" ]
                    , th [ class "text-left px-4 py-3 w-44" ] [ text "Email" ]
                    , th [ class "text-center px-4 py-3 w-28" ] [ text "Actions" ]
                    ]
                ]
            , tbody [] (List.map viewTableRow appointments)
            ]
        ]


viewTableRow : Appointment -> Html Msg
viewTableRow appointment =
    let
        rowClass =
            if appointment.status == "approved" then
                "bg-approved border-b border-gray-100"

            else
                "bg-white border-b border-gray-100"
    in
    tr [ class rowClass ]
        [ td [ class "px-4 py-3 text-sm text-foreground-primary" ]
            [ text appointment.name ]
        , td [ class "px-4 py-3 text-data text-xs text-foreground-primary" ]
            [ text (formatDateTime appointment.dateTime) ]
        , td [ class "px-4 py-3 text-sm text-foreground-secondary" ]
            [ text appointment.description ]
        , td [ class "px-4 py-3 text-data text-xs text-foreground-secondary" ]
            [ text appointment.contactNumber ]
        , td [ class "px-4 py-3 text-data text-xs text-foreground-secondary" ]
            [ text appointment.email ]
        , td [ class "px-4 py-3 text-center" ]
            [ div [ class "flex justify-center gap-2" ]
                [ viewApproveIcon appointment
                , viewEditIcon appointment
                , viewDeleteIcon appointment
                ]
            ]
        ]


viewApproveIcon : Appointment -> Html Msg
viewApproveIcon appointment =
    let
        colour =
            if appointment.status == "approved" then
                "text-accent-primary"

            else
                "text-foreground-muted hover:text-accent-primary"
    in
    button
        [ class ("btn-icon " ++ colour)
        , onClick (OpenApproveModal appointment)
        ]
        [ Icons.approveCheck 16 ]


viewEditIcon : Appointment -> Html Msg
viewEditIcon appointment =
    button
        [ class "btn-icon text-foreground-muted hover:text-foreground-primary"
        , onClick (OpenEditModal appointment)
        ]
        [ Icons.editPencil ]


viewDeleteIcon : Appointment -> Html Msg
viewDeleteIcon appointment =
    button
        [ class "btn-icon text-danger hover:opacity-75"
        , onClick (OpenDeleteModal appointment)
        ]
        [ Icons.deleteTrash 16 ]


formatDateTime : String -> String
formatDateTime iso =
    -- Display the first 16 chars of ISO string (YYYY-MM-DDTHH:MM)
    String.left 16 iso |> String.replace "T" " "


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
