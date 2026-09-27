local persistent_data = getgenv().persistent_data
local _rcprint        = getgenv()._rcprint

local farms = {}
getgenv().ns_farms = farms

local function log(msg) _rcprint("[Vanta] " .. msg .. "\n") end

local function defineFarm(opts)
    farms[opts.id] = {
        id                   = opts.id,
        persistent_data_flag = opts.flag,
        display_name         = opts.name,
        run                  = opts.run,
    }
end

local function startAntiAFK()
    local vim = Instance.new("VirtualInputManager")
    task.spawn(function()
        while true do
            task.wait(120)
            vim:SendKeyEvent(true,  Enum.KeyCode.Unknown, false, game)
            task.wait(0.1)
            vim:SendKeyEvent(false, Enum.KeyCode.Unknown, false, game)
        end
    end)
end

local function safeTween(cf)
    pcall(function()
        local lp = getgenv().local_player
        if lp and lp.root_part then
            lp.root_part.CFrame = cf
        end
    end)
end

-- ─── Farm Definitions ───────────────────────────────────────

defineFarm({ id = "auto_saramed",            flag = "auto_saramed",            name = "Auto Saramed",
    run = function()
        log("Auto Saramed started!")
        while persistent_data:get("auto_saramed") do
            task.wait(1)
            local live = workspace:FindFirstChild("Live")
            if live then
                for _, e in ipairs(live:GetChildren()) do
                    if not persistent_data:get("auto_saramed") then break end
                    local hrp = e:FindFirstChild("HumanoidRootPart")
                    local hum = e:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 and e ~= getgenv().local_player.character then
                        safeTween(hrp.CFrame * CFrame.new(0, 0, -3))
                        task.wait(0.5)
                    end
                end
            end
            task.wait(2)
        end
    end })

defineFarm({ id = "auto_duke",               flag = "auto_duke",               name = "Auto Duke",
    run = function()
        log("Auto Duke started!")
        while persistent_data:get("auto_duke") do
            task.wait(1)
            local live = workspace:FindFirstChild("Live")
            if live then
                for _, e in ipairs(live:GetChildren()) do
                    if e.Name:lower():match("duke") then
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        if hrp then safeTween(hrp.CFrame * CFrame.new(0, 0, -5)) task.wait(0.5) end
                    end
                end
            end
            task.wait(2)
        end
    end })

defineFarm({ id = "auto_ferryman",           flag = "auto_ferryman",           name = "Auto Ferryman",
    run = function()
        log("Auto Ferryman started!")
        while persistent_data:get("auto_ferryman") do
            task.wait(1)
            local live = workspace:FindFirstChild("Live")
            if live then
                for _, e in ipairs(live:GetChildren()) do
                    if e.Name:lower():match("ferryman") then
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        if hrp then safeTween(hrp.CFrame * CFrame.new(0, 0, -4)) task.wait(0.5) end
                    end
                end
            end
            task.wait(3)
        end
    end })

defineFarm({ id = "auto_layer2",             flag = "auto_layertwo",           name = "Auto Layer 2",
    run = function()
        log("Auto Layer 2 started!")
        while persistent_data:get("auto_layertwo") do
            task.wait(1)
            local live = workspace:FindFirstChild("Live")
            local lp = getgenv().local_player
            if live and lp.root_part then
                local nearest, nearestDist = nil, math.huge
                for _, e in ipairs(live:GetChildren()) do
                    if e ~= lp.character then
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local d = (hrp.Position - lp.root_part.Position).Magnitude
                            if d < nearestDist then nearestDist = d; nearest = e end
                        end
                    end
                end
                if nearest and nearest:FindFirstChild("HumanoidRootPart") then
                    safeTween(nearest.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4))
                    task.wait(0.5)
                end
            end
            task.wait(2)
        end
    end })

defineFarm({ id = "auto_echo_layer2",        flag = "auto_echo_layer2",        name = "Auto Echo (Layer 2)",
    run = function() log("Auto Echo Layer 2 started!") while persistent_data:get("auto_echo_layer2") do task.wait(5) end end })

defineFarm({ id = "auto_escape_depths",      flag = "auto_escape_depths",      name = "Auto Escape Depths",
    run = function() log("Auto Escape Depths started!") while persistent_data:get("auto_escape_depths") do task.wait(5) end end })

defineFarm({ id = "auto_authority",          flag = "auto_authority_missions", name = "Auto Authority Missions",
    run = function() log("Auto Authority started!") while persistent_data:get("auto_authority_missions") do task.wait(5) end end })

defineFarm({ id = "auto_mooneyrie",          flag = "auto_moonseyrie",         name = "Auto Mooneyrie",
    run = function() log("Auto Mooneyrie started!") while persistent_data:get("auto_moonseyrie") do task.wait(5) end end })

defineFarm({ id = "auto_progress",           flag = "auto_progress",           name = "Auto Progress",
    run = function() log("Auto Progress started!") while persistent_data:get("auto_progress") do task.wait(5) end end })

defineFarm({ id = "auto_voi",                flag = "auto_voi",                name = "Auto Voi",
    run = function() log("Auto Voi started!") while persistent_data:get("auto_voi") do task.wait(5) end end })

defineFarm({ id = "ministry_notefarm",       flag = "ministry_notefarm",       name = "Ministry Notefarm",
    run = function()
        log("Ministry Notefarm started!")
        while persistent_data:get("ministry_notefarm") do
            task.wait(5)
            local noteFolder = workspace:FindFirstChild("Notes") or workspace:FindFirstChild("Items")
            if noteFolder then
                for _, note in ipairs(noteFolder:GetDescendants()) do
                    if not persistent_data:get("ministry_notefarm") then break end
                    if note.Name:lower():match("note") and note:FindFirstChild("InteractPrompt") then
                        safeTween(note.CFrame)
                        pcall(function() fireproximityprompt(note.InteractPrompt) end)
                        task.wait(0.5)
                    end
                end
            end
        end
    end })

defineFarm({ id = "soup_echofarm",           flag = "soup_echofarm",           name = "Soup Echo Farm",
    run = function() log("Soup Echo Farm started!") while persistent_data:get("soup_echofarm") do task.wait(5) end end })

defineFarm({ id = "titus_echofarm",          flag = "titus_echofarm",          name = "Titus Echo Farm",
    run = function()
        log("Titus Echo Farm started!")
        while persistent_data:get("titus_echofarm") do
            task.wait(5)
            local live = workspace:FindFirstChild("Live")
            if live then
                for _, e in ipairs(live:GetChildren()) do
                    if e.Name:lower():match("titus") then
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        if hrp then safeTween(hrp.CFrame * CFrame.new(0, 0, -5)) task.wait(1) end
                    end
                end
            end
        end
    end })

defineFarm({ id = "titus_relicfarm",         flag = "autoecho_titus",          name = "Titus Relic Farm",
    run = function() log("Titus Relic Farm started!") while persistent_data:get("autoecho_titus") do task.wait(5) end end })

defineFarm({ id = "jetstriker_echofarm",     flag = "jetstriker_echofarm",     name = "Jetstriker Echo Farm",
    run = function() log("Jetstriker Echo Farm started!") while persistent_data:get("jetstriker_echofarm") do task.wait(5) end end })

defineFarm({ id = "auto_deepdrill",          flag = "auto_deepdrill",          name = "Auto Deepdrill",
    run = function() log("Auto Deepdrill started!") while persistent_data:get("auto_deepdrill") do task.wait(5) end end })

-- ─── Loader API ─────────────────────────────────────────────

local function shouldAutoStart()
    for _, farm in pairs(farms) do
        if persistent_data:get(farm.persistent_data_flag) == true then return true end
    end
    return false
end

local function startFarms()
    local any = false
    for _, farm in pairs(farms) do
        if persistent_data:get(farm.persistent_data_flag) == true then
            any = true
            task.spawn(function()
                local ok, err = pcall(farm.run)
                if not ok then log("Farm error [" .. farm.id .. "]: " .. tostring(err)) end
            end)
        end
    end
    if any then startAntiAFK() end
end

local function setFarm(flag, on)
    persistent_data:set(flag, on)
    if on then
        for _, farm in pairs(farms) do
            if farm.persistent_data_flag == flag then
                startAntiAFK()
                task.spawn(function()
                    local ok, err = pcall(farm.run)
                    if not ok then log("Farm error [" .. farm.id .. "]: " .. tostring(err)) end
                end)
                break
            end
        end
    end
end

return {
    farms            = farms,
    shouldAutoStart  = shouldAutoStart,
    startFarms       = startFarms,
    setFarm          = setFarm,
}
