--[[
    Sem Klauke, 2019
    Random Kill List, Gary's Mod, TTT

    logging helper
]]--
local module = {}
module.error = {}

module.prefix = "[RANDOM-KILL-LIST] "
module.prefix_dberror = "[DB ERROR] "
module.prefix_error = "[ERROR] "


function module.out(text)
    print(module.prefix .. text)
end

function module.error.out(text)
    module.out(module.prefix_error ..  text)
end

function module.error.db(text)
    module.out(module.prefix_dberror ..  text)
end
function module.error.statement_create(statement_name, db_errormsg)
    module.error.db("Statement " .. statement_name .. " not created with error")
    module.out(db_errormsg)
end

function module.error.statement_execute(statement_name, db_errormsg)
    module.error.db("Statement " .. statement_name .. " not excuted with error")
    module.out(db_errormsg)
end


return module