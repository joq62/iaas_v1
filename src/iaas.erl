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

-define(DbaseVmId,"10250").

%-define(ControlVmId,"10250").
%-define(TimeOut,3000).


%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state, {computer_running,
		computer_available,
		computer_not_available,
		vms_running,
		vms_available,
		vms_not_available,
		vm_candidates}).



%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------
-define(HbInterval,20*1000).
-define(ControlVmId,"10250").


% OaM related
-export([update_status_computers/0
	]).

-export([vm_status/1,computer_status/1,
	 start_node/3,stop_node/1,
	 active/0,passive/0,all/0,
	 allocate_vm/0,free_vm/1,
	 get_vm/2,get_all_vms/0,
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
update_status_computers()->
    gen_server:call(?MODULE, {update_status_computers},infinity).

vm_status(Status)->
    gen_server:call(?MODULE, {vm_status,Status},infinity).
computer_status(Status)->
    gen_server:call(?MODULE, {computer_status,Status},infinity).


allocate_vm()->
    gen_server:call(?MODULE, {allocate_vm},infinity).
free_vm(Vm)->
    gen_server:call(?MODULE, {free_vm,Vm},infinity).


get_vm(Restrictions,HostIds)->
    gen_server:call(?MODULE, {get_vm,Restrictions,HostIds},infinity).
get_all_vms()->
    gen_server:call(?MODULE, {get_all_vms},infinity).
    

    
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

% To be removed
-define(TEXTFILE,"./test_src/dbase_init.hrl").

init([]) ->
    ssh:start(),
%    ok=application:start(dbase_service),
    % To be removed
%    dbase_service:load_textfile(?TEXTFILE),
 %   timer:sleep(1000),

    spawn(fun()->h_beat(?HbInterval) end),
    {ok, #state{computer_running=[],
		computer_available=[],
		computer_not_available=[],
		vms_running=[],
		vms_available=[],
		vms_not_available=[],
		vm_candidates=[]}}.
    
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


handle_call({get_all_vms},_From,State) ->
    Reply=State#state.vm_candidates,
    {reply, Reply, State};


handle_call({update_status_computers},_From,State) ->
    Reply=rpc:call(node(),computer,update_status_computers,[],2*10000),	  
    {reply, Reply, State};

handle_call({allocate_vm},_From,State) ->
    Reply=rpc:call(node(),vm,allocate,[],5000),	  
    {reply, Reply, State};

handle_call({free_vm,Vm},_From,State) ->
    Reply=rpc:call(node(),vm,free,[Vm],5000),	  
    {reply, Reply, State};


handle_call({get_vm,Restriction,HostIds},_From,State) ->
   
    Reply=case Restriction of
	      not_from->
		  case [{XHostId,XVmId}||{XHostId,XVmId}<-State#state.vm_candidates,
					 false==lists:member(XHostId,HostIds)] of
		      []->		
			  NewState=State,	  
			  {error,[no_vms_running]};
		      [{YHostId,YVmId}|_]->
			  X=lists:delete({YHostId,YVmId},State#state.vm_candidates),
			  NewState=State#state{vm_candidates=lists:append(X,[{YHostId,YVmId}])},
			  {ok,{YHostId,YVmId,list_to_atom(YVmId++"@"++YHostId)}}
		  end;
	      from ->
		  case [{XHostId,XVmId}||{XHostId,XVmId}<-State#state.vm_candidates,
					 true==lists:member(XHostId,HostIds)] of
		      []->		
			  NewState=State,	  
			  {error,[no_vms_running]};
		      [{YHostId,YVmId}|_]->
			  X=lists:delete({YHostId,YVmId},State#state.vm_candidates),
			  NewState=State#state{vm_candidates=lists:append(X,[{YHostId,YVmId}])},
			  {ok,{YHostId,YVmId,list_to_atom(YVmId++"@"++YHostId)}}
		  end;
	      Err->
		  NewState=State,
		  {error,[eexists,Err]}
	  end,  
    {reply, Reply, NewState};

handle_call({vm_status,Status},_From,State) ->
    Reply=rpc:call(node(),oam_iaas,vm_status,[Status],5000),
    {reply,Reply,State};

handle_call({computer_status,Status},_From,State) ->
    Reply=rpc:call(node(),oam_iaas,computer_status,[Status],5000),
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
 %   timer:sleep(Interval),
    io:format(" *************** "),
    io:format(" ~p",[{time(),?MODULE}]),
    io:format(" *************** ~n"),

     % Update computer status
    rpc:call(node(),computer,update_status_computers,[],20*1000),
  %  io:format("StatusComputers ~p~n",[{StatusComputers,?MODULE,?LINE}]),




%    io:format("AllServices ~p~n",[{if_db:sd_read_all(),?MODULE,?LINE}]),
%    io:format("Allocated Vms : ~p~n",[if_db:vm_status(allocated)]),
%    io:format("Free Vms : ~p~n",[if_db:vm_status(free)]),
 %   io:format( "NotAvailable Vms : ~p~n",[if_db:vm_status(not_available)]),


  
 %   StatusVms=rpc:call(node(),vm,status_vms,[StatusComputers],10*1000),
  %  io:format("StatusVms ~p~n",[{StatusVms,?MODULE,?LINE}]),
    
    % Update teh dbase so it's consistent
 %   Updates=rpc:call(node(),iaas_lib,update_dbase,[StatusComputers,StatusVms],10*1000),
  %  io:format("Updates ~p~n",[{Updates,?MODULE,?LINE}]),
    
    % Try to create wanted state

 %   WantedStateComputers=rpc:call(node(),iaas_lib,wanted_state_computers,[StatusComputers],5*60*1000),
 %   io:format("WantedStateComputers ~p~n",[{WantedStateComputers,?MODULE,?LINE}]),
 
  %  ok=rpc:call(node(),computer,check_update,[],5*60*1000),
  %  ok=rpc:call(node(),vm,check_update,[],5*60*1000),

%    io:format("AllServices ~p~n",[{if_db:sd_read_all(),?MODULE,?LINE}]),
%    io:format("Allocated Vms : ~p~n",[if_db:vm_status(allocated)]),
%    io:format("Free Vms : ~p~n",[if_db:vm_status(free)]),
%    io:format( "NotAvailable Vms : ~p~n",[if_db:vm_status(not_available)]),
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
