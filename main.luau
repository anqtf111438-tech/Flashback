-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

-- Parent GUI safely (Executor / Studio compatibility)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlashbackGui"
screenGui.ResetOnSpawn = false

if gethui then
    screenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
else
    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then
        screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
end

-- Draggable Main Container Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainContainer"
mainFrame.Size = UDim2.new(0, 290, 0, 70)
mainFrame.Position = UDim2.new(0.5, -145, 0.75, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Active = true
mainFrame.Parent = screenGui

-- Mobile & PC Smooth Dragging Implementation
local dragging = false
local dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Styling helper for UI buttons
local function createButton(name, text, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 135, 0, 65)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    button.BackgroundTransparency = 0.2
    button.Text = text
    button.TextColor3 = Color3.fromRGB(80, 80, 80)
    button.TextSize = 18
    button.Font = Enum.Font.SourceSans
    button.AutoButtonColor = true
    button.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(160, 160, 160)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button

    return button
end

-- Create Buttons
local flashbackBtn = createButton("FlashbackBtn", "Flashback", UDim2.new(0, 0, 0, 0))
local resetBtn = createButton("ResetBtn", "Reset", UDim2.new(0, 155, 0, 0))

-- Flashback State Variables
local positions = {}
local isRewinding = false
local MAX_POSITIONS = 3000 -- Stores ~1 minute of movement history

-- Core Loop: Continuous Recording & Rewinding
RunService.Heartbeat:Connect(function()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then return end

    if isRewinding then
        if #positions > 0 then
            -- Rewind to previous position step-by-step
            local lastCFrame = table.remove(positions)
            rootPart.CFrame = lastCFrame
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
        else
            -- History depleted
            isRewinding = false
            flashbackBtn.Text = "Flashback"
        end
    else
        -- Record active movement frame
        table.insert(positions, rootPart.CFrame)
        if #positions > MAX_POSITIONS then
            table.remove(positions, 1)
        end
    end
end)

-- Toggle Flashback Mode
flashbackBtn.MouseButton1Click:Connect(function()
    if isRewinding then
        isRewinding = false
        flashbackBtn.Text = "Flashback"
    else
        if #positions > 0 then
            isRewinding = true
            flashbackBtn.Text = "Stop Flashback"
        end
    end
end)

-- Reset Recorded Flashback History
resetBtn.MouseButton1Click:Connect(function()
    positions = {}
    if isRewinding then
        isRewinding = false
        flashbackBtn.Text = "Flashback"
    end
end)
