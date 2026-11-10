-- FPS Booster BẢN CỰC MẠNH (chấp nhận xấu để lấy FPS tối đa)
-- Bấm RightControl để bật/tắt hẳn việc vẽ 3D (màn hình đen, FPS cao nhất, hợp để treo máy).
-- Cách dùng: đặt _G.Settings (tuỳ chọn) rồi chạy file này.

local Default = {
    Players = {
        ["Ignore Me"] = true,      -- Giữ nhân vật của bạn nguyên vẹn
        ["Ignore Others"] = false, -- Xử lý luôn nhân vật người khác
    },
    Meshes = { Destroy = true, LowDetail = true },
    Images = { Invisible = true, Destroy = true },
    ["No Particles"] = true,
    ["No Camera Effects"] = true,
    ["No Explosions"] = true,
    ["No Clothes"] = true,
    ["Low Water Graphics"] = true,
    ["No Shadows"] = true,
    ["Low Rendering"] = true,
    ["Low Quality Parts"] = true,
    ["No Lights"] = true,
    ["No Surface Appearance"] = true,
    ["No Sky"] = true,
    ["No Highlights"] = true,
    ["No Terrain Decoration"] = true,
    ["Unlock FPS"] = true,
    -- Thêm so với bản Mạnh
    ["Hide Others"] = true,              -- Người chơi khác trong suốt
    ["No Accessories"] = true,           -- Xoá mũ/tóc/phụ kiện (của người khác)
    ["Freeze Others Animations"] = true, -- Tắt animation của người chơi khác (giảm CPU)
    ["No World GUIs"] = true,            -- Tắt BillboardGui/SurfaceGui trong map (tên, biển hiệu)
    ["Mute Sounds"] = false,             -- Tắt toàn bộ âm thanh
    ["3D Rendering Off"] = false,        -- Tắt vẽ 3D ngay khi chạy (màn hình đen)
    ["Toggle Render Key"] = Enum.KeyCode.RightControl,
}

local function merge(base, over)
    if type(over) ~= "table" then return base end
    for k, v in pairs(over) do
        if type(v) == "table" and type(base[k]) == "table" then
            merge(base[k], v)
        else
            base[k] = v
        end
    end
    return base
end
local S = merge(Default, _G.Settings)

local Players   = game:GetService("Players")
local Lighting  = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Trả về Player sở hữu nhân vật chứa instance này (nếu có)
local function ownerPlayer(inst)
    local p = inst
    while p and p ~= Workspace do
        if p:IsA("Model") then
            local plr = Players:GetPlayerFromCharacter(p)
            if plr then return plr end
        end
        p = p.Parent
    end
    return nil
end

local function optimize(inst)
    if not inst.Parent then return end

    local plr = ownerPlayer(inst)
    local isOther = false
    if plr then
        if plr == LocalPlayer then
            if S.Players["Ignore Me"] then return end
        else
            if S.Players["Ignore Others"] then return end
            isOther = true
        end
    end

    if inst:IsA("BasePart") then
        if S["No Shadows"] then inst.CastShadow = false end
        if S["Low Quality Parts"] then
            inst.Material = Enum.Material.SmoothPlastic
            inst.Reflectance = 0
        end
        if isOther and S["Hide Others"] then inst.Transparency = 1 end
        if inst:IsA("MeshPart") then
            if S.Meshes.LowDetail then
                inst.RenderFidelity = Enum.RenderFidelity.Performance
            end
            if S.Meshes.Destroy then inst.TextureID = "" end
        end

    elseif inst:IsA("Accessory") then
        if plr and S["No Accessories"] then inst:Destroy() end

    elseif inst:IsA("Animator") then
        if isOther and S["Freeze Others Animations"] then inst:Destroy() end

    elseif inst:IsA("Humanoid") then
        if isOther then
            inst.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

    elseif inst:IsA("SpecialMesh") then
        if S.Meshes.Destroy then inst:Destroy() end

    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        if S.Images.Destroy then
            inst:Destroy()
        elseif S.Images.Invisible then
            inst.Transparency = 1
        end

    elseif inst:IsA("SurfaceAppearance") then
        if S["No Surface Appearance"] then inst:Destroy() end

    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
        or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
        if S["No Particles"] then inst.Enabled = false end

    elseif inst:IsA("Light") then
        if S["No Lights"] then inst.Enabled = false end

    elseif inst:IsA("Highlight") then
        if S["No Highlights"] then inst.Enabled = false end

    elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
        if S["No World GUIs"] then inst.Enabled = false end

    elseif inst:IsA("PostEffect") then
        if S["No Camera Effects"] then inst.Enabled = false end

    elseif inst:IsA("Sky") or inst:IsA("Atmosphere") or inst:IsA("Clouds") then
        if S["No Sky"] then inst:Destroy() end

    elseif inst:IsA("Explosion") then
        if S["No Explosions"] then
            inst.BlastPressure = 1
            inst.BlastRadius = 1
            inst.Visible = false
        end

    elseif inst:IsA("Clothing") or inst:IsA("ShirtGraphic") then
        if S["No Clothes"] then inst:Destroy() end
    end
end

-- Cài đặt toàn cục
pcall(function()
    if S["No Shadows"] then Lighting.GlobalShadows = false end
    if S["No Camera Effects"] then Lighting.FogEnd = 9e9 end

    local t = Workspace.Terrain
    if S["Low Water Graphics"] then
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
    end
    if S["No Terrain Decoration"] and sethiddenproperty then
        sethiddenproperty(t, "Decoration", false)
    end

    if S["Low Rendering"] then
        local r = settings().Rendering
        r.QualityLevel = Enum.QualityLevel.Level01
        r.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    end

    if S["Unlock FPS"] and setfpscap then
        setfpscap(999)
    end
end)

if S["Mute Sounds"] then
    pcall(function()
        UserSettings():GetService("UserGameSettings").MasterVolume = 0
    end)
end

-- Bật/tắt vẽ 3D
local renderOn = true
local function setRender(on)
    renderOn = on
    pcall(function() RunService:Set3dRenderingEnabled(on) end)
end
if S["3D Rendering Off"] then setRender(false) end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == S["Toggle Render Key"] then
        setRender(not renderOn)
    end
end)

-- Quét lần đầu theo đợt để không bị đơ
local BATCH = 800
local function scan(root)
    local count = 0
    for _, inst in ipairs(root:GetDescendants()) do
        pcall(optimize, inst)
        count += 1
        if count % BATCH == 0 then task.wait() end
    end
end

task.spawn(function()
    scan(Workspace)
    scan(Lighting)
end)

local function onAdded(inst)
    task.defer(function()
        pcall(optimize, inst)
    end)
end
Workspace.DescendantAdded:Connect(onAdded)
Lighting.DescendantAdded:Connect(onAdded)
