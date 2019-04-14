local sqlite3 = require("lsqlite3complete")

local config = require("config")

local database = assest( sqlite3.open(config.SQLITE_PATH) )


-- globals --

local PLAYERS = {} -- All players in the round
local TRAITORS = {} -- All traitors in the round
local VOTES = {}
local VOTE_COUNTS = {}
local TRAITOR_KILLERS = {}
local MESSAGES = {}


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

-- database maniplulation --

-- game hooks -- 

-- sqlite setup --

local sqlitesetup -- = require("setup-sqlite")
--sqlitesetup.setup(database)

-- timer setup --