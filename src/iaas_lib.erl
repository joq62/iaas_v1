%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(iaas_lib). 



-export([
	 wanted_state_computers/1,
	 update_dbase/2
	]).

-define(DbaseVmId,"10250").
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

wanted_state_computers(StatusComputers)->

    _R=[if_db:computer_update(XHostId,Status)||{Status,XHostId}<-StatusComputers],
  %  io:format("R =  ~p~n",[{R, time(),?MODULE,?LINE }]),
 
    AvailableComputers=if_db:computer_status(available),
%    io:format("AvailableComputers =  ~p~n",[{AvailableComputers, time(),?MODULE,?LINE }]),

    _CleanComputers=[computer:clean_computer(XHostId,?ControlVmId)||{XHostId,available}<-AvailableComputers],
 %   io:format("CleanComputers ~p~n",[{CleanComputers, time(),?MODULE,?LINE }]),    

    StartComputers=[computer:start_computer(XHostId,?ControlVmId)||{XHostId,available}<-AvailableComputers],
 %   io:format("StartComputers =  ~p~n",[{StartComputers, time(),?MODULE,?LINE }]),
    StartVmsResult=case [if_db:vm_host_id(XHostId)||{XHostId,available}<-AvailableComputers] of
		       []->
			   [];
		       [VmIds]-> 
	%   io:format("VmIds ~p~n",[{?MODULE,?LINE,VmIds }]),
			   VmInfo=[{XHostId,VmId}||{_Vm,XHostId,VmId,worker,_Status}<-VmIds],
						%   io:format("VmInfo ~p~n",[{?MODULE,?LINE,VmInfo }]),
			   _CleanVms=[vm:clean_vm(WorkerVmId,XHostId)||{XHostId,WorkerVmId}<-VmInfo],
	 %   io:format("CleanVms ~p~n",[{?MODULE,?LINE,CleanVms }]),
			   StartVms=[{vm:start_vm(WorkerVmId,XHostId),XHostId}||{XHostId,WorkerVmId}<-VmInfo],
	    io:format("StartVms ~p~n",[{?MODULE,?LINE,StartVms}]),
			   StartVms
    end,
    
  {StartComputers,StartVmsResult}.



% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
 % Update dbase: Services becomes orphans but are available via dbase 
    % HostId not_available -> remove informatin
    %HostId running OR available AND VmId not_running


update_dbase(StatusComputers,StatusVms)->
    io:format("StatusComputers ~p~n",[{StatusComputers,?MODULE,?LINE}]),
    io:format("StatusVms ~p~n",[{StatusVms,?MODULE,?LINE}]),

    AllServices=if_db:sd_read_all(), %{XServiceId,XVsn,XHostId,XVmId,XVm}
%    io:format("AllServices ~p~n",[{AllServices,?MODULE,?LINE}]),
    % NotAvailableComputers - remove all services from sd
    NotAvailableComputers=[XHostId||{not_available,XHostId}<-StatusComputers],
    io:format("NotAvailableComputers ~p~n",[{NotAvailableComputers,?MODULE,?LINE}]),
    ServicesToRemove=[{if_db:sd_delete(XServiceId,XVsn,XVm),{XServiceId,XVsn,XVm}}||{XServiceId,XVsn,XHostId,_XVmId,XVm}<-AllServices,
										    lists:member(XHostId,NotAvailableComputers)],
    io:format("ServicesToRemove ~p~n",[{ServicesToRemove,?MODULE,?LINE}]),

    %% Doesnt work 
    %% 
    VmsNotAvailable1=[{if_db:vm_update(list_to_atom(XVmId++"@"++XHostId),not_available),{XHostId,XVmId}}||{_,{not_running,XHostId,XVmId}}<-StatusVms],
    
    AllVms=if_db:vm_read_all(), %{Vm,HostId,VmId,Type,Status}
    VmsNotAvailable2=[{if_db:vm_update(YVm,not_available),{YHostId,YVmId}}||{YVm,YHostId,YVmId,_Type,_Status}<-AllVms,
											    lists:member(YHostId,NotAvailableComputers)],
    VmsNotAvailable=lists:append(VmsNotAvailable1,VmsNotAvailable2),
    io:format("VmsNotAvailable ~p~n",[{VmsNotAvailable,?MODULE,?LINE}]),
    
    {ServicesToRemove,VmsNotAvailable}.
