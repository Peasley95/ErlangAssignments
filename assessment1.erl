-module(assessment1).
-export([m4/1, sum_front/2, truncate/1]).

% Question 1:
%
%   This function retuns 14
%   The function takes the list and iterates taking away each element
%   away from the sum of the previous sum.
%   when it gets to the end of the list it takes 3 away from the overall product.
%   This works out like so.
%   3-(-2-(1-(-5-3))) 
%   = 3-(-2-(1-(-8)))
%   = 3-(-2-(1+8))
%   = 3-(-2-(9))
%   = 3-(-2-9)
%   = 3-(-11)
%   = 3+11
%   = 14
%   I have included the function to check my answer
m4([]) -> 3;
m4([X|Xs]) -> X - m4(Xs).

% Question 2:
%
%   1. The first issue is that commas are used to separate conditions as 
%   opposed to semi-colons.
%   
%   2. in the second clause, the arguments are the wrong way around. It should be a list
%   and then an integer.
%
%   3. infinite loop caused by N>0. Changed to N<length([X|Xs])

sum_front([X|Xs],0) -> 0;
sum_front([],_) -> 0;
sum_front([X|Xs],N) when N< length([X|Xs]) -> 
X + sum_front(Xs,N).

truncate([]) -> empty;
truncate([X|Xs]) when length(Xs) < 1 ->
    [];
truncate([X|Xs]) when length(Xs) >=0 ->
    [X| truncate(Xs)].
