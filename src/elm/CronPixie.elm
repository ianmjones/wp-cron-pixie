module CronPixie exposing (..)

import Html exposing (Html, div, text, h3, ul, li, span)
import Html.Attributes exposing (class, title)
import Html.Events exposing (..)
import Html.App
import Date
import Date.Format
import Time exposing (Time, second)
import String
import List exposing (head, tail, intersperse, foldl)
import Maybe exposing (withDefault)
import Task
import Http exposing (stringData, multipart)
import Json.Decode exposing (..)
import Json.Encode as Json


-- MODEL


type alias Model =
    { strings : Strings
    , nonce : String
    , timer_period : Float
    , schedules : List Schedule
    }


type alias Strings =
    { no_events : String
    , due : String
    , now : String
    , passed : String
    , weeks_abrv : String
    , days_abrv : String
    , hours_abrv : String
    , minutes_abrv : String
    , seconds_abrv : String
    , run_now : String
    }


type alias Schedule =
    { name : String
    , display : String
    , interval : Maybe Int
    , events : Maybe (List Event)
    }


type alias Event =
    { schedule : String
    , interval : Maybe Int
    , hook : String
    , args : List ( String, String )
    , timestamp : Int
    , seconds_due : Int
    }


type alias Divider =
    { name : String
    , val : Int
    }


type alias Flags =
    { strings : Strings
    , nonce : String
    , timer_period : String
    , schedules : Value
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model flags.strings flags.nonce (decodeTimerPeriod flags.timer_period) (decodeSchedules flags.schedules), Cmd.none )



{-
   mockSchedules : List Schedule
   mockSchedules =
       [ { name = "once_daily"
         , display = "Once Daily"
         , interval = Just 86400
         , events =
               Just
                   [ { schedule = Just "once_daily"
                     , interval = Just 86400
                     , hook = "wibble"
                     , args = []
                     , timestamp = 1234567890
                     , seconds_due = -120
                     }
                   ]
         }
       , { name = "twice_daily"
         , display = "Twice Daily"
         , interval = Just 86400
         , events =
               Just
                   [ { schedule = Just "once_daily"
                     , interval = Just 86400
                     , hook = "wibble"
                     , args = []
                     , timestamp = 1234567890
                     , seconds_due = 0
                     }
                   ]
         }
       , { name = "hourly"
         , display = "Hourly"
         , interval = Just 86400
         , events =
               Just
                   [ { schedule = Just "once_daily"
                     , interval = Just 86400
                     , hook = "wibble"
                     , args = []
                     , timestamp = 1234567890
                     , seconds_due = 3
                     }
                   ]
         }
       , { name = "every_15_mins"
         , display = "Every 15 Minutes"
         , interval = Just 86400
         , events =
               Just
                   [ { schedule = Just "once_daily"
                     , interval = Just 86400
                     , hook = "wibble"
                     , args = []
                     , timestamp = 1234567890
                     , seconds_due = 60
                     }
                   ]
         }
       , { name = "every_5_mins"
         , display = "Every 5 Minutes"
         , interval = Just 86400
         , events =
               Just
                   [ { schedule = Just "once_daily"
                     , interval = Just 86400
                     , hook = "wibble"
                     , args = []
                     , timestamp = 1234567890
                     , seconds_due = 120
                     }
                   ]
         }
       , { name = "every_min"
         , display = "Every Minute"
         , interval = Just 86400
         , events =
               Just
                   [ { schedule = Nothing
                     , interval = Just 86400
                     , hook = "wibble"
                     , args = []
                     , timestamp = 1234567890
                     , seconds_due = 1904550
                     }
                   ]
         }
       ]
-}
-- MESSAGES


type Msg
    = Tick Time
    | FetchSucceed (List Schedule)
    | FetchFail Http.Error
    | RunNow Event
    | PostSucceed String
    | PostFail Http.Error



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h3 []
            [ text "Schedules" ]
        , ul [ class "cron-pixie-schedules" ]
            (List.map (scheduleView model) model.schedules)
        ]


scheduleView : Model -> Schedule -> Html Msg
scheduleView model schedule =
    li []
        [ span [ class "cron-pixie-schedule-display", title schedule.name ]
            [ text schedule.display ]
        , eventsView model schedule.events
        ]


eventsView : Model -> Maybe (List Event) -> Html Msg
eventsView model events =
    case events of
        Just events' ->
            ul [ class "cron-pixie-events" ]
                (List.map (eventView model) events')

        _ ->
            text ""


eventView : Model -> Event -> Html Msg
eventView model event =
    li []
        [ span [ class "cron-pixie-event-run dashicons dashicons-controls-forward", title model.strings.run_now, onClick (RunNow event) ]
            []
        , span [ class "cron-pixie-event-hook" ]
            [ text event.hook ]
        , div [ class "cron-pixie-event-timestamp dashicons-before dashicons-clock" ]
            [ text " "
            , span [ class "cron-pixie-event-due" ]
                [ text (model.strings.due ++ ": " ++ (due event.timestamp)) ]
            , text " "
            , span [ class "cron-pixie-event-seconds-due" ]
                [ text ("(" ++ (displayInterval model event.seconds_due) ++ ")") ]
            ]
        ]


due : Int -> String
due timestamp =
    timestamp * 1000 |> toFloat |> Date.fromTime |> Date.Format.format "%Y-%m-%d %H:%M:%S"


intervals : Model -> List Divider
intervals model =
    [ { name = model.strings.weeks_abrv, val = 604800000 }
    , { name = model.strings.days_abrv, val = 86400000 }
    , { name = model.strings.hours_abrv, val = 3600000 }
    , { name = model.strings.minutes_abrv, val = 60000 }
    , { name = model.strings.seconds_abrv, val = 1000 }
    ]


displayInterval : Model -> Int -> String
displayInterval model seconds =
    let
        -- Convert everything to milliseconds so we can handle seconds in map.
        milliseconds =
            seconds * 1000
    in
        if 0 > (seconds + 60) then
            -- Cron runs max every 60 seconds.
            model.strings.passed
        else if 0 > (seconds - model.timer_period) then
            -- If due now or in next refresh period, show "now".
            model.strings.now
        else
            divideInterval [] milliseconds (intervals model) |> List.reverse |> String.join " "


divideInterval : List String -> Int -> List Divider -> List String
divideInterval parts milliseconds dividers =
    case dividers of
        e1 :: rest ->
            divideInterval' parts milliseconds (head dividers) (withDefault [] (tail dividers))

        _ ->
            parts


divideInterval' : List String -> Int -> Maybe Divider -> List Divider -> List String
divideInterval' parts milliseconds divider dividers =
    case divider of
        Just divider' ->
            let
                count =
                    milliseconds // divider'.val
            in
                if 0 < count then
                    divideInterval ((toString count ++ divider'.name) :: parts) (milliseconds % divider'.val) dividers
                else
                    divideInterval parts milliseconds dividers

        Nothing ->
            parts



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( model, getSchedules model.nonce )

        FetchSucceed schedules ->
            ( { model | schedules = schedules }, Cmd.none )

        FetchFail err ->
            ( model, Cmd.none )

        RunNow event ->
            let
                dueEvent =
                    { event | timestamp = (event.timestamp - event.seconds_due), seconds_due = 0 }
            in
                ( { model | schedules = List.map (updateScheduledEvent event dueEvent) model.schedules }, postEvent model.nonce dueEvent )

        PostSucceed schedules ->
            ( model, Cmd.none )

        PostFail err ->
            ( model, Cmd.none )


getSchedules : String -> Cmd Msg
getSchedules nonce =
    let
        url =
            Http.url "/wp-admin/admin-ajax.php" [ ( "action", "cron_pixie_schedules" ), ( "nonce", nonce ) ]
    in
        Task.perform FetchFail FetchSucceed (Http.get schedulesDecoder url)


schedulesDecoder : Decoder (List Schedule)
schedulesDecoder =
    list scheduleDecoder


scheduleDecoder : Decoder Schedule
scheduleDecoder =
    object4 Schedule ("name" := string) ("display" := string) (maybe ("interval" := int)) (maybe ("events" := (list eventDecoder)))


eventDecoder : Decoder Event
eventDecoder =
    object6 Event (oneOf [ "schedule" := string, succeed "false" ]) (maybe ("interval" := int)) ("hook" := string) ("args" := eventArgsDecoder) ("timestamp" := int) ("seconds_due" := int)


eventArgsDecoder : Decoder (List ( String, String ))
eventArgsDecoder =
    oneOf
        [ keyValuePairs string
        , succeed []
        ]


decodeSchedules : Value -> List Schedule
decodeSchedules json =
    let
        result =
            decodeValue schedulesDecoder json
    in
        case result of
            Ok schedules ->
                schedules

            Err error ->
                []


decodeTimerPeriod : String -> Float
decodeTimerPeriod string =
    let
        result =
            String.toFloat string
    in
        case result of
            Ok float ->
                float

            Err error ->
                5.0


updateScheduledEvent : Event -> Event -> Schedule -> Schedule
updateScheduledEvent oldEvent newEvent schedule =
    case schedule.events of
        Just events ->
            { schedule | events = Just <| List.map (updateMatchedEvent oldEvent newEvent) events }

        Nothing ->
            schedule


updateMatchedEvent : Event -> Event -> Event -> Event
updateMatchedEvent match newEvent event =
    if match == event then
        newEvent
    else
        event


postEvent : String -> Event -> Cmd Msg
postEvent nonce event =
    let
        url =
            "/wp-admin/admin-ajax.php"

        eventValue =
            Json.object
                [ ( "hook", Json.string event.hook )
                , ( "args", Json.object (List.map (\( key, val ) -> ( key, Json.string val )) event.args) )
                , ( "schedule", Json.string event.schedule )
                , ( "timestamp", Json.int event.timestamp )
                ]

        body =
            multipart
                [ stringData "action" "cron_pixie_events"
                , stringData "nonce" nonce
                , stringData "model" (Json.encode 0 eventValue)
                  -- , stringData "model" (Json.encode 0 eventValue)
                ]
    in
        Task.perform PostFail PostSucceed (Http.post string url body)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (model.timer_period * second) Tick



-- MAIN


main : Program Flags
main =
    Html.App.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
