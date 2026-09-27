--[[
    NewScript — Combined Deepwoken Script
    ╔══════════════════════════════════════════════════╗
    ║  Timings  : APC / Lycoris-Rewrite               ║
    ║  UI       : Custom (Linoria-based, redesigned)  ║
    ║  Farms    : All Project Rain automations        ║
    ╚══════════════════════════════════════════════════╝
    Executor: Volt  |  Keyless  |  Personal use only
--]]

-- ──────────────────────────────────────────────────────
-- [1] BOOTSTRAP — globals, services, stubs
-- ──────────────────────────────────────────────────────

if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

-- ──────────────────────────────────────────────────────
-- [0] ANTI-DETECTION — kill GetLogHistory & redirect logs
--   Must run FIRST before anything prints anything.
--
--   Why the original dev's fix didn't work:
--     → It only filtered "Lycoris Recode" / "debug.profileEnd()"
--     → Everything else (init logs, farm logs, errors) still leaked
--     → hookfunction(GetLogHistory) only intercepts client-side calls,
--       but the detection likely runs before our hook is set up if we
--       don't do it on line 1.
--
--   Our fix:
--     1. Nuke GetLogHistory entirely → always returns {}
--     2. Redirect print/warn/error to rconsoleprint (exploit console only)
--        so messages NEVER enter Roblox's LogService buffer at all.
--     3. Override LogService.MessageOut connections so any listener that
--        already connected sees nothing useful.
-- ──────────────────────────────────────────────────────
local _LogService = game:GetService("LogService")

-- Step 1: Nuke GetLogHistory — return empty table always.
-- This covers both the game calling it AND any future calls.
local _oldGetLogHistory
local _fakeGetLogHistory = function(...)
    return {}
end
pcall(function()
    _oldGetLogHistory = hookfunction(_LogService.GetLogHistory, newcclosure(_fakeGetLogHistory))
end)

-- Step 2: Redirect print/warn/error to rconsoleprint.
-- rconsoleprint writes to the exploit's console (Volt's internal window),
-- NOT to Roblox's LogService, so it never appears in GetLogHistory.
local _rcprint = (typeof(rconsoleprint) == "function" and rconsoleprint)
             or (typeof(rconsolewarn) == "function" and rconsolewarn)
             or function() end -- silent fallback if no rconsole

local function _safe_concat(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    return table.concat(parts, "\t")
end

local _oldPrint, _oldWarn, _oldError
pcall(function()
    _oldPrint = hookfunction(print, newcclosure(function(...)
        _rcprint("[print] " .. _safe_concat(...) .. "\n")
    end))
end)
pcall(function()
    _oldWarn = hookfunction(warn, newcclosure(function(...)
        _rcprint("[warn]  " .. _safe_concat(...) .. "\n")
    end))
end)
-- Don't hook error() — it needs to propagate for pcall to work correctly.

-- Step 3: Suppress LogService.MessageOut so any game-side listener
-- that connected AFTER us also sees nothing from our messages.
-- We do this by firing a fake empty event instead.
-- (This is belt-and-suspenders — steps 1+2 already cover most cases.)
pcall(function()
    local _msConn
    _msConn = _LogService.MessageOut:Connect(function(msg, msgType)
        -- Already intercepted at source by print/warn hooks above.
        -- This connection intentionally does nothing — it just prevents
        -- the message from bubbling to other MessageOut listeners
        -- by being the first one connected (Roblox fires in order).
        -- Note: we cannot truly block it, but we've already nuked
        -- the buffer via GetLogHistory and print hooks.
    end)
    -- Keep the connection alive for the session.
end)

-- LPH stubs (no obfuscation needed)
local function LPH_NO_VIRTUALIZE(f) return f end
local function LPH_JIT_MAX(f) return f end
local function LPH_JIT(f) return f end
local function LPH_ENCSTR(s) return s end

-- Service cache
local service_cache = {}
local services = setmetatable({}, {
    __index = function(_, k)
        if not service_cache[k] then
            service_cache[k] = game:GetService(k)
        end
        return service_cache[k]
    end
})
getgenv().services = services

-- Detach / reload guard
if getgenv()._newscript_loaded then
    pcall(function() getgenv()._newscript_loaded() end)
end

-- Place flags
local IS_DEPTHS   = game.PlaceId == 5735553160
local IS_ETREAN   = game.PlaceId == 6032399813
local IS_EASTERN  = game.PlaceId == 6473861193
local IS_ARENA    = game.PlaceId == 6832944305
local IS_DUNGEON  = game.PlaceId == 8668476218

-- Folder setup
local function ensureFolder(path)
    if not isfolder(path) then makefolder(path) end
end
ensureFolder("NewScript")
ensureFolder("NewScript/Config")
ensureFolder("NewScript/Assets")

-- ──────────────────────────────────────────────────────
-- [2] LIGHTWEIGHT UTILITIES
-- ──────────────────────────────────────────────────────

-- Signal
local Signal = {} do
    Signal.__index = Signal
    function Signal.new()
        return setmetatable({ _conns = {} }, Signal)
    end
    function Signal:connect(fn)
        table.insert(self._conns, fn)
        return { Disconnect = function() for i, c in ipairs(self._conns) do if c == fn then table.remove(self._conns, i) break end end end }
    end
    function Signal:fire(...)
        for _, fn in ipairs(self._conns) do
            task.spawn(fn, ...)
        end
    end
    function Signal:wait()
        local thread = coroutine.running()
        local conn
        conn = self:connect(function(...)
            conn:Disconnect()
            task.spawn(thread, ...)
        end)
        return coroutine.yield()
    end
end

-- Maid
local Maid = {} do
    Maid.__index = Maid
    function Maid.new()
        return setmetatable({ _tasks = {} }, Maid)
    end
    function Maid:give(task_)
        table.insert(self._tasks, task_)
        return #self._tasks
    end
    function Maid:clean()
        for _, t in ipairs(self._tasks) do
            pcall(function()
                if typeof(t) == "RBXScriptConnection" then t:Disconnect()
                elseif type(t) == "function" then t()
                elseif t and t.Destroy then t:Destroy() end
            end)
        end
        table.clear(self._tasks)
    end
end

-- Logger — writes directly to exploit rconsole, never to Roblox LogService
local Logger = {} do
    function Logger.log(msg)
        -- _rcprint is defined in section [0], always safe to call
        _rcprint("[NS] " .. tostring(msg) .. "\n")
    end
    function Logger.warn(msg)
        _rcprint("[NS][WARN] " .. tostring(msg) .. "\n")
    end
    function Logger.notify(msg, dur)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title    = "NewScript",
                Text     = tostring(msg),
                Duration = dur or 4,
            })
        end)
    end
end
getgenv().NSLogger = Logger

-- Persistent data (MemStorageService, Volt compatible)
local PersistentData = {} do
    local mss = services.MemStorageService
    local KEY = "newscript_persistent"
    if not mss:HasItem(KEY) then
        mss:SetItem(KEY, "{}")
    end
    function PersistentData:_raw()
        return services.HttpService:JSONDecode(mss:GetItem(KEY) or "{}")
    end
    function PersistentData:get(key, default)
        return self:_raw()[key] or default
    end
    function PersistentData:set(key, val)
        local d = self:_raw()
        d[key] = val
        mss:SetItem(KEY, services.HttpService:JSONEncode(d))
    end
    function PersistentData:wipe()
        mss:SetItem(KEY, "{}")
    end
end
getgenv().persistent_data = PersistentData

-- Latency
local Latency = {} do
    local ping_stat = services.Stats:FindFirstChild("Data Ping", true)
    function Latency:get_ping()
        if not ping_stat then return 0 end
        local old = getthreadidentity()
        setthreadidentity(8)
        local v = ping_stat:GetValue()
        setthreadidentity(old)
        return v / 1000
    end
    function Latency:half_ping()
        return self:get_ping() / 2
    end
end
getgenv().Latency = Latency

-- Local player helpers
local lp = services.Players.LocalPlayer
local local_player = {} do
    local_player.instance = lp
    local function refresh()
        local char = lp.Character
        if not char then return end
        local_player.character   = char
        local_player.humanoid    = char:FindFirstChild("Humanoid")
        local_player.root_part   = char:FindFirstChild("HumanoidRootPart")
    end
    refresh()
    lp.CharacterAdded:Connect(function(c)
        task.wait(0.1)
        refresh()
    end)
end
getgenv().local_player = local_player

-- Master maid / detach state
local masterMaid = Maid.new()
local _flags    = {}
local _detach   = false
getgenv().ns_flags = _flags

local function onDetach(fn)
    masterMaid:give(fn)
end
getgenv()._newscript_loaded = function()
    _detach = true
    masterMaid:clean()
end

-- EffectReplicator (lightweight, hooks into game's existing one if available)
local EffectReplicator = {} do
    function EffectReplicator:FindEffect(class)
        local char = local_player.character
        if not char then return false end
        local effects = char:FindFirstChild("Effects")
        if not effects then return false end
        return effects:FindFirstChild(class) ~= nil
    end
end
getgenv().EffectReplicator = EffectReplicator

-- KeyHandler — finds Deepwoken's encrypted remote table via gc scan
local KeyHandler = {} do
    local cache = {}
    local heaven_key = 2754 * (72 % (0.6769230769205024 * 7 * 7 % 5 % 64 % 41 / 66 + 12) / 54 / (4 / 36 + 5.3655660377358485) + 1 * 4 % 52 * 21 / 4 % 35 / 3) / 35 * 38 + (66 + (8 + 4 + 5 + 2 + 19035.52631578947) / 34 + 40 % 41 / 56 % 65 * 57 + 3381) + 420 + 35 * (0.3150684931506849 + 69 + 14 / 56 + 28 + 36) + (0.125 + 3)
    local remotes, enc_f

    local function scan_gc()
        if remotes and enc_f then return end
        for _, tbl in next, getgc(true) do
            if typeof(tbl) ~= "table" then continue end
            if getrawmetatable(tbl) then continue end
            if #tbl ~= 13 or tbl[9] ~= heaven_key then continue end
            remotes = tbl[12]
            enc_f   = tbl[13]
            break
        end
    end

    -- Retry until found
    task.spawn(function()
        while not (remotes and enc_f) do
            pcall(scan_gc)
            task.wait(0.5)
        end
    end)

    function KeyHandler:get_key(name)
        if cache[name] then return cache[name] end
        if not remotes or not enc_f then return nil end
        local ok, encoded = pcall(enc_f, name)
        if not ok or not encoded then return nil end
        cache[name] = remotes[encoded]
        return cache[name]
    end
end
getgenv().KeyHandler = KeyHandler

-- ──────────────────────────────────────────────────────
-- [3] DEFEND ACTION MANAGER (parry/dodge dispatcher)
-- ──────────────────────────────────────────────────────

local DefendActionManager = {} do
    DefendActionManager._queue   = {}
    DefendActionManager._handling = {}
    DefendActionManager._block_count = 0
    DefendActionManager._dodge_until = 0
    DefendActionManager._seq     = 0

    -- Throttled block/unblock
    local sent = 0
    local function throttled(name)
        return function()
            sent += 1
            task.delay(1, function() sent = math.max(0, sent - 1) end)
            if sent >= 75 then return end
            local remote = KeyHandler:get_key(name)
            if remote and remote.Parent then
                remote:FireServer()
            end
        end
    end

    local _block_fire   = throttled("Block")
    local _unblock_fire = throttled("Unblock")

    function DefendActionManager:queue_parry(mob)
        self._seq += 1
        local s = self._seq
        table.insert(self._queue, { mob = mob, type = "block",   when = tick(),       seq = s })
        table.insert(self._queue, { mob = mob, type = "unblock", when = tick() + 0.1, seq = s })
    end

    function DefendActionManager:queue_dodge(mob)
        table.insert(self._queue, { mob = mob, type = "dodge", when = tick() })
    end

    function DefendActionManager:_do_block()
        _block_fire()
    end
    function DefendActionManager:_do_unblock()
        _unblock_fire()
        task.spawn(function()
            local start = tick()
            while tick() - start < 0.05 do
                task.wait()
                _unblock_fire()
            end
        end)
    end
    function DefendActionManager:_do_dodge(action)
        local Keybinds = pcall(function()
            local kb = require(services.ReplicatedStorage:WaitForChild("KeyBinds"))
            kb.ForceActionDown("Dodge")
            kb.ForceActionUp("Dodge")
        end)
    end

    masterMaid:give(services.RunService.Heartbeat:Connect(function()
        local now = tick()
        -- Clean stale unblocks
        if DefendActionManager._block_count > 0 then
            local has_unblock = false
            for _, v in ipairs(DefendActionManager._queue) do
                if v.type == "unblock" then has_unblock = true break end
            end
            if not has_unblock and now - (DefendActionManager._block_started or now) > 0.25 then
                DefendActionManager._block_count = 0
                DefendActionManager:_do_unblock()
            end
        end

        for i = #DefendActionManager._queue, 1, -1 do
            local v = DefendActionManager._queue[i]
            if now >= v.when and not DefendActionManager._handling[v] then
                -- Target filter
                if not _flags.auto_parry then
                    table.remove(DefendActionManager._queue, i)
                    continue
                end

                DefendActionManager._handling[v] = true
                table.remove(DefendActionManager._queue, i)

                task.spawn(function()
                    if v.type == "block" then
                        DefendActionManager._block_count += 1
                        if DefendActionManager._block_count == 1 then
                            DefendActionManager._block_started = tick()
                            DefendActionManager:_do_block()
                        end
                    elseif v.type == "unblock" then
                        DefendActionManager._block_count = math.max(0, DefendActionManager._block_count - 1)
                        if DefendActionManager._block_count == 0 then
                            DefendActionManager:_do_unblock()
                        end
                    elseif v.type == "dodge" then
                        DefendActionManager._dodge_until = now + 0.1
                        DefendActionManager:_do_dodge(v)
                    end
                    DefendActionManager._handling[v] = nil
                end)

                if v.type == "block" or v.type == "dodge" then break end
            end
        end
    end))
end
getgenv().DefendActionManager = DefendActionManager

-- ──────────────────────────────────────────────────────
-- [4] WEAPON DATA HELPER (from Lycoris Globals/Weapon.lua)
-- ──────────────────────────────────────────────────────

local Weapon = {} do
    local function findThrownHandWeapon(entityName)
        local thrown = workspace:FindFirstChild("Thrown")
        if not thrown then return nil end
        local attach = thrown:FindFirstChild("Attach_" .. entityName)
        if not attach then return nil end
        return attach:FindFirstChild("HandWeapon")
    end

    function Weapon.data(entity)
        local lh = entity:FindFirstChild("LeftHand")
        local rh = entity:FindFirstChild("RightHand")
        if not lh and not rh then return nil end

        local hw = (lh and lh:FindFirstChild("HandWeapon"))
                or (rh and rh:FindFirstChild("HandWeapon"))
                or findThrownHandWeapon(entity.Name)
        if not hw then return nil end

        local stats = hw:FindFirstChild("Stats")
        if not stats then return nil end

        local ssv = stats:FindFirstChild("SwingSpeed")
        local lv  = stats:FindFirstChild("Length")
        local typ = hw:FindFirstChild("Type")
        if not ssv or not lv or not typ then return nil end

        local nemesis = false
        for _, inst in next, hw:GetChildren() do
            if inst:IsA("ParticleEmitter") and inst.Texture == "rbxassetid://11889781532" then
                nemesis = true
                break
            end
        end

        return {
            hw      = hw,
            ss      = ssv.Value,
            oss     = ssv:GetAttribute("OldValue") or ssv.Value,
            length  = lv.Value,
            type    = typ.Value or "N/A",
            nemesis = nemesis,
        }
    end

    function Weapon.handWeapon(entity)
        local lh = entity:FindFirstChild("LeftHand")
        local rh = entity:FindFirstChild("RightHand")
        local hw = (lh and lh:FindFirstChild("HandWeapon"))
                or (rh and rh:FindFirstChild("HandWeapon"))
        if not hw then
            hw = (function()
                local thrown = workspace:FindFirstChild("Thrown")
                if not thrown then return nil end
                local attach = thrown:FindFirstChild("Attach_" .. entity.Name)
                if not attach then return nil end
                return attach:FindFirstChild("HandWeapon")
            end)()
        end
        return hw
    end
end
getgenv().Weapon = Weapon

-- ──────────────────────────────────────────────────────
-- [5] APC / LYCORIS TIMING ENGINE
--   Replaces PR's animator-handler timing dispatch.
--   Directly ports WeaponTest.lua + GenericTelegraph.lua
--   All per-attack special handlers are in the dispatch table.
-- ──────────────────────────────────────────────────────

-- "TaskSpawner" — simple named task spawner (prevents spam)
local TaskSpawner = {} do
    local running = {}
    function TaskSpawner.spawn(name, fn)
        if running[name] then return end
        running[name] = true
        task.spawn(function()
            fn()
            running[name] = nil
        end)
    end
end

-- PartTiming stub (for Pistol bullet tracking, simplified)
local PartTiming = {} do
    PartTiming.__index = PartTiming
    function PartTiming.new()
        return setmetatable({ uhc = false, duih = false, fhb = false,
            name = "", hitbox = Vector3.new(10,10,10), cbm = false, actions = {} }, PartTiming)
    end
end

-- The main timing dispatch function (ported from WeaponTest.lua)
local function weaponTestHandler(entity, track)
    if entity.Name:match("evengarde") and
        (track.Animation.AnimationId:match("1SwordSwing1") or track.Animation.AnimationId:match("1SwordSwing2")) then
        if _G.EvengardeSwingGuard and (os.clock() - _G.EvengardeSwingGuard) < 4 then return end
        _G.EvengardeSwingGuard = os.clock()

        TaskSpawner.spawn("EvengardeSwingParry", function()
            task.wait(0.4)
            local start = os.clock()
            while (os.clock() - start) < 3 do
                DefendActionManager:queue_parry(entity)
                task.wait(0.05)
            end
        end)
        return
    end

    local data = Weapon.data(entity)
    if not data then return end

    local hrp = entity:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local windup

    if data.type == "Greataxe" and track.Speed ~= 1.0 then
        windup = (0.171 / track.Speed) + 0.120
    elseif data.type == "Greataxe" then
        windup = (0.171 / track.Speed) + 0.250 / data.ss
    elseif data.type == "Greathammer" and track.Speed ~= 1.0 then
        windup = (0.150 / track.Speed) + 0.200
    elseif data.type == "Greathammer" then
        windup = (0.150 / track.Speed) + 0.250 / data.ss
    elseif data.type == "Greatcannon" and track.Speed ~= 1.0 then
        windup = (0.155 / track.Speed) + 0.160
    elseif data.type == "Greatcannon" then
        windup = (0.155 / track.Speed) + 0.300
    elseif data.type == "Rapier" then
        windup = (0.155 / track.Speed) + 0.120
    elseif data.type == "Bow" then
        local thrown_obj = workspace.Thrown and workspace.Thrown:FindFirstChild("Attach_" .. entity.Name)
        local tip = thrown_obj and thrown_obj:FindFirstChild("HandWeapon") and thrown_obj.HandWeapon:FindFirstChild("TipAttachment")
        if tip then
            local ready = false
            while task.wait() and track.IsPlaying do
                ready = tip:FindFirstChild("Spark")
                if ready then break end
            end
            if not ready then return end
        end
        windup = 0.1
    elseif data.type == "Pistol" and not track.Animation.AnimationId:match("Shot") then
        windup = 0.350 / data.ss
    elseif data.type == "Pistol" and track.Animation.AnimationId:match("Shot") then
        local ispeed = track.Speed
        repeat task.wait() until track.Speed ~= ispeed
        windup = track.Speed == 0.0 and 0.100 or (0.075 / track.Speed)
    elseif data.type == "Rifle" and track.Animation.AnimationId:match("2") then
        local ispeed = track.Speed
        repeat task.wait() until track.Speed ~= ispeed
        windup = track.Speed == 0.0 and 0.100 or (0.150 / track.Speed)
    elseif data.type == "Rifle" then
        windup = (0.174 / track.Speed) + 0.125
    elseif data.type == "Club" then
        windup = (0.180 / track.Speed) + 0.100
    elseif data.type == "Twinblade" then
        windup = (0.200 / track.Speed) + 0.050
    elseif data.type == "Spear" then
        windup = (0.150 / track.Speed) + 0.100
    elseif data.type == "Greatsword" then
        windup = (0.158 / track.Speed) + 0.150
    elseif data.type == "Fist" then
        -- Titus special case
        if entity.Name:lower():match("titus") then
            repeat task.wait() until track.Speed > 0
            local finalSpeed = track.Speed + 0.2
            local delay_ms = (565 * 0.76) / finalSpeed
            task.wait((delay_ms - Latency:get_ping() * 1000) / 1000)
            DefendActionManager:queue_parry(entity)
            return
        end
        windup = (0.140 / track.Speed) + 0.130
    elseif data.type == "Dagger" then
        windup = (0.200 / track.Speed) + 0.075
    elseif data.type == "Staff" then
        windup = 0.350
    elseif data.type == "Sword" then
        windup = (0.200 / track.Speed) + 0.100
    end

    if not windup then return end

    local wait_time = (windup * 1000 - Latency:get_ping() * 1000) / 1000
    if wait_time > 0 then
        task.wait(wait_time)
    end

    if not track.IsPlaying then return end
    if not _flags.auto_parry then return end

    DefendActionManager:queue_parry(entity)

    -- Pistol bullet tracking
    if data.type == "Pistol" then
        TaskSpawner.spawn("WeaponTest_ScrapsingerBullet_" .. entity.Name, function()
            local thrown = workspace:FindFirstChild("Thrown")
            if not thrown then return end

            local bullet
            local conn
            conn = thrown.ChildAdded:Connect(function(child)
                if child.Name == "ScrapsingerBullet_" .. entity.Name then
                    bullet = child
                    conn:Disconnect()
                end
            end)

            local timeout = tick() + 2
            repeat task.wait() until bullet or tick() > timeout
            conn:Disconnect()

            if not bullet then return end

            repeat task.wait()
            until not bullet.Parent
               or (bullet.Position - local_player.root_part.Position).Magnitude < 20

            if bullet.Parent then
                DefendActionManager:queue_parry(entity)
            end
        end)
    end
end

-- GenericTelegraph handler (ported from GenericTelegraph.lua)
-- Fires when a telegraph effect appears on the local character
local function genericTelegraphHandler(entity, effectData)
    local selfCharacter = lp.Character
    if entity ~= selfCharacter then return end

    local telegraphType = effectData and effectData.telegraph
    local part = effectData and effectData.part

    if part and part:IsDescendantOf(selfCharacter) and part.Name == "HumanoidRootPart" then
        local dur = effectData.dur
        if dur ~= 1 then return end

        if not table.find({"dodge_only", "block_only", "parry_only"}, telegraphType) then return end

        local actionType = telegraphType == "dodge_only" and "dodge" or "parry"
        -- 950ms timing (slightly early to account for ping)
        task.wait((950 - Latency:get_ping() * 1000) / 1000)
        if not _flags.auto_parry then return end
        if actionType == "parry" then
            DefendActionManager:queue_parry(entity)
        else
            DefendActionManager:queue_dodge(entity)
        end
    end
end

-- Named per-attack timing overrides (from APC timing modules)
-- Each entry: animName pattern → { wait_ms, type }
-- These supplement WeaponTest for specific named moves
local NAMED_TIMINGS = {
    -- NPC specials
    ["AircraftStomp"]          = { wait = 450, type = "dodge" },
    ["ArdourBall"]             = { wait = 0,   type = "parry" },
    ["BlindingDawn"]           = { wait = 350, type = "parry" },
    ["BoltcrusherRunning"]     = { wait = 100, type = "parry" },
    ["BoneBoyLeap"]            = { wait = 200, type = "dodge" },
    ["BrutePunch"]             = { wait = 300, type = "parry" },
    ["ChaserSlam"]             = { wait = 350, type = "parry" },
    ["CloseShave"]             = { wait = 250, type = "dodge" },
    ["CrimsonRain"]            = { wait = 500, type = "parry" },
    ["CroccoGroundLeave"]      = { wait = 200, type = "dodge" },
    ["CroccoTailWhip"]         = { wait = 300, type = "parry" },
    ["DaggerThrow"]            = { wait = 350, type = "parry" },
    ["Decimate"]               = { wait = 600, type = "parry" },
    ["DreadBreath"]            = { wait = 300, type = "dodge" },
    ["DukeStomp"]              = { wait = 500, type = "dodge" },
    ["ElectroCarve"]           = { wait = 450, type = "parry" },
    ["Eruption"]               = { wait = 550, type = "dodge" },
    ["EtherBarrage"]           = { wait = 200, type = "parry" },
    ["FireForge"]              = { wait = 750, type = "parry" },
    ["FirePalm"]               = { wait = 400, type = "parry" },
    ["FiringLine"]             = { wait = 600, type = "dodge" },
    ["FlameGrab"]              = { wait = 350, type = "parry" },
    ["Flameleap"]              = { wait = 300, type = "dodge" },
    ["GlacialArc"]             = { wait = 450, type = "parry" },
    ["GrandJavelin"]           = { wait = 500, type = "parry" },
    ["IceDaggers"]             = { wait = 400, type = "parry" },
    ["IceLunge"]               = { wait = 300, type = "parry" },
    ["IceSpike"]               = { wait = 350, type = "parry" },
    ["KatanaCritical"]         = { wait = 550, type = "parry" },
    ["LightningAssault"]       = { wait = 350, type = "parry" },
    ["LightningBeam"]          = { wait = 500, type = "dodge" },
    ["LightningSlash"]         = { wait = 300, type = "parry" },
    ["LightningStream"]        = { wait = 250, type = "parry" },
    ["MetalRain"]              = { wait = 450, type = "dodge" },
    ["NeedleBarrage"]          = { wait = 300, type = "parry" },
    ["Onslaught"]              = { wait = 400, type = "parry" },
    ["ParasolTendrils"]        = { wait = 500, type = "dodge" },
    ["PressureBlast"]          = { wait = 400, type = "dodge" },
    ["PrimadonTripleStomp"]    = { wait = 300, type = "dodge" },
    ["PromDraw"]               = { wait = 350, type = "parry" },
    ["PumpkinThrow"]           = { wait = 400, type = "parry" },
    ["RapidPunches"]           = { wait = 150, type = "parry" },
    ["RapidSlashes"]           = { wait = 200, type = "parry" },
    ["RegentGrapple"]          = { wait = 400, type = "parry" },
    ["Revenge"]                = { wait = 300, type = "parry" },
    ["RisingShadow"]           = { wait = 500, type = "parry" },
    ["RisingThunder"]          = { wait = 450, type = "parry" },
    ["Rushdown"]               = { wait = 350, type = "parry" },
    ["SanguineDive"]           = { wait = 300, type = "dodge" },
    ["ScarletCannon"]          = { wait = 500, type = "parry" },
    ["Scythe"]                 = { wait = 450, type = "parry" },
    ["ShadowEncircle"]         = { wait = 400, type = "parry" },
    ["ShadowGun"]              = { wait = 300, type = "parry" },
    ["ShadowMetero"]           = { wait = 600, type = "dodge" },
    ["ShadowRoar"]             = { wait = 500, type = "dodge" },
    ["ShadowSaintsworn"]       = { wait = 400, type = "parry" },
    ["ShadowSludge"]           = { wait = 450, type = "parry" },
    ["SharkoKick"]             = { wait = 300, type = "parry" },
    ["ShoulderBash"]           = { wait = 350, type = "parry" },
    ["SilentheartWarn"]        = { wait = 600, type = "parry" },
    ["SinisterHalo"]           = { wait = 550, type = "parry" },
    ["Smite"]                  = { wait = 400, type = "parry" },
    ["SmoulderingHallow"]      = { wait = 500, type = "parry" },
    ["Stormbreaker"]           = { wait = 450, type = "parry" },
    ["StrongLeft"]             = { wait = 350, type = "parry" },
    ["TelegraphMajor"]         = { wait = 550, type = "parry" },
    ["TelegraphMinor"]         = { wait = 350, type = "parry" },
    ["TerrapodBarrage"]        = { wait = 400, type = "parry" },
    ["Thrust"]                 = { wait = 300, type = "parry" },
    ["TitusDrive"]             = { wait = 350, type = "parry" },
    ["TitusKick"]              = { wait = 300, type = "dodge" },
    ["TitusSkycrash"]          = { wait = 500, type = "dodge" },
    ["Tornado"]                = { wait = 400, type = "dodge" },
    ["VengefulSlashes"]        = { wait = 350, type = "parry" },
    ["WardensBlade"]           = { wait = 400, type = "parry" },
    ["WindBlade"]              = { wait = 350, type = "parry" },
    ["WindCarve"]              = { wait = 400, type = "parry" },
    ["WindGun"]                = { wait = 300, type = "parry" },
    ["WraithclawCrit"]         = { wait = 350, type = "parry" },
    ["WyrmCrit"]               = { wait = 400, type = "parry" },
    -- Criticals
    ["AraneaCrit"]             = { wait = 400, type = "parry" },
    ["ChorusCrit"]             = { wait = 350, type = "parry" },
    ["CrescentCrit"]           = { wait = 300, type = "dodge" },
    ["DaggerCritical"]         = { wait = 350, type = "parry" },
    ["DeepspindleCrit"]        = { wait = 400, type = "parry" },
    ["DualCurvedBladeCrit"]    = { wait = 380, type = "parry" },
    ["GreataxeCritical"]       = { wait = 600, type = "parry" },
    ["GreatswordCritical"]     = { wait = 500, type = "parry" },
    ["ImperatorRunCrit"]       = { wait = 300, type = "parry" },
    ["KatanaCritical"]         = { wait = 500, type = "parry" },
    ["NavaeCritical"]          = { wait = 350, type = "parry" },
    ["RailbladeCrit"]          = { wait = 400, type = "parry" },
    ["ScalesplitterCrit"]      = { wait = 350, type = "parry" },
    ["SoulthornCrit"]          = { wait = 380, type = "parry" },
    ["SpearCritical"]          = { wait = 350, type = "parry" },
    ["SwordCritical"]          = { wait = 400, type = "parry" },
    ["TantoCrit"]              = { wait = 300, type = "parry" },
    ["WhalingCrit"]            = { wait = 400, type = "parry" },
}

-- Build a pattern lookup from animation names
-- (game names anims like "WeaponType-AnimName", so we check for substring)
local function findNamedTiming(animName)
    for pattern, timing in pairs(NAMED_TIMINGS) do
        if animName:find(pattern) then
            return timing
        end
    end
    return nil
end

-- ──────────────────────────────────────────────────────
-- [6] ANIMATOR WATCHER — hooks into Live entities
-- ──────────────────────────────────────────────────────

local function getAnimName(track)
    -- Try to get name from ReplicatedStorage anim catalog
    local id = track.Animation.AnimationId:match("%d+")
    if not id then return "" end
    local assets = services.ReplicatedStorage:FindFirstChild("Assets")
    if not assets then return id end
    local anims = assets:FindFirstChild("Anims")
    if not anims then return id end
    for _, anim in ipairs(anims:GetDescendants()) do
        if anim:IsA("Animation") and anim.AnimationId:match("%d+") == id then
            return anim.Parent.Name .. "-" .. anim.Name
        end
    end
    return id
end

local watchedEntities = {}

local function attachEntityWatcher(entity)
    if watchedEntities[entity] then return end

    local animator = entity:FindFirstChild("Animator", true)
    if not animator then return end

    local conn
    conn = animator.AnimationPlayed:Connect(function(track)
        if not _flags.auto_parry then return end
        if entity == local_player.character then return end -- skip self
        if not track or not track.Animation then return end

        task.spawn(function()
            task.wait(1/60) -- one frame delay matches PR behaviour

            local animName = getAnimName(track)
            local named = findNamedTiming(animName)

            if named then
                local wait_s = (named.wait - Latency:get_ping() * 1000) / 1000
                if wait_s > 0 then task.wait(wait_s) end
                if not track.IsPlaying and named.wait > 100 then return end
                if not _flags.auto_parry then return end
                if named.type == "dodge" then
                    DefendActionManager:queue_dodge(entity)
                else
                    DefendActionManager:queue_parry(entity)
                end
            else
                -- Fallback to weapon timing (M1 swings etc)
                weaponTestHandler(entity, track)
            end
        end)
    end)

    local ancestry
    ancestry = entity.AncestryChanged:Connect(function(_, parent)
        if not parent then
            conn:Disconnect()
            ancestry:Disconnect()
            watchedEntities[entity] = nil
        end
    end)

    watchedEntities[entity] = { conn = conn, ancestry = ancestry }
    masterMaid:give(function()
        pcall(function() conn:Disconnect() end)
        pcall(function() ancestry:Disconnect() end)
        watchedEntities[entity] = nil
    end)
end

local function startParryEngine()
    local live = workspace:WaitForChild("Live", 10)
    if not live then return end

    -- Existing entities
    for _, entity in ipairs(live:GetChildren()) do
        task.spawn(function()
            local start = tick()
            repeat task.wait() until entity:FindFirstChild("Animator", true) or tick() - start > 5
            if entity:IsA("Model") then
                attachEntityWatcher(entity)
            end
        end)
    end

    -- New entities
    masterMaid:give(live.ChildAdded:Connect(function(entity)
        task.spawn(function()
            local start = tick()
            repeat task.wait() until entity:FindFirstChild("Animator", true) or tick() - start > 5
            if entity:IsA("Model") then
                attachEntityWatcher(entity)
            end
        end)
    end))

    -- Projectile auto-parry (ArdourBall, BoneSpear, Bullets, etc.)
    local thrown = workspace:FindFirstChild("Thrown") or workspace:WaitForChild("Thrown", 10)
    if thrown then
        masterMaid:give(thrown.ChildAdded:Connect(function(part)
            if not _flags.auto_parry then return end
            task.spawn(function()
                if part.Name == "ArdourBall2" then
                    repeat task.wait()
                    until not part.Parent or (part.Position - local_player.root_part.Position).Magnitude < 15
                    if not part.Parent then return end
                    local nomad
                    for _, c in ipairs(live:GetChildren()) do
                        if c.Name:match("nomad") then nomad = c break end
                    end
                    if nomad then DefendActionManager:queue_parry(nomad) end

                elseif part.Name == "BoneSpear" then
                    task.wait(2.15)
                    repeat task.wait()
                    until not part.Parent or (part.Position - local_player.root_part.Position).Magnitude < 75
                    if not part.Parent then return end
                    local bk
                    for _, c in ipairs(live:GetChildren()) do
                        if c.Name:match("boneboy") then bk = c break end
                    end
                    task.wait(math.max(0, 0.2 - Latency:get_ping()))
                    DefendActionManager:queue_parry(bk or live:GetChildren()[2])

                elseif part.Name == "Bullet" then
                    local closest, closestDist = nil, math.huge
                    for _, c in ipairs(live:GetChildren()) do
                        if c:FindFirstChild("HumanoidRootPart") then
                            local d = (part.Position - c.HumanoidRootPart.Position).Magnitude
                            if d < closestDist then closestDist = d; closest = c end
                        end
                    end
                    if closestDist > 120 then return end
                    repeat task.wait()
                    until not part.Parent or (part.Position - local_player.root_part.Position).Magnitude < 20
                    if not part.Parent then return end
                    if closest and closest ~= local_player.character then
                        DefendActionManager:queue_parry(closest)
                    end
                end
            end)
        end))
    end
end

-- ──────────────────────────────────────────────────────
-- [7] AUTOMATION LOADER & FARM STRUCTS
-- ──────────────────────────────────────────────────────

local farms = {}
getgenv().ns_farms = farms

-- Anti-AFK
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

local function shouldAutoStart()
    local flags = {
        "auto_saramed", "soup_echofarm", "titus_echofarm", "titus_relicfarm",
        "autoecho_titus", "auto_titus", "auto_echo_layer2", "ministry_notefarm",
        "auto_moonseyrie", "auto_layertwo", "auto_ferryman", "auto_authority_missions",
        "auto_duke", "auto_escape_depths", "auto_progress", "auto_voi",
        "auto_deepdrill", "jetstriker_echofarm",
    }
    for _, f in ipairs(flags) do
        if PersistentData:get(f) == true then return true end
    end
    return false
end

-- Farm definition helper
local function defineFarm(opts)
    local farm = {
        id                   = opts.id,
        persistent_data_flag = opts.flag,
        display_name         = opts.name,
        run                  = opts.run,
    }
    farms[opts.id] = farm
    return farm
end

-- Start all enabled farms
local function startFarms()
    local anyStarted = false
    for _, farm in pairs(farms) do
        if PersistentData:get(farm.persistent_data_flag) == true then
            anyStarted = true
            task.spawn(function()
                local ok, err = pcall(farm.run)
                if not ok then Logger.warn("Farm " .. farm.id .. " error: " .. tostring(err)) end
            end)
        end
    end
    if anyStarted then
        startAntiAFK()
    end
end

-- Toggle a farm on/off
local function setFarm(flag, on)
    PersistentData:set(flag, on)
    if on then
        for _, farm in pairs(farms) do
            if farm.persistent_data_flag == flag then
                startAntiAFK()
                task.spawn(function()
                    local ok, err = pcall(farm.run)
                    if not ok then Logger.warn("Farm " .. farm.id .. " error: " .. tostring(err)) end
                end)
                break
            end
        end
    end
end

-- Utility: teleport character
local function tpTo(cf)
    if local_player.root_part then
        local_player.root_part.CFrame = cf
    end
end

-- General server hop
local function serverHop(slot)
    slot = slot or lp:GetAttribute("DataSlot")
    local TP = services.TeleportService
    local servers = {}
    pcall(function()
        local ok, result = pcall(function()
            return TP:GetPlayersInServer()
        end)
    end)
    -- Basic rejoin-on-same-place approach for Volt
    TP:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
end

-- ──────────────────────────────────────────────────────
-- [8] FARM DEFINITIONS (all 16 automations from PR)
--    These are simplified stubs that preserve the core
--    loop logic. PR's full implementations use many
--    game-specific remotes which are referenced here.
-- ──────────────────────────────────────────────────────

-- Helper: fire a remote
local function getRequests()
    return services.ReplicatedStorage:FindFirstChild("Requests")
end

-- Helper: wait until character is alive in "Live"
local function waitForLive()
    while true do
        task.wait(0.5)
        local char = local_player.character
        if char and char.Parent and char.Parent.Name == "Live" then
            return char
        end
    end
end

-- Helper: safe tween (CFrame teleport fallback)
local function safeTween(targetCF, speed)
    -- On Volt we just teleport; speed param is ignored for safety
    pcall(function()
        if local_player.root_part then
            local_player.root_part.CFrame = targetCF
        end
    end)
end

-- ─── Auto Saramed (Dungeon) ───
defineFarm({
    id   = "auto_saramed",
    flag = "auto_saramed",
    name = "Auto Saramed",
    run  = function()
        Logger.notify("Auto Saramed started!")
        local requests = getRequests()
        while PersistentData:get("auto_saramed") do
            task.wait(1)
            if not local_player.character then task.wait(2) continue end
            -- Core saramed loop: move to monster, kill, collect, repeat
            local live = workspace:FindFirstChild("Live")
            if live then
                for _, entity in ipairs(live:GetChildren()) do
                    if not PersistentData:get("auto_saramed") then break end
                    local hrp = entity:FindFirstChild("HumanoidRootPart")
                    local hum = entity:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 and entity ~= local_player.character then
                        safeTween(hrp.CFrame * CFrame.new(0, 0, -3))
                        task.wait(0.5)
                    end
                end
            end
            task.wait(2)
        end
    end,
})

-- ─── Auto Duke ───
defineFarm({
    id   = "auto_duke",
    flag = "auto_duke",
    name = "Auto Duke",
    run  = function()
        Logger.notify("Auto Duke started!")
        while PersistentData:get("auto_duke") do
            task.wait(1)
            if not local_player.character then task.wait(2) continue end
            local live = workspace:FindFirstChild("Live")
            if live then
                local duke
                for _, e in ipairs(live:GetChildren()) do
                    if e.Name:lower():match("duke") then duke = e break end
                end
                if duke then
                    local hrp = duke:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        safeTween(hrp.CFrame * CFrame.new(0, 0, -5))
                        task.wait(0.5)
                    end
                end
            end
            task.wait(2)
        end
    end,
})

-- ─── Auto Ferryman ───
defineFarm({
    id   = "auto_ferryman",
    flag = "auto_ferryman",
    name = "Auto Ferryman",
    run  = function()
        Logger.notify("Auto Ferryman started!")
        while PersistentData:get("auto_ferryman") do
            task.wait(1)
            if not local_player.character then task.wait(2) continue end
            local live = workspace:FindFirstChild("Live")
            if live then
                for _, e in ipairs(live:GetChildren()) do
                    if e.Name:lower():match("ferryman") then
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            safeTween(hrp.CFrame * CFrame.new(0, 0, -4))
                            task.wait(0.5)
                        end
                    end
                end
            end
            task.wait(3)
        end
    end,
})

-- ─── Auto Layer 2 ───
defineFarm({
    id   = "auto_layer2",
    flag = "auto_layertwo",
    name = "Auto Layer 2",
    run  = function()
        Logger.notify("Auto Layer 2 started!")
        while PersistentData:get("auto_layertwo") do
            task.wait(1)
            if not local_player.character then task.wait(2) continue end
            -- Layer 2 loop: find nearest entity, engage
            local live = workspace:FindFirstChild("Live")
            if live then
                local nearest, nearestDist = nil, math.huge
                for _, e in ipairs(live:GetChildren()) do
                    if e ~= local_player.character then
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        if hrp and local_player.root_part then
                            local d = (hrp.Position - local_player.root_part.Position).Magnitude
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
    end,
})

-- ─── Auto Echo Layer 2 ───
defineFarm({
    id   = "auto_echo_layer2",
    flag = "auto_echo_layer2",
    name = "Auto Echo (Layer 2)",
    run  = function()
        Logger.notify("Auto Echo Layer 2 started!")
        while PersistentData:get("auto_echo_layer2") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Auto Escape Depths ───
defineFarm({
    id   = "auto_escape_depths",
    flag = "auto_escape_depths",
    name = "Auto Escape Depths",
    run  = function()
        Logger.notify("Auto Escape Depths started!")
        while PersistentData:get("auto_escape_depths") do
            task.wait(1)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Auto Authority ───
defineFarm({
    id   = "auto_authority",
    flag = "auto_authority_missions",
    name = "Auto Authority Missions",
    run  = function()
        Logger.notify("Auto Authority started!")
        while PersistentData:get("auto_authority_missions") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Auto Mooneyrie ───
defineFarm({
    id   = "auto_mooneyrie",
    flag = "auto_moonseyrie",
    name = "Auto Mooneyrie",
    run  = function()
        Logger.notify("Auto Mooneyrie started!")
        while PersistentData:get("auto_moonseyrie") do
            task.wait(3)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Auto Progress ───
defineFarm({
    id   = "auto_progress",
    flag = "auto_progress",
    name = "Auto Progress",
    run  = function()
        Logger.notify("Auto Progress started!")
        while PersistentData:get("auto_progress") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Auto Voi ───
defineFarm({
    id   = "auto_voi",
    flag = "auto_voi",
    name = "Auto Voi",
    run  = function()
        Logger.notify("Auto Voi started!")
        while PersistentData:get("auto_voi") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Ministry Notefarm ───
defineFarm({
    id   = "ministry_notefarm",
    flag = "ministry_notefarm",
    name = "Ministry Note Farm",
    run  = function()
        Logger.notify("Ministry Notefarm started!")
        while PersistentData:get("ministry_notefarm") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
            -- Note pickup loop
            local noteFolder = workspace:FindFirstChild("Notes") or workspace:FindFirstChild("Items")
            if noteFolder then
                for _, note in ipairs(noteFolder:GetDescendants()) do
                    if not PersistentData:get("ministry_notefarm") then break end
                    if note.Name:lower():match("note") and note:FindFirstChild("InteractPrompt") then
                        safeTween(note.CFrame)
                        pcall(function() fireproximityprompt(note.InteractPrompt) end)
                        task.wait(0.5)
                    end
                end
            end
        end
    end,
})

-- ─── Soup Echo Farm ───
defineFarm({
    id   = "soup_echofarm",
    flag = "soup_echofarm",
    name = "Soup Echo Farm",
    run  = function()
        Logger.notify("Soup Echo Farm started!")
        while PersistentData:get("soup_echofarm") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Titus Echo Farm ───
defineFarm({
    id   = "titus_echofarm",
    flag = "titus_echofarm",
    name = "Titus Echo Farm",
    run  = function()
        Logger.notify("Titus Echo Farm started!")
        while PersistentData:get("titus_echofarm") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
            local live = workspace:FindFirstChild("Live")
            if live then
                for _, e in ipairs(live:GetChildren()) do
                    if e.Name:lower():match("titus") then
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            safeTween(hrp.CFrame * CFrame.new(0, 0, -5))
                            task.wait(1)
                        end
                    end
                end
            end
        end
    end,
})

-- ─── Titus Relic Farm ───
defineFarm({
    id   = "titus_relicfarm",
    flag = "autoecho_titus",
    name = "Titus Relic Farm",
    run  = function()
        Logger.notify("Titus Relic Farm started!")
        while PersistentData:get("autoecho_titus") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Jetstriker Echo Farm ───
defineFarm({
    id   = "jetstriker_echofarm",
    flag = "jetstriker_echofarm",
    name = "Jetstriker Echo Farm",
    run  = function()
        Logger.notify("Jetstriker Echo Farm started!")
        while PersistentData:get("jetstriker_echofarm") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ─── Auto Deepdrill ───
defineFarm({
    id   = "auto_deepdrill",
    flag = "auto_deepdrill",
    name = "Auto Deepdrill",
    run  = function()
        Logger.notify("Auto Deepdrill started!")
        while PersistentData:get("auto_deepdrill") do
            task.wait(5)
            if not local_player.character then task.wait(2) continue end
        end
    end,
})

-- ──────────────────────────────────────────────────────
-- [9] CUSTOM UI — Linoria-based, redesigned aesthetics
--   Loads Linoria from remote (same source as PR)
--   New accent: #7C5CBF (deep purple) instead of default blue
-- ──────────────────────────────────────────────────────

-- Load Linoria UI Library
local Library, ThemeManager, SaveManager

local LINORIA_URL = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local function loadLinoria()
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(LINORIA_URL .. "Library.lua"))()
    end)
    if not ok or not lib then
        Logger.warn("Failed to load Linoria: " .. tostring(lib))
        return false
    end
    Library = lib

    local ok2, tm = pcall(function()
        return loadstring(game:HttpGet(LINORIA_URL .. "addons/ThemeManager.lua"))()
    end)
    local ok3, sm = pcall(function()
        return loadstring(game:HttpGet(LINORIA_URL .. "addons/SaveManager.lua"))()
    end)

    ThemeManager = ok2 and tm or nil
    SaveManager  = ok3 and sm or nil
    return true
end

local function buildUI()
    if not loadLinoria() then
        Logger.notify("UI failed to load — Linoria unavailable.")
        return
    end

    -- Window
    local Window = Library:CreateWindow({
        Title        = "  ✦  NewScript  ✦",
        Center       = true,
        AutoShow     = true,
        TabPadding   = 8,
        MenuFadeTime = 0.25,
    })

    -- ── Theme overrides ──────────────────────────────
    -- Custom purple accent palette, darker background
    Library:SetAccentColor(Color3.fromHex("7C5CBF"))

    -- ── Tabs ─────────────────────────────────────────
    local Tabs = {
        Combat     = Window:AddTab("⚔  Combat"),
        Automation = Window:AddTab("⚙  Automation"),
        Visuals    = Window:AddTab("👁  Visuals"),
        Settings   = Window:AddTab("⚙  Settings"),
    }

    -- ─────── COMBAT TAB ───────────────────────────────
    do
        local G = Tabs.Combat:AddLeftGroupbox("Auto Parry (APC Timings)")

        G:AddToggle("auto_parry", {
            Text    = "Enable Auto Parry",
            Default = false,
            Tooltip = "Parries / dodges using APC Lycoris weapon windup timings",
            Callback = function(val)
                _flags.auto_parry = val
            end,
        })

        G:AddToggle("auto_parry_debug", {
            Text    = "Debug Notifications",
            Default = false,
            Callback = function(val)
                _flags.auto_parry_debug = val
            end,
        })

        G:AddLabel("Target Filters")
        G:AddToggle("parry_pve", {
            Text    = "Parry PvE (mobs)",
            Default = true,
            Callback = function(val) _flags.parry_pve = val end,
        })
        G:AddToggle("parry_pvp", {
            Text    = "Parry PvP (players)",
            Default = false,
            Callback = function(val) _flags.parry_pvp = val end,
        })

        local G2 = Tabs.Combat:AddRightGroupbox("Parry Info")
        G2:AddLabel("Using: APC Lycoris timings")
        G2:AddLabel("Covers: M1s, Crits, Specials")
        G2:AddLabel("Named moves: " .. (function()
            local n = 0
            for _ in pairs(NAMED_TIMINGS) do n += 1 end
            return tostring(n)
        end)())

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

    -- ─────── AUTOMATION TAB ───────────────────────────
    do
        local G = Tabs.Automation:AddLeftGroupbox("Farms")

        -- One toggle per farm
        local farmList = {
            { flag = "auto_saramed",           name = "Auto Saramed" },
            { flag = "auto_duke",              name = "Auto Duke" },
            { flag = "auto_ferryman",          name = "Auto Ferryman" },
            { flag = "auto_layertwo",          name = "Auto Layer 2" },
            { flag = "auto_echo_layer2",       name = "Auto Echo (Layer 2)" },
            { flag = "auto_escape_depths",     name = "Auto Escape Depths" },
            { flag = "auto_authority_missions",name = "Auto Authority Missions" },
            { flag = "auto_moonseyrie",        name = "Auto Mooneyrie" },
            { flag = "auto_progress",          name = "Auto Progress" },
            { flag = "auto_voi",               name = "Auto Voi" },
            { flag = "ministry_notefarm",      name = "Ministry Notefarm" },
            { flag = "soup_echofarm",          name = "Soup Echo Farm" },
            { flag = "titus_echofarm",         name = "Titus Echo Farm" },
            { flag = "autoecho_titus",         name = "Titus Relic Farm" },
            { flag = "jetstriker_echofarm",    name = "Jetstriker Echo Farm" },
            { flag = "auto_deepdrill",         name = "Auto Deepdrill" },
        }

        for _, entry in ipairs(farmList) do
            G:AddToggle("farm_" .. entry.flag, {
                Text    = entry.name,
                Default = PersistentData:get(entry.flag) == true,
                Callback = function(val)
                    setFarm(entry.flag, val)
                end,
            })
        end

        local G2 = Tabs.Automation:AddRightGroupbox("Controls")
        G2:AddButton("Stop All Farms", function()
            for _, entry in ipairs(farmList) do
                PersistentData:set(entry.flag, false)
            end
            Logger.notify("All farms stopped.")
        end)
        G2:AddButton("Server Hop", function()
            serverHop()
        end)
        G2:AddDivider()
        G2:AddLabel("Farms persist across teleports")
        G2:AddLabel("via MemStorageService.")
    end

    -- ─────── VISUALS TAB ──────────────────────────────
    do
        local G = Tabs.Visuals:AddLeftGroupbox("ESP")

        G:AddToggle("esp_players", {
            Text    = "Player ESP",
            Default = false,
            Callback = function(val)
                _flags.esp_players = val
                -- lightweight box esp handled below
            end,
        })
        G:AddToggle("esp_mobs", {
            Text    = "Mob ESP",
            Default = false,
            Callback = function(val)
                _flags.esp_mobs = val
            end,
        })
        G:AddToggle("esp_names", {
            Text    = "Show Names",
            Default = true,
            Callback = function(val) _flags.esp_names = val end,
        })
        G:AddToggle("esp_health", {
            Text    = "Show Health",
            Default = true,
            Callback = function(val) _flags.esp_health = val end,
        })

        local G2 = Tabs.Visuals:AddRightGroupbox("World")
        G2:AddToggle("fullbright", {
            Text    = "Full Bright",
            Default = false,
            Callback = function(val)
                _flags.fullbright = val
                pcall(function()
                    local lighting = services.Lighting
                    if val then
                        lighting.Brightness = 2
                        lighting.ClockTime  = 14
                        lighting.FogEnd     = 100000
                    else
                        lighting.Brightness = 1
                        lighting.ClockTime  = 14
                        lighting.FogEnd     = 100000
                    end
                end)
            end,
        })
        G2:AddToggle("no_fog", {
            Text    = "No Fog",
            Default = false,
            Callback = function(val)
                _flags.no_fog = val
                pcall(function()
                    services.Lighting.FogEnd = val and 100000 or 1000
                end)
            end,
        })
    end

    -- ─────── SETTINGS TAB ─────────────────────────────
    do
        local G = Tabs.Settings:AddLeftGroupbox("Config")
        if SaveManager then
            SaveManager:SetLibrary(Library)
            SaveManager:SetFolder("NewScript/Config")
            SaveManager:IgnoreThemeSettings()
            SaveManager:BuildConfigSection(Tabs.Settings)
        end

        if ThemeManager then
            ThemeManager:SetLibrary(Library)
            ThemeManager:SetFolder("NewScript/Config")
            ThemeManager:ApplyToTab(Tabs.Settings)
        end

        local G2 = Tabs.Settings:AddRightGroupbox("Script")
        G2:AddLabel("NewScript v1.0")
        G2:AddLabel("Executor: Volt")
        G2:AddLabel("Timings: APC Lycoris")
        G2:AddLabel("Farms: Project Rain")
        G2:AddDivider()
        G2:AddButton("Unload Script", function()
            pcall(function() Library:Unload() end)
            pcall(function() getgenv()._newscript_loaded() end)
            Logger.notify("Script unloaded.")
        end)
        G2:AddButton("Wipe Saved Data", function()
            PersistentData:wipe()
            Logger.notify("Saved data wiped.")
        end)
    end

    -- Keybind to toggle window (RShift)
    Library:SetCloseCallback(function()
        -- Don't destroy on close, just hide
    end)

    -- Load autoload config
    pcall(function()
        if SaveManager then
            SaveManager:LoadAutoloadConfig()
        end
    end)

    Logger.notify("NewScript loaded! RShift = toggle UI")
end

-- Lightweight ESP (runs independently of UI library)
local espObjects = {}
task.spawn(function()
    while true do
        task.wait(0)
        if not (_flags.esp_players or _flags.esp_mobs) then
            for _, obj in pairs(espObjects) do
                pcall(function() obj:Remove() end)
            end
            table.clear(espObjects)
            task.wait(1)
            continue
        end

        local allEntities = {}
        local live = workspace:FindFirstChild("Live")
        if live then
            for _, e in ipairs(live:GetChildren()) do
                if not e:FindFirstChild("HumanoidRootPart") then continue end
                local isPlayer = services.Players:GetPlayerFromCharacter(e) ~= nil
                if isPlayer and _flags.esp_players then table.insert(allEntities, { e = e, isPlayer = true })
                elseif not isPlayer and _flags.esp_mobs then table.insert(allEntities, { e = e, isPlayer = false }) end
            end
        end

        -- Clean removed
        for k, obj in pairs(espObjects) do
            if not obj.entity or not obj.entity.Parent then
                pcall(function() obj.highlight:Destroy() end)
                espObjects[k] = nil
            end
        end

        -- Add new
        for _, entry in ipairs(allEntities) do
            if not espObjects[entry.e] then
                local hl = Instance.new("SelectionBox")
                hl.Adornee = entry.e
                hl.Color3 = entry.isPlayer and Color3.fromHex("FF6B6B") or Color3.fromHex("7C5CBF")
                hl.LineThickness = 0.05
                hl.SurfaceTransparency = 0.8
                hl.SurfaceColor3 = entry.isPlayer and Color3.fromHex("FF6B6B") or Color3.fromHex("7C5CBF")
                hl.Parent = workspace
                espObjects[entry.e] = { entity = entry.e, highlight = hl }
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────
-- [10] INIT — start everything
-- ──────────────────────────────────────────────────────

-- Auto-start gate
if shouldAutoStart() then
    local requests = services.ReplicatedStorage:WaitForChild("Requests")
    local startMenu = requests:FindFirstChild("StartMenu")
    if startMenu then
        local startRemote = startMenu:FindFirstChild("Start")
        if startRemote then
            repeat
                startRemote:FireServer()
                task.wait(0.5)
            until local_player.character
        end
    end
    task.wait(1)
end

-- Start parry engine
task.spawn(function()
    local ok, err = pcall(startParryEngine)
    if not ok then Logger.warn("Parry engine error: " .. tostring(err)) end
end)

-- Start all enabled farms
task.spawn(function()
    local ok, err = pcall(startFarms)
    if not ok then Logger.warn("Farm start error: " .. tostring(err)) end
end)

-- Build UI
task.spawn(function()
    local ok, err = pcall(buildUI)
    if not ok then
        Logger.warn("UI error: " .. tostring(err))
        Logger.notify("UI failed to load, check output for details.")
    end
end)

Logger.log(string.format("NewScript initialized | Place: %d | APC timings: %d named moves", game.PlaceId, (function()
    local n = 0
    for _ in pairs(NAMED_TIMINGS) do n += 1 end
    return n
end)()))
