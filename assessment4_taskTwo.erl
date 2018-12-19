-module(taskTwo).
-export([lossyNetwork/0,clientStartRobust/2,testTwo/0]).

lossyNetwork() ->
    receive 
        {Client, Server} -> lossyNetworkMcDoSomething(Client, Server)
    end.

lossyNetworkMcDoSomething(Client,Server) ->
    receive 
        {Server,estab} -> Client!{self(),estab};
        {Client, TCP} -> 
            A = rand:uniform(), 
            case A >= 0.5 of
                    true -> Server!{self(), TCP}, monitor:debug(Client, Client, TCP);
                    false -> dropped
            end;
        {Server, TCP} -> Client!{self(), TCP}, monitor:debug(Client, Server, TCP)
    end,
    lossyNetworkMcDoSomething(Client, Server).

% This is currently wrong but I just realised that 
% that I'm trying to resend the wrong packet. 
% You need to resend the one from before, not the next one.

clientStartRobust(Server,String) ->
        Server!{self(),{syn,0,0}},
        receive
            {Server,{synack,ServerSeq,ClientSeq}} -> 
                Server!{self(),{ack,ClientSeq,ServerSeq+1}},
                receive 
                    {Server,estab} -> 
                        sendPackets(Server,self(),ServerSeq+1,ClientSeq,taskOne:packet(String))
                after 2000 ->
                    retry(Server,ClientSeq,ServerSeq+1,String)
                end 
        after 2000 ->
            clientStartRobust(Server,String)
        end.
retry(Server,ClientSeq,ServerSeq,String) ->
        Server!{self(),{ack,ClientSeq,ServerSeq}},
        receive 
            {Server,estab} -> 
                sendPackets(Server,self(),ServerSeq,ClientSeq,taskOne:packet(String))
        after 2000 ->
            retry(Server,ClientSeq,ServerSeq,String)
        end.

% I have duplicated this functioin so that the changes are apparrent.
% I know that this is not good practice
%
% This function currently runs through completely or sends the first packet over and over again
sendPackets(Server,Pid,ServerSeq,ClientSeq,[X|Xs]) ->
    Server!{Pid,{ack,ClientSeq,ServerSeq,X}},
    receive
        {Server,{ack,NewServerSeq,NewClientSeq}} ->
            sendPackets(Server,Pid,NewServerSeq,NewClientSeq,Xs)
    after 2000 ->
            sendPackets(Server,Pid,ServerSeq,ClientSeq,[X|Xs])
    end;
sendPackets(Server,Pid,ServerSeq,ClientSeq,[]) ->
        Server!{Pid,{fin,ClientSeq,ServerSeq}},
        receive
            {_Client,{ack,ServerSeq,ClientSeq}} ->
                io:fwrite("~s~n",["Client done"])
        after 2000 ->
            Server!{Pid,{fin,ClientSeq,ServerSeq}},
            receive
                {_Client,{ack,ServerSeq,ClientSeq}} ->
                    io:fwrite("~s~n",["Client done"])
            after 2000 ->
                    sendPackets(Server,Pid,ServerSeq,ClientSeq,[])
            end
        end.

testTwo() ->
    Server = spawn(taskOne,serverStart,[]),
    Monitor = spawn(taskTwo,lossyNetwork,[]),
    Client = spawn(taskTwo,clientStartRobust,
                    [Monitor,"Small piece of text"]),
    Monitor!{Client,Server}.