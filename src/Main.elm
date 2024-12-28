module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, href, placeholder, readonly, style, value)
import Html.Events exposing (onInput)
import Json.Decode
import Json.Encode
import JsonPath
import JsonPath.Error exposing (Cursor, CursorOp(..), Error(..))



-- MAIN


main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { path : String
    , inputJson : InputJson
    , outputJson : OutputJson
    }


type alias InputJson =
    { raw : String
    , decoded : Result Json.Decode.Error Json.Decode.Value
    }


type alias OutputJson =
    { raw : String
    , decoded : Result DemoError Json.Decode.Value
    }


type DemoError
    = JsonDecodeError Json.Decode.Error
    | JsonPathError Error


init : Model
init =
    let
        initPath =
            "$.store.book[*].author"

        initOutputJson =
            initInputJson
                |> JsonPath.run initPath
                |> Result.mapError JsonPathError
    in
    { path = initPath
    , inputJson =
        { raw = Json.Encode.encode 4 initInputJson
        , decoded = Ok initInputJson
        }
    , outputJson =
        { raw = encodeResult initOutputJson
        , decoded = initOutputJson
        }
    }


initInputJson : Json.Decode.Value
initInputJson =
    Json.Encode.object
        [ ( "store"
          , Json.Encode.object
                [ ( "book"
                  , Json.Encode.list identity
                        [ Json.Encode.object
                            [ ( "category", Json.Encode.string "reference" )
                            , ( "author", Json.Encode.string "Nigel Rees" )
                            , ( "title", Json.Encode.string "Sayings of the Century" )
                            , ( "price", Json.Encode.float 8.95 )
                            ]
                        , Json.Encode.object
                            [ ( "category", Json.Encode.string "fiction" )
                            , ( "author", Json.Encode.string "Evelyn Waugh" )
                            , ( "title", Json.Encode.string "Sword of Honour" )
                            , ( "price", Json.Encode.float 12.99 )
                            ]
                        , Json.Encode.object
                            [ ( "category", Json.Encode.string "fiction" )
                            , ( "author", Json.Encode.string "Herman Melville" )
                            , ( "title", Json.Encode.string "Moby Dick" )
                            , ( "isbn", Json.Encode.string "0-553-21311-3" )
                            , ( "price", Json.Encode.float 8.99 )
                            ]
                        , Json.Encode.object
                            [ ( "category", Json.Encode.string "fiction" )
                            , ( "author", Json.Encode.string "J. R. R. Tolkien" )
                            , ( "title", Json.Encode.string "The Lord of the Rings" )
                            , ( "isbn", Json.Encode.string "0-395-19395-8" )
                            , ( "price", Json.Encode.float 22.99 )
                            ]
                        ]
                  )
                , ( "bicycle"
                  , Json.Encode.object
                        [ ( "color", Json.Encode.string "red" )
                        , ( "price", Json.Encode.float 19.95 )
                        ]
                  )
                ]
          )
        ]



-- UPDATE


type Msg
    = UpdatePath String
    | UpdateRawInputJson String


update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdatePath path ->
            run path model.inputJson.raw

        UpdateRawInputJson rawInputJson ->
            run model.path rawInputJson


run : String -> String -> Model
run path rawInputJson =
    let
        decodedInputJson =
            decodeRawJson rawInputJson

        decodedOutputJson =
            case decodedInputJson of
                Ok value ->
                    value
                        |> JsonPath.run path
                        |> Result.mapError JsonPathError

                Err error ->
                    Err (JsonDecodeError error)
    in
    { path = path
    , inputJson =
        { raw = rawInputJson
        , decoded = decodedInputJson
        }
    , outputJson =
        { raw = encodeResult decodedOutputJson
        , decoded = decodedOutputJson
        }
    }


decodeRawJson : String -> Result Json.Decode.Error Json.Decode.Value
decodeRawJson rawJson =
    Json.Decode.decodeString Json.Decode.value rawJson


encodeResult : Result DemoError Json.Decode.Value -> String
encodeResult result =
    case result of
        Ok value ->
            Json.Encode.encode 4 value

        Err (JsonDecodeError _) ->
            "Error: Failed to decode input JSON"

        Err (JsonPathError (PathParsingError _)) ->
            "Error: Failed to parse path expression"

        Err (JsonPathError (IndexNotFound cursor index)) ->
            String.concat
                [ "Error: Index "
                , String.fromInt index
                , " not found at "
                , printCursor cursor
                ]

        Err (JsonPathError (KeyNotFound cursor key)) ->
            String.concat
                [ "Error: Key "
                , "\"" ++ key ++ "\""
                , " not found at "
                , printCursor cursor
                ]

        Err (JsonPathError (NotAJsonArray cursor)) ->
            String.concat
                [ "Error: Expected a JSON array at "
                , printCursor cursor
                ]

        Err (JsonPathError (NotAJsonArrayNorAnObject cursor)) ->
            String.concat
                [ "Error: Expected a JSON array or object at "
                , printCursor cursor
                ]


printCursor : Cursor -> String
printCursor cursor =
    let
        loop : Cursor -> List String -> String
        loop rem acc =
            case rem of
                [] ->
                    String.join " -> " (List.reverse acc)

                (DownIndex index) :: nextRem ->
                    loop nextRem (String.fromInt index :: acc)

                (DownKey key) :: nextRem ->
                    loop nextRem (("\"" ++ key ++ "\"") :: acc)
    in
    loop (List.reverse cursor) []



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "section" ]
        [ div [ class "title is-2" ] [ text "JSONPath Demo" ]
        , div [ class "subtitle is-4" ]
            [ text "Demo of the "
            , a [ href "https://github.com/sophiecollard/jsonpath/tree/main" ] [ text "sophiecollard/jsonpath" ]
            , text " Elm package (version 2.0.0)"
            ]
        , div [ class "field" ]
            [ div [ class "label" ] [ text "Path" ]
            , div [ class "control" ]
                [ input [ class "input", placeholder "Path (eg: $.store.book[0])", value model.path, onInput UpdatePath ] [] ]
            ]
        , div [ class "columns" ]
            [ div [ class "column" ]
                [ div [ class "field" ]
                    [ div [ class "label" ] [ text "Input JSON" ]
                    , div [ class "control" ]
                        [ textarea
                            [ class "textarea", placeholder "{}", value model.inputJson.raw, style "min-height" "450px" ]
                            []
                        ]
                    ]
                ]
            , div [ class "column" ]
                [ div [ class "field" ]
                    [ div [ class "label" ] [ text "Output JSON" ]
                    , div [ class "control" ]
                        [ textarea
                            [ class "textarea", readonly True, value model.outputJson.raw, style "min-height" "450px" ]
                            []
                        ]
                    ]
                ]
            ]
        ]
