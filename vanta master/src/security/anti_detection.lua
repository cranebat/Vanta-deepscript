-- ──────────────────────────────────────────────────────
-- [0] ANTI-DETECTION — nuke GetLogHistory
-- ──────────────────────────────────────────────────────
-- DISABLED FOR NOW: this hook made LogService:GetLogHistory() always return
-- an empty table, which also blinds Volt's own console (it polls the same
-- API for its live log view). Re-enable once everything else is verified
-- working, and consider filtering out only "[Vanta]"-tagged entries instead
-- of nuking the whole history, so debugging stays possible.
--[[
local _LogService = game:GetService("LogService")

local _oldGetLogHistory
pcall(function()
    _oldGetLogHistory = hookfunction(_LogService.GetLogHistory, newcclosure(function(...)
        return {}
    end))
end)
--]]

return true
