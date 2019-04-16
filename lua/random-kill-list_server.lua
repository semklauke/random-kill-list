--[[
    Sem Klauke, 2019
    Random Kill List, Gary's Mod, TTT

    Main file, starting point
]]--
local config = include("rkl_config.lua")

-- globals --

local PLAYERS = {} -- All players in the round
local TRAITORS = {} -- All traitors in the round
local VOTES = {}
local VOTE_COUNTS = {}
local TRAITOR_KILLERS = {}
local MESSAGES = {}


-- logging --
local logging = include("rkl_logging.lua")

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

include("rkl_database.lua")
init_database()


-- sql statments 

local statements = {}
local t = {
    player = esc_sql(config.table.player),
    random_kills = esc_sql(config.table.random_kills),
    rounds_played = esc_sql(config.table.rounds_played)
}

-- %s (table.player), %s (SteamID of player)
statements.user_select = "SELECT rec_id, steam_id, current_nick FROM %s WHERE steam_id = %s LIMIT 1;"
statements.user_select = string.format(statements.user_select, t.player, "%s")

-- %s (table.rounds_played), %d (player_id of player)
statements.user_register = "INSERT INTO %s (player_id) VALUES (%d);"
statements.user_register = string.format(statements.user_register, t.rounds_played, "%d")

-- %s (table.player), %s (SteamID of new player), %s (current nickname of new player)
statements.user_add = "INSERT INTO %s (steam_id, current_nick) VALUES (%s, %s);"
statements.user_add = string.format(statements.user_add, t.player, "%s", "%s")

-- %s (table.player), %s (new nickname for player), %d (player_id of player)
statements.user_update = "UPDATE %s SET current_nick = %s WHERE rec_id = %d;"
statements.user_update = string.format(statements.user_update, t.player, "%s", "%d")

-- %s (table.random_kills), %s (table.player), %s (SteamID of attacker), 
-- %s (table.player), %s (SteamID of victim)
statements.random_kill_add = [[
    INSERT INTO %s (attacker_id, victim_id) VALUES ( 
    (SELECT rec_id FROM %s WHERE steam_id = %s),
    (SELECT rec_id FROM %s WHERE steam_id = %s));
]]
statements.random_kill_add = string.format(statements.random_kill_add, t.random_kills, t.player, "%s", t.player, "%s")

-- %s (table.random_kills), %s (table.player), %s (SteamID of attacker)
statements.user_random_kills = [[
    SELECT COUNT(*) AS kills
    FROM %s AS rks
    LEFT JOIN %s AS pl
    ON rks.attacker_id = pl.rec_id 
    WHERE pl.steam_id = %s 
    GROUP BY rks.attacker_id ORDER BY kills;
]]
statements.user_random_kills = string.format(statements.user_random_kills, t.random_kills, t.player, "%s")


-- database mainpluation

local function db_registerPlayer(ply)
    if isBotOrNil_Player(ply) then return end

    local user_select = string.format(statements.user_select, esc(ply:SteamID()))
    local user_select_return = sql.Query(user_select)

    if user_select_return == nil then
        -- player is not in database yet
        local user_add = string.format(statements.user_add, esc(ply:SteamID()), esc(ply:Nick()))
        if sql.Query(user_add) ~= nil then
            logging.error.query("user_add", sql.LastError())
        end
        logging.out("new register  " .. ply:Nick() .. " (" .. ply:SteamID() .. ")")

    elseif user_select_return == false then
        -- error occured
        logging.error.query("user_select", sql.LastError())        
    else
        -- player already in database
        local rec_id = tonumber(user_select_return[1].rec_id)
        local user_update = string.format(statements.user_update, esc(ply:Nick()), rec_id)
        if sql.Query(user_update) ~= nil then
             logging.error.query("user_update", sql.LastError())
        end
        logging.out("register  " .. ply:Nick() .. " (" .. ply:SteamID() .. ")")
    end    
end

local function db_addRandomeKill(attacker_steamid, victim_steamid)
    if isBotOrNil_String(attacker_steamid) or isBotOrNil_String(victim_steamid) then return end

    local msg

    local random_kill_add = string.format(statements.random_kill_add, esc(attacker_steamid), esc(victim_steamid))
    if sql.Query(random_kill_add) ~= nil then
        logging.error.query("random_kill_add", sql.LastError())
    else
        -- successfull added random kill
        local user_random_kills = string.format(statements.user_random_kills, esc(attacker_steamid))
        local user_random_kills_return = sql.QueryRow(user_random_kills)
        if (user_random_kills_return ~= nil) and (user_random_kills_return ~= false) then 
            local kills = user_random_kills_return.kills
            msg = logging.prefix .. getNickForSteamID(attacker_steamid) .. " now has " .. kills .. " Random Kills!"
        else
            logging.error.query("user_random_kills", sql.LastError())
        end
        logging.out("random kill for " .. getNickForSteamID(attacker_steamid) .. " (killed " .. getNickForSteamID(victim_steamid) .. ")")
    end
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


--  network setup setup --
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
