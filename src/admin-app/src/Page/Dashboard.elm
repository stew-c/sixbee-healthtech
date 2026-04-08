module Page.Dashboard exposing (EditModalState, Field(..), Model, Msg(..), init, initialFetch, update, view)

import Api
import Appointment exposing (Appointment, AppointmentListResponse, appointmentListResponseDecoder)
import ConfirmModal
import Html exposing (Html, button, div, h1, h2, input, label, p, span, table, tbody, td, text, textarea, th, thead, tr)
import Html.Attributes exposing (class, disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Icons
import Json.Encode as Encode
import Pagination
import Session exposing (Session)


type alias Model =
    { appointments : List Appointment
    , pagination : Pagination.Model
    , error : Maybe String
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


type Field
    = Name
    | DateTime
    | Description
    | ContactNumber
    | Email


type Msg
    = GotAppointments (Result Http.Error AppointmentListResponse)
    | OpenApproveModal Appointment
    | CloseApproveModal
    | ConfirmApprove
    | GotApproveResponse (Result Http.Error ())
    | OpenEditModal Appointment
    | CloseEditModal
    | EditField Field String
    | SaveEdit
    | GotSaveEditResponse (Result Http.Error ())
    | OpenDeleteModal Appointment
    | CloseDeleteModal
    | ConfirmDelete
    | GotDeleteResponse (Result Http.Error ())
    | PaginationMsg Pagination.Msg


init : Model
init =
    { appointments = []
    , pagination = Pagination.init
    , error = Nothing
    , editModal = Nothing
    , approveModal = Nothing
    , approving = False
    , deleteModal = Nothing
    , deleting = False
    }


fetchAppointments : Session -> Int -> Int -> Cmd Msg
fetchAppointments session page pageSize =
    Api.authGet session
        { url = "/api/appointments?page=" ++ String.fromInt page ++ "&pageSize=" ++ String.fromInt pageSize
        , expect = Http.expectJson GotAppointments appointmentListResponseDecoder
        }


initialFetch : Session -> Cmd Msg
initialFetch session =
    fetchAppointments session 1 10



-- HTTP


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


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , unauthorized : Bool
    }


update : Msg -> Model -> Session -> UpdateResult
update msg model session =
    case msg of
        GotAppointments (Ok response) ->
            let
                pag =
                    model.pagination
            in
            { model =
                { model
                    | appointments = response.items
                    , pagination = { pag | totalCount = response.totalCount, currentPage = response.page }
                    , error = Nothing
                }
            , cmd = Cmd.none
            , unauthorized = False
            }

        GotAppointments (Err err) ->
            case err of
                Http.BadStatus 401 ->
                    { model = model
                    , cmd = Cmd.none
                    , unauthorized = True
                    }

                _ ->
                    { model = { model | error = Just "Failed to load appointments." }
                    , cmd = Cmd.none
                    , unauthorized = False
                    }

        OpenApproveModal appointment ->
            { model = { model | approveModal = Just appointment, approving = False }
            , cmd = Cmd.none
            , unauthorized = False
            }

        CloseApproveModal ->
            { model = { model | approveModal = Nothing, approving = False }
            , cmd = Cmd.none
            , unauthorized = False
            }

        ConfirmApprove ->
            case model.approveModal of
                Just appointment ->
                    { model = { model | approving = True }
                    , cmd = approveAppointment session appointment.id
                    , unauthorized = False
                    }

                Nothing ->
                    { model = model, cmd = Cmd.none, unauthorized = False }

        GotApproveResponse (Ok _) ->
            { model = { model | approveModal = Nothing, approving = False }
            , cmd = fetchAppointments session model.pagination.currentPage model.pagination.pageSize
            , unauthorized = False
            }

        GotApproveResponse (Err _) ->
            { model = { model | approveModal = Nothing, approving = False, error = Just "Failed to approve appointment." }
            , cmd = fetchAppointments session model.pagination.currentPage model.pagination.pageSize
            , unauthorized = False
            }

        OpenEditModal appointment ->
            { model =
                { model
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
            , cmd = Cmd.none
            , unauthorized = False
            }

        CloseEditModal ->
            { model = { model | editModal = Nothing }
            , cmd = Cmd.none
            , unauthorized = False
            }

        EditField field val ->
            case model.editModal of
                Just state ->
                    let
                        updated =
                            case field of
                                Name ->
                                    { state | name = val }

                                DateTime ->
                                    { state | dateTime = val }

                                Description ->
                                    { state | description = val }

                                ContactNumber ->
                                    { state | contactNumber = val }

                                Email ->
                                    { state | email = val }
                    in
                    { model = { model | editModal = Just updated }
                    , cmd = Cmd.none
                    , unauthorized = False
                    }

                Nothing ->
                    { model = model, cmd = Cmd.none, unauthorized = False }

        SaveEdit ->
            case model.editModal of
                Just state ->
                    { model = { model | editModal = Just { state | saving = True, error = Nothing } }
                    , cmd = saveAppointment session state
                    , unauthorized = False
                    }

                Nothing ->
                    { model = model, cmd = Cmd.none, unauthorized = False }

        GotSaveEditResponse (Ok _) ->
            { model = { model | editModal = Nothing }
            , cmd = fetchAppointments session model.pagination.currentPage model.pagination.pageSize
            , unauthorized = False
            }

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
                    { model = { model | editModal = Just { state | saving = False, error = Just message } }
                    , cmd = Cmd.none
                    , unauthorized = False
                    }

                Nothing ->
                    { model = model, cmd = Cmd.none, unauthorized = False }

        OpenDeleteModal appointment ->
            { model = { model | deleteModal = Just appointment, deleting = False }
            , cmd = Cmd.none
            , unauthorized = False
            }

        CloseDeleteModal ->
            { model = { model | deleteModal = Nothing, deleting = False }
            , cmd = Cmd.none
            , unauthorized = False
            }

        ConfirmDelete ->
            case model.deleteModal of
                Just appointment ->
                    { model = { model | deleting = True }
                    , cmd = deleteAppointment session appointment.id
                    , unauthorized = False
                    }

                Nothing ->
                    { model = model, cmd = Cmd.none, unauthorized = False }

        GotDeleteResponse (Ok _) ->
            { model = { model | deleteModal = Nothing, deleting = False }
            , cmd = fetchAppointments session model.pagination.currentPage model.pagination.pageSize
            , unauthorized = False
            }

        GotDeleteResponse (Err _) ->
            { model = { model | deleteModal = Nothing, deleting = False, error = Just "Failed to delete appointment." }
            , cmd = fetchAppointments session model.pagination.currentPage model.pagination.pageSize
            , unauthorized = False
            }

        PaginationMsg paginationMsg ->
            let
                newPagination =
                    Pagination.update paginationMsg model.pagination
            in
            { model = { model | pagination = newPagination }
            , cmd = fetchAppointments session newPagination.currentPage newPagination.pageSize
            , unauthorized = False
            }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-surface-primary" ]
        [ div [ class "page-container" ]
            [ viewDashboardHeader model
            , viewDashboardError model.error
            , viewAppointmentsTable model.appointments
            , Html.map PaginationMsg (Pagination.view model.pagination)
            ]
        , viewEditModal model.editModal
        , viewApproveModal model.approveModal model.approving
        , viewDeleteModal model.deleteModal model.deleting
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
        [ viewEditField Name "Full Name *" "text" state.name
        , viewEditField DateTime "Appointment Date & Time *" "datetime-local" state.dateTime
        , div [ class "flex flex-col gap-1" ]
            [ label [ class "input-label" ] [ text "Description *" ]
            , textarea
                [ class "input-textarea"
                , value state.description
                , onInput (EditField Description)
                ]
                []
            ]
        , viewEditField ContactNumber "Contact Number *" "tel" state.contactNumber
        , viewEditField Email "Email Address *" "email" state.email
        ]


viewEditField : Field -> String -> String -> String -> Html Msg
viewEditField field labelText inputType fieldValue =
    div [ class "flex flex-col gap-1" ]
        [ label [ class "input-label" ] [ text labelText ]
        , input
            [ class "input-field-filled"
            , type_ inputType
            , value fieldValue
            , onInput (EditField field)
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
            ConfirmModal.view
                { icon = Icons.approveCheck 22
                , iconWrapperClass = "bg-approved text-accent-primary"
                , title = "Approve Appointment"
                , message = "Are you sure you want to approve the appointment for " ++ appointment.name ++ " on " ++ formatDateTime appointment.dateTime ++ "?"
                , confirmClass = "btn-primary"
                , confirmLabel = "Approve"
                , loadingLabel = "Approving..."
                , onCancel = CloseApproveModal
                , onConfirm = ConfirmApprove
                , loading = approving
                }


viewDeleteModal : Maybe Appointment -> Bool -> Html Msg
viewDeleteModal maybeAppointment deleting =
    case maybeAppointment of
        Nothing ->
            text ""

        Just appointment ->
            ConfirmModal.view
                { icon = Icons.deleteTrash 22
                , iconWrapperClass = "bg-danger-light text-danger"
                , title = "Delete Appointment"
                , message = "Are you sure you want to delete the appointment for " ++ appointment.name ++ "? This action cannot be undone."
                , confirmClass = "btn-danger"
                , confirmLabel = "Delete"
                , loadingLabel = "Deleting..."
                , onCancel = CloseDeleteModal
                , onConfirm = ConfirmDelete
                , loading = deleting
                }


formatDateTime : String -> String
formatDateTime iso =
    String.left 16 iso |> String.replace "T" " "
