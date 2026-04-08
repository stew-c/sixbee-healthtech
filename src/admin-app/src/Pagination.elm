module Pagination exposing (Model, Msg(..), init, totalPages, update, view)

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)


type alias Model =
    { currentPage : Int
    , pageSize : Int
    , totalCount : Int
    }


type Msg
    = GoToPage Int


init : Model
init =
    { currentPage = 1
    , pageSize = 10
    , totalCount = 0
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        GoToPage page ->
            { model | currentPage = clamp 1 (totalPages model) page }


totalPages : Model -> Int
totalPages model =
    if model.totalCount == 0 then
        1

    else
        ceiling (toFloat model.totalCount / toFloat model.pageSize)


pageInfo : Model -> String
pageInfo model =
    let
        start =
            (model.currentPage - 1) * model.pageSize + 1

        end =
            min (model.currentPage * model.pageSize) model.totalCount
    in
    if model.totalCount == 0 then
        "No appointments"

    else
        "Showing "
            ++ String.fromInt start
            ++ "–"
            ++ String.fromInt end
            ++ " of "
            ++ String.fromInt model.totalCount
            ++ " appointments"


view : Model -> Html Msg
view model =
    let
        pages =
            totalPages model

        isFirstPage =
            model.currentPage <= 1

        isLastPage =
            model.currentPage >= pages
    in
    div [ class "flex justify-between items-center px-4 py-3 border-t border-gray-200" ]
        [ span [ class "text-sm text-foreground-muted" ]
            [ text (pageInfo model) ]
        , div [ class "flex items-center gap-1" ]
            ([ viewPrevButton isFirstPage ]
                ++ List.map (viewPageButton model.currentPage) (List.range 1 pages)
                ++ [ viewNextButton isLastPage pages ]
            )
        ]


viewPrevButton : Bool -> Html Msg
viewPrevButton isDisabled =
    button
        [ class
            ("w-8 h-8 flex items-center justify-center rounded-md border border-gray-200 text-sm"
                ++ (if isDisabled then
                        " opacity-40 cursor-not-allowed"

                    else
                        " cursor-pointer hover:bg-gray-50"
                   )
            )
        , disabled isDisabled
        , onClick (GoToPage 1)
        ]
        [ text "‹" ]


viewNextButton : Bool -> Int -> Html Msg
viewNextButton isDisabled lastPage =
    button
        [ class
            ("w-8 h-8 flex items-center justify-center rounded-md border border-gray-200 text-sm"
                ++ (if isDisabled then
                        " opacity-40 cursor-not-allowed"

                    else
                        " cursor-pointer hover:bg-gray-50"
                   )
            )
        , disabled isDisabled
        , onClick (GoToPage lastPage)
        ]
        [ text "›" ]


viewPageButton : Int -> Int -> Html Msg
viewPageButton currentPage page =
    let
        isActive =
            currentPage == page
    in
    button
        [ class
            ("w-8 h-8 flex items-center justify-center rounded-md text-sm"
                ++ (if isActive then
                        " bg-accent-primary text-white font-semibold"

                    else
                        " cursor-pointer hover:bg-gray-50 text-foreground-secondary"
                   )
            )
        , onClick (GoToPage page)
        ]
        [ text (String.fromInt page) ]
 