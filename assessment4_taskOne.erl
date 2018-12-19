-module(taskOne).
-export([serverStart/0,clientStart/2,testOne/0,starter/0,packet/1,sendPackets/5]).

serverStart() -> 
    receive
        {Client,{syn,_,_}} ->
            Client!{self(),{synack,0,1}}, 
        receive   
            {Client,{ack,ClientSeq,ServerSeq}} -> 
                Client!{self(),estab},
                I = server:serverEstablished(Client,ServerSeq,ClientSeq,[],0),
                serverAux(I)
        after 2000 ->
            serverStart()
        end
    end.
% Auxilliary fuction to pass on the state
serverAux(I) ->
    receive
        {Client,{syn,_,_}} ->
            Client!{self(),{synack,I,1}},
        receive        
            {Client,{ack,ClientSeq,ServerSeq}} -> 
                Client!{self(),estab},
                A = server:serverEstablished(Client,ServerSeq,ClientSeq,[],0),
                serverAux(A)
        after 2000 ->
            serverAux(I)
        end
    end.

clientStart(Server,String) ->
    Server!{self(),{syn,0,0}},
    receive
        {Server,{synack,ServerSeq,ClientSeq}} ->
            Server!{self(),{ack,ClientSeq,ServerSeq+1}},
            receive {Server,estab} -> sendPackets(Server,self(),ServerSeq+1,ClientSeq,packet(String)) end
    end.

packet(String) when length(String) > 7 ->
    [string:substr(String,1,7)|packet(string:substr(String,8,length(String)))];
packet(String) ->
    [String].

sendPackets(Server,Pid,ServerSeq,ClientSeq,[X|Xs]) ->
    Server!{Pid,{ack,ClientSeq,ServerSeq,X}},
    receive
        {Server,{ack,NewServerSeq,NewClientSeq}} ->
                sendPackets(Server,Pid,NewServerSeq,NewClientSeq,Xs)      
    end;
sendPackets(Server,Pid,ServerSeq,ClientSeq,[]) ->
        Server!{Pid,{fin,ClientSeq,ServerSeq}},
        receive
            {_Client,{ack,ServerSeq,ClientSeq}} ->
                io:fwrite("~s~n",["Client done"])
        end. 

    
% 1.3 
%
%   tcpMonitorStart takes a tuple of the PID's of the server 
%   and the client and starts the tcpMonitor. In this function,    
%   the tcpMonitor acts as the server for the client and the client
%   for the server.
%   
%   This means that it receives messages, prints the debugging message
%   and then forwards the messages to their intended destinations,
%   This is a bit like message intercepting.

testOne() ->
    Monitor = spawn(monitor, tcpMonitorStart, []),
    Server = spawn(taskOne, serverStart, []),
    Client = spawn(taskOne, clientStart,
                    [Monitor, "Small piece of text"]),
    Monitor!{Client,Server}.                

starter() ->
    Server = spawn(taskOne, serverStart, []),
    _Client1 = spawn(taskOne, clientStart, 
                [Server, "The quick brown fox jumped over the lazy dog."]),
    _Client2 = spawn(taskOne, clientStart, 
                [Server, "Contrary to popular belief, Lorem Ipsum is not simply random text."]).