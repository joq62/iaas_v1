%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Manage Computers
%%% 
%%% Created : 
%%% -------------------------------------------------------------------
-module(iaas). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include("timeout.hrl").
%-include("log.hrl").
%-include("config.hrl").
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state, {computer_status}).



%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------
-define(HbInterval,20*1000).


-export([running_computers/0,available_computers/0,not_available_computers/0,
	 start_node/3,stop_node/1,
	 active/0,passive/0,all/0,
	 log/0
	]).

-export([start/0,
	 stop/0,
	 ping/0,
	 heart_beat/1
	]).

%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals



%% Gen server functions

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).


ping()-> 
    gen_server:call(?MODULE, {ping},infinity).

%%-----------------------------------------------------------------------
running_computers()->
    gen_server:call(?MODULE, {running_computers},infinity).
available_computers()->
    gen_server:call(?MODULE, {available_computers},infinity).
not_available_computers()->
    gen_server:call(?MODULE, {not_available_computers},infinity).

start_node(IpAddr,Port,VmId) ->
    gen_server:call(?MODULE, {start_node,IpAddr,Port,VmId},infinity).
stop_node(Vm) ->
    gen_server:call(?MODULE, {stop_node,Vm},infinity).
active()->
    gen_server:call(?MODULE, {active},infinity).
passive()->
    gen_server:call(?MODULE, {passive},infinity).
all()->
    gen_server:call(?MODULE, {all},infinity).

log()->
    gen_server:call(?MODULE, {log},infinity).
%%----------------------------------------------------------------------

heart_beat(Interval)->
    gen_server:cast(?MODULE, {heart_beat,Interval}).


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% --------------------------------------------------------------------
init([]) ->
 %   {ok,HbInterval}= application:get_env(hb_interval),
    ComputerStatus=computer:check_computers(),
    io:format("~p~n",[{?MODULE,?LINE,ComputerStatus}]),
    spawn(fun()->h_beat(?HbInterval) end),
    {ok, #state{computer_status=ComputerStatus}}.
    
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (aterminate/2 is called)
%% --------------------------------------------------------------------
handle_call({ping},_From,State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};


handle_call({running_computers},_From,State) ->
    Reply=[HostId||{running,HostId}<-State#state.computer_status],
    {reply,Reply,State};

handle_call({available_computers},_From,State) ->
    Reply=[HostId||{available,HostId}<-State#state.computer_status],
    {reply,Reply,State};

handle_call({not_available_computers},_From,State) ->
    Reply=[HostId||{not_available,HostId}<-State#state.computer_status],
    {reply,Reply,State};


handle_call({start_node,IpAddr,Port,VmId},_From,State) ->
    Reply={not_implemented,start_node,IpAddr,Port,VmId},
    {reply,Reply,State};

handle_call({stop_node,Vm},_From,State) ->
    Reply={not_implemented,stop_node,Vm},
    {reply,Reply,State};

handle_call({passive},_From,State) ->
    Reply={not_implemented,passive},
    {reply,Reply,State};

handle_call({active},_From,State) ->
    Reply={not_implemented,active},
    {reply,Reply,State};

handle_call({all},_From,State) ->
    Reply={not_implemented,all},
    {reply,Reply,State};

handle_call({log},_From,State) ->
    Reply={not_implemented,log},
    {reply,Reply,State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% -------------------------------------------------------------------
handle_cast({heart_beat,Interval}, State) ->
    spawn(fun()->h_beat(Interval) end),    
    {noreply, State};
			     
handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(Info, State) ->
    io:format("unmatched match info ~p~n",[{?MODULE,?LINE,Info}]),
    {noreply, State}.


%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
h_beat(Interval)->
    
    timer:sleep(Interval),
    rpc:cast(node(),?MODULE,heart_beat,[Interval]).

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
