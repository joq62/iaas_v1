-module(db_vm).
-import(lists, [foreach/2]).

%-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").
-export([create_table/0,
	 create/5,delete/1,
	 read_all/0, read/1,
	 update/2,
	 host_id/1,type/1,status/1
	]).

-record(vm,
	{
	  host_id,
	  vm_id,
	  type,
	  vm,
	  status
	}).

-define(TABLE,vm).
-define(RECORD,vm).


%% Special

host_id(Key)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.host_id==Key])),
    [{HostId,VmId,Type,Vm,Status}||{?RECORD,HostId,VmId,Type,Vm,Status}<-Z].
type(Key)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.type==Key])),
    [{HostId,VmId,Type,Vm,Status}||{?RECORD,HostId,VmId,Type,Vm,Status}<-Z].  
status(Key)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.status==Key])),
    [{HostId,VmId,Type,Vm,Status}||{?RECORD,HostId,VmId,Type,Vm,Status}<-Z].  

create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
				{type,bag}]),
    mnesia:wait_for_tables([?TABLE], 20000).

create(HostId,VmId,Type,Vm,Status)->
    Record=#vm{host_id=HostId,
	       vm_id=VmId,
	       type=Type,
	       vm=Vm,
	       status=Status
	      },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{HostId,VmId,Type,Vm,Status}||{?RECORD,HostId,VmId,Type,Vm,Status}<-Z].



read(Type) ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.type==Type])),
   % Z.
    [R||{?RECORD,_,R}<-Z].



update(Vm,NewStatus)->
  %  io:format("~p~n",[{?MODULE,?LINE,HostId,NewStatus}]),
    F = fun() ->
		case [X || X <- mnesia:table(?TABLE),
			   X#?RECORD.vm==Vm] of
		    []->
						% HostId not define
			mnesia:abort(?TABLE);
		    [VmRecord]->
			Oid = {?TABLE, VmRecord#vm.host_id},
			mnesia:delete(Oid),		
			Record =VmRecord#?RECORD{status=NewStatus},
			mnesia:write(Record)
		end
	end,
    mnesia:transaction(F).

delete(Type) ->
    Oid = {?TABLE,Type},
    F = fun() -> mnesia:delete(Oid) end,
  mnesia:transaction(F).


do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

%%-------------------------------------------------------------------------
