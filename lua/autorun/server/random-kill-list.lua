local sqlite3 = require("lsqlite3complete")

local config = require("config")

local db = sqlite3.open(config.SQLITE_PATH)