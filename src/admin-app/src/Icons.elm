module Icons exposing (approveCheck, close, deleteTrash, editPencil, heartPulse, logout)

import Html exposing (Html)
import Svg
import Svg.Attributes as SvgA


logout : Html msg
logout =
    icon 14
        [ Svg.path [ SvgA.d "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" ] []
        , Svg.path [ SvgA.d "M16 17l5-5-5-5" ] []
        , Svg.path [ SvgA.d "M21 12H9" ] []
        ]


heartPulse : Html msg
heartPulse =
    iconWithClass 24
        "text-foreground-inverse"
        [ Svg.path [ SvgA.d "M19.5 12.572l-7.5 7.428l-7.5-7.428A5 5 0 0 1 7.5 3.5c1.76 0 3.332.91 4.5 2.37C13.168 4.41 14.74 3.5 16.5 3.5a5 5 0 0 1 3 9.072z" ] []
        , Svg.path [ SvgA.d "M5 12h2l2 3l4-6l2 3h2" ] []
        ]


close : Int -> Html msg
close size =
    icon size
        [ Svg.path [ SvgA.d "M18 6L6 18" ] []
        , Svg.path [ SvgA.d "M6 6l12 12" ] []
        ]


approveCheck : Int -> Html msg
approveCheck size =
    icon size
        [ Svg.path [ SvgA.d "M22 11.08V12a10 10 0 1 1-5.93-9.14" ] []
        , Svg.path [ SvgA.d "M22 4L12 14.01l-3-3" ] []
        ]


editPencil : Html msg
editPencil =
    icon 16
        [ Svg.path [ SvgA.d "M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" ] []
        , Svg.path [ SvgA.d "M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" ] []
        ]


deleteTrash : Int -> Html msg
deleteTrash size =
    icon size
        [ Svg.path [ SvgA.d "M3 6h18" ] []
        , Svg.path [ SvgA.d "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" ] []
        ]



-- INTERNAL


icon : Int -> List (Svg.Svg msg) -> Html msg
icon size =
    iconWithClass size ""


iconWithClass : Int -> String -> List (Svg.Svg msg) -> Html msg
iconWithClass size cls children =
    let
        sizeStr =
            String.fromInt size

        baseAttrs =
            [ SvgA.viewBox "0 0 24 24"
            , SvgA.width sizeStr
            , SvgA.height sizeStr
            , SvgA.fill "none"
            , SvgA.stroke "currentColor"
            , SvgA.strokeWidth "2"
            , SvgA.strokeLinecap "round"
            , SvgA.strokeLinejoin "round"
            ]

        attrs =
            if cls == "" then
                baseAttrs

            else
                baseAttrs ++ [ SvgA.class cls ]
    in
    Svg.svg attrs children
