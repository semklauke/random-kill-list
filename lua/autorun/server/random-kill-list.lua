local sqlite3 = require("lsqlite3complete")

local config = require("config")

local database = assest( sqlite3.open(config.SQLITE_PATH) )


-- globals --

local players = {} -- All players in the round
local traitors = {} -- All traitors in the round
local votes = {}
local voteCounts = {}
local traitorKillers = {}
local messages = {}


-- helper functionn --

local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

local function checkDB()
    return database:isopen()
end


-- network communication to the client --

-- database maniplulation --

-- game hooks -- 

-- sqlite setup --

local sqlitesetup -- = require("setup-sqlite")
--sqlitesetup.setup(database)

-- timer setup --