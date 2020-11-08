%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  c
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(oam_iaas). 



-export([vm_status/1,
	 computer_status/1
	]).


-define(DbaseVmId,"10250").
-define(ControlVmId,"10250").
-define(TimeOut,3000).

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
vm_status(Status)->
    {ok,DbaseHostId}=inet:gethostname(),
    DbaseVm=list_to_atom(?DbaseVmId++"@"++DbaseHostId),
    L=rpc:call(DbaseVm,db_vm,status,[Status],5000),
 %   R=[{XStatus,VmId,HostId}||{_Vm,HostId,VmId,Type,XStatus}<-L],
    R=[{HostId,VmId}||{_Vm,HostId,VmId,_Type,_XStatus}<-L],
    
    R.
% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
computer_status(Status)->
    {ok,DbaseHostId}=inet:gethostname(),
    DbaseVm=list_to_atom(?DbaseVmId++"@"++DbaseHostId),
    L=rpc:call(DbaseVm,db_computer,status,[Status],5000),
 %   R=[{XStatus,VmId,HostId}||{_Vm,HostId,VmId,Type,XStatus}<-L],
    R=[HostId||{HostId,_XStatus}<-L],
    
    R.
	
	
