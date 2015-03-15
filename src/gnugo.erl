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


%%%===================================================================
%%% API
%%%===================================================================

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

receive_reply(Port) ->
    receive_reply(Port, []).

receive_reply(Port, Acc) ->
    CommandReply = receive_command_reply(Port, Acc),
    gtp:parse_command_reply({genmove, undefined}, CommandReply).


%%%
%%% GNU Go API
%%%

protocol_version(Port) ->
    sync_command(Port, protocol_version).

name(Port) ->
    sync_command(Port, name).

version(Port) ->
    sync_command(Port, version).

known_command(Port, Command) ->
    sync_command(Port, {known_command, Command}).

list_commands(Port) ->
    sync_command(Port, list_commands).

quit(Port) ->
    sync_command(Port, quit).

boardsize(Port, Size) ->
    sync_command(Port, {boardsize, Size}).

clear_board(Port) ->
    sync_command(Port, clear_board).

komi(Port, NewKomi) ->
    sync_command(Port, {komi, NewKomi}).

fixed_handicap(Port, NumberOfStones) ->
    sync_command(Port, {fixed_handicap, NumberOfStones}).

place_free_handicap(Port, NumberOfStones) ->
    sync_command(Port, {place_free_handicap, NumberOfStones}).

set_free_handicap(Port, Vertices) ->
    sync_command(Port, {set_free_handicap, Vertices}).

play(Port, Color, Move) ->
    sync_command(Port, {play, Color, Move}).

genmove(Port, Color) ->
    sync_command(Port, {genmove, Color}).

genmove_async(Port, Color) ->
    async_command(Port, {genmove, Color}).

undo(Port) ->
    sync_command(Port, undo).

time_settings(Port, MainTime, ByoYomiTime, ByoYomiStones) ->
    sync_command(Port, {time_settings,
                        MainTime,
                        ByoYomiTime,
                        ByoYomiStones}).

time_left(Port, Color, Time, Stones) ->
    sync_command(Port, {time_left, Color, Time, Stones}).

final_score(Port) ->
    sync_command(Port, final_score).

final_status_list(Port, Status) ->
    sync_command(Port, {final_status_list, Status}).

loadsgf(Port, FileName, MoveNumber) ->
    sync_command(Port, {loadsgf, FileName, MoveNumber}).

reg_genmove(Port, Color) ->
    sync_command(Port, {reg_genmove, Color}).

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
