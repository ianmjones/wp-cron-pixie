module CronPixie exposing (Divider, Event, Flags, Model, Msg(..), Schedule, Strings, decodeSchedules, decodeTimerPeriod, displayInterval, divideInterval, divideInterval_, due, eventArgsDecoder, eventDecoder, eventView, eventsView, getSchedules, init, intervals, main, postEvent, queryEscape, queryPair, scheduleDecoder, scheduleView, schedulesDecoder, subscriptions, update, updateMatchedEvent, updateScheduledEvent, url, view)

import Date
import Date.Format
import Html exposing (Html, div, h3, li, span, text, ul)
import Html.Attributes exposing (class, title)
import Html.Events exposing (..)
import Http exposing (encodeUri, multipartBody, stringPart)
import Json.Decode exposing (..)
import Json.Encode as Json
import List exposing (head, reverse, tail)
import Maybe exposing (withDefault)
import String
import Task
import Time exposing (Time, second)



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



-- MESSAGES


type Msg
    = Tick Time
    | Fetch (Result Http.Error (List Schedule))
    | RunNow Event
    | UpdateEvent (Result Http.Error String)



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
        Just events_ ->
            ul [ class "cron-pixie-events" ]
                (List.map (eventView model) events_)

        Nothing ->
            text ""


eventView : Model -> Event -> Html Msg
eventView model event =
    li []
        [ span [ class "cron-pixie-event-run dashicons dashicons-controls-forward", title model.strings.run_now, onClick (RunNow event) ]
            []
        , span [ class "cron-pixie-event-hook" ]
            [ text event.hook ]
        , div [ class "cron-pixie-event-timestamp dashicons-before dashicons-clock" ]
            [ text "\u{00A0}"
            , span [ class "cron-pixie-event-due" ]
                [ text (model.strings.due ++ ": " ++ due event.timestamp) ]
            , text "\u{00A0}"
            , span [ class "cron-pixie-event-seconds-due" ]
                [ text ("(" ++ displayInterval model event.seconds_due ++ ")") ]
            ]
        ]


due : Int -> String
due timestamp =
    timestamp
        * 1000
        |> toFloat
        |> Date.fromTime
        |> Date.Format.format "%Y-%m-%d %H:%M:%S"


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

    else if 0 > (toFloat seconds - model.timer_period) then
        -- If due now or in next refresh period, show "now".
        model.strings.now

    else
        divideInterval [] milliseconds (intervals model) |> reverse |> String.join " "


divideInterval : List String -> Int -> List Divider -> List String
divideInterval parts milliseconds dividers =
    case dividers of
        e1 :: rest ->
            divideInterval_ parts milliseconds (head dividers) (withDefault [] (tail dividers))

        _ ->
            parts


divideInterval_ : List String -> Int -> Maybe Divider -> List Divider -> List String
divideInterval_ parts milliseconds divider dividers =
    case divider of
        Just divider_ ->
            let
                count =
                    milliseconds // divider_.val
            in
            if 0 < count then
                divideInterval ((toString count ++ divider_.name) :: parts) (modBy divider_.val milliseconds) dividers

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

        Fetch (Ok schedules) ->
            ( { model | schedules = schedules }, Cmd.none )

        Fetch (Err _) ->
            ( model, Cmd.none )

        RunNow event ->
            let
                dueEvent =
                    { event | timestamp = event.timestamp - event.seconds_due, seconds_due = 0 }
            in
            ( { model | schedules = List.map (updateScheduledEvent event dueEvent) model.schedules }, postEvent model.nonce dueEvent )

        UpdateEvent (Ok schedules) ->
            ( model, Cmd.none )

        UpdateEvent (Err _) ->
            ( model, Cmd.none )


getSchedules : String -> Cmd Msg
getSchedules nonce =
    let
        encodedUrl =
            url "/wp-admin/admin-ajax.php" [ ( "action", "cron_pixie_schedules" ), ( "nonce", nonce ) ]
    in
    Http.send Fetch (Http.get encodedUrl schedulesDecoder)


schedulesDecoder : Decoder (List Schedule)
schedulesDecoder =
    list scheduleDecoder


scheduleDecoder : Decoder Schedule
scheduleDecoder =
    map4 Schedule (field "name" string) (field "display" string) (maybe (field "interval" int)) (maybe (field "events" (list eventDecoder)))


eventDecoder : Decoder Event
eventDecoder =
    map6 Event (oneOf [ field "schedule" string, succeed "false" ]) (maybe (field "interval" int)) (field "hook" string) (field "args" eventArgsDecoder) (field "timestamp" int) (field "seconds_due" int)


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
            multipartBody
                [ stringPart "action" "cron_pixie_events"
                , stringPart "nonce" nonce
                , stringPart "model" (Json.encode 0 eventValue)

                -- , stringData "model" (Json.encode 0 eventValue)
                ]
    in
    Http.send UpdateEvent (Http.post url body string)


url : String -> List ( String, String ) -> String
url baseUrl args =
    case args of
        [] ->
            baseUrl

        _ ->
            baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)


queryPair : ( String, String ) -> String
queryPair ( key, value ) =
    queryEscape key ++ "=" ++ queryEscape value


queryEscape : String -> String
queryEscape string =
    String.join "+" (String.split "%20" (encodeUri string))



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (model.timer_period * second) Tick



-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
