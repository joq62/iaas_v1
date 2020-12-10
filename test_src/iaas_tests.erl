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

-define(Master,"c2").
-define(MnesiaNodes,['c2@c2']).
-define(TEXTFILE,"./test_src/table_info.hrl").

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
  %  ?debugMsg("Test kill"),
  %  ?assertEqual(ok,test_kill()),


    ?debugMsg("Test system setup"),
    ?assertEqual(ok,setup()),

    %% Start application tests
    
    
    ?debugMsg("Start computer_test "),
    ?assertEqual(ok,computer_test:start()),
    ?debugMsg("Stop computer_test "),

%    ?debugMsg("Start db_vm_test "),
%    ?assertEqual(ok,db_vm_test:start()),
%    ?debugMsg("Stop db_vm_test "),

%    ?debugMsg("Start iaas function test "),
%    ?assertEqual(ok,iaas_function_test:start()),
%    ?debugMsg("Stop db_vm_test "),

    ?debugMsg("Start stop_test_system:start"),
    %% End application tests
    cleanup(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
test_kill()->
    ssh:start(),
    User="joq62",
    PassWd="festum01",
    R0=my_ssh:ssh_send("192.168.0.200",60200,User,PassWd,"hostname",5000),
    io:format("R0 ~p~n",[R0]),
    R1=my_ssh:ssh_send("192.168.0.201",60201,User,PassWd,"hostname",5000),
    io:format("R1 ~p~n",[R1]),
    E0=my_ssh:ssh_send("192.168.0.233",60201,User,PassWd,"hostname",5000),
    io:format("E0 ~p~n",[E0]),
    E1=my_ssh:ssh_send("192.168.0.200",60200,User,"glurk","hostname",5000),
    io:format("E1 ~p~n",[E1]),
    E2=my_ssh:ssh_send("192.168.0.200",60200,"glurk",PassWd,"hostname",5000),
    io:format("E2 ~p~n",[E2]),
    E3=my_ssh:ssh_send("192.168.0.200",65,User,PassWd,"hostname",5000),
    io:format("R0 ~p~n",[E3]),
    init:stop().
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
    %Init local mnesia
    ?assertEqual(ok,application:start(dbase)), 
    ?assertMatch({pong,_,_},dbase:ping()),
    ?assertEqual(ok,init_tables:start()),
    timer:sleep(500),
    ?assertEqual(ok,application:start(iaas)), 
    ?assertMatch({pong,_,_},iaas:ping()),
    ok.

cleanup()->
  %  application:stop(sd_service),
  %  rpc:call('node1@asus',init,stop,[]),
    init:stop(),
    ok.


