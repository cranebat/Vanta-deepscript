local KeyHandler        = getgenv().KeyHandler
local _flags            = getgenv().ns_flags
local masterMaid        = getgenv().masterMaid
local services          = getgenv().services

local DefendActionManager = {}
DefendActionManager._queue        = {}
DefendActionManager._handling     = {}
DefendActionManager._block_count  = 0
DefendActionManager._dodge_until  = 0
DefendActionManager._seq          = 0

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

function DefendActionManager:_do_dodge()
    pcall(function()
        local kb = require(services.ReplicatedStorage:WaitForChild("KeyBinds"))
        kb.ForceActionDown("Dodge")
        kb.ForceActionUp("Dodge")
    end)
end

masterMaid:give(services.RunService.Heartbeat:Connect(function()
    local now = tick()

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

return DefendActionManager
