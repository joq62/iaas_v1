-module(db_vm).
-import(lists, [foreach/2]).

%-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").
-export([create_table/0,	 
	 create_table/1,
	 create/5,delete/1,
	 read_all/0, read/1,
	 update/2,
	 host_id/1,type/1,status/1
	]).

-record(vm,
	{
	  vm,
	  host_id,
	  vm_id,
	  type,
	  status
	}).

-define(TABLE,vm).
-define(RECORD,vm).


%% Special

host_id(Key)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.host_id==Key])),
    [{Vm,HostId,VmId,Type,Status}||{?RECORD,Vm,HostId,VmId,Type,Status}<-Z].
type(Key)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.type==Key])),
    [{Vm,HostId,VmId,Type,Status}||{?RECORD,Vm,HostId,VmId,Type,Status}<-Z].  
status(Key)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.status==Key])),
    [{Vm,HostId,VmId,Type,Status}||{?RECORD,Vm,HostId,VmId,Type,Status}<-Z].  

create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables([?TABLE], 20000).
create_table(NodeList)->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
				 {disc_copies,NodeList}]),
    mnesia:wait_for_tables([?TABLE], 20000).


create(Vm,HostId,VmId,Type,Status)->
    Record=#vm{
	      vm=Vm,
	      host_id=HostId,
	      vm_id=VmId,
	       type=Type,
	       status=Status
	      },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{Vm,HostId,VmId,Type,Status}||{?RECORD,Vm,HostId,VmId,Type,Status}<-Z].



read(Type) ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.type==Type])),
   % Z.
    [R||{?RECORD,_,R}<-Z].



update(Vm,NewStatus)->
    F = fun() ->
		RecordList=mnesia:read(?TABLE,Vm), 
		case RecordList of
		    []->
						% HostId not define
			mnesia:abort(?TABLE);
		   [VmRecord]->
			Oid = {?TABLE,Vm},
			mnesia:delete(Oid),		
			Record =VmRecord#?RECORD{status=NewStatus},
			mnesia:write(Record)
		end
	end,
    mnesia:transaction(F).

delete(Vm) ->
    Oid = {?TABLE,Vm},
    F = fun() -> mnesia:delete(Oid) end,
  mnesia:transaction(F).


do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

%%-------------------------------------------------------------------------
