--[[
    ██╗   ██╗ █████╗ ███╗   ██╗████████╗ █████╗
    ██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██╔══██╗
    ██║   ██║███████║██╔██╗ ██║   ██║   ███████║
    ╚██╗ ██╔╝██╔══██║██║╚██╗██║   ██║   ██╔══██║
     ╚████╔╝ ██║  ██║██║ ╚████║   ██║   ██║  ██║
      ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝
    Timings : APC / Lycoris Rewrite
    Farms   : Project Rain
    Executor: Volt  |  Keyless  |  Personal
--]]

-- ── Change this to your GitHub Raw URL ──────────────────────
local BASE_URL = "https://raw.githubusercontent.com/cranebat/Vanta-deepscript/main/vanta%20master/src/"
-- ─────────────────────────────────────────────────────────────

if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

local function loadModule(path)
    local src = game:HttpGet(BASE_URL .. path)
    local fn, err = loadstring(src, path)
    if not fn then error("[Vanta] Failed to compile " .. path .. ": " .. tostring(err)) end
    return fn()
end

-- ──────────────────────────────────────────────────────
-- [0] Anti-detection FIRST — before anything can print
-- ──────────────────────────────────────────────────────
loadModule("security/anti_detection.lua")

-- ──────────────────────────────────────────────────────
-- [1] Core globals
-- ──────────────────────────────────────────────────────
local _rcprint = getgenv()._rcprint
local function log(msg) _rcprint("[Vanta] " .. tostring(msg) .. "\n") end

-- Services
local services = setmetatable({}, {
    __index = function(_, k) return game:GetService(k) end
})
getgenv().services = services

-- Maid
local Maid = {} do
    Maid.__index = Maid
    function Maid.new() return setmetatable({ _tasks = {} }, Maid) end
    function Maid:give(t)
        table.insert(self._tasks, t)
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
getgenv().masterMaid = Maid.new()
getgenv().ns_flags   = {}

-- Detach guard
if getgenv()._vanta_loaded then
    pcall(getgenv()._vanta_loaded)
end
getgenv()._vanta_loaded = function()
    getgenv().masterMaid:clean()
end

-- KeyHandler (GC scan for Deepwoken's encrypted remotes)
local KeyHandler = {} do
    local cache = {}
    local heaven_key = 2754*(72%(0.6769230769205024*7*7%5%64%41/66+12)/54/(4/36+5.3655660377358485)+1*4%52*21/4%35/3)/35*38+(66+(8+4+5+2+19035.52631578947)/34+40%41/56%65*57+3381)+420+35*(0.3150684931506849+69+14/56+28+36)+(0.125+3)
    local remotes, enc_f
    local function scan_gc()
        if remotes and enc_f then return end
        for _, tbl in next, getgc(true) do
            if typeof(tbl) ~= "table" or getrawmetatable(tbl) then continue end
            if #tbl ~= 13 or tbl[9] ~= heaven_key then continue end
            remotes = tbl[12]; enc_f = tbl[13]; break
        end
    end
    task.spawn(function()
        while not (remotes and enc_f) do pcall(scan_gc); task.wait(0.5) end
        log("KeyHandler ready")
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

-- Local player
local lp = services.Players.LocalPlayer
local local_player = { instance = lp }
local function refreshLP()
    local char = lp.Character
    if char then
        local_player.character = char
        local_player.humanoid  = char:FindFirstChild("Humanoid")
        local_player.root_part = char:FindFirstChild("HumanoidRootPart")
    end
end
refreshLP()
lp.CharacterAdded:Connect(function() task.wait(0.1); refreshLP() end)
getgenv().local_player = local_player

-- Latency
local Latency = {} do
    local ping_stat = services.Stats:FindFirstChild("Data Ping", true)
    function Latency:get_ping()
        if not ping_stat then return 0 end
        local old = getthreadidentity(); setthreadidentity(8)
        local v = ping_stat:GetValue(); setthreadidentity(old)
        return v / 1000
    end
end
getgenv().Latency = Latency

-- PersistentData
local PersistentData = {} do
    local mss = services.MemStorageService
    local KEY = "vanta_persistent"
    if not mss:HasItem(KEY) then mss:SetItem(KEY, "{}") end
    function PersistentData:get(key, default)
        return services.HttpService:JSONDecode(mss:GetItem(KEY) or "{}")[key] or default
    end
    function PersistentData:set(key, val)
        local d = services.HttpService:JSONDecode(mss:GetItem(KEY) or "{}")
        d[key] = val
        mss:SetItem(KEY, services.HttpService:JSONEncode(d))
    end
    function PersistentData:wipe()
        mss:SetItem(KEY, "{}")
    end
end
getgenv().persistent_data = PersistentData

-- Folder setup
for _, path in ipairs({ "Vanta", "Vanta/Config", "Vanta/Assets" }) do
    if not isfolder(path) then makefolder(path) end
end

-- ──────────────────────────────────────────────────────
-- [2] Load core modules
-- ──────────────────────────────────────────────────────
getgenv().Weapon            = loadModule("core/weapon.lua")
getgenv().DefendActionManager = loadModule("core/defend_manager.lua")
local ParryEngine           = loadModule("core/parry_engine.lua")
local Automation            = loadModule("automation/farms.lua")
local BuildUI               = loadModule("ui/main_ui.lua")

-- ──────────────────────────────────────────────────────
-- [3] Auto-start gate
-- ──────────────────────────────────────────────────────
if Automation.shouldAutoStart() then
    pcall(function()
        local requests = services.ReplicatedStorage:WaitForChild("Requests")
        local startMenu = requests:FindFirstChild("StartMenu")
        if startMenu then
            local startRemote = startMenu:FindFirstChild("Start")
            if startRemote then
                repeat startRemote:FireServer(); task.wait(0.5)
                until local_player.character
            end
        end
    end)
    task.wait(1)
end

-- ──────────────────────────────────────────────────────
-- [4] Start everything
-- ──────────────────────────────────────────────────────
task.spawn(function()
    local ok, err = pcall(ParryEngine.start)
    if not ok then log("Parry engine error: " .. tostring(err)) end
end)

task.spawn(function()
    local ok, err = pcall(Automation.startFarms)
    if not ok then log("Farm start error: " .. tostring(err)) end
end)

task.spawn(function()
    local ok, err = pcall(BuildUI, Automation)
    if not ok then
        log("UI error: " .. tostring(err))
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Vanta", Text = "UI failed — check console", Duration = 5
            })
        end)
    end
end)

log("Vanta initialized | Place: " .. game.PlaceId)
