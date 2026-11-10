-- FPS Booster (bản tối ưu, chạy độc lập, không tải code từ bên ngoài)
-- Cách dùng: đặt _G.Settings (tuỳ chọn) rồi chạy file này. Không đặt thì dùng mặc định bên dưới.

local Default = {
    Players = {
        ["Ignore Me"] = true,     -- Không đụng vào nhân vật của bạn
        ["Ignore Others"] = true, -- Không đụng vào nhân vật người khác
    },
    Meshes = {
        Destroy = false,   -- Xoá SpecialMesh, bỏ texture của MeshPart
        LowDetail = true,  -- MeshPart dùng RenderFidelity = Performance
    },
    Images = {
        Invisible = true,  -- Decal/Texture trong suốt
        Destroy = false,   -- Xoá hẳn Decal/Texture
    },
    ["No Particles"] = true,       -- Tắt ParticleEmitter, Trail, Beam, Smoke, Fire, Sparkles
    ["No Camera Effects"] = true,  -- Tắt PostEffect (Blur, Bloom, SunRays, ...)
    ["No Explosions"] = true,      -- Ẩn Explosion
    ["No Clothes"] = true,         -- Xoá quần áo
    ["Low Water Graphics"] = true, -- Nước đơn giản
    ["No Shadows"] = true,         -- Tắt bóng đổ
    ["Low Rendering"] = true,      -- Hạ quality level
    ["Low Quality Parts"] = true,  -- Material Plastic, bỏ Reflectance
}

-- Gộp cấu hình người dùng (_G.Settings) lên trên mặc định
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

-- Kiểm tra instance có thuộc nhân vật cần bỏ qua không (đi ngược lên cây cha)
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
            inst.Material = Enum.Material.Plastic
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

    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
        or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
        if S["No Particles"] then inst.Enabled = false end

    elseif inst:IsA("PostEffect") then
        if S["No Camera Effects"] then inst.Enabled = false end

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

    if S["Low Water Graphics"] then
        local t = Workspace.Terrain
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
    end

    if S["Low Rendering"] then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end)

-- Quét lần đầu theo từng đợt nhỏ để không bị đơ game
local BATCH = 400
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

-- Xử lý object mới xuất hiện (defer để character kịp gán cho Player)
local function onAdded(inst)
    task.defer(function()
        pcall(optimize, inst)
    end)
end
Workspace.DescendantAdded:Connect(onAdded)
Lighting.DescendantAdded:Connect(onAdded)
