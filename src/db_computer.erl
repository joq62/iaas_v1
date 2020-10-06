-module(db_computer).
-import(lists, [foreach/2]).

%-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").
-export([create_table/0,
	 create/1,delete/1,
	 read_all/0, read/1,
	 update/5	   
	]).

-record(computer,
	{
	  host_id,
	  ssh_uid,
	  ssh_passwd,
	  ip_addr,
	  port
	}).

-define(TABLE,computer).
-define(RECORD,computer).

create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables(?TABLE, 20000).

create(Record) ->
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{HostId,SshUid,SshPassWd,IpAddr,Port}||{?RECORD,HostId,SshUid,SshPassWd,IpAddr,Port}<-Z].



read(HostId) ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.host_id==HostId])),
    [{Id,SshUid,SshPassWd,IpAddr,Port}||{?RECORD,Id,SshUid,SshPassWd,IpAddr,Port}<-Z].


update(HostId,SshId,SshPwd,IpAddr,Port)->
    F = fun() ->
		Oid = {?TABLE, HostId},
		mnesia:delete(Oid),
		Record = #?RECORD{host_id=HostId,ssh_uid=SshId,ssh_passwd=SshPwd,
				  ip_addr=IpAddr,port=Port},
		mnesia:write(Record)
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
