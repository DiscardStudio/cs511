%%% Stub for Quiz 5


-module(calc).
-compile(nowarn_export_all).
-compile(export_all).

env() -> #{"x"=>3, "y"=>7}.

e1() ->
    {add, 
     {const,3},
     {divi,
      {var,"x"},
      {const,4}}}.

e2() ->
    {add, 
     {const,3},
     {divi,
      {var,"x"},
      {const,0}}}.

e3() ->
    {add, 
     {const,3},
     {divi,
      {var,"r"},
      {const,4}}}.

eval({const,N},_E) ->
    {val, N};

eval({var,Id},E) ->
    {val, maps:find(Id,E)};

eval({add,E1,E2},E) ->
    eval(E1, E) + eval(E2, E);

eval({sub,E1,E2},E) ->
    complete;

eval({mult,E1,E2},E) ->
    complete;

eval({divi,E1,E2},E) ->
    complete.

