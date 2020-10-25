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
    ?assertEqual(ok,iaas_vm2()),
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
iaas_vm2()->
    ?assertEqual(ok,
		 db_vm:create_table()),

    % Create
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30000"++"@"++"asus"),"asus","30000",controller,not_available)),
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30001"++"@"++"asus"),"asus","30001",worker,not_available)),
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30002"++"@"++"asus"),"asus","30002",worker,available)),
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30000"++"@"++"sthlm_1"),"sthlm_1","30000",worker,not_available)),
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30001"++"@"++"sthlm_1"),"sthlm_1","30001",worker,not_available)),
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30002"++"@"++"sthlm_1"),"sthlm_1","30002",worker,available)),
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30000"++"@"++"asus2"),"asus2","30000",worker,free)),
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30001"++"@"++"asus2"),"asus2","30001",worker,allocated)),
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30002"++"@"++"asus2"),"asus2","30002",worker,available)),
    
    ?assertEqual([{'30002@asus',"asus","30002",worker,available},
		  {'30001@asus',"asus","30001",worker,not_available},
		  {'30000@asus',"asus","30000",controller,not_available},
		  {'30002@sthlm_1',"sthlm_1","30002",worker,available},
		  {'30001@sthlm_1',"sthlm_1","30001",worker,not_available},
		  {'30000@sthlm_1',"sthlm_1","30000",worker,not_available},
		  {'30002@asus2',"asus2","30002",worker,available},
		  {'30001@asus2',"asus2","30001",worker,allocated},
		  {'30000@asus2',"asus2","30000",worker,free}],
		 db_vm:read_all()),

    % host id
   
    ?assertEqual([{'30002@asus',"asus","30002",worker,available},
		  {'30001@asus',"asus","30001",worker,not_available},
		  {'30000@asus',"asus","30000",controller,not_available}],
		 db_vm:host_id("asus")),

    ?assertEqual([{'30002@sthlm_1',"sthlm_1","30002",worker,available},
		  {'30001@sthlm_1',"sthlm_1","30001",worker,not_available},
		  {'30000@sthlm_1',"sthlm_1","30000",worker,not_available}],
		 db_vm:host_id("sthlm_1")),

    ?assertEqual([{'30002@asus2',"asus2","30002",worker,available},
		  {'30001@asus2',"asus2","30001",worker,allocated},
		  {'30000@asus2',"asus2","30000",worker,free}],
		 db_vm:host_id("asus2")),

    % type
    ?assertEqual([{'30002@asus',"asus","30002",worker,available},
		  {'30001@asus',"asus","30001",worker,not_available},
		  {'30002@sthlm_1',"sthlm_1","30002",worker,available},
		  {'30001@sthlm_1',"sthlm_1","30001",worker,not_available},
		  {'30000@sthlm_1',"sthlm_1","30000",worker,not_available},
		  {'30002@asus2',"asus2","30002",worker,available},
		  {'30001@asus2',"asus2","30001",worker,allocated},
		  {'30000@asus2',"asus2","30000",worker,free}],
		 db_vm:type(worker)),
    ?assertEqual([{'30000@asus',"asus","30000",controller,not_available}],
		 db_vm:type(controller)),
 
    % status
    ?assertEqual([{'30001@asus',"asus","30001",worker,not_available},
		  {'30000@asus',"asus","30000",controller,not_available},
		  {'30001@sthlm_1',"sthlm_1","30001",worker,not_available},
		  {'30000@sthlm_1',"sthlm_1","30000",worker,not_available}],
		 db_vm:status(not_available)),
    ?assertEqual([{'30002@asus',"asus","30002",worker,available},
		  {'30002@sthlm_1',"sthlm_1","30002",worker,available},
		  {'30002@asus2',"asus2","30002",worker,available}],
		 db_vm:status(available)),
    ?assertEqual([{'30000@asus2',"asus2","30000",worker,free}],
		 db_vm:status(free)),
    ?assertEqual([{'30001@asus2',"asus2","30001",worker,allocated}],
		 db_vm:status(allocated)),
    
   
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
    ?assertEqual({atomic,ok},db_vm:create(list_to_atom("30000"++"@"++"asus"),"asus","30000",worker,glurk)),
    
    ?assertEqual([{'30000@asus',"asus","30000",worker,glurk}],
		 db_vm:host_id("asus")),

    ?assertEqual([{'30000@asus',"asus","30000",worker,glurk}],
		 db_vm:read_all()),

    % Update ok
    ?assertEqual({atomic,ok},db_vm:update('30000@asus',not_available)),
    ?assertEqual([{'30000@asus',"asus","30000",worker,not_available}],
		 db_vm:read_all()),

    % Update error
    ?assertEqual({aborted,vm},db_vm:update("glurk",not_available)),
     
    ?assertEqual({atomic,ok},db_vm:delete('30000@asus')),
    ?assertEqual([],
		 db_computer:read('30000@asus')),
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


