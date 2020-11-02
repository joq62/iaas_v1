%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(vms). 



-export([vm_status/2,
	 status_vms/2,
	 candidates/2
	]).


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
% [{HostId,[{HostId,VmId}]} 
%[{HostId1,VmId1},{HostId2,VmId1},{HostIdN,VmId1},{HostId1,Vmid2},
% 
% 
%
candidates(CandidateList,RunningVms)->
 %   io:format( "CandidateList : ~p~n",[{?MODULE,?LINE,CandidateList}]), 
    R =x1(RunningVms,[]),
    AddToCandidateList=[{HostId,VmId}||{HostId,VmId}<-R,
				       false==lists:member({HostId,VmId},CandidateList)],
    L2=[{HostId,VmId}||{HostId,VmId}<-CandidateList,
		       lists:member({HostId,VmId},R)],
    NewCandidateList=lists:append(AddToCandidateList,L2),
 %  io:format( "NewCandidateList : ~p~n",[{?MODULE,?LINE,NewCandidateList}]), 
    NewCandidateList.
x1([],R)->
    R;
x1(L,Acc)->
 %   io:format( "L : ~p~n",[{?MODULE,?LINE,L}]),  
    Lx= [{HostId,VmId}||{_,[{HostId,VmId}|_]}<-L],
 %   io:format( "Lx : ~p~n",[{?MODULE,?LINE,Lx}]),  
 
    case Lx of
	[]->
	    T=[],
	    NewAcc=Acc;
	Lx->
	    T=x2(Lx,L),
	    NewAcc=lists:append(Lx,Acc)
    end,	      
    x1(T,NewAcc).

x2([],R)->
    R;
x2([{HostId,VmId}|T],Acc)->
    case lists:keyfind(HostId,1,Acc) of
	false->
	    NewAcc=Acc;
	{HostId,L} ->
%	    io:format( "Acc : ~p~n",[{?MODULE,?LINE,Acc}]), 
%	    io:format( "HostId,L : ~p~n",[{?MODULE,?LINE,HostId,L}]), 
	    NewL=lists:delete({HostId,VmId},L),
%	    io:format( "NewL : ~p~n",[{?MODULE,?LINE,NewL}]),  
	    NewAcc=lists:keyreplace(HostId,1,Acc,{HostId,NewL})
    end,
    x2(T,NewAcc).
    
get_candidate()->
    ok.

get_candidate(_HostIdList)->
    ok.
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
