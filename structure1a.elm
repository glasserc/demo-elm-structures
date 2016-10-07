-- Version 1a, which uses Result instead of Task
--
-- This is mostly identical with the first version, but with a few changes
-- to make the types line up in calling functions. Of course, it's
-- impossible to get Task to line up with Result, so I don't try. This
-- version should give you a compiler error.
--
-- Whether this type signature is better than the last one depends on what
-- you expect your "handling" function to do. If it should just be
-- manipulating values in memory, maybe you want this one. If it should be
-- participating in a protocol by launching more tasks, then maybe you want
-- the previous one.
--
-- The thrust of this repo is about another point having to do with
-- higher-order functions, so I'm going to leave this branch of the
-- evolutionary tree alone and forge on with structure2.elm (ignoring
-- whether it returns Task or not).

module App exposing (..)

import Dom
import Html exposing (Html, div, text)
import Html.App
import List
import String exposing (split)
import Task

-- MODEL
type alias Model =
    List Attendee

type alias Attendee = String

init : ( Model, Cmd Msg )
init =
    ( [], startFetch )

-- MESSAGES
type Msg
    = FetchSucceeded (List String)
    | FetchFailed String

-- VIEW
view : Model -> Html Msg
view model =
    div [] (case model of
      [] -> [text "... no attendees yet ..."]
      attendees -> List.map text [
          toString (List.length attendees),
          " attendees: ",
          String.join ", " attendees
          ])

-- UPDATE
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchSucceeded attendees ->
            ( attendees, Cmd.none )
        -- probably ought to do something here but this would require adding something to the model
        FetchFailed error ->
            ( [], Cmd.none )

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- MAIN
main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


startFetch : Cmd Msg
startFetch = Task.perform FetchFailed FetchSucceeded fetchRecords

----- "Client" code starts here! -----
type alias Response =
    { status : Int
    , statusMsg : String
    , body : String
    }

type alias FetchError = String
type alias ParsedRecords = List String

fetchRecords : Task.Task FetchError ParsedRecords
fetchRecords = clientCall recordsEndpoint

-- Pretend there's actual network stuff here. For these examples it isn't super important.
clientCall : a -> Task.Task FetchError ParsedRecords
clientCall _ = Task.succeed (Response 200 "OK" "magopian,glasserc,leplatrem,natim,n1k0") |> toParsedResponse

toParsedResponse : Task.Task FetchError Response -> Task.Task FetchError ParsedRecords
toParsedResponse = parseResponseWith parseStrings

parseResponseWith : (String -> Result error result) -> Task.Task error Response -> Task.Task error result
parseResponseWith handle task =
    let
        -- Exercise: are there better ways to write this?
        -- What if the error type of the Result is something like an Int and we need it to be a String?
        parseResponse { body } = case handle body of
            Ok result -> Task.succeed result
            Err bad -> Task.fail bad
    in
        task `Task.andThen` parseResponse

-- This is definitely some safe string parsing code.
-- We actually don't need to look too closely at this, since
-- it's just a Result.
parseStrings : String -> Result error ParsedRecords
parseStrings s =
    let
        -- Writing this is of course completely impossible now,
        -- since a Task can't be converted into a Result
        -- (because a Task requires an impure action).
        stupidFocus = Dom.focus "some-random-element" |> swallowError
        swallowError t = t `Task.onError` ignore
        ignore _ = Task.succeed ()
    in
        stupidFocus `Result.andThen` \_ -> Ok (split "," s)


-- We don't actually need this since we only support one endpoint :)
type alias Endpoint = Int
recordsEndpoint : Endpoint
recordsEndpoint = 5
