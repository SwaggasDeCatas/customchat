-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local function loadPlayerConfig()
	local url = "https://raw.githubusercontent.com/SwaggasDeCatas/customchat/refs/heads/main/chat/PlayerConfigs.lua"
	local success, result = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)

	if success then
		return result
	else
		warn("Failed to load player config:", result)
		return {}
	end
end

local playerConfigs = loadPlayerConfig()

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
local function loadCelebrationUI()
	local url = "https://raw.githubusercontent.com/SwaggasDeCatas/customchat/refs/heads/main/chat/UI.lua"
	local success, module = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)

	if success and module then
		return module
	else
		warn("Failed to load CelebrationUI module:", module)
		return nil
	end
end

local CelebrationUI = loadCelebrationUI()
if not CelebrationUI then return end

-- Marker template
local markerTemplate = CelebrationUI.CreateMarkerTemplate(player)

-- GUI setup
local guiRefs = CelebrationUI.CreateGUI(player)
local GUI = guiRefs.GUI
local mainFrame = guiRefs.MainFrame
local scroll = guiRefs.Scroll
local chatBox = guiRefs.ChatBox
local requestLabel = guiRefs.RequestLabel
local requestSound = guiRefs.RequestSound
local minimizeBtn = guiRefs.MinimizeBtn
local alertSound = guiRefs.AlertSound

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		scroll.Visible = false
		chatBox.Visible = false
		mainFrame.BackgroundTransparency = 1
		mainFrame.UIStroke.Transparency = 1
		minimizeBtn.Text = "+"
	else
		scroll.Visible = true
		chatBox.Visible = true
		mainFrame.BackgroundTransparency = 0.2
		mainFrame.UIStroke.Transparency = 0
		minimizeBtn.Text = "-"
	end
end)

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
-------------------------------------------------
-- EMOJI DICTIONARY (add something to this to add an emoji and allat)
-------------------------------------------------
local emojiMap = {
	[":flushed:"] = "😳",
	[":sob:"] = "😭",
	[":skull:"] = "💀",
	[":fire:"] = "🔥",
	[":100:"] = "💯",
	[":eyes:"] = "👀",
	[":laughing:"] = "😂",
	[":angry:"] = "😡",
	[":cold:"] = "🥶",
	[":heart:"] = "❤️",
	[":sunglasses:"] = "😎",
	[":joy:"] = "😂",
}

local function replaceEmojis(text)
	for code, emoji in pairs(emojiMap) do
		text = string.gsub(text, code, emoji)
	end
	return text
end

local function addMessage(plr, text)
	if not active then return end
text = replaceEmojis(text)
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
	-------------------------------------------------
	-- IMAGE MESSAGE CHECK (styled like normal messages)
	-------------------------------------------------
	local assetId = string.match(text, "rbxassetid://(%d+)")
	if assetId then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(tonumber(assetId))
		end)

		if success and info and info.AssetTypeId then
			if info.AssetTypeId == 1 or info.AssetTypeId == 13 then -- Image / Decal

				local config = playerConfigs[plr.UserId]
				local isContinuation = (lastSender == plr)

				-- Frame size bigger for images
				local frameHeight = isContinuation and 200 or 240

				local frame = Instance.new("Frame")
				frame.BackgroundTransparency = 1
				frame.LayoutOrder = #messages + 1
				frame.Size = UDim2.new(0.95, 0, 0, frameHeight)
				frame.Parent = scroll

				if not isContinuation then
					-- Player headshot image
					local imageLabel = Instance.new("ImageLabel")
					imageLabel.Size = UDim2.new(0.1, 0, 0.2, 0)
					imageLabel.BackgroundTransparency = 1
					imageLabel.ScaleType = Enum.ScaleType.Fit
					imageLabel.Image = config and config.PFP or string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=420&h=420", plr.UserId)
					imageLabel.Parent = frame

					local uicorner = Instance.new("UICorner")
					uicorner.CornerRadius = UDim.new(1, 0)
					uicorner.Parent = imageLabel

					-- Player name label
					local nameLabel = Instance.new("TextLabel")
					nameLabel.BackgroundTransparency = 1
					nameLabel.Position = UDim2.new(0.11, 0, 0, 0)
					nameLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
					nameLabel.TextScaled = true
					nameLabel.TextWrapped = true
					nameLabel.Font = Enum.Font.Montserrat
					nameLabel.FontFace.Weight = Enum.FontWeight.SemiBold
					nameLabel.TextXAlignment = Enum.TextXAlignment.Left
					nameLabel.TextColor3 = plr and getPlayerColor(plr) or Color3.fromRGB(255,255,255)
					nameLabel.Text = config and (config.Username .. " (@"..plr.Name..")") or plr.Name
					nameLabel.Parent = frame
				end

				-- Image message label
				local imgLabel = Instance.new("ImageLabel")
				imgLabel.BackgroundTransparency = 1
				imgLabel.Position = isContinuation and UDim2.new(0.11, 0, 0, 0) or UDim2.new(0.11, 0, 0.1, 0)
				imgLabel.Size = isContinuation and UDim2.new(0.9, 0, 1, 0) or UDim2.new(0.9, 0, 0.9, 0)
				imgLabel.Image = "rbxassetid://" .. assetId
				imgLabel.ScaleType = Enum.ScaleType.Fit
				imgLabel.Parent = frame

				table.insert(messages, frame)

				-- Remove oldest message if over MAX_MESSAGES
				if #messages > MAX_MESSAGES then
					local oldest = table.remove(messages, 1)
					if oldest then oldest:Destroy() end
				end

				task.defer(function()
					local canvasHeight = scroll.AbsoluteCanvasSize.Y
					local viewHeight = scroll.AbsoluteSize.Y
					scroll.CanvasPosition = Vector2.new(0, math.max(0, canvasHeight - viewHeight))
				end)

				lastSender = plr
				return
			end
		end
	end

	-------------------------------------------------
	-- NORMAL TEXT MESSAGE
	-------------------------------------------------
	local config = playerConfigs[plr.UserId]

	-- Determine if this is a continuation of the previous sender
	local isContinuation = (lastSender == plr)

	-- Frame setup
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.LayoutOrder = #messages + 1
	frame.Size = isContinuation and UDim2.new(0.95, 0, 0.05, 0) or UDim2.new(0.95, 0, 0.1, 0)
	frame.Parent = scroll

	if not isContinuation then
		-- Player headshot image
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Size = UDim2.new(0.1, 0, 0.7, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.ScaleType = Enum.ScaleType.Fit
		imageLabel.Image = config and config.PFP or string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=420&h=420", plr.UserId)
		imageLabel.Parent = frame

		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(1, 0)
		uicorner.Parent = imageLabel

		-- Player name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Position = UDim2.new(0.11, 0, 0, 0)
		nameLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
		nameLabel.TextScaled = true
		nameLabel.TextWrapped = true
		nameLabel.Font = Enum.Font.MontserratMedium
		nameLabel.FontFace.Weight = Enum.FontWeight.SemiBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		--nameLabel.TextColor3 = plr and getPlayerColor(plr) or Color3.fromRGB(255,255,255)
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Text = config and config.Username or plr.Name
		nameLabel.Parent = frame
	end

	-- Message text
	local messageLabel = Instance.new("TextLabel")
	messageLabel.BackgroundTransparency = 1
	messageLabel.Position = isContinuation and UDim2.new(0.11, 0, 0, 0) or UDim2.new(0.11, 0, 0.4, 0)
	messageLabel.Size = isContinuation and UDim2.new(0.9, 0, 0.8, 0) or UDim2.new(0.9, 0, 0.4, 0)
	messageLabel.TextScaled = true
	messageLabel.TextWrapped = true
	messageLabel.Font = Enum.Font.Montserrat
	messageLabel.FontFace.Weight = Enum.FontWeight.Regular
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextColor3 = Color3.fromRGB(225,225,225)
	messageLabel.Text = text
	messageLabel.Parent = frame

	-- Store message frame
	table.insert(messages, frame)

	-- Remove oldest message if over max
	if #messages > MAX_MESSAGES then
		local oldest = table.remove(messages, 1)
		if oldest then oldest:Destroy() end
	end

	-- Scroll to bottom
	task.defer(function()
		local canvasHeight = scroll.AbsoluteCanvasSize.Y
		local viewHeight = scroll.AbsoluteSize.Y
		scroll.CanvasPosition = Vector2.new(0, math.max(0, canvasHeight - viewHeight))
	end)

	-- Play alert if targeted
	if string.match(text, ":alert " .. player.Name) then
		alertSound:Play()
	end

	lastSender = plr
end

-------------------------------------------------
-- SEND CHAT FUNCTION
-------------------------------------------------
local function sendChat(enterPressed)
	if not active then return end
	if not chatBox.Text or chatBox.Text == "" then return end

	-- Only send if Enter was pressed OR focus manually lost while typing
	if enterPressed == false and typing then
		return
	end

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
local rightAltConn = UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.RightAlt then
		if chatBox:IsFocused() then
			chatBox:ReleaseFocus()
		else
			mainFrame.Visible = true
			chatBox:CaptureFocus()
		end
	end
end)
table.insert(playerConnections, rightAltConn)

-------------------------------------------------
-- CHATBOX FOCUS TRACKING
-------------------------------------------------
local focusedConn = chatBox.Focused:Connect(function()
	typing = true
end)
table.insert(playerConnections, focusedConn)

local focusLostConn = chatBox.FocusLost:Connect(function(enterPressed)
	typing = false
	sendChat(enterPressed)
end)
table.insert(playerConnections, focusLostConn)

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
