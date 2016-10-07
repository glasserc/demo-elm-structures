-- Structure 2, which makes `andThen` explicit
--
-- In this structure, I bring the `andThen` up one level (from
-- `parseResponseWith` into `clientCall`). In other words, turn
--
-- foo : Task foo bar -> Task foo baz
-- fooCaller = someTask |> foo
--
-- into
--
-- foo : bar -> Task foo baz
-- fooCaller = someTask `Task.andThen` foo
--
-- Any function which takes a Task eventually has to use `andThen` to work
-- with it, and exposing that fact to the caller can sometimes lead to more
-- flexible-feeling APIs.
--
-- In this particular example, I think `parseResponse` really belongs in
-- `fetchRecords`, not `clientCall`, because IMHO `clientCall` should
-- produce a `Response` (i.e. should be agnostic to what is being
-- requested) and `fetchRecords` knows that it wants a
-- `ParsedRecords` (i.e. is best situated to specify the kind of parsing).
-- But that change is independent of whether you use a `|>` or an
-- `andThen`.

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
clientCall _ = Task.succeed (Response 200 "OK" "magopian,glasserc,leplatrem,natim,n1k0")
    `Task.andThen` parseResponse

parseResponse : Response -> Task.Task FetchError ParsedRecords
parseResponse = parseResponseWith parseStrings

-- Of course, it's possible to simplify this further, but I didn't want to obscure the change.
parseResponseWith : (String -> Task.Task error result) -> Response -> Task.Task error result
parseResponseWith handle response =
    let
        parseResponse { body } = handle body
    in
        parseResponse response

parseStrings : String -> Task.Task error ParsedRecords
parseStrings s = Task.succeed (split "," s)


-- We don't actually need this since we only support one endpoint :)
type alias Endpoint = Int
recordsEndpoint : Endpoint
recordsEndpoint = 5
