-module(server).

-export([start_server/0]).

-include_lib("./defs.hrl").

-spec start_server() -> _.
-spec loop(_State) -> _.
-spec do_join(_ChatName, _ClientPID, _Ref, _State) -> _.
-spec do_leave(_ChatName, _ClientPID, _Ref, _State) -> _.
-spec do_new_nick(_State, _Ref, _ClientPID, _NewNick) -> _.
-spec do_client_quit(_State, _Ref, _ClientPID) -> _NewState.

start_server() ->
    catch(unregister(server)),
    register(server, self()),
    case whereis(testsuite) of
	undefined -> ok;
	TestSuitePID -> TestSuitePID!{server_up, self()}
    end,
    loop(
      #serv_st{
	 nicks = maps:new(), %% nickname map. client_pid => "nickname"
	 registrations = maps:new(), %% registration map. "chat_name" => [client_pids]
	 chatrooms = maps:new() %% chatroom map. "chat_name" => chat_pid
	}
     ).

loop(State) ->
    receive 
	%% initial connection
	{ClientPID, connect, ClientNick} ->
	    NewState =
		#serv_st{
		   nicks = maps:put(ClientPID, ClientNick, State#serv_st.nicks),
		   registrations = State#serv_st.registrations,
		   chatrooms = State#serv_st.chatrooms
		  },
	    loop(NewState);
	%% client requests to join a chat
	{ClientPID, Ref, join, ChatName} ->
	    NewState = do_join(ChatName, ClientPID, Ref, State),
	    loop(NewState);
	%% client requests to join a chat
	{ClientPID, Ref, leave, ChatName} ->
	    NewState = do_leave(ChatName, ClientPID, Ref, State),
	    loop(NewState);
	%% client requests to register a new nickname
	{ClientPID, Ref, nick, NewNick} ->
	    NewState = do_new_nick(State, Ref, ClientPID, NewNick),
	    loop(NewState);
	%% client requests to quit
	{ClientPID, Ref, quit} ->
	    NewState = do_client_quit(State, Ref, ClientPID),
	    loop(NewState);
	{TEST_PID, get_state} ->
	    TEST_PID!{get_state, State},
	    loop(State)
    end.

%% executes join protocol from server perspective
do_join(ChatName, ClientPID, Ref, State) ->
    case maps:get(ChatName, State#serv_st.chatrooms) of
		{badmap,_} ->
			error;
		{badkey,_} ->
			S = spawn(chatroom, start_chatroom, [ChatName]),
			S!{self(), Ref, register, ClientPID, maps:get(ClientPID,State#serv_st.nicks)},
			#serv_st{
				nicks=State#serv_st.nicks,
				registrations=maps:put(ChatName,lists:append(maps:get(ChatName,State#serv_st.registrations),[ClientPID]),State#serv_st.registrations),
				chatrooms=maps:put(ChatName,S,State#serv_st.chatrooms)
			};
		Value ->
			Value!{self(), Ref, register, ClientPID, maps:get(ClientPID,State#serv_st.nicks)},
			#serv_st{
				nicks=State#serv_st.nicks,
				registrations=maps:put(ChatName,lists:append(maps:get(ChatName,State#serv_st.registrations),[ClientPID]),State#serv_st.registrations),
				chatrooms=State#serv_st.chatrooms
			}
	end.
	

%% executes leave protocol from server perspective
do_leave(ChatName, ClientPID, Ref, State) ->
    case maps:get() of
		{badmap, _} ->
			error;
		{badkey, _} ->
			error;
		Value ->
			Value!{self(), Ref, unregister, ClientPID, maps:get(ClientPID,State#serv_st.nicks)},
			NewState = #serv_st{
				nicks=State#serv_st.nicks,
				registrations=maps:put(ChatName,lists:delete(ClientPID,maps:get(ChatName,State#serv_st.registrations)),State#serv_st.registrations),
				chatrooms=State#serv_st.chatrooms
			},
			ClientPID!{self(), Ref, ack_leave},
			NewState
	end.

find_item(_,_, []) ->
	false;
find_item(State, E, [H|T]) -> 
	case maps:get(H,State#serv_st.nicks) of
		{badmap, _} ->
			false;
		{badkey, _} ->
			find_item(State, E,T);
		Value ->
			case maps:get(Value,State#serv_st.nicks) of 
				{badmap, _} ->
					false;
				{badkey, _} ->
					false;
				Value when Value == E ->
					true;
				_ -> 
					find_item(State, E,T)
			end
	end.
%% executes new nickname protocol from server perspective
do_new_nick(State, Ref, ClientPID, NewNick) ->
    case find_item(State, NewNick,maps:keys(State#serv_st.nicks)) of
		true ->
			ClientPID!{self(), Ref, err_nick_used};
		false ->
			[ E!{self(), Ref, update_nick, ClientPID, NewNick} || E <- maps:keys(State#serv_st.chatrooms) ],
			NewState = #serv_st{
				nicks=maps:put(ClientPID,NewNick, State#serv_st.nicks),
				registrations=State#serv_st.registrations,
				chatrooms=State#serv_st.chatrooms	
			},
			ClientPID!{self(), Ref, ok_nick},
			NewState
	end.

%% executes client quit protocol from server perspective
do_client_quit(State, Ref, ClientPID) ->
	[ E!{self(), Ref, unregister, ClientPID} || E <- maps:keys(State#serv_st.chatrooms) ],
	ClientPID!{self(), Ref, ack_quit},
	#serv_st{
		nicks=maps:remove(ClientPID, State#serv_st.nicks),
		registrations=State#serv_st.registrations, %Need to remove client from here
		chatrooms=State#serv_st.chatrooms	
	}.
