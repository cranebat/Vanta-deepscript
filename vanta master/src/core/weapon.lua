local Weapon = {}

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
            or findThrownHandWeapon(entity.Name)
    return hw
end

return Weapon
