module ConfirmModal exposing (Config, view)

import Html exposing (Html, button, div, h2, p, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)


type alias Config msg =
    { icon : Html msg
    , iconWrapperClass : String
    , title : String
    , message : String
    , confirmClass : String
    , confirmLabel : String
    , loadingLabel : String
    , onCancel : msg
    , onConfirm : msg
    , loading : Bool
    }


view : Config msg -> Html msg
view config =
    div [ class "modal-overlay z-50" ]
        [ div [ class "modal-card max-w-sm w-full mx-4 text-center" ]
            [ div [ class "flex flex-col items-center gap-3 mb-4" ]
                [ div [ class ("w-12 h-12 rounded-full flex items-center justify-center " ++ config.iconWrapperClass) ]
                    [ config.icon ]
                , h2 [ class "text-lg font-bold text-foreground-primary" ]
                    [ text config.title ]
                , p [ class "text-sm text-foreground-secondary" ]
                    [ text config.message ]
                ]
            , div [ class "flex gap-3 justify-center" ]
                [ button
                    [ class "btn-secondary"
                    , onClick config.onCancel
                    ]
                    [ text "Cancel" ]
                , button
                    [ class
                        (config.confirmClass
                            ++ (if config.loading then
                                    " opacity-75 cursor-not-allowed"

                                else
                                    ""
                               )
                        )
                    , onClick config.onConfirm
                    , disabled config.loading
                    ]
                    [ text
                        (if config.loading then
                            config.loadingLabel

                         else
                            config.confirmLabel
                        )
                    ]
                ]
            ]
        ]
