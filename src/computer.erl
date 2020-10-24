%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(computer). 



-export([status_computers/0,
	 start_vms/2,start_computer/2,
	 clean_computer/2,clean_vms/2
	]).

-define(ControlVmId,"10250").
-define(TimeOut,3000).
-define(ControlVmIds,["10250"]).

%% ====================================================================
%% External functions
%% ====================================================================

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%@doc, spec etc

status_computers()->
    F1=fun get_hostname/2,
    F2=fun check_host_status/3,

    Computers=db_computer:read_all(),
   % io:format("Computers = ~p~n",[{?MODULE,?LINE,Computers}]),
    Status=mapreduce:start(F1,F2,[],Computers),
    Status.
    
   

		  
get_hostname(Parent,{HostId,User,PassWd,IpAddr,Port})->
    Msg="hostname",
    Result=my_ssh:ssh_send(IpAddr,Port,User,PassWd,Msg,?TimeOut),
    Parent!{computer_status,{HostId,Result}}.

check_host_status(computer_status,Vals,_)->
    Result=check_host_status(Vals,[]),
    Result.

check_host_status([],Status)->
    Status;
check_host_status([{HostId,[HostId]}|T],Acc)->
    Vm10250=list_to_atom("10250"++"@"++HostId),
    NewAcc=case net_adm:ping(Vm10250) of
	       pong->
		   [{running,HostId}|Acc];
	       pang->
		   [{available,HostId}|Acc]
	   end,
    check_host_status(T,NewAcc);
check_host_status([{HostId,{error,_Err}}|T],Acc) ->
    check_host_status(T,[{not_available,HostId}|Acc]).

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
clean_vms(VmIds,HostId)->
    F1=fun clean_node/2,
    F2=fun clean_node_result/3,
%    io:format("HostId,VmIds ~p~n",[{?MODULE,?LINE,HostId,VmIds}]),
    L=[{HostId,XVmId}||XVmId<-VmIds],
%    io:format("L  ~p~n",[{?MODULE,?LINE,L}]),
    ResultNodeStart=mapreduce:start(F1,F2,[],L),
    ResultNodeStart.

clean_node(Parent,{HostId,VmId})->
    % Read computer info 
    Result=case db_computer:read(HostId) of
	       []->
		   {error,[eexists,HostId]};
	     %  [{HostId,User,PassWd,IpAddr,Port}]->
	       _->
						%	    ok=rpc:call(list_to_atom(?ControlVmId++"@"++HostId),
						%			file,del_dir_r,[VmId]),
%		   io:format("HostId,VmId ~p~n",[{?MODULE,?LINE,HostId,VmId}]),
		   rpc:call(list_to_atom(?ControlVmId++"@"++HostId),
			      os,cmd,["rm -rf "++VmId]),
		   R=rpc:call(list_to_atom(?ControlVmId++"@"++HostId),filelib,is_dir,[VmId]),
		   timer:sleep(300),
		   rpc:call(list_to_atom(VmId++"@"++HostId),
			    init,stop,[]),
		   timer:sleep(300),
%		   io:format("rm -rf VmId = ~p~n",[{R,VmId,?MODULE,?LINE}]),
		   {R,VmId}
    end,
    Parent!{clean_node,Result}.

clean_node_result(_Key,Vals,_)->		
    Vals.

clean_computer(HostId,VmId)->
    % Read computer info 
    Result=case db_computer:read(HostId) of
	       []->
		   {error,[eexists,HostId]};
	       [{HostId,User,PassWd,IpAddr,Port}]->
		   ok=my_ssh:ssh_send(IpAddr,Port,User,PassWd,"rm -rf "++VmId,2*?TimeOut)
						%	    io:format("VmId = ~p",[{VmId,?MODULE,?LINE}])
		       
	   end,
    Result.
% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


start_vms(VmIds,HostId)->
    F1=fun start_node/2,
    F2=fun start_node_result/3,
%    L=[{XHostId,XVmId}||XVmId<-VmIds],
    L=[{HostId,VmId}||VmId<-VmIds],
    ResultNodeStart=mapreduce:start(F1,F2,[],L),
    ResultNodeStart.


start_node(Parent,{HostId,VmId})->
    StartResult=case db_computer:read(HostId) of
		    []->
			{error,[eexists,HostId]};
		    %[{HostId,User,PassWd,IpAddr,Port}]->
		    _->
			ControlVm=list_to_atom(?ControlVmId++"@"++HostId),
			ok=rpc:call(ControlVm,file,make_dir,[VmId]),
			[]=rpc:call(ControlVm,os,cmd,["erl -sname "++VmId++" -setcookie abc -detached "],2*?TimeOut),
			Vm=list_to_atom(VmId++"@"++HostId),
			R=check_started(500,Vm,10,{error,[Vm]}),
		%	io:format("VmId = ~p",[{VmId,?MODULE,?LINE}]),
		%	io:format(",  ~p~n",[{R,?MODULE,?LINE}]),
			R
		end,
    Parent!{start_node,StartResult}.

start_node_result(start_node,Vals,_)->		
    Vals.



start_computer(HostId,VmId)->
    StartResult=case db_computer:read(HostId) of
		    []->
			{error,[eexists,HostId]};
		    [{HostId,User,PassWd,IpAddr,Port}]->
			ok=my_ssh:ssh_send(IpAddr,Port,User,PassWd,"mkdir "++VmId,2*?TimeOut),
			ok=my_ssh:ssh_send(IpAddr,Port,User,PassWd,"erl -sname "++VmId++" -setcookie abc -detached ",2*?TimeOut),
			Vm=list_to_atom(VmId++"@"++HostId),
			R=check_started(500,Vm,10,{error,[Vm]}),
			rpc:call(Vm,mnesia,start,[]),
		%	io:format("VmId = ~p",[{VmId,?MODULE,?LINE}]),
		%	io:format(",  ~p~n",[{R,?MODULE,?LINE}]),
%			timer:sleep(500),
			R
		end,
    StartResult.


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



