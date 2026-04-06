module Main exposing (main)

import Browser
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (class)


main : Program () () ()
main =
    Browser.sandbox
        { init = ()
        , update = \_ _ -> ()
        , view = \_ -> view
        }


view : Html ()
view =
    div [ class "min-h-screen bg-surface-primary flex items-center justify-center" ]
        [ h1 [ class "text-2xl font-bold text-foreground-primary" ] [ text "SixBee HealthTech" ] ]
