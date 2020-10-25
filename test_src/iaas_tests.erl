%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(iaas_tests).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------

-define(Master,"asus").
-define(MnesiaNodes,['iaas@asus']).
-define(TEXTFILE,"./test_src/iaas_init.hrl").

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
    ?debugMsg("Test system setup"),
    ?assertEqual(ok,setup()),

    %% Start application tests
    
    
    ?debugMsg("Start db_computer_test "),
    ?assertEqual(ok,db_computer_test:start()),
    ?debugMsg("Stop db_computer_test "),

    ?debugMsg("Start db_vm_test "),
    ?assertEqual(ok,db_vm_test:start()),
    ?debugMsg("Stop db_vm_test "),

    ?debugMsg("Start iaas function test "),
    ?assertEqual(ok,iaas_function_test:start()),
    ?debugMsg("Stop db_vm_test "),

    ?debugMsg("Start stop_test_system:start"),
    %% End application tests
    cleanup(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
 
    [rpc:call(Node,application,stop,[mnesia])||Node<-?MnesiaNodes], 
    io:format("~p~n",[{?MODULE,?LINE,mnesia:create_schema(?MnesiaNodes)}]),
    [rpc:call(Node,application,start,[mnesia])||Node<-?MnesiaNodes],
%    {atomic,ok}=mnesia:load_textfile(?TEXTFILE),
    
    ok.

cleanup()->
  %  application:stop(sd_service),
  %  rpc:call('node1@asus',init,stop,[]),
    init:stop(),
    ok.


