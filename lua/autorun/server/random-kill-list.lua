--[[
    Sem Klauke, 2019
    Random Kill List, Gary's Mod, TTT

    Main file, starting point
]]--

local sqlite3 = require("lsqlite3complete")

local config = require("config")

local database = assert( sqlite3.open(config.SQLITE_PATH) )


-- globals --

local PLAYERS = {} -- All players in the round
local TRAITORS = {} -- All traitors in the round
local VOTES = {}
local VOTE_COUNTS = {}
local TRAITOR_KILLERS = {}
local MESSAGES = {}


-- logging --
local logging = require("logging")

-- helper functionn --

local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

local function checkDouble(table, key)
    for k,v in pairs(table) do
        if k == key then
            return true
        end
    end
    return false
end

local function checkDB()
    return database:isopen()
end

local function isBotOrNil_Player(p)
    if p == nil then return true end
    if p:SteamID() == "BOT" then return true end
    return false
end

local function isBotOrNil_String(p)
    if p == nil then return true end
    if p == "BOT" then return true end
    return false
end


-- network communication to the client --

local function net_openListPanel(ply)
    net.Start("THELIST_TheListPanel")
    if ply == nil then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

local function net_askTraitor(ply)
    net.Start("THELIST_AskTraitor")
    net.Send(ply)
end

local function net_askEverybody()
    net.Start("THELIST_AskEverybody")
    net.Broadcast()
end

local function net_finishVoteFor(steamid)
    net.Start("THELIST_StopVote")
    net.WriteString(steamid)
    net.Broadcast()
    --count upvotes
    local upvotes = 0
    for _,v in pairs(VOTES[steamid]) do
        if v == true then
            upvotes = upvotes + 1
        end
    end
    local max = player.GetCount()
    local text = "[THE LIST] "
    if upvotes >= round(max * config.VOTE_PERC) then 
        -- TODO
        --db_addRandomeKill(thelist_traitorKiller[steamid], steamid)
        text = text .. "Vote passed with " .. upvotes .. " upvotes for " .. TRAITORS[steamid] 
    else
        text = text .. "Vote failed with " .. upvotes .. " upvotes for " .. TRAITORS[steamid]
    end
    PrintMessage(HUD_PRINTTALK, text)
    TRAITORS[steamid] = nil
    VOTES[steamid] = {}
    VOTE_COUNTS[steamid] = nil
    TRAITOR_KILLERS[steamid] = nil

end


-- sqlite setup --

local sqlitesetup = require("init-database")
sqlitesetup.init(database)
logging.out("Database initialised")


-- database maniplulation --

-- statements 
local statements = {}
-- :steam (SteamID of player)
statements.user_select = database:prepare("SELECT rec_id, steam_id, current_nick FROM player WHERE steam_id = :steam;")
if not statements.user_select then logging.error.statement_create("user_select", database:errmsg()) end

-- :ply (player_id of player)
statements.user_register = database:prepare("INSERT INTO rounds_played (player_id) VALUES (:ply);")
if not statements.user_register then logging.error.statement_create("user_register", database:errmsg()) end

-- :steam (SteamID of new player), :nick (current Nickname of new player0)
statements.user_add = database:prepare("INSERT INTO player (steam_id, current_nick) VALUES (:steam, :nick);")
if not statements.user_add then logging.error.statement_create("user_add", database:errmsg()) end 

-- :ply (player_id of player)
statements.user_update = database:prepare("UPDATE player SET current_nick = :nick WHERE rec_id = :ply;")
if not statements.user_update then logging.error.statement_create("user_update", database:errmsg()) end 

-- :attacker (SteamID of attacker), :victim (SteamID of victim)
statements.random_kill_add = database:prepare([[
    INSERT INTO random_kills (attacker_id, victim_id) VALUES ( 
    (SELECT rec_id FROM player WHERE steam_id = :attacker),
    (SELECT rec_id FROM player WHERE steam_id = :victim));
]])
if not statements.random_kill_add then logging.error.statement_create("random_kill_add", database:errmsg()) end


local function db_registerPlayer(ply)
    if isBotOrNil_Player(ply) then return end

    checkDB()

    statements.user_select:bind_names({ steam = ply:SteamID() })
    local user_select_return = statements.user_select:step() 

    if user_select_return == sqlite3.ROW then

        -- player already in database
        local user = get_uvalues()
        statements.user_update:bind_names({ ply = user.rec_id })
        if not statements.user_update:step() == sqlite3.DONE then
            logging.error.statement_execute("user_update", database:errmsg())
        end
        statements.user_update:reset()

    elseif user_select_return == sqlite3.DONE then

        -- player is not in database yet
        statements.user_add:bind_names({ steam = ply:SteamID(), nick = ply:Nick() })
        if not statements.user_add:step() == sqlite3.DONE then
            logging.error.statement_execute("user_add", database:errmsg())
        end
        statements.user_add:reset()

    else
        -- error occured
        logging.error.statement_execute("user_select", database:errmsg())
    end

    statements.user_select:reset()
    
end

local function db_addRandomeKill(attacker_steamid, victim_steamid)
    if isBotOrNil_String(attacker_steamid) or isBotOrNil_String(victim_steamid) then return end

    checkDB()

    statements.random_kill_add:bind_names({ attacker = attacker_steamid, victim = victim_steamid })
    if not statements.random_kill_add:step() == sqlite3.DONE then
        logging.error.statement_execute("random_kill_add", database:errmsg())
    end
    statements.random_kill_add:reset()
end

-- game hooks -- 


-- timer setup --

























