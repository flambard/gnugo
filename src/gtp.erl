-module(gtp).

%% API
-export([ command/1
        , parse_command_reply/2
        ]).

%%%===================================================================
%%% API
%%%===================================================================

command(protocol_version) ->
    "protocol_version\n";
command(name) ->
    "name\n";
command(version) ->
    "version\n";
command({known_command, Command}) ->
    io_lib:format("known_command ~s\n", [Command]);
command(list_commands) ->
    "list_commands\n";
command(quit) ->
    "quit\n";
command({boardsize, Size}) ->
    io_lib:format("boardsize ~B\n", [Size]);
command(clear_board) ->
    "clear_board\n";
command({komi, NewKomi}) ->
    io_lib:format("komi ~f\n", [NewKomi]);
command({fixed_handicap, NumberOfStones}) ->
    io_lib:format("fixed_handicap ~B\n", [NumberOfStones]);
command({place_free_handicap, NumberOfStones}) ->
    io_lib:format("place_free_handicap ~B\n", [NumberOfStones]);
command({set_free_handicap, Vertices}) ->
    io_lib:format("set_free_handicap ~s\n",
                  [string:join([vertex_to_iolist(V) || V <- Vertices], " ")]);
command({play, Color, Move}) ->
    MoveArg = case Move of
                  pass   -> "PASS";
                  Vertex -> vertex_to_iolist(Vertex)
              end,
    io_lib:format("play ~p ~s\n", [Color, MoveArg]);
command({genmove, Color}) ->
    io_lib:format("genmove ~p\n", [Color]);
command(undo) ->
    "undo\n";
command({time_settings, MainTime, ByoYomiTime, ByoYomiStones}) ->
    io_lib:format("time_settings ~B ~B ~B\n",
                  [MainTime, ByoYomiTime, ByoYomiStones]);
command({time_left, Color, Time, Stones}) ->
    io_lib:format("time_left ~p ~B ~B\n", [Color, Time, Stones]);
command(final_score) ->
    "final_score\n";
command({final_status_list, Status}) ->
    io_lib:format("final_status_list ~s\n", [Status]);
command({loadsgf, FileName, MoveNumber}) ->
    io_lib:format("loadsgf ~s ~B\n", [FileName, MoveNumber]);
command({reg_genmove, Color}) ->
    io_lib:format("reg_genmove ~p\n", [Color]);
command(showboard) ->
    "showboard\n".


parse_command_reply(Command, "= " ++ Result) ->
    parse_result(Command, Result);
parse_command_reply(Command, "=" ++ IdResult) ->
    {_Id, Result} = split_id_from_result(IdResult),
    parse_result(Command, Result);
parse_command_reply(_Command, "? " ++ Error) ->
    {error, Error};
parse_command_reply(_Command, "?" ++ IdError) ->
    {_Id, Error} = split_id_from_result(IdError),
    {error, Error}.



%%%===================================================================
%%% Internal functions
%%%===================================================================

split_id_from_result(IdResult) ->
    {Id, " " ++ Result} =
        lists:splitwith(fun (C) -> $0 =< C andalso C =< $9 end, IdResult),
    {list_to_integer(Id), Result}.


parse_result(protocol_version, Result) ->
    {ok, list_to_integer(Result)};
parse_result(name, Result) ->
    {ok, Result};
parse_result(version, Result) ->
    {ok, Result};
parse_result({known_command, _Command}, Result) ->
    case Result of
        "true"  -> true;
        "false" -> false
    end;
parse_result(list_commands, Result) ->
    {ok, string:tokens(Result, "\n")};
parse_result(quit, "") ->
    ok;
parse_result({boardsize, _Size}, "") ->
    ok;
parse_result(clear_board, "") ->
    ok;
parse_result({komi, _NewKomi}, "") ->
    ok;
parse_result({fixed_handicap, _NumberOfStones}, Result) ->
    Vertices = [vertex_from_string(V) || V <- string:tokens(Result, " ")],
    {ok, Vertices};
parse_result({place_free_handicap, _NumberOfStones}, Result) ->
    Vertices = [vertex_from_string(V) || V <- string:tokens(Result, " ")],
    {ok, Vertices};
parse_result({set_free_handicap, _Vertices}, "") ->
    ok;
parse_result({play, _Color, _Move}, "") ->
    ok;
parse_result({genmove, _Color}, Result) ->
    Move = case Result of
               "PASS"   -> pass;
               "resign" -> resign;
               Vertex   -> vertex_from_string(Vertex)
           end,
    {ok, Move};
parse_result(undo, "") ->
    ok;
parse_result({time_settings, _MainTime, _ByoYomiTime, _ByoYomiStones}, "") ->
    ok;
parse_result({time_left, _Color, _Time, _Stones}, "") ->
    ok;
parse_result(final_score, Result) ->
    {ok, Result};
parse_result({final_status_list, _Status}, Result) ->
    Vertices = [vertex_from_string(V) || V <- string:tokens(Result, " ")],
    {ok, Vertices};
parse_result({loadsgf, _FileName, _MoveNumber}, "") ->
    ok;
parse_result({reg_genmove, _Color}, Result) ->
    Move = case Result of
               "PASS"   -> pass;
               "resign" -> resign;
               Vertex   -> vertex_from_string(Vertex)
           end,
    {ok, Move};
parse_result(showboard, Result) ->
    io:format([Result, "\n\n"]),
    ok.



vertex_from_string([Letter | Digits]) ->
    {list_to_atom(string:to_lower([Letter])), list_to_integer(Digits)}.

vertex_to_iolist({Letter, Digits}) ->
    io_lib:format("~p~B", [Letter, Digits]).
