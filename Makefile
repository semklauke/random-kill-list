SERVER=./lua/autorun/server
CLIENT=./lua/autorun/client

server:
	(cd $(SERVER) && lua random-kill-list.lua)

client:
	(cd $(CLIENT) && lua cl_random-kill-list.lua)

.PHONY: clean
clean:
	rm -rf ./resource/randomKillsList.db

.PHONY: install
install:
	if [ $(luarocks list | grep "lsqlite3complete" | wc -l) -eq 1 ]; then luarocks install lsqlite3complete; fi;
	mkdir ../lua/autorun/server/randome-kill-list/
	cp -R lua/autorun/server/* ../lua/autorun/server/randome-kill-list/
	cp -R lua/autorun/client/* ../lua/autorun/client/
	cp -R resource/* ../resource/
