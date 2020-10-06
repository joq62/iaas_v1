%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(sd_test).  
     
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("log.hrl").

-define(VM1,'node1@asus').
%% --------------------------------------------------------------------
-export([start/0]).

%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:emulate loader
%% Description: requires pod+container module
%% Returns: non
%% --------------------------------------------------------------------
start()->
    add_1(),
  %  all(),
 %   error(),
 %   event(),    
    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
add_1()->
    rpc:call(node(),sd_service,add_service,["s1"]),
    rpc:call(?VM1,sd_service,add_service,["s1"]),
    rpc:call(node(),sd_service,trade_services,[]),
    rpc:call(?VM1,sd_service,trade_services,[]),
    timer:sleep(100),
    ?assertMatch([{"s1",sd_test@asus}],
		 rpc:call(node(),sd_service,fetch_all,[local_services])),
    ?assertMatch([{"s1",node1@asus}],
		 rpc:call(node(),sd_service,fetch_all,[external_services])),
    ?assertMatch([{"s1",node1@asus},
		  {"s1",sd_test@asus}],
		 rpc:call(node(),sd_service,fetch_all,[all])),

 
    rpc:call(?VM1,sd_service,remove_service,["s1"]),
    rpc:call(?VM1,sd_service,trade_services,[]),
    timer:sleep(1000),
    
   ?assertMatch([],
		 rpc:call(?VM1,sd_service,fetch_all,[local_services])),
    ?assertMatch([{"s1",sd_test@asus}],rpc:call(?VM1,sd_service,fetch_all,[all])),

    ok.
    
