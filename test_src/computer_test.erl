%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(computer_test).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------

-define(Master,"c2").
-define(MnesiaNodes,['c2@c2']).



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
 
    ?debugMsg("Start db_test"),
    ?assertEqual(ok,db_test()),
    ?debugMsg("Stop db_test "),

    ?debugMsg("Start check_computer_status"),
    ?assertEqual(ok,check_computer_status()),
    ?debugMsg("Stop check_computer_status "),

    ?debugMsg("Start start_restart_computer"),
    ?assertEqual(ok,start_restart_computer()),
    ?debugMsg("Stop start_restart_computer "),

   %% End application tests
    cleanup(),
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start_restart_computer()->
    ?assertEqual([{"c0","joq62","festum01","192.168.0.200",60200,available}],
		 if_db:computer_read("c0")),
%    R=my_ssh:ssh_send("192.168.0.200",60200,"joq62","festum01","date ",5000),
    R=my_ssh:ssh_send("192.168.0.200",60200,"joq62","festum01","erl -sname c0 -detached -setcookie abc",5000),
    io:format("~p~n",[{?MODULE,?LINE,R}]),
    ?assertEqual(pong,s(100,1000,'c0@c0',glurk)),
    timer:sleep(10*60*1000),
    
    ok.

s(0,_,_,R)->
    R;
s(N,I,Node,_R)->
    NewR=case net_adm:ping(Node) of
	     pong->
		 NewN=0,
		 pong;
	     pang ->
		 timer:sleep(I),
		 NewN=N-1,
		 pang
	 end,
    io:format("NewN,NewR ~p~n",[{?MODULE,?LINE,NewN,NewR}]),
    s(NewN,I,Node,NewR).

		  
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
check_computer_status()->
    ?assertEqual(ok,iaas:update_status_computers()),
    
    ?assertEqual(["c2"],iaas:computer_status(running)),
    ?assertEqual(["c1","c0"],
		 iaas:computer_status(available)),
    ?assertEqual(["wrong_port",
		  "wrong_hostname",
		  "wrong_ipaddr",
		  "wrong_passwd",
		  "wrong_userid"],
		 iaas:computer_status(not_available)),
    
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
db_test()->
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


