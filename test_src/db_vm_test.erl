%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(db_vm_test).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------

-define(Master,"asus").
-define(MnesiaNodes,['iaas@asus']).

-define(WorkerVmIds,["30000","30001","30002","30003","30004","30005","30006","30007","30008","30009"]).


%% External exports
-export([start/0]).



%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
 
    ?debugMsg("Start iaas vm "),
    ?assertEqual(ok,iaas_vm()),
    ?debugMsg("Stop iaas vm "),


    ?debugMsg("Start stop_test_system:start"),
    %% End application tests
    cleanup(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
iaas_vm()->
    ?assertEqual(ok,
		 db_vm:create_table()),

    % Create
    ?assertEqual({atomic,ok},db_vm:create("asus","30000",worker,list_to_atom("30000"++"@"++"asus"),glurk)),
    
    ?assertEqual([{"asus","30000",worker,'30000@asus',glurk}],
		 db_vm:read_all()),

    % Update ok
    ?assertEqual({atomic,ok},db_computer:update("asus",not_available)),
    ?assertEqual([{"asus","pi","festum01","192.168.0.100",60110,not_available}],
		 db_computer:read("asus")),

    % Update error
    ?assertEqual({aborted,computer},db_computer:update("glurk",not_available)),
     
    ?assertEqual({atomic,ok},db_computer:delete("asus")),
    ?assertEqual([],
		 db_computer:read("asus")),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
iaas_computer()->
    ?assertEqual(ok,
		 db_computer:create_table()),

    % Create
    ?assertEqual({atomic,ok},db_computer:create("asus","pi","festum01","192.168.0.100",60110,glurk)),
    ?assertEqual([{"asus","pi","festum01","192.168.0.100",60110,glurk}],
		 db_computer:read("asus")),

    % Update ok
    ?assertEqual({atomic,ok},db_computer:update("asus",not_available)),
    ?assertEqual([{"asus","pi","festum01","192.168.0.100",60110,not_available}],
		 db_computer:read("asus")),

    % Update error
    ?assertEqual({aborted,computer},db_computer:update("glurk",not_available)),
     
    ?assertEqual({atomic,ok},db_computer:delete("asus")),
    ?assertEqual([],
		 db_computer:read("asus")),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
    
    ok.

cleanup()->


    ok.


