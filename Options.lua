local _, F = ...
SLASH_FELBOT1 = "/felbot"
SlashCmdList.FELBOT = function(message)
    local _,class=UnitClass("player")
    if class~="WARLOCK" then F:Print("Access denied. For warlocks only. Use Buff Rag instead."); return end
    if not F.db then F:Print("FelBot is not ready yet."); return end
    if InCombatLockdown() then F:Print("Settings are available out of combat."); return end
    local args = {}
    for word in message:lower():gmatch("%S+") do args[#args + 1] = word end
    local cmd = args[1]
    if not cmd then F.options:SetShown(not F.options:IsShown()); return end
    if cmd == "size" or cmd == "spacing" or cmd == "offset" then
        local value = tonumber(args[2])
        local minimum, maximum = 10, 40
        if cmd == "spacing" then minimum, maximum = 0, 15 end
        if cmd == "offset" then minimum, maximum = -400, 200 end
        if not value or value < minimum or value > maximum then
            F:Print(cmd .. " must be between " .. minimum .. " and " .. maximum); return
        end
        F.db[cmd] = value
    elseif cmd == "priority" then
        -- Keep the original three-buff command working for existing users.
        if #args == 4 then args[5] = "breath" end
        if #args ~= 5 then F:Print("Use each once: armor sense detect breath"); return end
        local seen = {}
        for i = 2, 5 do
            local key = args[i]
            if not key or key == "soul" or not F.spells[key] or seen[key] then
                F:Print("Use each once: /felbot priority armor sense detect breath"); return
            end
            seen[key] = true
        end
        F.db.priority = { args[2], args[3], args[4], args[5] }
    else
        F:Print("/felbot opens settings. Commands: size, offset, spacing, priority."); return
    end
    F:Refresh()
    F:Print("Settings updated.")
end
