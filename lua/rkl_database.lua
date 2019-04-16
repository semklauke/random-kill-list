--[[
    Sem Klauke, 2019
    Random Kill List, Gary's Mod, TTT

    Database functions + setup
]]--

local config = include("rkl_config.lua")
local logging = include("rkl_logging.lua")

function esc(unescaped)
    return sql.SQLStr(unescaped, false)
end

function esc_sql(unescaped)
    return sql.SQLStr(unescaped, true)
end

function init_database()
    logging.out("init database")
    local needs_init = false
    local tables_sql = string.format("name=%s OR name=%s OR name=%s", esc(config.table.player), esc(config.table.random_kills), esc(config.tables.rounds_played))
    for sqltable in tables do
        if not sql.sql.TableExists(sqltable) then
            needs_init = true
            break
        end
    end
    if needs_init then
        logging.out("no tables exists - creating tables")
        init_tables()
    end
    init_encoding()
end


-- SQL statments --

local sql_create_player = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        `rec_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        `steam_id` VARCHAR NOT NULL DEFAULT '',
        `current_nick` VARCHAR DEFAULT NULL
    );
]]
sql_create_player = string.format(sql_create_player, esc_sql(config.table.player))

local sql_create_random_kills = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        `rec_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        `attacker_id` INTEGER NOT NULL,
        `victim_id` INTEGER NOT NULL,
        `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(`attacker_id`) REFERENCES %s(`rec_id`),
        FOREIGN KEY(`victim_id`) REFERENCES %s(`rec_id`)
    );
]]
sql_create_random_kills = string.format(sql_create_random_kills, esc_sql(config.table.random_kills), esc(config.table.player), esc(config.table.player))

local sql_create_rounds_played = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        `rec_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        `date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `player_id` INTEGER NOT NULL,
        FOREIGN KEY(`player_id`) REFERENCES %s(`rec_id`)
    );
]]
sql_create_rounds_played = string.format(sql_create_rounds_played, esc_sql(config.table.rounds_played), esc(config.table.player))


-- database init functions -- 
local function init_tables()
    if sql.Query(sql_create_player) ~= nil then
        logging.error.query("sql_create_player", sql.LastError())
    end
    logging.out(tables.player ..  " created")

    if sql.Query(sql_create_random_kills) ~= nil then
        logging.error.query("sql_create_random_kills", sql.LastError())
    end
    logging.out(tables.random_kills ..  " created")

    if sql.Query(sql_create_rounds_played) ~= nil then
        logging.error.query("sql_create_rounds_played", sql.LastError())
    end
    logging.out(tables.rounds_played ..  " created")
end

local function init_encoding()
    if sql.Query([[PRAGMA encoding = "UTF-8";]]) ~= nil then
        logging.error.query("PRAGMA encoding = UTF-8;", sql.LastError())
    end
end