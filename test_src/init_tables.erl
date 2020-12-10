%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(init_tables). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%%---------------------------------------------------------------------
%% Records for test
%%
-define(InitFile,"./test_src/table_info.hrl").

%% --------------------------------------------------------------------

-export([start/0]).

%% ====================================================================
%% External functions
%% ====================================================================
init_table()->
    {ok,Info}=file:consult(?InitFile),
    dbase:init_table_info(Info),
   
    ?assertEqual(["c2","c1","wrong_port","c0",
		  "wrong_hostname","wrong_ipaddr",
		  "wrong_passwd","wrong_userid"],
		 mnesia:dirty_all_keys(computer)),
    ?assertEqual([genesis],
		 mnesia:dirty_all_keys(deployment)),
    ?assertEqual(["control","math"],
		 mnesia:dirty_all_keys(deployment_spec)),
    ?assertEqual(["joq62"],
		 mnesia:dirty_all_keys(passwd)),
    ?assertEqual(["iaas","control"],
		 mnesia:dirty_all_keys(sd)),
    ?assertEqual(["adder_service","common","divi_service","multi_service"],
		 mnesia:dirty_all_keys(service_def)),

    ?assertEqual([info],
		 mnesia:dirty_all_keys(log)),
    ok.


% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start()->
    %initiate table 
    ?assertEqual(ok,init_table()),
    

    ok.
