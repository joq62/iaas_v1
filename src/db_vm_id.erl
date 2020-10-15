-module(db_vm_id).
-import(lists, [foreach/2]).

%-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").
-export([create_table/0,
	 create/1,delete/1,
	 read_all/0, read/1,
	 update/2	   
	]).

-record(vm_id,
	{
	  type,
	  id
	}).

-define(TABLE,vm_id).
-define(RECORD,vm_id).

create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables(?TABLE, 20000).

create(Record) ->
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{Type,Id}||{?RECORD,Type,Id}<-Z].



read(Type) ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.type==Type])),
   % Z.
    [R||{?RECORD,_,R}<-Z].


update(Type,Id)->
    F = fun() ->
		Oid = {?TABLE,Type},
		mnesia:delete(Oid),
		Record = #?RECORD{type=Type,id=Id},
		mnesia:write(Record)
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
