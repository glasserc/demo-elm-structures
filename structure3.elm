-- Structure 3, which breaks out `extractText`
--
-- In this example, I break out a function `extractText`, which is a way to
-- get the string contents of a Response if available. This means I don't
-- need to pass the `handle` function as a higher-order function; I can
-- just use it directly with `andThen`.

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

-- This function is kind of meaningless here because every Response
-- has a String body.  But in the example I saw online, some Responses
-- don't have a String body, so there's the possibility of failure.
extractText : Response -> Task.Task error String
extractText { body } = Task.succeed body

parseResponseWith : (String -> Task.Task error result) -> Task.Task error Response -> Task.Task error result
parseResponseWith handle task =
        task `Task.andThen` extractText `Task.andThen` handle

parseStrings : String -> Task.Task error ParsedRecords
parseStrings s = Task.succeed (split "," s)


-- We don't actually need this since we only support one endpoint :)
type alias Endpoint = Int
recordsEndpoint : Endpoint
recordsEndpoint = 5
