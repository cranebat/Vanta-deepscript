-- ──────────────────────────────────────────────────────
-- [0] ANTI-DETECTION — nuke GetLogHistory
-- ──────────────────────────────────────────────────────
local _LogService = game:GetService("LogService")

-- Nuke GetLogHistory — return empty table always.
-- When Deepwoken calls LogService:GetLogHistory() to scan logs, it gets an empty table.
local _oldGetLogHistory
pcall(function()
    _oldGetLogHistory = hookfunction(_LogService.GetLogHistory, newcclosure(function(...)
        return {}
    end))
end)

return true
