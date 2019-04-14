--[[
    Sem Klauke, 2019
    Random Kill List, Gary's Mod, TTT

    Database setup
]]--
local module = {}

-- database = sqlite3 database connection
function module.init(database)
    module.database = database
    local needs_init = true
    local tables = [[
        name='player' 
        OR name='random_kills' 
        OR name='rounds_played' 
    ]]
    for row in module.database:nrows("SELECT name FROM sqlite_master WHERE type='table' AND (" .. tables .. ");") do
        needs_init = false
    end
    if needs_init then
        module.init_tables()
    end
    module.init_encoding()
end


-- SQL statments --

local sql_create_player = [[
    CREATE TABLE IF NOT EXISTS `player` (
        `rec_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        `steam_id` VARCHAR NOT NULL DEFAULT '',
        `current_nick` VARCHAR DEFAULT NULL
    );

]]

local sql_create_random_kills = [[
    CREATE TABLE IF NOT EXISTS `random_kills` (
        `rec_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        `attacker_id` INTEGER NOT NULL,
        `victim_id` INTEGER NOT NULL,
        `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(`attacker_id`) REFERENCES player(`rec_id`),
        FOREIGN KEY(`victim_id`) REFERENCES player(`rec_id`)
    );

]]

local sql_create_rounds_played = [[
    CREATE TABLE IF NOT EXISTS `rounds_played` (
        `rec_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        `date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `player_id` INTEGER NOT NULL,
        FOREIGN KEY(`player_id`) REFERENCES player(`rec_id`)
    );

]]

-- database init functions -- 
function module.init_tables()
    assert(module.database:exec(sql_create_player))
    assert(module.database:exec(sql_create_random_kills))
    assert(module.database:exec(sql_create_rounds_played))
end

function module.init_encoding()
    module.database:exec([[PRAGMA encoding = "UTF-8";]]);
end

-- return module
return module