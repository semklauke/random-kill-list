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
	if [ $(sudo luarocks list | grep "lsqlite3complete" | wc -l) =  1 ]; then sudo luarocks install lsqlite3complete; fi;
	rm .gitignore
	rm -rf .git
	rm LICENSE
	rm README.md
	rm .DS_Store
	rm Makefile
