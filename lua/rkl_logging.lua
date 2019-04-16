--[[
    Sem Klauke, 2019
    Random Kill List, Gary's Mod, TTT

    logging helper
]]--
local logging = {}
logging.error = {}

logging.prefix = "[RANDOM-KILL-LIST] "
logging.prefix_dberror = "[DB ERROR] "
logging.prefix_error = "[ERROR] "


function logging.out(text)
    print(logging.prefix .. text)
end

function logging.error.out(text)
    logging.out(logging.prefix_error ..  text)
end

function logging.error.db(text)
    logging.out(logging.prefix_dberror ..  text)
end
function logging.error.query(statement_name, db_errormsg)
    logging.error.db("Query " .. statement_name .. " failed with error")
    logging.out(db_errormsg)
end

return logging