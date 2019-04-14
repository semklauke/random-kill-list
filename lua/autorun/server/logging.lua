--[[
    Sem Klauke, 2019
    Random Kill List, Gary's Mod, TTT

    logging helper
]]--
local module = {}
module.prefix = "DB ERROR: "
module.error = {}

function module.out(text)
    print("[RANDOM-KILL-LIST] " .. text)
end


function module.error.statement_create(statement_name, db_errormsg)
    module.out(module.prefix .. "Statement " .. statement_name .. " not created with error")
    module.out(db_errormsg)
end

function module.error.statement_execute(statement_name, db_errormsg)
    module.out(module.prefix .. "Statement " .. statement_name .. " not excuted with error")
    module.out(db_errormsg)
end