-- First version
--
-- This version:
--
-- * Demonstrates the weakness of using Task even in places where it isn't
--  necessary.
-- * Has a multi-level higher-order-function-based request-processing pipeline.
--
-- Every other version of the file in this repo can be meaningfully
-- diff'd against this one.

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

parseResponseWith : (String -> Task.Task error result) -> Task.Task error Response -> Task.Task error result
parseResponseWith handle task =
    let
        parseResponse { body } = handle body
    in
        task `Task.andThen` parseResponse

-- Well, this should just be some safe string parsing code.
-- We probably don't need to look too closely at this, since it's not like
-- it can do anything super strange.
parseStrings : String -> Task.Task error ParsedRecords
parseStrings s =
    let
        -- Oops.. wait, why is this here?
        -- I hope we caught this in code review...
        stupidFocus = Dom.focus "some-random-element" |> swallowError
        swallowError t = t `Task.onError` ignore
        ignore _ = Task.succeed ()
    in
        stupidFocus `Task.andThen` \_ -> Task.succeed (split "," s)


-- We don't actually need this since we only support one endpoint :)
type alias Endpoint = Int
recordsEndpoint : Endpoint
recordsEndpoint = 5
