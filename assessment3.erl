-module(assess3).
-compile(export_all).


client(State, S) ->
    S!{left,1,State},
    S!{right,3,State},
    receive
        X -> io:fwrite("Message ~s received~n", [X])
    end.


server(State) ->
        receive
                {left,P,State} -> skip, server(State); 
                {right, Q, Y} -> 
                    Q!State,
                server(Y)
            end.

run() ->
    Server = spawn(?MODULE,server,[0]),
    spawn(?MODULE,client,[0,Server]),
    spawn(?MODULE,client,[0,Server]).

% This is deterministic because there is no delay involved and there is no way to deviate from the loop

test1(P,Q,Serv) ->
    receive
    {P,Q} -> A = {P,Q}
    end;
    Serv!A.

test2() ->
    [].
%Did not work


    
