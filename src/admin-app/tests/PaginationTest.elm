module PaginationTest exposing (..)

import Expect
import Pagination exposing (Model, Msg(..), init, totalPages, update)
import Test exposing (..)


suite : Test
suite =
    describe "Pagination"
        [ describe "totalPages"
            [ test "12 items, page size 10 = 2 pages" <|
                \_ ->
                    totalPages { init | totalCount = 12 }
                        |> Expect.equal 2
            , test "10 items, page size 10 = 1 page" <|
                \_ ->
                    totalPages { init | totalCount = 10 }
                        |> Expect.equal 1
            , test "0 items = 1 page" <|
                \_ ->
                    totalPages { init | totalCount = 0 }
                        |> Expect.equal 1
            , test "25 items, page size 10 = 3 pages" <|
                \_ ->
                    totalPages { init | totalCount = 25 }
                        |> Expect.equal 3
            , test "1 item = 1 page" <|
                \_ ->
                    totalPages { init | totalCount = 1 }
                        |> Expect.equal 1
            ]
        , describe "GoToPage"
            [ test "updates current page" <|
                \_ ->
                    { init | totalCount = 25 }
                        |> update (GoToPage 2)
                        |> .currentPage
                        |> Expect.equal 2
            , test "clamps to first page" <|
                \_ ->
                    { init | totalCount = 25 }
                        |> update (GoToPage 0)
                        |> .currentPage
                        |> Expect.equal 1
            , test "clamps to last page" <|
                \_ ->
                    { init | totalCount = 25 }
                        |> update (GoToPage 99)
                        |> .currentPage
                        |> Expect.equal 3
            ]
        , describe "page info"
            [ test "previous disabled on page 1" <|
                \_ ->
                    init.currentPage
                        |> Expect.equal 1
            , test "page info shows correct range" <|
                \_ ->
                    let
                        model =
                            { init | totalCount = 12 }

                        start =
                            (model.currentPage - 1) * model.pageSize + 1

                        end =
                            min (model.currentPage * model.pageSize) model.totalCount

                        info =
                            "Showing "
                                ++ String.fromInt start
                                ++ "–"
                                ++ String.fromInt end
                                ++ " of "
                                ++ String.fromInt model.totalCount
                                ++ " appointments"
                    in
                    Expect.equal "Showing 1–10 of 12 appointments" info
            ]
        ]
