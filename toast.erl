-module(toast).
-import(string,[to_lower/1]).
-import(string,[sub_string/3]).
-export([actor_start/0, actor/1, bitCoinCreation/1, panodu/1, create_panodu/2, newProcess_servants/2,toasting/2]).


createRandomVal(Len, AvailSet) ->
    lists:foldl(fun(_, Acc) ->
                        [lists:nth(rand:uniform(length(AvailSet)),
                                   AvailSet)]
                            ++ Acc
                end, [], lists:seq(1, Len)).

bitCoinCreation(K) ->
    receive
        {mine, From, SNode} ->
            RandomKey = "uavula;"++createRandomVal(47,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ;!@#$%^&*()+-_=0123456789"),
            FinalHash = to_lower(integer_to_list(binary:decode_unsigned(crypto:hash(sha256,RandomKey)),16)),
            FinalHashLength = string:len(FinalHash),
            if 
                FinalHashLength =< (64-K) ->
                    io:format("Got Coin ~n"),
                    panodu ! got,
                    {From, SNode} ! {got_coin,{RandomKey, zeroesAffixing(K)++FinalHash}};
                true ->
                    spawn(toast, bitCoinCreation,[K]) ! {mine, From, SNode}
            end
    end.

actor(K)->
    receive
        hello ->
            io:format("someonesays Hello~n");
        {i_am_panodu, PanoduPid} ->
            io:format("Actor Received a Panodu~n"),
            io:format("Panodu Node ~p ~n",[PanoduPid]),
            PanoduPid ! hello;
        {got_coin, {Coin, FinalHash}} ->
            io:format("Coin : FinalHash ---> ~p  :  ~p~n",[Coin,FinalHash]);
        {mine, WPid} ->
            WPid ! {zcount, K};
        {time,CPU,REAL, RATIO} ->
            io:format("CPU TIME : ~p REAL TIME : ~p RATIO : ~p",[CPU,REAL, RATIO]);
        terminate ->
            exit("Exited")
    end,
    actor(K).

zeroesAffixing(0) -> "";
zeroesAffixing(N) -> 
    "0"++zeroesAffixing(N-1).

panodu(SNode) ->
    
    {actorPid, SNode} ! {mine, self()},
    receive
        {zcount, K} ->
            spawn(toast, bitCoinCreation,[K]) ! {mine, actorPid, SNode}
    end.

newProcess_servants(1, SNode) ->
    spawn(toast, panodu, [SNode]);
    
newProcess_servants(N, SNode) ->
    spawn(toast, panodu, [SNode]),
    newProcess_servants(N-1, SNode).

toasting(S,C) ->
    register(panodu,spawn(toast,create_panodu,[S,C])).

create_panodu(SNode,C) ->
    {_,_}=statistics(runtime),
    {_,_}=statistics(wall_clock),
    io:format("Creating Panodu~n"),
    newProcess_servants(C, SNode),
    listen(1,SNode).

listen(N,SNode) ->
    receive 
        got ->
            io:format("B : ~p" , [N]), 
            if 
                N == 6 ->
                    {_,CPU}=statistics(runtime),
                    {_,REAL}=statistics(wall_clock),
                    {actorPid,SNode} ! {time,CPU, REAL, CPU/REAL};
                true -> 
                    listen(N+1,SNode)
            end
    end.

actor_start() ->
    {ok, K} = io:read("Enter a number: "),
    io:format("Entered No.of leading zeroes : ~p~n",[K]),
    register(actorPid,spawn(toast, actor,[K])),
    {_,_}=statistics(runtime),
    {_,_}=statistics(wall_clock).


