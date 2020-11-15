%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(computer). 



-export([
	 status_computers/0,
	 start_computer/2,
	 clean_computer/1,
	 clean_computer/2
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


% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%@doc, spec etc

status_computers()->
    F1=fun get_hostname/2,
    F2=fun check_host_status/3,
    {ok,HostId}=inet:gethostname(),
    DbaseVm=list_to_atom(?DbaseVmId++"@"++HostId),
    Computers=rpc:call(DbaseVm,db_computer,read_all,[]),
  %  io:format("Computers = ~p~n",[{?MODULE,?LINE,Computers}]),
    Status=mapreduce:start(F1,F2,[],Computers),
  %  io:format("Computers Status = ~p~n",[{?MODULE,?LINE,Status}]),
    Status.
    
   

		  
get_hostname(Parent,{HostId,User,PassWd,IpAddr,Port,_Status})->
    Msg="hostname",
    Result=my_ssh:ssh_send(IpAddr,Port,User,PassWd,Msg,?TimeOut),
  %  io:format("Result = ~p~n",[{?MODULE,?LINE,Result}]),
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
clean_computer(HostId)->

% [{'30000@asus',"asus","30000",controller,not_available}]=db_vm:host_id(HostId),
% [{"asus","pi","festum01","192.168.0.100",60110,not_available}]=db_computer:read(HostId)),
    Result=case if_db:computer_read(HostId) of
	       []->
		   {error,[eexists,HostId,?MODULE,?LINE]};
	       [{HostId,User,PassWd,IpAddr,Port,_ComputerStatus}]->
		   case if_db:vm_host_id(HostId) of
		       []->
			   {error,[eexists_vms,HostId,?MODULE,?LINE]};
		       VmIdList->
			   do_clean(VmIdList,HostId,User,PassWd,IpAddr,Port)			       
						%io:format("VmId = ~p",[{VmId,?MODULE,?LINE}])
		   end
	   end,
    Result.
do_clean([],_,_,_,_,_)->
    ok;
do_clean([{Vm,_HostId,VmId,_Type,_VmStatus}|T],HostId,User,PassWd,IpAddr,Port)->
    if_db:vm_update(Vm,not_available),
    [if_db:sd_delete(ServiceId,Vsn,ServiceVm)||{ServiceId,Vsn,_XHostId,_VmId,ServiceVm}<-if_db:sd_read_all(),
							      ServiceVm==Vm],
    rpc:call(Vm,init,stop,[],5000),
    ok=my_ssh:ssh_send(IpAddr,Port,User,PassWd,"rm -rf "++VmId,2*?TimeOut),
    do_clean(T,HostId,User,PassWd,IpAddr,Port).
% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
clean_computer(HostId,VmId)->
    % Read computer info 
    Result=case if_db:computer_read(HostId) of
	       []->
		   {error,[eexists,HostId]};
	       [{HostId,User,PassWd,IpAddr,Port,_Status}]->
		   Vm=list_to_atom(VmId++"@"++HostId),
		   if_db:vm_update(Vm,not_available),
		   [if_db:sd_delete(ServiceId,Vsn,ServiceVm)||{ServiceId,Vsn,_HostId,_VmId,ServiceVm}<-if_db:sd_read_all(),
							      ServiceVm==Vm],
		   Vm=list_to_atom(VmId++"@"++HostId),
		   rpc:call(Vm,init,stop,[],1000),
		   ok=my_ssh:ssh_send(IpAddr,Port,User,PassWd,"rm -rf "++VmId,2*?TimeOut)
	    %	    io:format("VmId = ~p",[{VmId,?MODULE,?LINE}])
		       
	   end,
    Result.

start_computer(HostId,VmId)->
    {ok,DbaseHostId}=inet:gethostname(),
    DbaseVm=list_to_atom(?DbaseVmId++"@"++DbaseHostId),
    StartResult=case rpc:call(DbaseVm,db_computer,read,[HostId]) of
		    []->
			{error,[eexists,HostId,?MODULE,?LINE]};
		    [{HostId,User,PassWd,IpAddr,Port,_Status}]->
			ok=my_ssh:ssh_send(IpAddr,Port,User,PassWd,"mkdir "++VmId,2*?TimeOut),
			ok=my_ssh:ssh_send(IpAddr,Port,User,PassWd,"erl -sname "++VmId++" -setcookie abc -detached ",2*?TimeOut),
			Vm=list_to_atom(VmId++"@"++HostId),
			R=check_started(500,Vm,10,{error,[Vm]}),
			case R of
			    ok->
				rpc:call(Vm,mnesia,start,[]),
				db_computer:update(HostId,running),
				db_vm:update(Vm,allocated),
			        % starta common !!!!!
				{ok,HostId};
			    Err->
				{error,[Err,Vm,?MODULE,?LINE]}
			end			
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



