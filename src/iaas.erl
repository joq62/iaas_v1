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
-record(state, {computer_status,vm_status}).



%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------
-define(HbInterval,20*1000).
-define(ControlVmId,"10250").
-define(WorkerVmIds,["30000","30001","30002","30003","30004","30005","30006","30007","30008","30009"]).

-export([vm_status/1,computer_status/1,
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
vm_status(Type)->
    gen_server:call(?MODULE, {vm_status,Type},infinity).
computer_status(Type)->
    gen_server:call(?MODULE, {computer_status,Type},infinity).


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

heart_beat({Interval,ComputerStatus,VmStatus})->
    gen_server:cast(?MODULE, {heart_beat,{Interval,ComputerStatus,VmStatus}}).


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

% To be removed
-define(TEXTFILE,"./test_src/dbase_init.hrl").

init([]) ->
 
    ssh:start(),
    ok=application:start(dbase_service),
    % To be removed
    dbase_service:load_textfile(?TEXTFILE),
    timer:sleep(1000),

    spawn(fun()->h_beat(?HbInterval) end),
    {ok, #state{computer_status=[],vm_status=[]}}.
    
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

handle_call({vm_status,Type},_From,State) ->
    Reply= case Type of
	       running->
		   [{HostId,R}||{HostId,
			    {running,R},
			    {available,_A},
			    {not_available,_NA}}<-State#state.vm_status];
	       available->
		   [{HostId,A}||{HostId,
				 {running,_R},
				 {available,A},
				 {not_available,_NA}}<-State#state.vm_status];
	       not_available->
		   [{HostId,NA}||{HostId,
				 {running,_R},
				 {available,_A},
				 {not_available,NA}}<-State#state.vm_status];
	       Err->
		   {error,[edefined,Err]}
	   end,
    {reply,Reply,State};

handle_call({computer_status,Type},_From,State) ->
    Reply= case Type of
	       running->
		   [HostId||{running,HostId}<-State#state.computer_status];
	       available->
		   [HostId||{available,HostId}<-State#state.computer_status];
	       not_available->
		   [HostId||{not_available,HostId}<-State#state.computer_status];
	       Err->
		   {error,[edefined,Err]}
	   end,
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
handle_cast({heart_beat,{Interval,ComputerStatus,VmStatus}}, State) ->
    io:format("ComputerStatus ~p~n",[{?MODULE,?LINE,time(),ComputerStatus}]),
    io:format("VmStatus ~p~n",[{?MODULE,?LINE,time(),VmStatus}]),
    NewState=State#state{computer_status=ComputerStatus,vm_status=VmStatus},
    spawn(fun()->h_beat(Interval) end),    
    {noreply, NewState};
			     
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
 %   io:format(" *************** "),
 %   io:format(" ~p",[{time()}]),
 %   io:format(" *************** ~n"),
    ComputerStatus=computer:status_computers(),
%    io:format("ComputerActualState ~p~n",[{?MODULE,?LINE,time(),ComputerStatus}]),
    AvailableComputers=[HostId||{available,HostId}<-ComputerStatus],
    
    [ControlVmId]=db_vm_id:read(controller),
%    io:format("ControlVmId ~p~n",[{?MODULE,?LINE,ControlVmId}]),
    WorkerVmIds=db_vm_id:read(worker),
%    io:format("WorkerVmIds ~p~n",[{?MODULE,?LINE,WorkerVmIds}]),

    _CleanComputers=[computer:clean_computer(HostId,ControlVmId)||HostId<-AvailableComputers],
%    io:format("CleanComputers ~p~n",[{?MODULE,?LINE,CleanComputers}]),

    _StartComputers=[computer:start_computer(HostId,ControlVmId)||HostId<-AvailableComputers],
 %   io:format("StartComputers ~p~n",[{?MODULE,?LINE,StartComputers}]),  

    _CleanVms=[computer:clean_vms(WorkerVmIds,HostId)||HostId<-AvailableComputers],
  %  io:format("CleanVms ~p~n",[{?MODULE,?LINE,CleanVms }]),

    _StartVms=[computer:start_vms(WorkerVmIds,HostId)||HostId<-AvailableComputers],
 %   io:format("StartVms ~p~n",[{?MODULE,?LINE,StartVms}]),
  
    RunningComputers=[HostId||{running,HostId}<-ComputerStatus],
    VmStatus=[vms:status_vms(HostId,WorkerVmIds)||HostId<-RunningComputers],
 %   io:format("VmStatus ~p~n",[{?MODULE,?LINE,VmStatus}]),

    _CleanVms2=[computer:clean_vms(VmIds,HostId)||{HostId,_,{available,VmIds},_}<-VmStatus],
%    io:format("CleanVms2 ~p~n",[{?MODULE,?LINE,CleanVms2 }]),

    _StartVms2=[computer:start_vms(VmIds,HostId)||{HostId,_,{available,VmIds},_}<-VmStatus],
%    io:format("StartVms2 ~p~n",[{?MODULE,?LINE,StartVms2}]),
    
    
    ComputerStatus2=computer:status_computers(),
    VmStatus2=[vms:status_vms(HostId,WorkerVmIds)||HostId<-RunningComputers],


    rpc:cast(node(),?MODULE,heart_beat,[{Interval,ComputerStatus2,VmStatus2}]).

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
