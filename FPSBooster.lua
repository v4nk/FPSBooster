-- FPS Booster BẢN MẠNH (mặc định tối đa FPS, đánh đổi hình ảnh)
-- Cách dùng: đặt _G.Settings (tuỳ chọn) rồi chạy file này.

local Default = {
    Players = {
        ["Ignore Me"] = true,
        ["Ignore Others"] = true,
    },
    Meshes = {
        Destroy = true,    -- Xoá SpecialMesh, bỏ texture MeshPart
        LowDetail = true,  -- RenderFidelity = Performance
    },
    Images = {
        Invisible = true,
        Destroy = true,    -- Xoá hẳn Decal/Texture
    },
    ["No Particles"] = true,
    ["No Camera Effects"] = true,
    ["No Explosions"] = true,
    ["No Clothes"] = true,
    ["Low Water Graphics"] = true,
    ["No Shadows"] = true,
    ["Low Rendering"] = true,
    ["Low Quality Parts"] = true,
    -- Các tuỳ chọn thêm so với bản thường
    ["No Lights"] = true,          -- Tắt PointLight/SpotLight/SurfaceLight (ăn FPS khá nhiều)
    ["No Surface Appearance"] = true, -- Xoá SurfaceAppearance (texture PBR)
    ["No Sky"] = true,             -- Xoá Sky/Atmosphere/Clouds
    ["No Highlights"] = true,      -- Tắt Highlight
    ["No Terrain Decoration"] = true, -- Tắt cỏ trên địa hình (cần executor hỗ trợ)
    ["Unlock FPS"] = true,         -- Mở khoá giới hạn FPS (cần executor hỗ trợ)
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
local LocalPlayer = Players.LocalPlayer

local function isIgnored(inst)
    local p = inst
    while p and p ~= Workspace do
        if p:IsA("Model") then
            local plr = Players:GetPlayerFromCharacter(p)
            if plr then
                if plr == LocalPlayer then
                    return S.Players["Ignore Me"]
                end
                return S.Players["Ignore Others"]
            end
        end
        p = p.Parent
    end
    return false
end

local function optimize(inst)
    if not inst.Parent or isIgnored(inst) then return end

    if inst:IsA("BasePart") then
        if S["No Shadows"] then inst.CastShadow = false end
        if S["Low Quality Parts"] then
            inst.Material = Enum.Material.SmoothPlastic
            inst.Reflectance = 0
        end
        if inst:IsA("MeshPart") then
            if S.Meshes.LowDetail then
                inst.RenderFidelity = Enum.RenderFidelity.Performance
            end
            if S.Meshes.Destroy then
                inst.TextureID = ""
            end
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

-- Cài đặt toàn cục (chỉ làm một lần)
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

-- Quét lần đầu theo đợt để không bị đơ
local BATCH = 600
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
