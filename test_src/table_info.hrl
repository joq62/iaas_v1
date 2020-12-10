
[db_log,'10250@asus',module1,line1,info,{1962,03,07},{22,18,34},"System start and intial init of mnesia"].

[db_computer,"c0","joq62","festum01","192.168.0.200",60200,not_available].
[db_computer,"c1","joq62","festum01","192.168.0.201",60201,not_available].
[db_computer,"c2","joq62","festum01","192.168.0.202",60202,not_available].
[db_computer,"wrong_hostname","pi","festum01","192.168.0.110",60100,not_available].
[db_computer,"wrong_ipaddr","pi","festum01","25.168.0.110",60100,not_available].
[db_computer,"wrong_port","pi","festum01","192.168.0.110",2323,not_available].
[db_computer,"wrong_userid","glurk","festum01","192.168.0.110",60100,not_available].
[db_computer,"wrong_passwd","pi","glurk","192.168.0.110",60100,not_available].


[db_service_def,"adder_service","1.0.0","joq62"].
[db_service_def,"multi_service","1.0.0","joq62"].
[db_service_def,"divi_service","1.0.0","joq62"].
[db_service_def,"common","1.0.0","joq62"].


[db_passwd,"joq62","20Qazxsw20"].

[db_deployment_spec,"math","1.0.0",no_restrictions,[{"adder_service","1.0.0"},{"divi_service","1.0.0"}]].
[db_deployment_spec,"control","1.0.0",{node,'10250@asus'},[{"control","1.0.0"},{"iaas","1.0.0"}]].

[db_deployment,genesis,"control","1.0.0",{1970,01,01},{00,00,00},"asus","10250",
 [{"control","1.0.0",'10250@asus'},{"iaas","1.0.0",'10250@asus'}],ta_bort].

[db_sd,"iaas","1.0.0","asus","10250",'10250@asus'].
[db_sd,"control","1.0.0","asus","10250",'10250@asus'].



