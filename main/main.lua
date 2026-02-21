-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Local Player
local player = Players.LocalPlayer
local active = true
local typing = false
local MAX_MESSAGES = 30

local playerConnections = {} -- all tracked connections
local messages = {} -- UI message labels

-------------------------------------------------
-- PLAYER COLORS (light colors)
-------------------------------------------------
local playerColors = {
	Color3.fromRGB(255, 128, 128), -- light red
	Color3.fromRGB(255, 200, 150), -- light orange
	Color3.fromRGB(255, 255, 150), -- light yellow
	Color3.fromRGB(150, 255, 150), -- light green
	Color3.fromRGB(150, 255, 255), -- light cyan
	Color3.fromRGB(150, 200, 255), -- light blue
	Color3.fromRGB(255, 150, 255), -- light pink
	Color3.fromRGB(200, 150, 255), -- light purple
}

local function getPlayerColor(plr)
	return playerColors[(plr.UserId % #playerColors) + 1]
end

-------------------------------------------------
-- CELEBRATION FOLDER & MARKER TEMPLATE
-------------------------------------------------
local folder = ReplicatedStorage:FindFirstChild("CelebrationGuiAssets")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "CelebrationGuiAssets"
	folder.Parent = ReplicatedStorage
end

-- Make the marker template
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

-------------------------------------------------
-- CREATE SCREEN GUI
-------------------------------------------------
local GUI = Instance.new("ScreenGui")
GUI.Name = "CelebrationFeedUI"
GUI.Parent = player:WaitForChild("PlayerGui")
GUI.ResetOnSpawn = false

-------------------------------------------------
-- MAIN FRAME
-------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.3, 0, 0.25, 0)
mainFrame.Position = UDim2.new(0.7, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Parent = GUI
--mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = true

local UiCorner = Instance.new("UICorner")
UiCorner.Parent = mainFrame
UiCorner.CornerRadius = UDim.new(0, 10)

local UiStroke = Instance.new("UIStroke")
UiStroke.Parent = mainFrame
UiStroke.Color = Color3.fromRGB(255, 255, 255)
UiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UiStroke.Transparency = 0

-------------------------------------------------
-- REQUEST LABEL (BP / FP messages)
-------------------------------------------------
local requestLabel = Instance.new("TextLabel")
requestLabel.Size = UDim2.new(1, 0, 0.1, 0)          -- bigger height
requestLabel.Position = UDim2.new(0, 0, -0.1, 0)     -- slightly above frame
requestLabel.BackgroundTransparency = 1
requestLabel.TextColor3 = Color3.fromRGB(255, 0, 0)    -- black text
requestLabel.Font = Enum.Font.Montserrat
requestLabel.Font = Enum.Font.Montserrat
requestLabel.TextScaled = true
requestLabel.TextStrokeTransparency = 1               -- optional for readability
requestLabel.TextStrokeColor3 = Color3.fromRGB(255,255,255)
requestLabel.Text = ""
requestLabel.TextTransparency = 1
requestLabel.Parent = mainFrame

local requestSound = Instance.new("Sound")
requestSound.SoundId = "rbxassetid://6043410483"
requestSound.Volume = 1
requestSound.Parent = mainFrame

local function showRequestMessage(text)
	requestLabel.Text = string.upper(text)
	requestLabel.TextTransparency = 0
	requestSound:Play()
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 3)
	local tween = TweenService:Create(requestLabel, tweenInfo, {TextTransparency = 1})
	tween:Play()
end

-------------------------------------------------
-- SCROLL FRAME
-------------------------------------------------
local scroll = Instance.new("ScrollingFrame")
scroll.Parent = mainFrame
scroll.AnchorPoint = Vector2.new(0, 0)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.Size = UDim2.new(1, -10, 0.75, -10)
scroll.BackgroundTransparency = 1
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
scroll.ScrollBarThickness = 5

local UIList = Instance.new("UIListLayout")
UIList.Parent = scroll
UIList.Padding = UDim.new(0, 4)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.VerticalAlignment = Enum.VerticalAlignment.Bottom

-------------------------------------------------
-- CHAT BOX
-------------------------------------------------
local chatBox = Instance.new("TextBox")
chatBox.Parent = mainFrame
chatBox.AnchorPoint = Vector2.new(0.5,0)
chatBox.Position = UDim2.new(0.5,0,0.9,0)
chatBox.Size = UDim2.new(0.9,0,0.075,0)
chatBox.PlaceholderText = "Chat here..."
chatBox.Text = ""
chatBox.ClearTextOnFocus = false
chatBox.TextScaled = true
chatBox.TextColor3 = Color3.fromRGB(255, 255, 255)
chatBox.BackgroundTransparency = 0.2
chatBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
chatBox.Font = Enum.Font.Montserrat
chatBox.Visible = true

-------------------------------------------------
-- MINIMIZE BUTTON
-------------------------------------------------
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 5)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextScaled = true
minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = mainFrame

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		scroll.Visible = false
		chatBox.Visible = false
		mainFrame.BackgroundTransparency = 1
		UiStroke.Transparency = 1
		minimizeBtn.Text = "+"
	else
		scroll.Visible = true
		chatBox.Visible = true
		mainFrame.BackgroundTransparency = 0.2
		UiStroke.Transparency = 0
		minimizeBtn.Text = "-"
	end
end)

-------------------------------------------------
-- SOUND SETUP
-------------------------------------------------
local alertSound = Instance.new("Sound")
alertSound.SoundId = "rbxassetid://2185981764"
alertSound.Volume = 1
alertSound.Parent = mainFrame

-------------------------------------------------
-- PASS MARKER LINES (per player)
-------------------------------------------------
local previousMarkers = {} -- [player] = previousMarker
local function connectMarkers(plr, newMarker)
	local prevMarker = previousMarkers[plr]
	if prevMarker then
		local line = Instance.new("Part")
		line.Anchored = true
		line.CanCollide = false
		line.Material = Enum.Material.Neon
		line.Color = Color3.fromRGB(255,255,255)
		line.Size = Vector3.new(0.05,0.05,1)
		line.Name = "MarkerLine"
		line.Parent = Workspace

		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not prevMarker or not newMarker then
				line:Destroy()
				if conn then conn:Disconnect() end
				return
			end
			local startPos = prevMarker.Position + Vector3.new(0,1,0)
			local endPos = newMarker.Position + Vector3.new(0,1,0)
			local dir = endPos - startPos
			line.Size = Vector3.new(0.05, 0.05, dir.Magnitude)
			line.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0,0,-dir.Magnitude/2)
		end)

		newMarker.Destroying:Connect(function()
			line:Destroy()
			if conn then conn:Disconnect() end
			if previousMarkers[plr] == newMarker then
				previousMarkers[plr] = nil
			end
		end)
		prevMarker.Destroying:Connect(function()
			line:Destroy()
			if conn then conn:Disconnect() end
			if previousMarkers[plr] == prevMarker then
				previousMarkers[plr] = nil
			end
		end)
	end
	previousMarkers[plr] = newMarker
end

-------------------------------------------------
-- ADD MESSAGE FUNCTION
-------------------------------------------------
local lastSender = nil

local function addMessage(plr, text)
	if not active then return end

	-------------------------------------------------
	-- PASS MARKER
	-------------------------------------------------
	if string.sub(text,1,9) == "Initiate," then
		local args = string.split(text,",")
		if args[2] == "Passmarker" and args[3] then
			local coords = string.split(args[3], " ")
			for i=1,#coords do coords[i] = tonumber(coords[i]) end
			local pos = Vector3.new(coords[1],coords[2],coords[3])
			local marker = markerTemplate:Clone()
			marker.Position = pos
			marker.Parent = Workspace
			marker.Billboard.PlayerName.Text = plr.Name
			connectMarkers(plr, marker)
			task.delay(3,function()
				if marker then marker:Destroy() end
			end)
		end
		return
	end

	-------------------------------------------------
	-- BP / FP REQUESTS
	-------------------------------------------------
	if text == ":bp" then
		showRequestMessage(plr.Name .. " requested back post")
		return
	end

	if text == ":fp" then
		showRequestMessage(plr.Name .. " requested front post")
		return
	end

	-------------------------------------------------
	-- IMAGE MESSAGE CHECK
	-------------------------------------------------
	local assetId = string.match(text, "rbxassetid://(%d+)")
	if assetId then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(tonumber(assetId))
		end)

		if success and info and info.AssetTypeId then
			-- AssetTypeId 1 = Image, 13 = Decal (varies but safe check)
			if info.AssetTypeId == 1 or info.AssetTypeId == 13 then

				local container = Instance.new("Frame")
				container.BackgroundTransparency = 1
				container.Size = UDim2.new(1,0,0,200)
				container.LayoutOrder = #messages + 1
				container.Parent = scroll

				-- Image
				local image = Instance.new("ImageLabel")
				image.BackgroundTransparency = 1
				image.Size = UDim2.new(1,0,0.9,0)
				image.Position = UDim2.new(0,0,0,0)
				image.Image = "rbxassetid://" .. assetId
				image.ScaleType = Enum.ScaleType.Fit
				image.Parent = container

				-- Player Name
				local nameLabel = Instance.new("TextLabel")
				nameLabel.BackgroundTransparency = 1
				nameLabel.Size = UDim2.new(1,0,0.1,0)
				nameLabel.Position = UDim2.new(0,0,0.9,0)
				nameLabel.TextScaled = true
				nameLabel.TextWrapped = true
				nameLabel.TextColor3 = getPlayerColor(plr)
				nameLabel.Font = Enum.Font.Montserrat
				nameLabel.Text = "[" .. plr.Name .. "]"
				nameLabel.Parent = container

				table.insert(messages, container)

				if #messages > MAX_MESSAGES then
					local oldest = table.remove(messages,1)
					if oldest then oldest:Destroy() end
				end

				task.defer(function()
					local canvasHeight = scroll.AbsoluteCanvasSize.Y
					local viewHeight = scroll.AbsoluteSize.Y
					scroll.CanvasPosition = Vector2.new(0, math.max(0, canvasHeight - viewHeight))
				end)

				return
			end
		end
	end

	-------------------------------------------------
	-- NORMAL TEXT MESSAGE
	-------------------------------------------------
	local isContinuation = (lastSender == plr)
	
	if isContinuation then
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0.95, 0,0.05, 0)
		frame.BackgroundTransparency = 1
		frame.LayoutOrder = #messages + 1
		frame.Parent = scroll
		
		local label2 = Instance.new("TextLabel")
		label2.BackgroundTransparency = 1
		label2.Position = UDim2.new(0.11, 0, 0, 0)
		label2.Size = UDim2.new(0.9, 0, 0.8, 0)
		label2.TextScaled = true
		label2.TextWrapped = true
		label2.Font = Enum.Font.Montserrat
		label2.FontFace.Weight = Enum.FontWeight.Regular
		label2.Text = text
		label2.TextXAlignment = Enum.TextXAlignment.Left
		label2.TextColor3 = Color3.fromRGB(255,255,255)
		label2.Parent = frame
		
		table.insert(messages, frame)
	else
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0.95, 0,0.1, 0)
		frame.BackgroundTransparency = 1
		frame.LayoutOrder = #messages + 1
		frame.Parent = scroll

		local imagelabel = Instance.new("ImageLabel")
		imagelabel.Size = UDim2.new(0.1, 0, 1, 0)
		imagelabel.BackgroundTransparency = 1
		imagelabel.ScaleType = Enum.ScaleType.Fit
		imagelabel.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=420&h=420", plr.UserId)
		imagelabel.Parent = frame

		local uicorner = Instance.new("UICorner")
		uicorner.Parent = imagelabel
		uicorner.CornerRadius = UDim.new(1, 0)

		local label1 = Instance.new("TextLabel")
		label1.BackgroundTransparency = 1
		label1.Position = UDim2.new(0.11, 0, 0.4, 0)
		label1.Size = UDim2.new(0.9, 0, 0.4, 0)
		label1.TextScaled = true
		label1.TextWrapped = true
		label1.Font = Enum.Font.Montserrat
		label1.FontFace.Weight = Enum.FontWeight.Regular
		label1.Text = text
		label1.TextXAlignment = Enum.TextXAlignment.Left
		label1.TextColor3 = Color3.fromRGB(255,255,255)

		local label2 = Instance.new("TextLabel")
		label2.BackgroundTransparency = 1
		label2.Position = UDim2.new(0.11, 0, 0, 0)
		label2.Size = UDim2.new(0.9, 0, 0.4, 0)
		label2.TextScaled = true
		label2.TextWrapped = true
		label2.Font = Enum.Font.Montserrat
		label2.FontFace.Weight = Enum.FontWeight.SemiBold
		label2.Text = plr.Name
		label2.TextXAlignment = Enum.TextXAlignment.Left
		label2.TextColor3 = plr and getPlayerColor(plr) or Color3.fromRGB(255,255,255)

		label1.Parent = frame
		label2.Parent = frame
		
		table.insert(messages, frame)
	end
	
	

	lastSender = plr

	if #messages > MAX_MESSAGES then
		local oldest = table.remove(messages,1)
		if oldest then oldest:Destroy() end
	end

	task.defer(function()
		local canvasHeight = scroll.AbsoluteCanvasSize.Y
		local viewHeight = scroll.AbsoluteSize.Y
		scroll.CanvasPosition = Vector2.new(0, math.max(0, canvasHeight - viewHeight))
	end)

	if string.match(text, ":alert " .. player.Name) then
		alertSound:Play()
	end
end

-------------------------------------------------
-- SEND CHAT FUNCTION
-------------------------------------------------
local function sendChat()
	if not active or chatBox.Text == "" then return end
	local msg = chatBox.Text
	local dataEvent = ReplicatedStorage:WaitForChild("Event"):WaitForChild("Data")
	local tackleCelebration = player.Data.Keybinds.Tackle.Celebration

	dataEvent:FireServer(tackleCelebration, msg)
	chatBox.Text = ""
end
table.insert(playerConnections, chatBox.FocusLost:Connect(sendChat))

-------------------------------------------------
-- TRACK PLAYER VALUE CHANGES
-------------------------------------------------
local function trackPlayer(plr)
	if not plr:FindFirstChild("Data") then return end
	if not plr.Data:FindFirstChild("Keybinds") then return end
	if not plr.Data.Keybinds:FindFirstChild("Tackle") then return end
	if not plr.Data.Keybinds.Tackle:FindFirstChild("Celebration") then return end

	local valueObj = plr.Data.Keybinds.Tackle.Celebration
	local conn = valueObj.Changed:Connect(function(newValue)
		addMessage(plr, tostring(newValue))
	end)
	table.insert(playerConnections, conn)
end

local function setupTeamTracking()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Team == player.Team then
			trackPlayer(plr)
		end
	end
end
setupTeamTracking()

-------------------------------------------------
-- PLAYER JOIN / TEAM CHANGE
-------------------------------------------------
table.insert(playerConnections, Players.PlayerAdded:Connect(function(plr)
	local teamChangeConn = plr:GetPropertyChangedSignal("Team"):Connect(function()
		if plr.Team == player.Team then
			trackPlayer(plr)
		end
	end)
	table.insert(playerConnections, teamChangeConn)
end))

table.insert(playerConnections, player:GetPropertyChangedSignal("Team"):Connect(function()
	for _, conn in ipairs(playerConnections) do
		pcall(function() conn:Disconnect() end)
	end
	playerConnections = {}
	for _, msg in ipairs(messages) do msg:Destroy() end
	messages = {}
	setupTeamTracking()
end))

-------------------------------------------------
-- TOGGLE TYPING MODE (Right Alt)
-------------------------------------------------
local ignoreNextInput = false
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightAlt then
		if not typing then
			typing = true
			mainFrame.Visible = true
			chatBox:CaptureFocus()
			ignoreNextInput = true
		else
			typing = false
			chatBox:ReleaseFocus()
		end
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if ignoreNextInput and input.UserInputType == Enum.UserInputType.Keyboard then
		ignoreNextInput = false
	end
end)

-------------------------------------------------
-- MARKERS & PASS DEBOUNCE
-------------------------------------------------
local pitchParts = {} -- whitelist for raycasting
table.insert(pitchParts, workspace.Pitch.Grass)
local canMark = true

table.insert(playerConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F3 then
		active = false
		for _, conn in ipairs(playerConnections) do pcall(function() conn:Disconnect() end) end
		playerConnections = {}
		for _, msg in ipairs(messages) do msg:Destroy() end
		messages = {}
		if GUI then GUI:Destroy() end
		print("Celebration Feed fully disabled.")
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		local char = player.Character
		if char and char:FindFirstChild("Pass") and canMark then
			canMark = false
			local mousePos = UserInputService:GetMouseLocation()
			local cam = workspace.CurrentCamera
			local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
			local rayObj = Ray.new(ray.Origin, ray.Direction*1000)
			local part, hitPos = workspace:FindPartOnRayWithWhitelist(rayObj, pitchParts)
			if hitPos then
				local celebrationVal = string.format("Initiate,Passmarker,%f %f %f", hitPos.X, hitPos.Y, hitPos.Z)
				local dataEvent = ReplicatedStorage:WaitForChild("Event"):WaitForChild("Data")
				dataEvent:FireServer(player.Data.Keybinds.Tackle.Celebration, celebrationVal)
			end
			task.delay(0.1,function() canMark = true end)
		end
	end
end))
