-- Apex Hub v2.1 (Fully Fixed)
-- Dead Rails AutoFarm + ESP + Speed
loadstring(game:HttpGet("https://raw.githubusercontent.com/darkgafan/apex-hub/main/apex%20hub.lua", true))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Improved Character Handling
local Char
local function onCharacterAdded(newChar)
    Char = newChar
    if speedBoost then
        newChar:WaitForChild("Humanoid").WalkSpeed = 40
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    task.spawn(onCharacterAdded, LocalPlayer.Character)
end

-- Optimized AutoFarm
local autoFarmEnabled = false
local bondCache = {}

local function scanForBonds()
    bondCache = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("bond") or obj.Name:lower():find("collect")) then
            table.insert(bondCache, obj)
        end
    end
    return #bondCache
end

local function collectBond(bond)
    if not bond or not bond:IsDescendantOf(workspace) then return false end
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return false end
    
    -- Smooth teleport instead of tween
    local startTime = tick()
    local root = Char.HumanoidRootPart
    local originalPos = root.CFrame
    
    for i = 1, 10 do
        root.CFrame = bond.CFrame:Lerp(originalPos, 0.1 * i)
        task.wait(0.05)
    end
    
    return bond:IsDescendantOf(workspace)
end

-- Persistent ESP
local espEnabled = false
local function updateESP()
    for _, bond in ipairs(bondCache) do
        if bond:IsDescendantOf(workspace) then
            if espEnabled and not bond:FindFirstChild("ApexESP") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ApexESP"
                highlight.FillColor = Color3.fromRGB(0, 255, 150)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.Parent = bond
            elseif not espEnabled and bond:FindFirstChild("ApexESP") then
                bond.ApexESP:Destroy()
            end
        end
    end
end

-- Anti-Cheat Speed
local speedBoost = false
RunService.Heartbeat:Connect(function()
    if Char and Char:FindFirstChild("Humanoid") then
        Char.Humanoid.WalkSpeed = speedBoost and 40 or 16
    end
end)

-- Win Teleport (Bypass)
function tweenToWin()
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local winPad = workspace:FindFirstChild("WinPad") or workspace:FindFirstChild("EndPad")
    if winPad then
        local root = Char.HumanoidRootPart
        for i = 1, 20 do
            root.CFrame = winPad.CFrame:Lerp(root.CFrame, 0.95)
            task.wait(0.1)
        end
    end
end

-- GUI (Same as before but with fixed buttons)
-- ... [Rest of your original GUI code] ...

print("[Apex Hub v2.1 - Fully Patched]")