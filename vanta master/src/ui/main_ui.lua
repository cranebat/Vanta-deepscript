local _flags    = getgenv().ns_flags
local services  = getgenv().services

return function(automation)
    -- Load Linoria
    local LINORIA_URL = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
    local Library, ThemeManager, SaveManager

    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(LINORIA_URL .. "Library.lua"))()
    end)
    if not ok or not lib then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Vanta", Text = "UI failed to load — check console.", Duration = 5
            })
        end)
        return
    end
    Library = lib

    pcall(function() ThemeManager = loadstring(game:HttpGet(LINORIA_URL .. "addons/ThemeManager.lua"))() end)
    pcall(function() SaveManager  = loadstring(game:HttpGet(LINORIA_URL .. "addons/SaveManager.lua"))()  end)

    -- ─── Window ─────────────────────────────────────
    local Window = Library:CreateWindow({
        Title        = "  ✦  Vanta  ✦",
        Center       = true,
        AutoShow     = true,
        TabPadding   = 8,
        MenuFadeTime = 0.2,
    })
    Library.AccentColor = Color3.fromHex("7C5CBF") -- deep purple

    local Tabs = {
        Combat     = Window:AddTab("⚔  Combat"),
        Automation = Window:AddTab("⚙  Automation"),
        Visuals    = Window:AddTab("👁  Visuals"),
        Settings   = Window:AddTab("✦  Settings"),
    }

    -- ─── COMBAT ─────────────────────────────────────
    do
        local G = Tabs.Combat:AddLeftGroupbox("Auto Parry")
        G:AddToggle("auto_parry", {
            Text    = "Enable Auto Parry",
            Default = false,
            Tooltip = "APC Lycoris weapon windup timings",
            Callback = function(val) _flags.auto_parry = val end,
        })
        G:AddToggle("auto_parry_debug", {
            Text    = "Debug Mode",
            Default = false,
            Callback = function(val) _flags.auto_parry_debug = val end,
        })
        G:AddDivider()
        G:AddLabel("Target Filters")
        G:AddToggle("parry_pve", {
            Text = "PvE (mobs)", Default = true,
            Callback = function(val) _flags.parry_pve = val end,
        })
        G:AddToggle("parry_pvp", {
            Text = "PvP (players)", Default = false,
            Callback = function(val) _flags.parry_pvp = val end,
        })

        local G2 = Tabs.Combat:AddRightGroupbox("Timings Info")
        G2:AddLabel("Engine: APC / Lycoris Rewrite")
        G2:AddLabel("Covers: M1s, Crits, Specials")
        G2:AddDivider()
        G2:AddLabel("Weapon windups (per type):")
        G2:AddLabel("  Sword:      0.200/spd + 0.100")
        G2:AddLabel("  Dagger:     0.200/spd + 0.075")
        G2:AddLabel("  Fist:       0.140/spd + 0.130")
        G2:AddLabel("  Greataxe:   0.171/spd + 0.250")
        G2:AddLabel("  Greatsword: 0.158/spd + 0.150")
        G2:AddLabel("  Staff:      0.350 flat")
        G2:AddLabel("  Spear:      0.150/spd + 0.100")
        G2:AddLabel("  Rifle:      0.174/spd + 0.125")
    end

    -- ─── AUTOMATION ─────────────────────────────────
    do
        local G = Tabs.Automation:AddLeftGroupbox("Farms")

        local farmList = {
            { flag = "auto_saramed",            name = "Auto Saramed" },
            { flag = "auto_duke",               name = "Auto Duke" },
            { flag = "auto_ferryman",           name = "Auto Ferryman" },
            { flag = "auto_layertwo",           name = "Auto Layer 2" },
            { flag = "auto_echo_layer2",        name = "Auto Echo (Layer 2)" },
            { flag = "auto_escape_depths",      name = "Auto Escape Depths" },
            { flag = "auto_authority_missions", name = "Auto Authority Missions" },
            { flag = "auto_moonseyrie",         name = "Auto Mooneyrie" },
            { flag = "auto_progress",           name = "Auto Progress" },
            { flag = "auto_voi",                name = "Auto Voi" },
            { flag = "ministry_notefarm",       name = "Ministry Notefarm" },
            { flag = "soup_echofarm",           name = "Soup Echo Farm" },
            { flag = "titus_echofarm",          name = "Titus Echo Farm" },
            { flag = "autoecho_titus",          name = "Titus Relic Farm" },
            { flag = "jetstriker_echofarm",     name = "Jetstriker Echo Farm" },
            { flag = "auto_deepdrill",          name = "Auto Deepdrill" },
        }

        for _, entry in ipairs(farmList) do
            local persistent_data = getgenv().persistent_data
            G:AddToggle("farm_" .. entry.flag, {
                Text    = entry.name,
                Default = persistent_data:get(entry.flag) == true,
                Callback = function(val)
                    automation.setFarm(entry.flag, val)
                end,
            })
        end

        local G2 = Tabs.Automation:AddRightGroupbox("Controls")
        G2:AddButton("Stop All Farms", function()
            for _, entry in ipairs(farmList) do
                getgenv().persistent_data:set(entry.flag, false)
            end
            Library:Notify("All farms stopped.")
        end)
        G2:AddButton("Server Hop", function()
            pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(
                    game.PlaceId, game.JobId,
                    game:GetService("Players").LocalPlayer
                )
            end)
        end)
    end

    -- ─── VISUALS ────────────────────────────────────
    do
        local G = Tabs.Visuals:AddLeftGroupbox("ESP")
        G:AddToggle("esp_players", { Text = "Player ESP",   Default = false, Callback = function(val) _flags.esp_players = val end })
        G:AddToggle("esp_mobs",    { Text = "Mob ESP",      Default = false, Callback = function(val) _flags.esp_mobs    = val end })
        G:AddToggle("esp_names",   { Text = "Show Names",   Default = true,  Callback = function(val) _flags.esp_names   = val end })
        G:AddToggle("esp_health",  { Text = "Show Health",  Default = true,  Callback = function(val) _flags.esp_health  = val end })

        local G2 = Tabs.Visuals:AddRightGroupbox("World")
        G2:AddToggle("fullbright", {
            Text = "Full Bright", Default = false,
            Callback = function(val)
                pcall(function()
                    local l = services.Lighting
                    l.Brightness = val and 2 or 1
                    l.FogEnd = 100000
                end)
            end,
        })
        G2:AddToggle("no_fog", {
            Text = "No Fog", Default = false,
            Callback = function(val)
                pcall(function() services.Lighting.FogEnd = val and 100000 or 1000 end)
            end,
        })
    end

    -- ─── SETTINGS ───────────────────────────────────
    do
        if SaveManager then
            SaveManager:SetLibrary(Library)
            SaveManager:SetFolder("Vanta/Config")
            SaveManager:IgnoreThemeSettings()
            SaveManager:BuildConfigSection(Tabs.Settings)
        end
        if ThemeManager then
            ThemeManager:SetLibrary(Library)
            ThemeManager:SetFolder("Vanta/Config")
            ThemeManager:ApplyToTab(Tabs.Settings)
        end

        local G2 = Tabs.Settings:AddRightGroupbox("About")
        G2:AddLabel("Vanta v1.0")
        G2:AddLabel("Executor : Volt")
        G2:AddLabel("Timings  : APC Lycoris")
        G2:AddLabel("Farms    : Project Rain base")
        G2:AddDivider()
        G2:AddButton("Unload Vanta", function()
            pcall(function() Library:Unload() end)
            pcall(function() getgenv()._newscript_loaded() end)
        end)
        G2:AddButton("Wipe Saved Data", function()
            getgenv().persistent_data:wipe()
            Library:Notify("Saved data wiped.")
        end)
    end

    pcall(function()
        if SaveManager then SaveManager:LoadAutoloadConfig() end
    end)
end
