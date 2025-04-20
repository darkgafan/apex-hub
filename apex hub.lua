-- File: dead_rails_autofarm.lua
-- Improved Dead Rails Auto Farm Script with GUI (Apex Hub - Neon Theme)
-- [v2.0] - Fixed win conditions, dynamic ESP, proper character handling

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

-- Save System
local SETTINGS_FILE = "DeadRailsSave.json"
local collectedBonds = 0
local totalBonds = 0
local savedData = {}
local startTime = tick()
local finishTime = 0

-- Character Handling
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

local function saveStats()
    pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode({
            bonds = collectedBonds,
            runtime = tick() - startTime
        }))
    end)
end

local function loadStats()
    pcall(function()
        if isfile(SETTINGS_FILE) then
            savedData = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            collectedBonds = savedData.bonds or 0
            startTime = tick() - (savedData.runtime or 0)
        end
    end)
end

local function resetStats()
    collectedBonds = 0
    totalBonds = 0
    finishTime = 0
    startTime = tick()
    if isfile(SETTINGS_FILE) then delfile(SETTINGS_FILE) end
end

loadStats()

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ApexHubGui"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 270, 0, 400)
Frame.Position = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Frame.BorderSizePixel = 0
Frame.BackgroundTransparency = 0.1
Frame.Parent = ScreenGui

local dragToggle, dragInput, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragToggle then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1.5
UIStroke.Color = Color3.fromRGB(0, 255, 150)
UIStroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "APEX HUB v2.0"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 45)
Status.TextColor3 = Color3.fromRGB(0, 255, 150)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.Gotham
Status.TextSize = 14
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Frame

local function updateStatus()
    local elapsed = math.floor(tick() - startTime)
    Status.Text = finishTime > 0
        and string.format("Time: %ds | Bonds: %d/%d | Win in %ds", elapsed, collectedBonds, totalBonds, finishTime)
        or string.format("Time: %ds | Bonds: %d/%d", elapsed, collectedBonds, totalBonds)
end

local function createButton(name, position, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 240, 0, 38)
    Button.Position = position
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(0, 255, 150)
    Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 16
    Button.AutoButtonColor = true
    Button.ClipsDescendants = true
    Button.Parent = Frame
    
    local ButtonStroke = Instance.new("UIStroke")
    ButtonStroke.Thickness = 1
    ButtonStroke.Color = Color3.fromRGB(0, 200, 100)
    ButtonStroke.Parent = Button
    
    Button.MouseButton1Click:Connect(callback)
    return Button
end

-- Auto Farm
local autoFarmEnabled = false
local bondCache = {}
local function scanForBonds()
    bondCache = {}
    totalBonds = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Bond" then
            table.insert(bondCache, obj)
            totalBonds += 1
        end
    end
end

local function collectBond(bond)
    if not bond or not bond:IsDescendantOf(workspace) then return end
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    
    local goal = {}
    goal.CFrame = bond.CFrame
    local tween = TweenService:Create(Char.HumanoidRootPart, TweenInfo.new(1), goal)
    tween:Play()
    tween.Completed:Wait()
    
    if bond:IsDescendantOf(workspace) then
        collectedBonds += 1
        updateStatus()
    end
end

local function autoFarmLoop()
    while autoFarmEnabled and task.wait(0.5) do
        scanForBonds()
        if totalBonds == 0 then continue end
        
        for _, bond in ipairs(bondCache) do
            if not autoFarmEnabled then break end
            if bond:IsDescendantOf(workspace) then
                collectBond(bond)
            end
        end
        
        if collectedBonds >= totalBonds and totalBonds > 0 then
            finishTime = math.floor(tick() - startTime)
            updateStatus()
            tweenToWin()
            break
        end
    end
end

local function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        task.spawn(autoFarmLoop)
    end
end

-- Tween to Win
function tweenToWin()
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    
    local winPad = workspace:FindFirstChild("WinPad")
    if winPad then
        local goal = {CFrame = winPad.CFrame + Vector3.new(0, 5, 0)}
        local tween = TweenService:Create(Char.HumanoidRootPart, TweenInfo.new(2), goal)
        tween:Play()
    end
end

-- ESP System
local espEnabled = false
local espHighlights = {}
local function updateESP()
    for _, bond in ipairs(bondCache) do
        if bond:IsDescendantOf(workspace) then
            if espEnabled and not bond:FindFirstChildOfClass("Highlight") then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(0, 255, 150)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.Parent = bond
                table.insert(espHighlights, highlight)
            elseif not espEnabled and bond:FindFirstChildOfClass("Highlight") then
                bond:FindFirstChildOfClass("Highlight"):Destroy()
            end
        end
    end
end

local function toggleESP()
    espEnabled = not espEnabled
    updateESP()
end

-- Speed Boost
local speedBoost = false
local function toggleSpeed()
    speedBoost = not speedBoost
    if Char and Char:FindFirstChild("Humanoid") then
        Char.Humanoid.WalkSpeed = speedBoost and 40 or 16
    end
end

-- GUI Toggle
local guiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        guiVisible = not guiVisible
        ScreenGui.Enabled = guiVisible
    end
end)

-- Create Buttons
createButton("Toggle Auto Farm", UDim2.new(0, 15, 0, 80), toggleAutoFarm)
createButton("Tween to Win", UDim2.new(0, 15, 0, 130), tweenToWin)
createButton("Toggle Bond ESP", UDim2.new(0, 15, 0, 180), toggleESP)
createButton("Toggle Speed Boost", UDim2.new(0, 15, 0, 230), toggleSpeed)
createButton("Save Progress", UDim2.new(0, 15, 0, 280), saveStats)
createButton("Reset Progress", UDim2.new(0, 15, 0, 330), resetStats)

-- Auto-update ESP for new bonds
workspace.DescendantAdded:Connect(function(descendant)
    if autoFarmEnabled and descendant:IsA("BasePart") and descendant.Name == "Bond" then
        table.insert(bondCache, descendant)
        totalBonds += 1
        if espEnabled then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(0, 255, 150)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Parent = descendant
            table.insert(espHighlights, highlight)
        end
    end
end)

-- Runtime Updates
RunService.Heartbeat:Connect(updateStatus)

-- Cleanup
LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        saveStats()
        ScreenGui:Destroy()
    end
end)

print("[Apex Hub v2.0 Loaded - Improved AutoFarm with Dynamic ESP]")