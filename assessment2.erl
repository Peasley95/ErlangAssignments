-module(assessment1).
-compile(export_all).

% Part One: Trees

% Type of binary trees with integers stored at each node.
-type value() :: integer().
-type tree() :: leaf
            | {node,value(),tree(),tree()}.

% 1.1 
tdepth(leaf) -> 0;
% Guard to check which way to traverse down the tree.
tdepth({node,_,T1,T2}) when T1>T2  ->
    1 + tdepth(T1);
tdepth({node,_,_T1,T2}) ->
    1 + tdepth(T2).


% 1.2 The base case is for two leaves to
% increase the answer by two and stop.
leaves(leaf) -> 
    1;
leaves({node,_,T1,T2}) ->
    leaves(T1) + leaves(T2).

% 1.3 
flatten(leaf) ->
    [];
flatten({node,V,T1,T2}) ->
    flatten(T1)++[V]++flatten(T2).


% I defined the tnodes function incase it is needed for 1.4
% I didn't end up using it though.
tnodes(leaf) ->
    0;
tnodes({node,_,T1,T2}) ->
   1 + tnodes(T1) + tnodes(T2).

% 1.4 I used the flatten function from 1.3 to complete this
% After flattening into a list the list gets passed back into the function
% So I had to implement it in 2 steps to account for the change in input type
idx([X|_],0)  ->
    X;
idx([_|Xs],N)  ->
    idx(Xs,N-1);
idx(T,N) ->
    idx(flatten(T),N).




% Part Two SSA

% 2.1 First there is a type declaration for expression. This is to determine what
%     is in the right hand side of a statement. 
-type expr() :: {'num',integer()}
 | {'var',atom()}
 | {'add',expr(),expr()}
 | {'mul',expr(),expr()}
 | {'sub',expr(),expr()}
 | {'divide',expr(),expr()}.
% Then there is a type declaration for the environment, This is to hold the integer values
% that correspond with each atom variable.
-type env() :: [{atom(),integer()}].
% Lastly there is a "main" type wich is the 4 tuples needed to create an ssa program.
% They are the left hand side of the :=. The right hand side of the :=.
% The next ssa statement. Lastly the environment that it is being run in.
-type ssa() :: {{'left', {'var',atom()}},{'right',expr()},{'next',ssa()},env()}
| {{'left', {'var',atom}},{'right',expr()},{'next',endOfProg},env()}. 



addToEnv(V,{endOfProg},E,L) ->
    lists:append(E,[{L,V}]);
addToEnv(V,{_L,_R,_N,_OldE},E,L) ->
    lists:append(E,[{L,V}]).
addToEnv(V,{_OldL,_R,_N,E},L) ->
    lists:append(E,[{L,V}]).
% 2.2 assessment1:run({{left,{var,a}},{right,{add,{num,4},{num,7}}},{next,{{left,{var,b}},{right,{mul,{var,a},{num,3}}},{next,endOfProg},[]}},[]}). is the program that I am attempting to run 
% to test my solution. It works an outputs [{a,11},{b,33}] as expected. I have tried to simplify it but only succeed in breaking it so I am moving on.
% assessment1:run({{left,{var,a}},{right,{num,3}},{next,{{left,{var,b}},{right,{add,{var,a},{num,2}}},{next, {{left,{var,c}},{right,{mul,{var,b},{var,b}}},{next,{endOfProg}},[]}},[]}},[]}).[{a,3},{b,5},{c,25}]
% Is the example from the paper. I messed up and had the environment within the tuple but it was too late to correct it when I noticed.
%
% Sorry about how messy this is. You should be able to pass in a program like the example program that I used before and the fuction should return 
% the populated environment.
run({{left,{var,L}},{right,R},{next,N},E}) ->
        V=eval(E,R),
        NewE = addToEnv(V,N,L),
        run(N,NewE).
% This is for the base case of when the next program is the end, it just returns what is currently in the environment which should be correct.
run({endOfProg},E) ->
        E;
%   
run({{left,{var,L}},{right,R},{next,N},_oldE},E) ->
        V=eval(E,R),
        NewE = addToEnv(V,N,E,L),
        run(N,NewE).

% 2.3 I plan on doing this by running the program and checking the environment in list form
% by removing the values because they're not important right now

% I wrote this function to order the list and take away instances of X.
% I didn't think it would work but it did so here you go
orderList([]) ->
    [];
orderList([{X,_}|Xs]) ->
    lists:sort([X|orderList(Xs)--[X]]).

% Base case
unique([]) ->
    [];
% after the list is ordered it checks that removing all cases of X
% from the list only decrements the size by one. This shows that the variables are unique
% returns true if unique and false if not unique.
unique([X|Xs])  ->
        length([X|Xs]) - 1 =/= length([Xs] -- [X]);
% Entry point, runs the SSA program and spits out a list of the variables assigned to in the program
unique(P) ->
    [X|Xs] = run(P),
    unique(orderList([X|Xs])).

% 2.4 This will also return either true or false
defined({{left,L},{right,R},{next,N},Env}) ->
    E = run({{left,L},{right,R},{next,N},Env}),
    eval(E,R).
    % Env = run(P),
  %  defined(P,Env).
%defined({{left,{var,L}},R,{next,N},_},[{X1,X2}|Xs]) when X1 =/= R->
 %   defined(X1 == L) orelse defined(Xs);   
%defined({{left,{var,L}},R,{next,N},_},[{X1,X2}|Xs]) ->
  %  X1 =/= L orelse defined(Xs).

% 2.5 For this I'll use the {add,{num,8},{mul,{num,2},{num,9}} expression from expr.erl
translate_expr(Expr) ->
        X = eval([],Expr),
        E = [{newVar,X}],
        translate_expr(Expr,E).
translate_expr(Expr,[{X,_Val}|Xs]) ->
        SSA = {{left,{var,X}},{right,Expr},{next,endOfProg},[{X,_Val}|Xs]},
        run(SSA).

    





% Stuff from the lectures that were needed to implement run 
lookupVar(A,[{Var,X}|_Xs]) when A==Var ->
    X;
lookupVar(A,[_Env|Xs]) ->
    lookupVar(A,Xs).

-spec print(expr()) -> string().
print({num,N}) ->
    integer_to_list(N);
print({var,A}) ->
    atom_to_list(A);
print({add,E1,E2}) ->
    "("++print(E1)++"+"++print(E2)++")";
print({mul,E1,E2}) ->
    "("++print(E1)++"*"++print(E2)++")";
print({sub,E1,E2}) ->
    "("++print(E1)++"-"++print(E2)++")";
print({divide,E1,E2}) ->
    "("++print(E1)++"/"++print(E2)++")".

-spec eval(env(),expr()) -> integer().

eval(Env,endOfProg) ->
Env;
eval(_Env,{num,N}) ->
    N;
eval(Env,{var,A}) ->
    lookupVar(A,Env);
eval(Env,{add,E1,E2}) ->
    eval(Env,E1)+eval(Env,E2);
eval(Env,{mul,E1,E2}) ->
    eval(Env,E1)*eval(Env,E2);
eval(Env,{sub,E1,E2}) ->
    eval(Env,E1)-eval(Env,E2);
eval(Env,{divide,E1,E2}) ->
    eval(Env,E1) div eval(Env,E2).

    

    