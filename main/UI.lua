-- ReplicatedStorage/CelebrationUI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CelebrationUI = {}

function CelebrationUI.CreateMarkerTemplate(player)
    local folder = ReplicatedStorage:FindFirstChild("CelebrationGuiAssets")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CelebrationGuiAssets"
        folder.Parent = ReplicatedStorage
    end

    local markerTemplate = folder:FindFirstChild("Marker")
    if not markerTemplate then
        markerTemplate = Instance.new("Part")
        markerTemplate.Name = "Marker"
        markerTemplate.Size = Vector3.new(0.1,0.1,0.1)
        markerTemplate.Anchored = true
        markerTemplate.CanCollide = false
        markerTemplate.Transparency = 1
        markerTemplate.Parent = folder

        local bill = Instance.new("BillboardGui")
        bill.Name = "Billboard"
        bill.Size = UDim2.new(8,5,8,5)
        bill.ZIndexBehavior = Enum.ZIndexBehavior.Global
        bill.SizeOffset = Vector2.new(0,0.5)
        bill.Parent = markerTemplate

        local arrow = Instance.new("ImageLabel")
        arrow.Name = "Arrow"
        arrow.Image = "http://www.roblox.com/asset/?id=260958688"
        arrow.Size = UDim2.new(0.4,0,0.4,0)
        arrow.Position = UDim2.new(0.3,0,0.3,0)
        arrow.Rotation = 180
        arrow.BackgroundTransparency = 1
        arrow.Parent = bill

        local ring = Instance.new("ImageLabel")
        ring.Name = "Ring"
        ring.Image = "rbxassetid://137218958897908"
        ring.ImageColor3 = Color3.fromRGB(0,85,255)
        ring.Size = UDim2.new(0.8,0,0.8,0)
        ring.Position = UDim2.new(0.1,0,0.1,0)
        ring.BackgroundTransparency = 1
        ring.Parent = bill

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "PlayerName"
        nameLabel.Size = UDim2.new(1,0,0.2,0)
        nameLabel.Position = UDim2.new(0,0,0.8,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.Montserrat
        nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
        nameLabel.TextScaled = true
        nameLabel.Text = player.Name
        nameLabel.Parent = bill
    end

    return markerTemplate
end

function CelebrationUI.CreateGUI(player)
    local GUI = Instance.new("ScreenGui")
    GUI.Name = "CelebrationFeedUI"
    GUI.Parent = player:WaitForChild("PlayerGui")
    GUI.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.3,0,0.25,0)
    mainFrame.Position = UDim2.new(0.7,0,0.3,0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = true
    mainFrame.Parent = GUI

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0,10)
    uiCorner.Parent = mainFrame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(255,255,255)
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Transparency = 0
    uiStroke.Parent = mainFrame

    -- Request label
    local requestLabel = Instance.new("TextLabel")
    requestLabel.Size = UDim2.new(1,0,0.1,0)
    requestLabel.Position = UDim2.new(0,0,-0.1,0)
    requestLabel.BackgroundTransparency = 1
    requestLabel.TextColor3 = Color3.fromRGB(255,0,0)
    requestLabel.Font = Enum.Font.Montserrat
    requestLabel.TextScaled = true
    requestLabel.TextStrokeTransparency = 1
    requestLabel.TextStrokeColor3 = Color3.fromRGB(255,255,255)
    requestLabel.Text = ""
    requestLabel.TextTransparency = 1
    requestLabel.Parent = mainFrame

    local requestSound = Instance.new("Sound")
    requestSound.SoundId = "rbxassetid://6043410483"
    requestSound.Volume = 1
    requestSound.Parent = mainFrame

    -- Scroll frame
    local scroll = Instance.new("ScrollingFrame")
    scroll.Parent = mainFrame
    scroll.AnchorPoint = Vector2.new(0,0)
    scroll.Position = UDim2.new(0,5,0,35)
    scroll.Size = UDim2.new(1,-10,0.75,-10)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarImageColor3 = Color3.fromRGB(255,255,255)
    scroll.ScrollBarThickness = 5

    local uiList = Instance.new("UIListLayout")
    uiList.Parent = scroll
    uiList.Padding = UDim.new(0,4)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.VerticalAlignment = Enum.VerticalAlignment.Bottom

    -- Chat box
    local chatBox = Instance.new("TextBox")
    chatBox.Parent = mainFrame
    chatBox.AnchorPoint = Vector2.new(0.5,0)
    chatBox.Position = UDim2.new(0.5,0,0.9,0)
    chatBox.Size = UDim2.new(0.9,0,0.075,0)
    chatBox.PlaceholderText = "Chat here..."
    chatBox.Text = ""
    chatBox.ClearTextOnFocus = false
    chatBox.TextScaled = true
    chatBox.TextColor3 = Color3.fromRGB(255,255,255)
    chatBox.BackgroundTransparency = 0.2
    chatBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    chatBox.Font = Enum.Font.Montserrat
    chatBox.Visible = true

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0,25,0,25)
    minimizeBtn.Position = UDim2.new(1,-30,0,5)
    minimizeBtn.Text = "-"
    minimizeBtn.Font = Enum.Font.SourceSansBold
    minimizeBtn.TextScaled = true
    minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Parent = mainFrame

    local alertSound = Instance.new("Sound")
    alertSound.SoundId = "rbxassetid://2185981764"
    alertSound.Volume = 1
    alertSound.Parent = mainFrame

    return {
        GUI = GUI,
        MainFrame = mainFrame,
        Scroll = scroll,
        ChatBox = chatBox,
        RequestLabel = requestLabel,
        RequestSound = requestSound,
        MinimizeBtn = minimizeBtn,
        AlertSound = alertSound
    }
end

return CelebrationUI
