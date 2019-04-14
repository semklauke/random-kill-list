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

local function getNickForSteamID(steamid)
    player.GetBySteamID(steamid):Nick()
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
    if upvotes >= round(max * config.VOTE_PERC) then 
        PrintMessage(HUD_PRINTTALK, logging.prefix .. "Vote PASSED with " .. upvotes .. " upvotes for " .. TRAITORS[steamid])
        db_addRandomeKill(TRAITOR_KILLERS[steamid], steamid)
    else
        PrintMessage(HUD_PRINTTALK, logging.prefix .. "Vote FAILED with " .. upvotes .. " upvotes for " .. TRAITORS[steamid])
    end
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

-- attacker_steamid (SteamID of attacker)
statements.user_random_kills = database:prepare([[
    SELECT COUNT(*) AS kills
    FROM random_kills 
    LEFT JOIN player 
    ON random_kills.attacker_id = player.rec_id 
    WHERE player.steam_id = :attacker_steamid 
    GROUP BY random_kills.attacker_id ORDER BY kills DESC
]])
if not statements.user_random_kills then logging.error.statement_create("user_random_kills", database:errmsg()) end


local function db_registerPlayer(ply)
    if isBotOrNil_Player(ply) then return end

    checkDB()

    statements.user_select:bind_names({ steam = ply:SteamID() })
    local user_select_return = statements.user_select:step() 

    if user_select_return == sqlite3.ROW then

        -- player already in database
        local data = statements.user_select:get_uvalues()
        statements.user_update:bind_names({ ply = data.rec_id })
        if not statements.user_update:step() == sqlite3.DONE then
            logging.error.statement_execute("user_update", database:errmsg())
        end
        statements.user_update:reset()
        logging.out("register  " .. ply:Nick() .. " (" .. ply:SteamID() .. ")")

    elseif user_select_return == sqlite3.DONE then

        -- player is not in database yet
        statements.user_add:bind_names({ steam = ply:SteamID(), nick = ply:Nick() })
        if not statements.user_add:step() == sqlite3.DONE then
            logging.error.statement_execute("user_add", database:errmsg())
        end
        statements.user_add:reset()
        logging.out("new register  " .. ply:Nick() .. " (" .. ply:SteamID() .. ")")

    else
        -- error occured
        logging.error.statement_execute("user_select", database:errmsg())
    end

    statements.user_select:reset()
    
end

local function db_addRandomeKill(attacker_steamid, victim_steamid)
    if isBotOrNil_String(attacker_steamid) or isBotOrNil_String(victim_steamid) then return end

    checkDB()
    local msg

    statements.random_kill_add:bind_names({ attacker = attacker_steamid, victim = victim_steamid })
    if not statements.random_kill_add:step() == sqlite3.DONE then
        logging.error.statement_execute("random_kill_add", database:errmsg())
    else
        
        statements.user_random_kills:bind_names({ attacker_steamid = attacker_steamid })
        local user_random_kills_return = statements.user_random_kills:step()
        if user_random_kills_return == sqlite3.ROW then 
            local kills = statements.user_random_kills:get_uvalues().kills
            msg = logging.prefix .. getNickForSteamID(attacker_steamid) .. " now has " .. kills .. " Random Kills!"
        else
            logging.error.statement_execute("user_random_kills", database:errmsg())
        end
        statements.user_random_kills:reset()
        logging.out("random kill for " .. getNickForSteamID(attacker_steamid) .. " (killed " .. getNickForSteamID(victim_steamid) .. ")")
    end
    statements.random_kill_add:reset()
    return msg
end


-- game hooks -- 

hook.Add("TTTBeginRound", "RKL_TTTBeginRoundHook", function()
    PLAYERS = {}

    for i,ply in ipairs(player:GetAll()) do
        db_registerPlayer(ply)
        PLAYERS[ply:SteamID()] = {}
    end
end)

hook.Add("TTTEndRound", "RKL_TTTEndRoundHook", function()
    for sid,nick in pairs(TRAITORS) do
        net.Start("RKL_AskEverybody")
        net.WriteString(nick)
        net.WriteString(sid)
        net.Broadcast()
        timer.Simple(25, function() if TRAITORS[sid] ~= nil then net_finishVoteFor(sid) end end)
    end

    timer.Simple(26, function() 
        TRAITORS = {}
        VOTES = {}
        VOTE_COUNTS = {}
        TRAITOR_KILLERS = {}
    end)

    for _,ply in ipairs(player:GetAll()) do
        if isBotOrNil_Player(ply) == false then for i,victim in ipairs(PLAYERS[ply:SteamID()]) do
            if isBotOrNil_String(victim) == false then
                local msg = db_addRandomeKill(ply:SteamID(), victim)
                table.insert(MESSAGES, msg)
            end
        end end
    end

    for _,msg in ipairs(MESSAGES) do
        PrintMessage(HUD_PRINTTALK, msg)
    end

    MESSAGES = {}
    
    timer.Simple(3, net_openListPanel)

end)

hook.Add("PlayerDeath", "RKL_PlayerDeathHook", function (ply, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and (ply ~= attacker) and ply ~= nil then
        if ply:GetTraitor() == false and attacker:GetTraitor() == false then
            table.insert(PLAYER[attacker:SteamID()], ply:SteamID())
        end
        if ply:GetTraitor() == true then
            TRAITOR_KILLERS[ply:SteamID()] = attacker:SteamID()
        end
    end
end)

hook.Add("PostPlayerDeath", "RKL_PostPlayerDeathHook", function (ply)
    if ply:GetTraitor() == true then
        net.Start("RKL_AskTraitor")
        net.Send(ply)
    end
end)

hook.Add("PlayerSay", "ChatCommands", function( ply, text, team )
    -- Make the chat message entirely lowercase
    text = string.lower( text )
    if text == "!thelist" or text == "!rklist" or text == "!kills" or text == "!list" then
        net_openListPanel(ply)
        return ""
    end
end)



-- network recives

net.Receive("RKL_TraitorVoted", function(len, sendingPlayer)
    if net.ReadString() == SEND_KEY then
        if net.ReadBool() == true then
            logging.out("Traitor " .. sendingPlayer:Nick() .. " voted YES")
            local msg = logging.prefix .. sendingPlayer:Nick() .. " has scheduled a RandomKill Vote as Traitor"
            table.insert(MESSAGES, text)
            TRAITORS[sendingPlayer:SteamID()] = sendingPlayer:Nick()
            VOTES[sendingPlayer:SteamID()] = {}
            VOTE_COUNTS[sendingPlayer:SteamID()] = player.GetHumans()
        else 
            logging.out("Traitor " .. sendingPlayer:Nick() .. " voted NO")
            TRAITOR_KILLERS[sendingPlayer:SteamID()] = nil
        end
    end
end)


 network setup setup --
timer.Simple(11, function()
    --resource.AddFile("/home/steam/Steam/gm/garrysmod/lua/autorun/cl_TheList.lua")
    checkDB()
    util.AddNetworkString("RKL_StopVote")
    util.AddNetworkString("RKL_TheListPanel")
    util.AddNetworkString("RKL_TraitorVoted")
    util.AddNetworkString("RKL_AskTraitor")
    util.AddNetworkString("RKL_AskEverybody")
    util.AddNetworkString("RKL_UserVoted")
end)