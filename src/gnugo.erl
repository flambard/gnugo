-module(gnugo).

-export([ start/0
        , receive_reply/1
        , receive_reply/2
        ]).

%% GNU Go API
-export([ protocol_version/1
        , name/1
        , version/1
        , known_command/2
        , list_commands/1
        , quit/1
        , boardsize/2
        , clear_board/1
        , komi/2
        , fixed_handicap/2
        , place_free_handicap/2
        , set_free_handicap/2
        , play/3
        , genmove/2
        , genmove_async/2
        , undo/1
        , time_settings/4
        , time_left/4
        , final_score/1
        , final_status_list/2
        , loadsgf/3
        , reg_genmove/2
        , showboard/1
        ]).

-type gnugo_ref() :: port().
-type color() :: 'black' | 'white'.
-type vertex() :: {atom(), integer()}.
-type move() :: vertex() | 'pass' | 'resign'.
-type status() :: 'alive' | 'seki' | 'dead'.

%%%===================================================================
%%% API
%%%===================================================================

-spec start() -> {ok, gnugo_ref()} | {error, term()}.
start() ->
    case os:find_executable("gnugo") of
        false    -> {error, could_not_find_gnugo_executable};
        FilePath ->
            Args = ["--mode", "gtp"],
            Port = open_port({spawn_executable, FilePath},
                             [ {args, Args}
                             , {line, 128}
                             , exit_status
                             , hide
                             ]),
            {ok, Port}
    end.

-spec receive_reply(GnuGo :: gnugo_ref()) -> {ok, term()}.
receive_reply(Port) ->
    receive_reply(Port, []).

-spec receive_reply(GnuGo :: gnugo_ref(), Acc :: list()) -> {ok, term()}.
receive_reply(Port, Acc) ->
    CommandReply = receive_command_reply(Port, Acc),
    gtp:parse_command_reply({genmove, undefined}, CommandReply).


%%%
%%% GNU Go API
%%%

-spec protocol_version(gnugo_ref()) -> {ok, Version :: integer()}.
protocol_version(Port) ->
    sync_command(Port, protocol_version).

-spec name(gnugo_ref()) -> {ok, Name :: string()}.
name(Port) ->
    sync_command(Port, name).

-spec version(gnugo_ref()) -> {ok, Version :: string()}.
version(Port) ->
    sync_command(Port, version).

-spec known_command(gnugo_ref(), Command :: string()) -> boolean().
known_command(Port, Command) ->
    sync_command(Port, {known_command, Command}).

-spec list_commands(gnugo_ref()) -> {ok, Commands :: list(string())}.
list_commands(Port) ->
    sync_command(Port, list_commands).

-spec quit(gnugo_ref()) -> ok.
quit(Port) ->
    sync_command(Port, quit).

-spec boardsize(gnugo_ref(), Size :: integer()) -> ok.
boardsize(Port, Size) ->
    sync_command(Port, {boardsize, Size}).

-spec clear_board(gnugo_ref()) -> ok.
clear_board(Port) ->
    sync_command(Port, clear_board).

-spec komi(gnugo_ref(), Komi :: float()) -> ok.
komi(Port, Komi) ->
    sync_command(Port, {komi, Komi}).

-spec fixed_handicap(gnugo_ref(), NumberOfStones :: integer()) ->
                            {ok, Vertices :: list(vertex())}.
fixed_handicap(Port, NumberOfStones) ->
    sync_command(Port, {fixed_handicap, NumberOfStones}).

-spec place_free_handicap(gnugo_ref(), NumberOfStones :: integer()) ->
                                 {ok, Vertices :: list(vertex())}.
place_free_handicap(Port, NumberOfStones) ->
    sync_command(Port, {place_free_handicap, NumberOfStones}).

-spec set_free_handicap(gnugo_ref(), Vertices :: list(vertex())) -> ok.
set_free_handicap(Port, Vertices) ->
    sync_command(Port, {set_free_handicap, Vertices}).

-spec play(gnugo_ref(), color(), Move :: move()) -> ok.
play(Port, Color, Move) ->
    sync_command(Port, {play, Color, Move}).

-spec genmove(gnugo_ref(), color()) -> {ok, move()}.
genmove(Port, Color) ->
    sync_command(Port, {genmove, Color}).

-spec genmove_async(gnugo_ref(), color()) -> ok.
genmove_async(Port, Color) ->
    async_command(Port, {genmove, Color}).

-spec undo(gnugo_ref()) -> ok.
undo(Port) ->
    sync_command(Port, undo).

-spec time_settings(gnugo_ref(),
                    MainTime :: integer(),
                    ByoYomiTime :: integer(),
                    ByoYomiStones :: integer()) -> ok.
time_settings(Port, MainTime, ByoYomiTime, ByoYomiStones) ->
    sync_command(Port, {time_settings,
                        MainTime,
                        ByoYomiTime,
                        ByoYomiStones}).

-spec time_left(gnugo_ref(), color(), Time :: integer(), Stones :: integer()) ->
                       ok.
time_left(Port, Color, Time, Stones) ->
    sync_command(Port, {time_left, Color, Time, Stones}).

-spec final_score(gnugo_ref()) -> {ok, Result :: string()}.
final_score(Port) ->
    sync_command(Port, final_score).

-spec final_status_list(gnugo_ref(), status()) ->
                               {ok, Vertices :: list(vertex())}.
final_status_list(Port, Status) ->
    sync_command(Port, {final_status_list, Status}).

-spec loadsgf(gnugo_ref(), FileName :: string(), MoveNumber :: integer()) -> ok.
loadsgf(Port, FileName, MoveNumber) ->
    sync_command(Port, {loadsgf, FileName, MoveNumber}).

-spec reg_genmove(gnugo_ref(), color()) -> {ok, move()}.
reg_genmove(Port, Color) ->
    sync_command(Port, {reg_genmove, Color}).

-spec showboard(gnugo_ref()) -> ok.
showboard(Port) ->
    sync_command(Port, showboard).


%%%===================================================================
%%% Internal functions
%%%===================================================================

async_command(Port, Command) ->
    port_command(Port, gtp:command(Command)),
    ok.

sync_command(Port, Command) ->
    port_command(Port, gtp:command(Command)),
    CommandReply = receive_command_reply(Port),
    gtp:parse_command_reply(Command, CommandReply).

receive_command_reply(Port) ->
    receive_command_reply(Port, []).

receive_command_reply(Port, Acc) ->
    receive
        {Port, {data, {eol, []}}}   -> string:join(lists:reverse(Acc), "\n");
        {Port, {data, {eol, Line}}} -> receive_command_reply(Port, [Line | Acc])
    end.
