-module(project3).
-export([main/2, begin_net/2, chal_accomp/2, rest_node/1, peer/4]).

fetch_for_dist(Key, Key, _, Distance) ->
    Distance;
fetch_for_dist(Key, NodeId, M, Distance) ->
    fetch_for_dist(Key, (NodeId + 1) rem trunc(math:pow(2, M)), M, Distance + 1)
.

fetch_shortest(_, [], MinNode, _, _) ->
    MinNode;
fetch_shortest(Key, FingerNodeIds, MinNode, MinVal, State) ->
    [First| Rest] = FingerNodeIds,
    Distance = fetch_for_dist(Key, First, dict:fetch(m, State), 0),
    if
        Distance < MinVal ->
            fetch_shortest(Key, Rest, First, Distance, State);
        true -> 
            fetch_shortest(Key, Rest, MinNode, MinVal, State)
    end
.

fet_m(NoPeers) ->
    trunc(math:ceil(math:log2(NoPeers)))
.

fetch_shortest_node(Key, FingerNodeIds, State) ->
    case lists:member(Key, FingerNodeIds) of
        true -> Key;
        _ -> fetch_shortest(Key, FingerNodeIds, -1, 10000000, State)
    end

.


within_range(From, To, Key, M) ->
    if 
        From < To -> 
            (From =< Key) and (Key =< To);
        trunc(From) == trunc(To) ->
            trunc(Key) == trunc(From);
        From > To ->
            ((Key >= 0) and (Key =< To)) or ((Key >= From) and (Key < trunc(math:pow(2, M))))
    end
.

nearest_finger(_, NodeState, 0) -> NodeState;
nearest_finger(Id, NodeState, M) -> 
    MthFinger = lists:nth(M, dict:fetch(finger_table, NodeState)),
    
    case within_range(dict:fetch(id, NodeState), Id, dict:fetch(peer ,MthFinger), dict:fetch(m, NodeState)) of
        true -> 

            dict:fetch(pid ,MthFinger) ! {state, self()},
            receive
                {statereply, FingerNodeState} ->
                    FingerNodeState
            end,
            FingerNodeState;

        _ -> nearest_finger(Id, NodeState, M - 1)
    end
.

nodearbitrary(Peer_id, []) -> Peer_id;
nodearbitrary(_, CurrentPeers) -> lists:nth(rand:uniform(length(CurrentPeers)), CurrentPeers).

get_previous(Id, NodeState) ->
    case 
        within_range(dict:fetch(id, NodeState) + 1, dict:fetch(id, dict:fetch(successor, NodeState)), Id, dict:fetch(m, NodeState)) of 
            true -> NodeState;
            _ -> get_previous(Id, nearest_finger(Id, NodeState, dict:fetch(m, NodeState)))
    end
.

get_successor(Id, NodeState) ->
    PredicessorNodeState = get_previous(Id, NodeState),
    dict:fetch(successor, PredicessorNodeState)
.

peer_chord(ChordPeers, PeersNum, M, CondNet) ->
    RemainingHashes = lists:seq(0, PeersNum - 1, 1) -- ChordPeers,
    Hash = lists:nth(rand:uniform(length(RemainingHashes)), RemainingHashes),
    Pid = spawn(project3, peer, [Hash, M, ChordPeers, dict:new()]),
    % io:format("~n ~p ~p ~n", [Hash, Pid]),
    [Hash, dict:store(Hash, Pid, CondNet)]
.


rest_node(NodeState) ->
    Hash = dict:fetch(id, NodeState),
    receive
            
        {lookup, Id, Key, HopsCount, _Pid} ->

                NodeVal = fetch_shortest_node(Key, dict:fetch_keys(dict:fetch(finger_table ,NodeState)), NodeState),
                UpdatedState = NodeState,
                %io:format("Lookup::: ~p  For Key ~p  ClosestNode ~p ~n", [Hash, Key, NodeVal]),
                if 
                    
                    (Hash == Key) -> 
                        taskcompletionmonitor ! {completed, Hash, HopsCount, Key};
                    (NodeVal == Key) and (Hash =/= Key) -> 
                        taskcompletionmonitor ! {completed, Hash, HopsCount, Key};
                    
                    true ->
                        dict:fetch(NodeVal, dict:fetch(finger_table, NodeState)) ! {lookup, Id, Key, HopsCount + 1, self()}
                end
                ;
        {kill} ->
            UpdatedState = NodeState,
            exit("received exit signal");
        {state, Pid} -> Pid ! NodeState,
                        UpdatedState = NodeState;
        {get_successor, Id, Pid} ->
                        FoundSeccessor = get_successor(Id, NodeState),
                        UpdatedState = NodeState,
                        {Pid} ! {get_successor_reply, FoundSeccessor};

        
        {fix_fingers, FingerTable} -> 
            % io:format("Received Finger for ~p ~p", [Hash, FingerTable]),
            UpdatedState = dict:store(finger_table, FingerTable, NodeState)
    end, 
    rest_node(UpdatedState).

peer(Hash, M, ChordPeers, _NodeState) -> 
    %io:format("Node is spawned with hash ~p",[Hash]),
    FingerTable = lists:duplicate(M, nodearbitrary(Hash, ChordPeers)),
    NodeStateUpdated = dict:from_list([{id, Hash}, {predecessor, nil}, {finger_table, FingerTable}, {next, 0}, {m, M}]),
    rest_node(NodeStateUpdated)        
.


node_process(ChordPeers, _, _, 0, CondNet) -> 
    [ChordPeers, CondNet];
node_process(ChordPeers, PeersNum, M, NoPeers, CondNet) ->
    [Hash, NewNetworkState] = peer_chord(ChordPeers, PeersNum,  M, CondNet),
    node_process(lists:append(ChordPeers, [Hash]), PeersNum, M, NoPeers - 1, NewNetworkState)
.



get_ith_successor(Hash, CondNet, I,  M) -> 
    case dict:find((Hash + I) rem trunc(math:pow(2, M)), CondNet) of
        error ->
             get_ith_successor(Hash, CondNet, I + 1, M);
        _ -> (Hash + I) rem trunc(math:pow(2, M))
    end
.

fineger_table_data(_, _, M, M,FingerList) ->
    FingerList;
fineger_table_data(Node, CondNet, M, I, FingerList) ->
    Hash = element(1, Node),
    Ith_succesor = get_ith_successor(Hash, CondNet, trunc(math:pow(2, I)), M),
    fineger_table_data(Node, CondNet, M, I + 1, FingerList ++ [{Ith_succesor, dict:fetch(Ith_succesor, CondNet)}] )
.


fingtables(_, [], FTDict,_) ->
    FTDict;

fingtables(CondNet, NetList, FTDict,M) ->
    [First | Rest] = NetList,
    FingerTables = fineger_table_data(First, CondNet,M, 0,[]),
    fingtables(CondNet, Rest, dict:store(element(1, First), FingerTables, FTDict), M)
.



send_finger_tables_nodes([], _, _) ->
    ok;
send_finger_tables_nodes(NodesToSend, CondNet, FingerTables) ->
    [First|Rest] = NodesToSend,
    Pid = dict:fetch(First, CondNet),
    Pid ! {fix_fingers, dict:from_list(dict:fetch(First, FingerTables))},
    send_finger_tables_nodes(Rest, CondNet, FingerTables)
.


send_finger_tables(CondNet,M) ->
    FingerTables = fingtables(CondNet, dict:to_list(CondNet), dict:new(),M),
    % io:format("~n~p~n", [FingerTables]),
    send_finger_tables_nodes(dict:fetch_keys(FingerTables), CondNet, FingerTables)
.

get_node_pid(Hash, CondNet) -> 
    case dict:find(Hash, CondNet) of
        error -> nil;
        _ -> dict:fetch(Hash, CondNet)
    end
.

send_message_to_node(_, [], _) ->
    ok;
send_message_to_node(Key, ChordPeers, CondNet) ->
    [First | Rest] = ChordPeers,
    Pid = get_node_pid(First, CondNet),
    Pid ! {lookup, First, Key, 0, self()},
    send_message_to_node(Key, Rest, CondNet)
.

send_messages_all_nodes(_, 0, _, _) ->
    ok;
send_messages_all_nodes(ChordPeers, NumRequest, M, CondNet) ->
    timer:sleep(1000),
    Key = lists:nth(rand:uniform(length(ChordPeers)), ChordPeers),
    send_message_to_node(Key, ChordPeers, CondNet),
    send_messages_all_nodes(ChordPeers, NumRequest - 1, M, CondNet)
.

kill_all_nodes([], _) ->
    ok;
kill_all_nodes(ChordPeers, CondNet) -> 
    [First | Rest] = ChordPeers,
    get_node_pid(First, CondNet) ! {kill},
    kill_all_nodes(Rest, CondNet).

getTotalHops() ->
    receive
        {totalhops, HopsCount} ->
            HopsCount
        end.


chal_accomp(0, HopsCount) ->
    start_process ! {totalhops, HopsCount}
;

chal_accomp(NumRequests, HopsCount) ->
    receive 
        {completed, _Pid, HopsCountForTask, _Key} ->
            % io:format("received completion from ~p, Number of Hops ~p, For Key ~p", [Pid, HopsCountForTask, Key]),
            chal_accomp(NumRequests - 1, HopsCount + HopsCountForTask)
    end
.


find_kill_send(ChordPeers, NoPeers, NumRequest, M, CondNet) ->
    register(taskcompletionmonitor, spawn(project3, chal_accomp, [NoPeers * NumRequest, 0])),

    send_messages_all_nodes(ChordPeers, NumRequest, M, CondNet),

    TotalHops = getTotalHops(),
    
    {ok, File} = file:open("./stats.txt", [append]),
    io:format(File, "~n Average Hops = ~p   TotalHops = ~p    NoPeers = ~p    NumRequests = ~p  ~n", [TotalHops/(NoPeers * NumRequest), TotalHops, NoPeers , NumRequest]),
    io:format("~n Average Hops = ~p   TotalHops = ~p    NoPeers = ~p    NumRequests = ~p  ~n", [TotalHops/(NoPeers * NumRequest), TotalHops, NoPeers , NumRequest]),
    kill_all_nodes(ChordPeers, CondNet)
.

begin_net(Num_Nodes, Num_Request) ->
    M = fet_m(Num_Nodes),
    [CNodes, NetState] = node_process([], round(math:pow(2, M)), M, Num_Nodes, dict:new()),
    
    send_finger_tables(NetState,M),
    find_kill_send(CNodes, Num_Nodes, Num_Request, M, NetState)
.


main(Nodes, Requests) ->
    register(start_process, spawn(project3, begin_net, [Nodes, Requests]))
.
