-- ──────────────────────────────────────────────────────
-- [0] ANTI-DETECTION — kill GetLogHistory & redirect logs
-- ──────────────────────────────────────────────────────
local _LogService = game:GetService("LogService")

-- Step 1: Nuke GetLogHistory — return empty table always
local _oldGetLogHistory
pcall(function()
    _oldGetLogHistory = hookfunction(_LogService.GetLogHistory, newcclosure(function(...)
        return {}
    end))
end)

-- Step 2: Redirect print/warn to rconsoleprint (exploit console only)
local _rcprint = (typeof(rconsoleprint) == "function" and rconsoleprint)
             or (typeof(rconsolewarn) == "function" and rconsolewarn)
             or function() end

getgenv()._rcprint = _rcprint

local function _safe_concat(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    return table.concat(parts, "\t")
end

pcall(function()
    hookfunction(print, newcclosure(function(...)
        _rcprint("[print] " .. _safe_concat(...) .. "\n")
    end))
end)
pcall(function()
    hookfunction(warn, newcclosure(function(...)
        _rcprint("[warn]  " .. _safe_concat(...) .. "\n")
    end))
end)

-- Step 3: Connect first to MessageOut so we sit at front of listener queue
pcall(function()
    _LogService.MessageOut:Connect(function() end)
end)

return true
