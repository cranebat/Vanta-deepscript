local _flags            = getgenv().ns_flags
local masterMaid        = getgenv().masterMaid
local services          = getgenv().services
local local_player      = getgenv().local_player
local Latency           = getgenv().Latency
local Weapon            = getgenv().Weapon
local DefendActionManager = getgenv().DefendActionManager

-- Named task spawner (prevents duplicate spawns for same name)
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

-- ─── Named attack timings (APC / Lycoris) ───
local NAMED_TIMINGS = {
    -- NPC Specials
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

local function findNamedTiming(animName)
    for pattern, timing in pairs(NAMED_TIMINGS) do
        if animName:find(pattern) then return timing end
    end
    return nil
end

-- ─── Weapon windup handler (APC / Lycoris WeaponTest.lua) ───
local function weaponTestHandler(entity, track)
    -- Evengarde special
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
    if not entity:FindFirstChild("HumanoidRootPart") then return end

    local windup

    if     data.type == "Greataxe"   and track.Speed ~= 1.0 then windup = (0.171 / track.Speed) + 0.120
    elseif data.type == "Greataxe"                           then windup = (0.171 / track.Speed) + 0.250 / data.ss
    elseif data.type == "Greathammer" and track.Speed ~= 1.0 then windup = (0.150 / track.Speed) + 0.200
    elseif data.type == "Greathammer"                        then windup = (0.150 / track.Speed) + 0.250 / data.ss
    elseif data.type == "Greatcannon" and track.Speed ~= 1.0 then windup = (0.155 / track.Speed) + 0.160
    elseif data.type == "Greatcannon"                        then windup = (0.155 / track.Speed) + 0.300
    elseif data.type == "Rapier"                             then windup = (0.155 / track.Speed) + 0.120
    elseif data.type == "Bow" then
        local attach = workspace.Thrown and workspace.Thrown:FindFirstChild("Attach_" .. entity.Name)
        local tip = attach and attach:FindFirstChild("HandWeapon") and attach.HandWeapon:FindFirstChild("TipAttachment")
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
    elseif data.type == "Pistol" then
        local ispeed = track.Speed
        repeat task.wait() until track.Speed ~= ispeed
        windup = track.Speed == 0.0 and 0.100 or (0.075 / track.Speed)
    elseif data.type == "Rifle" and track.Animation.AnimationId:match("2") then
        local ispeed = track.Speed
        repeat task.wait() until track.Speed ~= ispeed
        windup = track.Speed == 0.0 and 0.100 or (0.150 / track.Speed)
    elseif data.type == "Rifle"      then windup = (0.174 / track.Speed) + 0.125
    elseif data.type == "Club"       then windup = (0.180 / track.Speed) + 0.100
    elseif data.type == "Twinblade"  then windup = (0.200 / track.Speed) + 0.050
    elseif data.type == "Spear"      then windup = (0.150 / track.Speed) + 0.100
    elseif data.type == "Greatsword" then windup = (0.158 / track.Speed) + 0.150
    elseif data.type == "Fist" then
        if entity.Name:lower():match("titus") then
            repeat task.wait() until track.Speed > 0
            local finalSpeed = track.Speed + 0.2
            local delay_ms = (565 * 0.76) / finalSpeed
            task.wait(math.max(0, (delay_ms - Latency:get_ping() * 1000) / 1000))
            if _flags.auto_parry then DefendActionManager:queue_parry(entity) end
            return
        end
        windup = (0.140 / track.Speed) + 0.130
    elseif data.type == "Dagger" then windup = (0.200 / track.Speed) + 0.075
    elseif data.type == "Staff"  then windup = 0.350
    elseif data.type == "Sword"  then windup = (0.200 / track.Speed) + 0.100
    end

    if not windup then return end

    local wait_s = math.max(0, (windup * 1000 - Latency:get_ping() * 1000) / 1000)
    if wait_s > 0 then task.wait(wait_s) end
    if not track.IsPlaying then return end
    if not _flags.auto_parry then return end

    DefendActionManager:queue_parry(entity)
end

-- ─── Animation name resolver ───
local function getAnimName(track)
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

-- ─── Per-entity animator watcher ───
local watchedEntities = {}

local function attachEntityWatcher(entity)
    if watchedEntities[entity] then return end
    local animator = entity:FindFirstChild("Animator", true)
    if not animator then return end

    local conn
    conn = animator.AnimationPlayed:Connect(function(track)
        if not _flags.auto_parry then return end
        if entity == local_player.character then return end
        if not track or not track.Animation then return end

        task.spawn(function()
            task.wait(1 / 60)
            local animName = getAnimName(track)
            local named = findNamedTiming(animName)

            if named then
                local wait_s = math.max(0, (named.wait - Latency:get_ping() * 1000) / 1000)
                if wait_s > 0 then task.wait(wait_s) end
                if not _flags.auto_parry then return end
                if named.type == "dodge" then
                    DefendActionManager:queue_dodge(entity)
                else
                    DefendActionManager:queue_parry(entity)
                end
            else
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

-- ─── Start the parry engine ───
local function start()
    local live = workspace:WaitForChild("Live", 10)
    if not live then return end

    for _, entity in ipairs(live:GetChildren()) do
        task.spawn(function()
            local s = tick()
            repeat task.wait() until entity:FindFirstChild("Animator", true) or tick() - s > 5
            if entity:IsA("Model") then attachEntityWatcher(entity) end
        end)
    end

    masterMaid:give(live.ChildAdded:Connect(function(entity)
        task.spawn(function()
            local s = tick()
            repeat task.wait() until entity:FindFirstChild("Animator", true) or tick() - s > 5
            if entity:IsA("Model") then attachEntityWatcher(entity) end
        end)
    end))

    -- Projectile auto-parry (ArdourBall, BoneSpear, Bullet)
    local thrown = workspace:FindFirstChild("Thrown") or workspace:WaitForChild("Thrown", 10)
    if thrown then
        masterMaid:give(thrown.ChildAdded:Connect(function(part)
            if not _flags.auto_parry then return end
            task.spawn(function()
                if part.Name == "ArdourBall2" then
                    repeat task.wait()
                    until not part.Parent or (part.Position - local_player.root_part.Position).Magnitude < 15
                    if not part.Parent then return end
                    for _, c in ipairs(live:GetChildren()) do
                        if c.Name:match("nomad") then DefendActionManager:queue_parry(c) break end
                    end

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

return { start = start, NAMED_TIMINGS = NAMED_TIMINGS }
