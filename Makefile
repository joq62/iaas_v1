all:
	rm -rf  ebin/* test_ebin/* src/*~ test_src/*~ *~ erl_crash.dump src/*.beam test_src/*.beam;
	cp src/*.app ebin;
doc_gen:
	rm -rf  node_config logfiles doc/*;
	erlc ../doc_gen.erl;
	erl -s doc_gen start -sname doc

test:
	rm -rf  *_service include logfiles app_config node_config latest.log;
	rm -rf *.beam src/*.beam test_src/*.beam ebin/* test_ebin/* erl_crash.dump;
#	include
	git clone https://github.com/joq62/include.git;
	cp src/*app ebin;
	erlc -I include -o ebin src/*.erl;
	erlc -I include -o test_ebin test_src/*.erl;
	erl -config test.config -pa ebin -sname node1 -detached
	erl -config test.config -pa ebin -pa */ebin -pa test_ebin -s sd_service_tests start -sname sd_test
