--[[
    Sem Klauke, 2019
    Random Kill List, Gary's Mod, TTT
    
    Global variables and settings
]]--
local config = {}

config.SQLITE_FILE="randomKillsList.db"
config.WEBVIEW_FOLDER="randome-kill-list-webview/" -- don't forget trailing /

config.VOTE_PERC = 0.8
config.SEND_KEY = "SHJKDGKASJDHSKLADG&@%&DSKLJAHLBDKBA<SBD"

-- Only edit of you know what you are doing
config.RESOURCE_PATH="../../../resource/"
config.SQLITE_PATH=config.RESOURCE_PATH .. config.SQLITE_FILE
config.WEBVIEW_PATH=config.RESOURCE_PATH .. config.WEBVIEW_FOLDER

return config
