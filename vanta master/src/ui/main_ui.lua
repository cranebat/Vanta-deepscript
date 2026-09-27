local _flags     = getgenv().ns_flags
local services   = getgenv().services
local local_player = getgenv().local_player

return function(automation)
    -- ── Load Linoria ─────────────────────────────────────────────
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

    -- ── Choice Frame ─────────────────────────────────────────────
    local ChoiceFrame
    pcall(function() ChoiceFrame = require("@src/ui/choice_frame") end)

    -- ── Refs ──────────────────────────────────────────────────────
    local Toggles = Library.Toggles
    local Options  = Library.Options

    -- ── Window ───────────────────────────────────────────────────
    local Window = Library:CreateWindow({
        Title        = "  ✦  Vanta  ✦",
        Center       = true,
        AutoShow     = true,
        TabPadding   = 8,
        MenuFadeTime = 0.2,
    })
    Library.AccentColor = Color3.fromHex("7C5CBF")

    -- ── Tabs ─────────────────────────────────────────────────────
    local Tabs = {
        Combat     = Window:AddTab("⚔  Combat"),
        Visuals    = Window:AddTab("👁  Visuals"),
        Automation = Window:AddTab("⚙  Automation"),
        Settings   = Window:AddTab("✦  Settings"),
    }

    -- ─────────────────────────────────────────────────────────────
    -- COMBAT
    -- ─────────────────────────────────────────────────────────────
    do
        local T = Tabs.Combat

        -- ── Assistance ───────────────────────────────────────────
        local Assist = T:AddLeftGroupbox("Assistance")

        Assist:AddToggle("easy_roll_cancel", {
            Text    = "Easy Roll Cancel",
            Default = false,
            Tooltip = "Allows you to press M1 mid dash to cancel it.",
            Callback = function(v) _flags.easy_roll_cancel = v end,
        })
        Assist:AddToggle("auto_dustlunge", {
            Text    = "Auto Assassination",
            Default = false,
            Tooltip = "Hold M1 to attack via assassination.",
            Callback = function(v) _flags.auto_dustlunge = v end,
        })
        Assist:AddLabel("Assassination Bind (hold)"):AddKeyPicker("auto_dustlunge_bind", { Default = "V", Mode = "Hold", Text = "Assassination Bind (hold)" })
        Assist:AddToggle("auto_dustlunge_debug", {
            Text    = "Assassination Debug",
            Default = false,
            Tooltip = "Displays the assassination hitbox.",
            Callback = function(v) _flags.auto_dustlunge_debug = v end,
        })
        Assist:AddDivider()
        Assist:AddToggle("m1_hold", {
            Text    = "M1 Hold",
            Default = false,
            Tooltip = "Hold M1 to continuously attack.",
            Callback = function(v) _flags.m1_hold = v end,
        })
        Assist:AddToggle("no_aerials", {
            Text    = "No Aerials (M1 Hold)",
            Default = false,
            Tooltip = "Never aerials when holding M1.",
            Callback = function(v) _flags.no_aerials = v end,
        })

        -- ── No Stun ──────────────────────────────────────────────
        local NoStun = T:AddRightGroupbox("No Stun")

        NoStun:AddToggle("fast_swing", {
            Text    = "Remove Weapon Endlag",
            Default = false,
            Tooltip = "Removes endlag from swinging.",
            Callback = function(v) _flags.fast_swing = v end,
        })
        NoStun:AddToggle("no_stun", {
            Text    = "No Stun",
            Default = false,
            Tooltip = "Removes all stun from the game.",
            Callback = function(v) _flags.no_stun = v end,
        })
        NoStun:AddLabel("No Stun Bind"):AddKeyPicker("no_stun_bind", { Default = "None", Mode = "Toggle", Text = "No Stun Bind" })
        NoStun:AddDropdown("no_stun_items", {
            Text   = "Removed Effects",
            Values = {
                "LightningStun","PreventAction","OffhandAttack","UsingCritical","MobileAction",
                "MediumAttack","CarryObject","PreventRoll","LightAttack","HeavyAttack",
                "InDialogue","UsingSpell","NoParkour","NoJumpAlt","Blocking","NoAttack",
                "Carried","Falling","Chilled","Pinned","Action","Dodged","NoJump","NoRoll","NoMove","Stun",
            },
            Default = {
                "LightningStun","PreventAction","OffhandAttack","UsingCritical","MobileAction",
                "MediumAttack","CarryObject","PreventRoll","LightAttack","HeavyAttack",
                "InDialogue","UsingSpell","NoParkour","NoJumpAlt","Blocking","NoAttack",
                "Carried","Falling","Chilled","Pinned","Action","Dodged","NoJump","NoRoll","NoMove","Stun",
            },
            Multi   = true,
            Tooltip = "Effects that No Stun removes.",
        })

        -- ── Attach to Back ───────────────────────────────────────
        local ATB = T:AddLeftGroupbox("Attach to Back")

        ATB:AddToggle("attach_to_back", {
            Text    = "Attach to Back",
            Default = false,
            Tooltip = "Attach to target's back. M1/M2 to select.",
            Callback = function(v) _flags.attach_to_back = v end,
        })
        ATB:AddLabel("ATB Bind"):AddKeyPicker("attach_to_back_bind", { Default = "None", Mode = "Toggle", Text = "ATB Bind" })
        ATB:AddSlider("atb_x_offset", { Text = "X Offset", Default = 0,  Min = -150, Max = 150, Rounding = 0 })
        ATB:AddSlider("atb_y_offset", { Text = "Y Offset", Default = 0,  Min = -150, Max = 150, Rounding = 0 })
        ATB:AddSlider("atb_z_offset", { Text = "Z Offset", Default = 5,  Min = -150, Max = 150, Rounding = 0 })
        ATB:AddToggle("atb_lock_rotation",   { Text = "Ignore Rotation",  Default = false })
        ATB:AddToggle("atb_prevent_voiding", { Text = "Prevent Voiding",  Default = false })
        ATB:AddToggle("atb_rotate",          { Text = "Rotate Towards",   Default = false })
        ATB:AddSlider("atb_speed", { Text = "Control Speed", Default = 16, Min = 1, Max = 100, Rounding = 0, Suffix = "st/s" })
        ATB:AddDropdown("allowed_atb_targets", {
            Text    = "Allowed Targets",
            Values  = { "Guildmates", "Players", "Mobs" },
            Default = { "Guildmates", "Players", "Mobs" },
            Multi   = true,
        })

        -- ── Auto Parry (Tabbox) ───────────────────────────────────
        local APBox   = T:AddLeftTabbox()
        local APMain  = APBox:AddTab("Main")
        local APPVE   = APBox:AddTab("PVE")
        local APPPVP  = APBox:AddTab("PVP")
        local APOther = APBox:AddTab("Other")

        -- Main
        APMain:AddToggle("auto_parry", {
            Text    = "Auto Parry",
            Default = false,
            Tooltip = "Automatically parry/defend incoming attacks.",
            Callback = function(v) _flags.auto_parry = v end,
        })
        APMain:AddLabel("Auto Parry Bind"):AddKeyPicker("auto_parry_bind", { Default = "None", Mode = "Toggle", Text = "Auto Parry Bind" })
        APMain:AddDivider()
        APMain:AddSlider("dont_process_players_over_studs", {
            Text = "Skip Players Over", Default = 60, Min = 5, Max = 500, Rounding = 0, Suffix = "s",
            Callback = function(v) _flags.dont_process_players_over_studs = v end,
        })
        APMain:AddSlider("dont_process_mobs_over_studs", {
            Text = "Skip Mobs Over", Default = 60, Min = 5, Max = 500, Rounding = 0, Suffix = "s",
            Callback = function(v) _flags.dont_process_mobs_over_studs = v end,
        })
        APMain:AddSlider("task_concurrency", {
            Text = "Task Concurrency", Default = 20, Min = 15, Max = 750, Rounding = 0, Suffix = " actions"
        })
        APMain:AddDivider()

        -- Anti AP Breaker
        APMain:AddToggle("basic_validation", {
            Text    = "Anti AP Breaker",
            Default = true,
            Tooltip = "Prevents AP breaking by validating timings.",
            Callback = function(v) _flags.basic_validation = v end,
        })
        APMain:AddToggle("aggressive_validation", {
            Text    = "More Aggressive Checks",
            Default = false,
            Callback = function(v) _flags.aggressive_validation = v end,
        })
        APMain:AddToggle("anti_ap_breaker_debug", {
            Text    = "Validation Notifications",
            Default = false,
            Callback = function(v) _flags.anti_ap_breaker_debug = v end,
        })
        APMain:AddToggle("reveal_animations", {
            Text    = "Reveal Animations",
            Default = true,
            Callback = function(v) _flags.reveal_animations = v end,
        })
        APMain:AddDropdown("validation_filters", {
            Text    = "Validation Filters",
            Values  = { "WT <= X", "S >= X", "Priority Hiding", "Core Priority", "Idle Priority", "Length <= Xms", "Fadetime" },
            Default = { "WT <= X", "Core Priority", "Idle Priority", "Priority Hiding", "S >= X", "Fadetime" },
            Multi   = true,
        })
        APMain:AddDropdown("validation_log_filters", {
            Text    = "Validation Log Filters",
            Values  = { "WT <= X", "S >= X", "Priority Hiding", "Core Priority", "Idle Priority", "Length <= Xms", "Fadetime" },
            Default = { "WT <= X", "Core Priority", "Idle Priority", "Priority Hiding", "S >= X" },
            Multi   = true,
        })
        APMain:AddSlider("anti_ap_breaker_max_speed",  { Text = "Max Speed (S >= X)",   Default = 5,  Min = 1,  Max = 100, Rounding = 0, Suffix = "x" })
        APMain:AddSlider("anti_ap_breaker_minimum_wt", { Text = "Min Weight Target",    Default = 10, Min = 10, Max = 100, Rounding = 0, Suffix = "x" })
        APMain:AddSlider("anti_ap_breaker_length_ms",  { Text = "Min Length (Xms)",     Default = 50, Min = 1,  Max = 500, Rounding = 0, Suffix = "ms" })
        APMain:AddDivider()

        APMain:AddToggle("auto_parry_debug", {
            Text    = "Debug Notifications",
            Default = false,
            Callback = function(v) _flags.auto_parry_debug = v end,
        })
        APMain:AddToggle("log_speed_changes", {
            Text    = "Log Speed Changes",
            Default = false,
            Callback = function(v) _flags.log_speed_changes = v end,
        })
        APMain:AddDivider()

        -- Humanization
        APMain:AddToggle("ap_randomization", {
            Text    = "Humanization",
            Default = false,
            Tooltip = "Adds randomization to AP actions.",
            Callback = function(v) _flags.ap_randomization = v end,
        })
        APMain:AddSlider("parry_to_dodge_chance_undefined", { Text = "Force Dodge (Untagged)", Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APMain:AddSlider("parry_to_dodge_chance_spells",    { Text = "Force Dodge (Spells)",   Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APMain:AddSlider("parry_to_dodge_chance_critical",  { Text = "Force Dodge (Crits)",    Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APMain:AddSlider("parry_to_dodge_chance_m1",        { Text = "Force Dodge (M1)",       Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APMain:AddSlider("parry_to_fallback_chance",        { Text = "Parry → Fallback",       Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APMain:AddSlider("bluff_feint_chance",              { Text = "Bluff Feint Chance",     Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APMain:AddToggle("only_convert_dodge_if_possible", {
            Text    = "Only Dodge If Possible",
            Default = false,
            Tooltip = "Only converts parries to dodges when the dodge is actually possible.",
        })
        APMain:AddDivider()

        -- Auto Feint
        APMain:AddToggle("auto_feint", {
            Text    = "Auto Feint",
            Default = false,
            Tooltip = "Automatically feints when AP wants to parry.",
            Callback = function(v) _flags.auto_feint = v end,
        })
        APMain:AddLabel("Auto Feint Bind"):AddKeyPicker("auto_feint_bind", { Default = "None", Mode = "Toggle", Text = "Auto Feint Bind" })
        APMain:AddSlider("feint_chance", { Text = "Feint Chance", Default = 100, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APMain:AddDropdown("blocked_auto_feint_moves", {
            Text    = "Don't Feint Against",
            Values  = { "Critical", "Untagged", "Spell", "M1" },
            Default = {},
            Multi   = true,
        })
        APMain:AddDropdown("auto_feint_own_tags", {
            Text    = "Feint Our Move Types",
            Values  = { "M1", "Spell" },
            Default = { "M1", "Spell" },
            Multi   = true,
        })
        APMain:AddDivider()

        APMain:AddDropdown("fallbacks", {
            Text    = "Fallbacks",
            Values  = { "Curse of the Unbidden", "Prediction", "Block", "Vent" },
            Default = { "Curse of the Unbidden" },
            Multi   = true,
            Tooltip = "Fallbacks for Auto Parry.",
        })
        APMain:AddDropdown("filters", {
            Text   = "Filters",
            Values = {
                "Dont Parry If Enemy Hit In Criticals",
                "Dont Parry If Mob Block Broken",
                "Dont Parry In Chime Countdown",
                "Dont Parry If Not Mob Target",
                "Dont Parry If Not In Combat",
                "Dont Parry If Holding Block",
                "Dont Parry If In Payback",
                "Dont Parry If Off Roblox",
                "Dont Parry If Off Screen",
                "Dont Parry If Guildmate",
                "Dont Parry In AP Frames",
                "Dont Parry If Knocked",
                "Dont Parry If Typing",
                "Dont Parry If Ally",
                "Dont Roll",
            },
            Default = {},
            Multi   = true,
        })
        APMain:AddDropdown("allowed_targets", {
            Text    = "Allowed Targets",
            Values  = { "Unknown", "PVE", "PVP", "All" },
            Default = { "Unknown", "PVE", "PVP", "All" },
            Multi   = true,
        })

        -- PVE / PVP (shared helper)
        local function makeParrySettings(tab, prefix)
            tab:AddToggle(prefix.."blatant_roll_with_anims", {
                Text = "Blatant Roll w/ Anims", Default = false,
                Tooltip = "Plays an anim while using blatant roll.",
            })
            tab:AddToggle(prefix.."roll_if_unequipped", {
                Text = "Roll If Unequipped", Default = false,
            })
            tab:AddToggle(prefix.."blatant_crouch", {
                Text = "Blatant Crouch", Default = false,
                Tooltip = "Fires the crouch remote directly.",
            })
            tab:AddToggle(prefix.."blatant_roll", {
                Text = "Blatant Roll", Default = false,
                Tooltip = "Fires the roll remote instead of going through the client.",
            })
            tab:AddToggle(prefix.."roll_cancel", {
                Text = "Roll Cancel", Default = false,
                Tooltip = "Cancels rolls by M2ing.",
            })
            tab:AddToggle(prefix.."auto_equip", {
                Text = "Auto Equip", Default = false,
                Tooltip = "Automatically equips your weapon.",
            })
            tab:AddDivider()
            tab:AddSlider(prefix.."max_roll_cancel_delay", { Text = "Max Cancel Delay", Default = 150, Min = 1, Max = 200, Rounding = 0, Suffix = "ms" })
            tab:AddSlider(prefix.."min_roll_cancel_delay", { Text = "Min Cancel Delay", Default = 70,  Min = 1, Max = 200, Rounding = 0, Suffix = "ms" })
            tab:AddSlider(prefix.."roll_cancel_chance",    { Text = "Cancel Chance",    Default = 90,  Min = 1, Max = 100, Rounding = 0, Suffix = "%" })
            tab:AddSlider(prefix.."parry_chance",          { Text = "Parry Chance",     Default = 100, Min = 1, Max = 100, Rounding = 0, Suffix = "%" })
        end
        makeParrySettings(APPVE,  "pve_")
        makeParrySettings(APPPVP, "pvp_")

        -- Other
        APOther:AddToggle("view_hitboxes", {
            Text = "View Hitboxes", Default = false,
            Tooltip = "Renders hitbox visualizers.",
        })
        APOther:AddSlider("max_boxes",   { Text = "Max Hitboxes",        Default = 5,   Min = 1, Max = 100, Rounding = 0, Suffix = "hbs" })
        APOther:AddSlider("hb_trans",    { Text = "Hitbox Transparency", Default = 100, Min = 1, Max = 100, Rounding = 0, Suffix = "%" })
        APOther:AddToggle("show_hitbox_simulation", { Text = "View Hitbox Simulation", Default = false })
        APOther:AddDropdown("HS_HitboxType", {
            Text = "Hitbox Shape", Values = { "Block", "Ball", "Cylinder" }, Default = "Block", Multi = false,
        })
        APOther:AddSlider("HS_HitboxSizeX", { Text = "Hitbox X", Default = 4, Min = 0, Max = 250, Rounding = 0, Suffix = "s" })
        APOther:AddSlider("HS_HitboxSizeY", { Text = "Hitbox Y", Default = 4, Min = 0, Max = 250, Rounding = 0, Suffix = "s" })
        APOther:AddSlider("HS_HitboxSizeZ", { Text = "Hitbox Z", Default = 4, Min = 0, Max = 250, Rounding = 0, Suffix = "s" })
        APOther:AddSlider("HS_ShiftOffset", { Text = "Shift Offset", Default = 0, Min = -250, Max = 30, Rounding = 0, Suffix = "s" })
        APOther:AddDivider()
        APOther:AddDropdown("m1_timing_hitbox_type", {
            Text = "M1 Hitbox Type", Values = { "Square", "Ball" }, Default = "Ball", Multi = false,
        })
        APOther:AddDropdown("blocked_timings", {
            Text = "Blocked Timings", Values = {}, Default = {}, Multi = true, Tooltip = "Timings to never fire.",
        })
        APOther:AddDropdown("chance_timings", {
            Text = "Chance Editor", Values = {}, Default = "", Multi = false, Tooltip = "Pick a timing to edit its chance.",
        })
        APOther:AddSlider("chance_parry_weight", { Text = "Parry Chance", Default = 100, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APOther:AddSlider("chance_dodge_weight", { Text = "Dodge Chance", Default = 0,   Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APOther:AddSlider("chance_skip_weight",  { Text = "Skip Chance",  Default = 0,   Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
        APOther:AddButton({
            Text = "Load Timing List",
            Func = function()
                local list = {}
                for k in pairs(getgenv().NAMED_TIMINGS or {}) do table.insert(list, k) end
                table.sort(list)
                Options.blocked_timings:SetValues(list)
                Options.chance_timings:SetValues(list)
                Library:Notify("Loaded " .. #list .. " timings.")
            end,
        })
        APOther:AddButton({
            Text = "Set Timing Chance",
            Func = function()
                local t = Options.chance_timings.Value
                if not t or t == "" then Library:Notify("Select a timing first.", 4) return end
                Library:Notify(string.format("%s → P:%d D:%d S:%d",
                    t,
                    Options.chance_parry_weight.Value,
                    Options.chance_dodge_weight.Value,
                    Options.chance_skip_weight.Value))
            end,
        })
        APOther:AddDivider()
        APOther:AddToggle("info_logger", {
            Text    = "Timing Logger",
            Default = false,
            Tooltip = "Logs animations to console.",
        })
        APOther:AddSlider("info_logger_range", { Text = "Logger Range", Default = 1, Min = 1, Max = 500, Rounding = 0, Suffix = "s" })

        -- ── Anim Speed Changer ────────────────────────────────────
        local ASC = T:AddRightGroupbox("Anim Speed Changer")

        ASC:AddToggle("anim_speed_changer", {
            Text    = "Anim Speed Changer",
            Default = false,
            Tooltip = "Changes animation speed — affects AP timings.",
            Callback = function(v) _flags.anim_speed_changer = v end,
        })
        ASC:AddLabel("Speed Changer Bind"):AddKeyPicker("anim_speed_changer_bind", { Default = "None", Mode = "Toggle", Text = "Speed Changer Bind" })
        ASC:AddToggle("switch_speeds", {
            Text    = "Switch Speed",
            Default = false,
            Tooltip = "Switches between min/max instead of random.",
        })
        ASC:AddDropdown("anim_speed_changer_types", {
            Text    = "Affected Types",
            Values  = { "Criticals", "Untagged", "Spells", "Bells", "M1s" },
            Default = {},
            Multi   = true,
        })
        local function makeSpeedSlider(flag, label)
            ASC:AddSlider(flag.."_min", { Text = label .. " Min", Default = 0.9, Min = 0.1, Max = 2.1, Rounding = 2, Suffix = "x" })
            ASC:AddSlider(flag.."_max", { Text = label .. " Max", Default = 1.1, Min = 0.1, Max = 2.1, Rounding = 2, Suffix = "x" })
        end
        makeSpeedSlider("anim_critical_speed", "Criticals")
        makeSpeedSlider("anim_untagged_speed", "Untagged")
        makeSpeedSlider("anim_spell_speed",    "Spells")
        makeSpeedSlider("anim_bell_speed",     "Bells")
        makeSpeedSlider("anim_m1_speed",       "M1s")

        -- ── Silent Aim ───────────────────────────────────────────
        local SA = T:AddLeftGroupbox("Silent Aim")

        SA:AddToggle("silent_aim", {
            Text    = "Silent Aim",
            Default = false,
            Callback = function(v) _flags.silent_aim = v end,
        })
        SA:AddToggle("force_chime_opponent", {
            Text    = "Force Chime Opponent",
            Default = false,
            Tooltip = "Forces SA onto chime opponent, no FOV check.",
        })
        SA:AddToggle("show_fov", {
            Text = "Show FOV Circle", Default = false,
            Callback = function(v) _flags.show_fov = v end,
        })
        SA:AddToggle("fov_filled", { Text = "Fill FOV", Default = false })
        SA:AddSlider("fov_transparency", { Text = "FOV Transparency", Default = 10,  Min = 0,  Max = 100,  Rounding = 0, Suffix = "%" })
        SA:AddSlider("prediction",       { Text = "Prediction",       Default = 15,  Min = 0,  Max = 200,  Rounding = 0, Suffix = "%" })
        SA:AddSlider("fov_radius",       { Text = "FOV Radius",       Default = 90,  Min = 1,  Max = 2000, Rounding = 0, Suffix = "px" })
        SA:AddDropdown("allowed_sa_targets", {
            Text    = "Allowed SA Targets",
            Values  = { "Guildmates", "Players", "Mobs" },
            Default = { "Players", "Mobs" },
            Multi   = true,
        })

        -- ── Safe Input ───────────────────────────────────────────
        local SI = T:AddRightGroupbox("Safe Input")

        SI:AddLabel("Requires M1 Hold & Auto Parry.")
        SI:AddToggle("block_input", {
            Text    = "Block Input [WIP]",
            Default = false,
            Tooltip = "Blocks input during attacks.",
            Callback = function(v) _flags.block_input = v end,
        })
        SI:AddSlider("bi_punishable_time",      { Text = "Punishable Time",       Default = 650, Min = 1,    Max = 1000, Rounding = 0, Suffix = "ms" })
        SI:AddSlider("extra_bi_punishable_time", { Text = "Extra Punishable Time", Default = 0,   Min = -500, Max = 500,  Rounding = 0, Suffix = "ms" })
        SI:AddDropdown("bi_punishable_type", {
            Text = "Punishable Type", Values = { "Dynamic", "Custom", "Always" }, Default = "Custom", Multi = false,
        })
        SI:AddDropdown("allowed_bi_targets", {
            Text = "Allowed SI Targets", Values = { "PVE", "PVP" }, Default = { "PVE", "PVP" }, Multi = true,
        })
        SI:AddDropdown("blocked_safe_input_user_moves", {
            Text = "Blocked User Moves", Values = { "Criticals", "M1s", "M2s" }, Default = { "M1s" }, Multi = true,
        })
        SI:AddDropdown("blocked_safe_input_moves", {
            Text    = "Don't Against",
            Values  = { "Animations", "Critical", "Untagged", "Effects", "Spell", "Parts", "Bell", "M1" },
            Default = {},
            Multi   = true,
        })

        -- ── Mantra Slidecasting ───────────────────────────────────
        local MS = T:AddLeftGroupbox("Mantra Slidecasting")

        MS:AddToggle("mantra_slidecasting", {
            Text    = "Mantra Slidecasting",
            Default = false,
            Callback = function(v) _flags.mantra_slidecasting = v end,
        })
        MS:AddLabel("Slidecast Bind"):AddKeyPicker("mantra_slidecasting_bind", { Default = "None", Mode = "Toggle", Text = "Slidecast Bind" })
        MS:AddSlider("mantra_slidecasting_chance", { Text = "Trigger Chance", Default = 70, Min = 1, Max = 100, Rounding = 0, Suffix = "%" })
        MS:AddDropdown("mantra_slidecasting_mantras", { Text = "Trigger Mantras", Values = {}, Default = {}, Multi = true })
        MS:AddButton({
            Text = "Load Mantras (Slidecast)",
            Func = function()
                local list = {}
                if local_player and local_player.instance then
                    for _, m in local_player.instance.Backpack:GetChildren() do
                        if m.Name:find("Mantra:") then
                            table.insert(list, m:GetAttribute("DefaultName") or m.Name)
                        end
                    end
                end
                Options.mantra_slidecasting_mantras:SetValues(list)
                Library:Notify("Loaded " .. #list .. " mantras.")
            end,
        })

        -- ── Mantra Rolling ───────────────────────────────────────
        local MR = T:AddRightGroupbox("Mantra Rolling")

        MR:AddToggle("action_rolling", {
            Text    = "Mantra Rolling",
            Default = false,
            Callback = function(v) _flags.action_rolling = v end,
        })
        MR:AddLabel("Rolling Bind"):AddKeyPicker("action_rolling_bind", { Default = "None", Mode = "Toggle", Text = "Rolling Bind" })
        MR:AddSlider("action_rolling_chance", { Text = "Trigger Chance", Default = 70, Min = 1, Max = 100, Rounding = 0, Suffix = "%" })
        MR:AddDropdown("action_rolling_mantras", { Text = "Trigger Mantras", Values = {}, Default = {}, Multi = true })
        MR:AddButton({
            Text = "Load Mantras (Roll)",
            Func = function()
                local list = {}
                if local_player and local_player.instance then
                    for _, m in local_player.instance.Backpack:GetChildren() do
                        if m.Name:find("Mantra:") then
                            table.insert(list, m:GetAttribute("DefaultName") or m.Name)
                        end
                    end
                end
                Options.action_rolling_mantras:SetValues(list)
                Library:Notify("Loaded " .. #list .. " mantras.")
            end,
        })

        -- ── Backstab Movestacker ─────────────────────────────────
        local BS = T:AddLeftGroupbox("Backstab Movestacker")

        BS:AddToggle("backstab_movestacker", {
            Text    = "Backstab Movestacker",
            Default = false,
            Tooltip = "Casts in an Authority Ensign backstab (Backstabber talent required).",
            Callback = function(v) _flags.backstab_movestacker = v end,
        })
        BS:AddDropdown("backstab_movestacker_mantras", { Text = "Trigger Mantras", Values = {}, Default = {}, Multi = true })
        BS:AddButton({
            Text = "Load Mantras (Backstab)",
            Func = function()
                local list = {}
                if local_player and local_player.instance then
                    for _, m in local_player.instance.Backpack:GetChildren() do
                        if m.Name:find("Mantra:") then
                            table.insert(list, m:GetAttribute("DefaultName") or m.Name)
                        end
                    end
                end
                Options.backstab_movestacker_mantras:SetValues(list)
                Library:Notify("Loaded " .. #list .. " mantras.")
            end,
        })

        -- ── APC Timings Info ─────────────────────────────────────
        local TInfo = T:AddRightGroupbox("APC Timings Info")
        TInfo:AddLabel("Engine: APC Lycoris Rewrite")
        TInfo:AddLabel("Covers: M1s · Crits · Specials")
        TInfo:AddDivider()
        TInfo:AddLabel("Sword:       0.200/spd + 0.100")
        TInfo:AddLabel("Dagger:      0.200/spd + 0.075")
        TInfo:AddLabel("Fist:        0.140/spd + 0.130")
        TInfo:AddLabel("Greataxe:    0.171/spd + 0.250")
        TInfo:AddLabel("Greatsword:  0.158/spd + 0.150")
        TInfo:AddLabel("Greathammer: 0.150/spd + 0.200")
        TInfo:AddLabel("Greatcannon: 0.155/spd + 0.160")
        TInfo:AddLabel("Staff:       0.350 flat")
        TInfo:AddLabel("Spear:       0.150/spd + 0.100")
        TInfo:AddLabel("Rifle:       0.174/spd + 0.125")
        TInfo:AddLabel("Twinblade:   0.200/spd + 0.050")
        TInfo:AddLabel("Rapier:      0.155/spd + 0.120")
        TInfo:AddLabel("Club:        0.180/spd + 0.100")
        TInfo:AddLabel("Pistol:      0.350/ss flat")
    end

    -- ─────────────────────────────────────────────────────────────
    -- VISUALS
    -- ─────────────────────────────────────────────────────────────
    do
        local T = Tabs.Visuals

        -- ── Modifiers ─────────────────────────────────────────────
        local Mod = T:AddLeftGroupbox("Modifiers")

        local modToggles = {
            { "leaderboard_spectate", "Leaderboard Spectate",   "Spectate by clicking names on the leaderboard." },
            { "sanity_indicator",     "Sanity Indicator",        "Currency icon for sanity." },
            { "proximity_list",       "Player Proximity",        "Displays nearby players." },
            { "show_all_on_map",      "Show All On Map",         "See everyone on the map." },
            { "streamer_mode",        "Streamer Mode",           "Hides your name." },
            { "chain_counter",        "Chain Counter",           "Shows Chain of Perfection stacks." },
            { "noclip_camera",        "Noclip Camera",           "Camera clips through walls." },
            { "full_bright",          "Full Bright",             "Brightens the game." },
            { "show_chat",            "Show Chat",               "Unhides the Roblox chat." },
            { "inf_zoom",             "Inf Zoom",                "Infinite zoom." },
            { "free_cam",             "Freecam",                 "Free camera movement." },
            { "zoom",                 "Zoom",                    "Zoom in on objects." },
            { "race_morph_menu",      "Race Morph Menu",         "Opens race/face/enchant menu (F4)." },
        }
        for _, t in ipairs(modToggles) do
            Mod:AddToggle(t[1], {
                Text    = t[2],
                Default = false,
                Tooltip = t[3],
                Callback = function(v) _flags[t[1]] = v end,
            })
        end
        Mod:AddSlider("fullbright_intensity",   { Text = "Fullbright Intensity", Default = 100, Min = 0,   Max = 100,  Rounding = 0, Suffix = "%" })
        Mod:AddSlider("player_proximity_range", { Text = "Proximity Range",      Default = 1000, Min = 5,   Max = 10000, Rounding = 0 })
        Mod:AddSlider("player_proximity_vol",   { Text = "Proximity Volume",     Default = 1.5,  Min = 0.1, Max = 10,   Rounding = 1 })
        Mod:AddToggle("show_list",              { Text = "Show Proximity List",        Default = false })
        Mod:AddToggle("notify_in_range",        { Text = "Proximity Notifications",    Default = false })
        Mod:AddToggle("notify_with_sound",      { Text = "Proximity Sounds",           Default = false })
        Mod:AddSlider("free_cam_speed",         { Text = "Freecam Speed",              Default = 4,  Min = 1, Max = 30, Rounding = 0 })
        Mod:AddToggle("safe_spot",              { Text = "Freecam @ Safespot",         Default = false })
        Mod:AddSlider("zoom_sens_mult",         { Text = "Zoom Sensitivity Mult",      Default = 50, Min = 10, Max = 100, Rounding = 0, Suffix = "%" })
        Mod:AddToggle("apply_mouse_sens",       { Text = "Apply Mouse Sens (Zoom)",    Default = false })

        -- ── Player ESP ─────────────────────────────────────────────
        local ESPBox    = T:AddRightTabbox()
        local ESPPlayer = ESPBox:AddTab("Players")
        local ESPGlobal = ESPBox:AddTab("Global")

        ESPPlayer:AddToggle("player_esp", {
            Text = "Player ESP", Default = false,
            Callback = function(v) _flags.player_esp = v end,
        })
        ESPPlayer:AddLabel("Player ESP Bind"):AddKeyPicker("player_esp_bind", { Default = "None", Mode = "Toggle", Text = "Player ESP Bind" })
        ESPPlayer:AddLabel("Player ESP Color"):AddColorPicker("player_esp_color", { Default = Color3.fromRGB(205, 214, 244), Title = "Player ESP Color" })
        ESPPlayer:AddToggle("vw_color", { Text = "Voidwalker Color",    Default = true })
        ESPPlayer:AddLabel("Voidwalker Color"):AddColorPicker("voidwalker_esp_color", { Default = Color3.fromRGB(203, 166, 247), Title = "Voidwalker Color" })
        ESPPlayer:AddToggle("gm_color", { Text = "Guildmate Color",     Default = true })
        ESPPlayer:AddLabel("Guildmate Color"):AddColorPicker("guildmate_esp_color", { Default = Color3.fromRGB(148, 226, 213), Title = "Guildmate Color" })
        ESPPlayer:AddToggle("esp_healthbar", { Text = "Player Healthbars", Default = false })
        ESPPlayer:AddToggle("esp_boxes",     { Text = "Player Boxes",      Default = false })
        ESPPlayer:AddToggle("esp_nametags",  { Text = "Player Names",      Default = true  })
        ESPPlayer:AddToggle("esp_fadeout",       { Text = "Player Fadeout",     Default = false })
        ESPPlayer:AddToggle("esp_fadeout_hover", { Text = "Fadeout on Hover",   Default = true  })
        ESPPlayer:AddSlider("text_size",               { Text = "Text Size",       Default = 12,    Min = 6,   Max = 60,    Rounding = 0, Suffix = "px" })
        ESPPlayer:AddSlider("player_fadeout_distance", { Text = "Fadeout Divisor", Default = 5000,  Min = 100, Max = 50000, Rounding = 0, Suffix = "s" })
        ESPPlayer:AddSlider("max_player_distance",     { Text = "ESP Distance",    Default = 20000, Min = 100, Max = 50000, Rounding = 0, Suffix = "s" })
        ESPPlayer:AddDropdown("ESP_TAGS", {
            Text    = "ESP Tags",
            Values  = { "Roblox Display Name","Roblox Player Name","Character Name","Health %","HP/Max","Level","Danger Time","Ping","Distance","Agility" },
            Default = { "Character Name","Health %","HP/Max","Level","Danger Time","Ping","Distance" },
            Multi   = true,
        })
        ESPPlayer:AddDropdown("ESP_BARS", {
            Text    = "ESP Bars",
            Values  = { "posture","sanity","hunger","water","blood","armor" },
            Default = { "sanity","blood","posture" },
            Multi   = true,
        })

        ESPGlobal:AddDropdown("Font", {
            Text = "Font", Values = { "Arial","GothamBold","Lexend","Code","Gotham" }, Default = "Arial", Multi = false,
        })
        ESPGlobal:AddDropdown("distance_naming", {
            Text = "Distance Terminology", Values = { "meters & km", "studs" }, Default = "meters & km", Multi = false,
        })
        ESPGlobal:AddSlider("esp_update_rate", { Text = "Label Update Rate", Default = 2, Min = 1, Max = 60, Rounding = 0, Suffix = "fps" })
        ESPGlobal:AddToggle("show_stored_damage", {
            Text = "Show Stored Damage", Default = false,
            Tooltip = "Shows pending Poser stack damage as colored overlay.",
        })
        ESPGlobal:AddLabel("Stored Damage Color"):AddColorPicker("show_stored_damage_color", { Default = Color3.fromRGB(137, 180, 250), Title = "Stored Damage Color" })

        -- ── World ESP ──────────────────────────────────────────────
        local WorldESP = T:AddRightGroupbox("World ESP")

        local worldEsps = {
            { "mob_esp",          "Mob ESP",          Color3.fromRGB(243,139,168) },
            { "dropped_item_esp", "Dropped Item ESP", Color3.fromRGB(175,255,215) },
            { "chest_esp",        "Chest ESP",        Color3.fromRGB(249,226,175) },
            { "ingredient_esp",   "Ingredient ESP",   Color3.fromRGB(137,180,250) },
            { "artifact_esp",     "Artifact ESP",     Color3.fromRGB(203,166,247) },
            { "campfire_esp",     "Campfire ESP",     Color3.fromRGB(243,181,156) },
            { "obelisk_esp",      "Obelisk ESP",      Color3.fromRGB(255,255,255) },
            { "banner_esp",       "Banner ESP",       Color3.fromRGB(156,243,185) },
            { "meteor_esp",       "Bell Meteor ESP",  Color3.fromRGB(238,153,160) },
            { "crate_esp",        "Crate ESP",        Color3.fromRGB(237,135,150) },
            { "cache_esp",        "Cache ESP",        Color3.fromRGB(183,189,248) },
            { "shop_esp",         "Shop ESP",         Color3.fromRGB(216,221,233) },
            { "area_esp",         "Area ESP",         Color3.fromRGB(205,214,244) },
            { "bag_esp",          "Bag ESP",          Color3.fromRGB(249,226,175) },
            { "npc_esp",          "NPC ESP",          Color3.fromRGB(244,219,214) },
            { "owl_esp",          "Owl Feather ESP",  Color3.fromRGB(106, 25,206) },
            { "jetty_post_esp",   "Jetty Post ESP",   Color3.fromRGB(243,181,156) },
            { "whirlpool_esp",    "Whirlpool ESP",    Color3.fromRGB(137,180,250) },
            { "job_esp",          "Job ESP",          Color3.fromRGB(242,213,207) },
        }
        for _, e in ipairs(worldEsps) do
            WorldESP:AddToggle(e[1], {
                Text = e[2], Default = false,
                Callback = function(v) _flags[e[1]] = v end,
            })
            WorldESP:AddLabel(e[2] .. " Color"):AddColorPicker(e[1].."_color", { Default = e[3], Title = e[2] .. " Color" })
            WorldESP:AddSlider(e[1].."_max_dist", {
                Text = e[2] .. " Distance", Default = 2000, Min = 1, Max = 50000, Rounding = 0, Suffix = "s"
            })
        end

        WorldESP:AddDropdown("mob_filter", {
            Text = "Blacklist Mobs", Values = { "Gigameds", "Guards" }, Default = { "Gigameds", "Guards" }, Multi = true,
        })
        WorldESP:AddDropdown("mob_health_format", {
            Text = "Mob Health Format", Values = { "hp%, hp/max", "hp/max", "hp%" }, Default = "hp/max", Multi = false,
        })
        WorldESP:AddToggle("mob_esp_healthbar",     { Text = "Mob Healthbars",       Default = false })
        WorldESP:AddToggle("chest_esp_show_opened", { Text = "Show Opened Chests",   Default = false })
        WorldESP:AddToggle("hide_game_esp",         { Text = "Hide Ingame Job ESP",  Default = true })

        -- Ingredient filter
        local ingredientArray = { "All Ingredients" }
        WorldESP:AddDropdown("ingredient_filter", {
            Text = "Filter Ingredients", Values = ingredientArray, Default = { "All Ingredients" }, Multi = true,
        })
        WorldESP:AddButton({
            Text = "Refresh Ingredient List",
            Func = function()
                local found = {}
                pcall(function()
                    for _, v in pairs(workspace:WaitForChild("Ingredients"):GetChildren()) do
                        if not table.find(found, v.Name) then
                            table.insert(found, v.Name)
                        end
                    end
                end)
                table.clear(ingredientArray)
                table.insert(ingredientArray, "All Ingredients")
                for _, name in ipairs(found) do table.insert(ingredientArray, name) end
                Options.ingredient_filter:SetValues(ingredientArray)
                Library:Notify("Found " .. #found .. " ingredients.")
            end,
        })
    end

    -- ─────────────────────────────────────────────────────────────
    -- AUTOMATION
    -- ─────────────────────────────────────────────────────────────
    do
        local T = Tabs.Automation

        local G = T:AddLeftGroupbox("Farms")
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
        local pd = getgenv().persistent_data
        for _, entry in ipairs(farmList) do
            G:AddToggle("farm_" .. entry.flag, {
                Text    = entry.name,
                Default = pd and pd:get(entry.flag) == true or false,
                Callback = function(v) automation.setFarm(entry.flag, v) end,
            })
        end

        local G2 = T:AddRightGroupbox("Controls")
        G2:AddButton({
            Text = "Stop All Farms",
            Func = function()
                for _, entry in ipairs(farmList) do
                    if pd then pd:set(entry.flag, false) end
                    local tog = Toggles["farm_" .. entry.flag]
                    if tog then tog:SetValue(false) end
                end
                Library:Notify("All farms stopped.")
            end,
        })
        G2:AddButton({
            Text = "Server Hop",
            Func = function()
                pcall(function()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(
                        game.PlaceId,
                        game.JobId,
                        game:GetService("Players").LocalPlayer
                    )
                end)
            end,
        })
        G2:AddDivider()
        G2:AddLabel("Active farms persist across")
        G2:AddLabel("server hops via MemStorage.")
    end

    -- ─────────────────────────────────────────────────────────────
    -- SETTINGS
    -- ─────────────────────────────────────────────────────────────
    do
        local T = Tabs.Settings

        if SaveManager then
            SaveManager:SetLibrary(Library)
            SaveManager:SetFolder("Vanta/Config")
            SaveManager:IgnoreThemeSettings()
            SaveManager:BuildConfigSection(T)
        end
        if ThemeManager then
            ThemeManager:SetLibrary(Library)
            ThemeManager:SetFolder("Vanta/Config")
            ThemeManager:ApplyToTab(T)
        end

        local G2 = T:AddRightGroupbox("About")
        G2:AddLabel("Vanta — Nextgen")
        G2:AddLabel("Timings: APC / Lycoris Rewrite")
        G2:AddLabel("UI:      Project Rain style")
        G2:AddLabel("Farms:   16 auto-farms")
        G2:AddDivider()
        G2:AddButton({
            Text = "Unload Vanta",
            Func = function()
                pcall(function() Library:Unload() end)
                pcall(function() getgenv()._vanta_loaded() end)
            end,
        })
        G2:AddButton({
            Text = "Wipe Saved Data",
            Func = function()
                if ChoiceFrame then
                    ChoiceFrame.set(
                        "Wipe ALL saved data? This cannot be undone.",
                        function()
                            getgenv().persistent_data:wipe()
                            Library:Notify("Saved data wiped.")
                        end,
                        function()
                            Library:Notify("Wipe cancelled.")
                        end,
                        "Wipe",
                        "Cancel"
                    )
                else
                    getgenv().persistent_data:wipe()
                    Library:Notify("Saved data wiped.")
                end
            end,
        })
    end

    -- ── Auto-load saved config ────────────────────────────────────
    pcall(function()
        if SaveManager then SaveManager:LoadAutoloadConfig() end
    end)
end
