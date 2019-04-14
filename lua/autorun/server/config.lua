--[[
    Sem Klauke, 2019

    Global variables and settings
]]--
local config = {}

config.SQLITE_FILE="randomKillsList.db"
config.WEBVIEW_FOLDER="randome-kill-list-webview/" -- don't forget trailing /
-- Only edit of you know what you are doing
config.RESOURCE_PATH="../../../resource/"
config.SQLITE_PATH=config.RESOURCE_PATH .. config.SQLITE_FILE
config.WEBVIEW_PATH=config.RESOURCE_PATH .. config.WEBVIEW_FOLDER