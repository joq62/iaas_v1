%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  c
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(vm). 



-export([check_update/0,
	 start_vm/2,
	 start_vms/2,
	 clean_vm/2,
	 clean_vms/2,
	 allocate/0,
	 free/1
%        vm_status/2,
%	 status_vms/2
	
	]).


-define(DbaseVmId,"10250").
-define(ControlVmId,"10250").
-define(TimeOut,3000).

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
check_update()->
    AllVms=if_db:vm_read_all(),
    Ping=[{net_adm:ping(Vm),Vm}||{Vm,_HostId,_VmId,_Type,_Status}<-AllVms],
    [free(Vm)||{R,Vm}<-Ping,
	       R/=pong],
    ok.

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
allocate()->
    Result= case if_db:vm_status(free) of
		[]->
		    {error,[no_free_vms,?MODULE,?LINE]};
		FreeVms ->
		    [{Vm,HostId,VmId,_,free}|_]=FreeVms,
		    if_db:vm_update(Vm,allocated),
		    {ok,HostId,VmId}
	    end,
    Result.

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
free(Vm)->
    Result= case if_db:vm_info(Vm) of
		[]->
		    {error,[eexist,Vm,?MODULE,?LINE]};
		[{_,HostId,VmId,_,_}]->
		    case clean_vm(VmId,HostId) of
			{false,VmId}->
			    case start_vm(VmId,HostId) of
				{ok,_}->
				    ok;
				Err->
				    Err
			    end;
			Err ->
			    {error,[some_error,Err,?MODULE,?LINE]}
		    end
	    end,
    Result.

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start_vm(VmId,HostId)->
    io:format("Start Vm = ~p~n",[{VmId,HostId,?MODULE,?LINE}]),
    StartResult=case if_db:computer_read(HostId) of
		    []->
			{error,[eexists,HostId,?MODULE,?LINE]};
						%[{HostId,User,PassWd,IpAddr,Port}]->
		    _->
			ControlVm=list_to_atom(?ControlVmId++"@"++HostId),
			ok=rpc:call(ControlVm,file,make_dir,[VmId]),
			[]=rpc:call(ControlVm,os,cmd,["erl -sname "++VmId++" -setcookie abc -detached "],2*?TimeOut),
			Vm=list_to_atom(VmId++"@"++HostId),
			R=check_started(500,Vm,10,{error,[Vm]}),
			case R of
			    ok->
				if_db:vm_update(Vm,free),
				{ok,Vm};
			    Err->
				{error,[Err,Vm,?MODULE,?LINE]}
			end
		end,
    StartResult.

start_vms(VmIds,HostId)->
    F1=fun start_node/2,
    F2=fun start_node_result/3,
%    L=[{XHostId,XVmId}||XVmId<-VmIds],
    L=[{HostId,VmId}||VmId<-VmIds],
    ResultNodeStart=mapreduce:start(F1,F2,[],L),
    ResultNodeStart.


start_node(Parent,{HostId,VmId})->
    {ok,DbaseHostId}=inet:gethostname(),
    DbaseVm=list_to_atom(?DbaseVmId++"@"++DbaseHostId),
    StartResult=case rpc:call(DbaseVm,db_computer,read,[HostId]) of
		    []->
			{error,[eexists,HostId,?MODULE,?LINE]};
		    %[{HostId,User,PassWd,IpAddr,Port}]->
		    _->
			ControlVm=list_to_atom(?ControlVmId++"@"++HostId),
			ok=rpc:call(ControlVm,file,make_dir,[VmId]),
			[]=rpc:call(ControlVm,os,cmd,["erl -sname "++VmId++" -setcookie abc -detached "],2*?TimeOut),
			Vm=list_to_atom(VmId++"@"++HostId),
			R=check_started(500,Vm,10,{error,[Vm]}),
			io:format("~p~n",[{?MODULE,?LINE,HostId,VmId,R}]),
			case R of
			    ok->
				if_db:vm_update(Vm,free),
				{ok,Vm};
			    Err->
				{error,[Err,Vm,?MODULE,?LINE]}
			end
		end,
    Parent!{start_node,StartResult}.

start_node_result(start_node,Vals,_)->		
    Vals.


% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


check_started(_N,_Vm,_Timer,ok)->
    ok;
check_started(0,_Vm,_Timer,Result)->
    Result;
check_started(N,Vm,Timer,_Result)->
    NewResult=case net_adm:ping(Vm) of
		  pong->
		      ok;
		  Err->
		      timer:sleep(Timer),
		      {error,[Err,Vm]}
	      end,
    check_started(N-1,Vm,Timer,NewResult).


% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
clean_vm(VmId,HostId)->
    Result=case if_db:computer_read(HostId) of
	       []->
		   {error,[eexists,HostId,?MODULE,?LINE]};
	     %  [{HostId,User,PassWd,IpAddr,Port}]->
	       _->
						%	    ok=rpc:call(list_to_atom(?ControlVmId++"@"++HostId),
						%			file,del_dir_r,[VmId]),
%		   io:format("HostId,VmId ~p~n",[{?MODULE,?LINE,HostId,VmId}]),
		   ControlVm=list_to_atom(?ControlVmId++"@"++HostId),
		   rpc:call(ControlVm,os,cmd,["rm -rf "++VmId]),
		   R=rpc:call(ControlVm,filelib,is_dir,[VmId]),
		   timer:sleep(300),
		   Vm=list_to_atom(VmId++"@"++HostId),
		   rpc:call(Vm,init,stop,[]),
		   if_db:vm_update(Vm,not_available),	     	   
		   timer:sleep(300),
		   timer:sleep(300),
%		   io:format("rm -rf VmId = ~p~n",[{R,VmId,?MODULE,?LINE}]),
		   {R,VmId}
    end,
    Result.

clean_vms(VmIds,HostId)->
    F1=fun clean_node/2,
    F2=fun clean_node_result/3,
%    io:format("HostId,VmIds ~p~n",[{?MODULE,?LINE,HostId,VmIds}]),
    L=[{HostId,XVmId}||XVmId<-VmIds],
%    io:format("L  ~p~n",[{?MODULE,?LINE,L}]),
    ResultNodeStart=mapreduce:start(F1,F2,[],L),
    ResultNodeStart.

clean_node(Parent,{HostId,VmId})->
    Result=case if_db:computer_read(HostId) of
	       []->
		   {error,[eexists,HostId,?MODULE,?LINE]};
	     %  [{HostId,User,PassWd,IpAddr,Port}]->
	       _->
						%	    ok=rpc:call(list_to_atom(?ControlVmId++"@"++HostId),
						%			file,del_dir_r,[VmId]),
%		   io:format("HostId,VmId ~p~n",[{?MODULE,?LINE,HostId,VmId}]),
		   ControlVm=list_to_atom(?ControlVmId++"@"++HostId),
		   rpc:call(ControlVm,os,cmd,["rm -rf "++VmId]),
		   R=rpc:call(ControlVm,filelib,is_dir,[VmId]),
		   timer:sleep(300),
		   Vm=list_to_atom(VmId++"@"++HostId),
		   rpc:call(Vm,init,stop,[]),
		   if_db:vm_update(Vm,not_available),		   
		   timer:sleep(300),
%		   io:format("rm -rf VmId = ~p~n",[{R,VmId,?MODULE,?LINE}]),
		   {R,VmId}
    end,
    Parent!{clean_node,Result}.

clean_node_result(_Key,Vals,_)->		
    Vals.

%% ====================================================================
%% External functions
%% ====================================================================

vm_status(VmStatus,Type)->
    Reply= case Type of
	       running->
		   [{HostId,R}||{HostId,
				 {running,R},
				 {available,_A},
				 {not_available,_NA}}<-VmStatus];
	       available->
		   [{HostId,A}||{HostId,
				 {running,_R},
				 {available,A},
				 {not_available,_NA}}<-VmStatus];
	       not_available->
		   [{HostId,NA}||{HostId,
				 {running,_R},
				  {available,_A},
				 {not_available,NA}}<-VmStatus];
	       Err->
		   {error,[edefined,Err]}
	   end,
    Reply.
% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%@doc, spec etc

status_vms(HostId,VmIds)->
    F1=fun do_ping/2,
    F2=fun check_vm_status/3,

    io:format("HostId,VmIds  ~p~n",[{?MODULE,?LINE,HostId,VmIds}]),
    Vms=[{HostId,VmId,list_to_atom(VmId++"@"++HostId)}||VmId<-VmIds],
    Status=mapreduce:start(F1,F2,[],Vms),
    Running=[{HostIdX,VmIdX}||{running,HostIdX,VmIdX}<-Status],
    Available=[{HostIdX,VmIdX}||{available,HostIdX,VmIdX}<-Status],  
    NotAvailable=[{HostIdX,VmIdX}||{not_available,HostIdX,VmIdX}<-Status],   
    {HostId,{running,Running},{available,Available},{not_available,NotAvailable}}.
		  
do_ping(Parent,{HostId,VmId,Vm})->
    Result=net_adm:ping(Vm),
    Parent!{vm_status,{HostId,VmId,Result}}.

check_vm_status(vm_status,Vals,_)->
    Result=check_vm_status(Vals,[]),
    Result.

check_vm_status([],Status)->
    Status;
check_vm_status([{HostId,VmId,Result}|T],Acc)->
  %  io:format("Vm  ~p~n",[{?MODULE,?LINE,Vm,Result}]),
    NewAcc=case Result of
	       pong->
		   [{running,HostId,VmId}|Acc];
	       pang->
		   [{available,HostId,VmId}|Acc];
	       _ ->
		   [{not_available,HostId,VmId}|Acc]
	   end,
    check_vm_status(T,NewAcc).

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
