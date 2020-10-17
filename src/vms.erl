%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(vms). 



-export([status_vms/2
	]).


%% ====================================================================
%% External functions
%% ====================================================================

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%@doc, spec etc

status_vms(HostId,VmIds)->
    F1=fun do_ping/2,
    F2=fun check_vm_status/3,

  %  io:format("HostId,VmIds  ~p~n",[{?MODULE,?LINE,HostId,VmIds}]),
    Vms=[{VmId,list_to_atom(VmId++"@"++HostId)}||VmId<-VmIds],
    Status=mapreduce:start(F1,F2,[],Vms),
    Running=[VmId||{running,VmId}<-Status],
    Available=[VmId||{available,VmId}<-Status],  
    NotAvailable=[VmId||{not_available,VmId}<-Status],   
    {HostId,{running,Running},{available,Available},{not_available,NotAvailable}}.
		  
do_ping(Parent,{VmId,Vm})->
    Result=net_adm:ping(Vm),
    Parent!{vm_status,{VmId,Result}}.

check_vm_status(vm_status,Vals,_)->
    Result=check_vm_status(Vals,[]),
    Result.

check_vm_status([],Status)->
    Status;
check_vm_status([{VmId,Result}|T],Acc)->
  %  io:format("Vm  ~p~n",[{?MODULE,?LINE,Vm,Result}]),
    NewAcc=case Result of
	       pong->
		   [{running,VmId}|Acc];
	       pang->
		   [{available,VmId}|Acc];
	       _ ->
		   [{not_available,VmId}|Acc]
	   end,
    check_vm_status(T,NewAcc).

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
