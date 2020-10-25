-module(db_computer).
-import(lists, [foreach/2]).

%-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").
-export([create_table/0,
	 create_table/1,
	 create/6,delete/1,
	 read_all/0, read/1,
	 update/2,
	 status/1   
	]).

-record(computer,
	{
	  host_id,
	  ssh_uid,
	  ssh_passwd,
	  ip_addr,
	  port,
	  status
	}).

-define(TABLE,computer).
-define(RECORD,computer).

% Add create_table with disc nodes
status(Key)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.status==Key])),
    [{HostId,Status}||{?RECORD,HostId,_SshUid,_SshPassWd,_IpAddr,_Port,Status}<-Z].


create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables([?TABLE], 20000).
create_table(NodeList)->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
				 {disc_copies,NodeList}]),
    mnesia:wait_for_tables([?TABLE], 20000).

 

create(HostId,SshId,SshPwd,IpAddr,Port,Status) ->
    Record=#computer{host_id=HostId,
		     ssh_uid=SshId,
		     ssh_passwd=SshPwd,
		     ip_addr=IpAddr,
		     port=Port,
		     status=Status
		    },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{HostId,SshUid,SshPassWd,IpAddr,Port,Status}||{?RECORD,HostId,SshUid,SshPassWd,IpAddr,Port,Status}<-Z].



read(HostId) ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.host_id==HostId])),
    [{Id,SshUid,SshPassWd,IpAddr,Port,Status}||{?RECORD,Id,SshUid,SshPassWd,IpAddr,Port,Status}<-Z].


update(HostId,NewStatus)->
  %  io:format("~p~n",[{?MODULE,?LINE,HostId,NewStatus}]),
    F = fun() ->
		    case mnesia:read(?TABLE,HostId) of
		    []->
						% HostId not define
			mnesia:abort(?TABLE);
		    [ComputerRecord]->
			Oid = {?TABLE, HostId},
			mnesia:delete(Oid),		
			Record =ComputerRecord#?RECORD{status=NewStatus},
			mnesia:write(Record)
		end
	end,
    mnesia:transaction(F).

delete(HostId) ->
    Oid = {?TABLE, HostId},
    F = fun() -> mnesia:delete(Oid) end,
  mnesia:transaction(F).


do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

%%-------------------------------------------------------------------------
