--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PLAYER REFERENCES
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

--// WORLD REFERENCES
local PitchPart = workspace:WaitForChild("Pitch"):WaitForChild("Grass")
local BallsFolder = workspace:WaitForChild("Balls")
local Ball = BallsFolder:WaitForChild("CBM")

--// REMOTES
local RS = ReplicatedStorage
local MainFunction = RS:WaitForChild("Event").MainFunction
local MainEvent = RS:WaitForChild("Event").MainEvent

--// SETTINGS
local DANGER_RADIUS = 35
local AUTO_DEFENSE_DISTANCE = 12
local DEFENSIVE_BEHIND = 5
local ANGLE_OFFSET = 0.3
local SPEED_BOOST = 24
local NORMAL_SPEED = 19
local HALF_LINE_Z = 0

local TACKLE_DISTANCE = 6
local TACKLE_COOLDOWN = 3

local SAFE_PASS_RADIUS = 10
local isPoweringUp = false

local lastTackleTime = 0
local canPassTime = 0
local hasPassed = false

local connections = {}
local STOP_SCRIPT = false
local cd = false

--// YOUR EXACT ANIMATIONS
local SlideAnim = Instance.new("Animation")
SlideAnim.AnimationId = "rbxassetid://17824593324"
local SlideTrack = humanoid:LoadAnimation(SlideAnim)

local ChestAnim = Instance.new("Animation")
ChestAnim.AnimationId = "rbxassetid://17824583639"
local ChestTrack = humanoid:LoadAnimation(ChestAnim)

local PassHold = Instance.new("Animation")
PassHold.AnimationId = "rbxassetid://17883974151"
local PassHoldTrack = humanoid:LoadAnimation(PassHold)

local PassRelease = Instance.new("Animation")
PassRelease.AnimationId = "rbxassetid://17883975642"
local PassReleaseTrack = humanoid:LoadAnimation(PassRelease)

--// GOALS
local AWAY_GOAL_POS = Vector3.new(2,5.32,349)
local HOME_GOAL_POS = Vector3.new(2,5,-349)

local myGoalPos, opponentGoalPos
if player.Team.Name == "Home" then
	myGoalPos = HOME_GOAL_POS
	opponentGoalPos = AWAY_GOAL_POS
else
	myGoalPos = AWAY_GOAL_POS
	opponentGoalPos = HOME_GOAL_POS
end

--====================================================
-- STOP EVERYTHING (F4)
--====================================================
local function stopAll()
	STOP_SCRIPT = true
	
	for _,c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)

	humanoid:Move(Vector3.zero)
	humanoid.WalkSpeed = NORMAL_SPEED
	
	if SlideTrack.IsPlaying then SlideTrack:Stop() end
	if ChestTrack.IsPlaying then ChestTrack:Stop() end
end

table.insert(connections,
	UserInputService.InputBegan:Connect(function(input,gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.F4 then
			stopAll()
		end
	end)
)

--====================================================
-- PASS LOGIC (UNCHANGED)
--====================================================
local function passToPlayer(targetPlayer)
	humanoid:Move(Vector3.zero)

	if Ball.Owner.Value ~= player then
		MainFunction:InvokeServer("Ownership", Ball, Ball.Position, 100, 10, nil)
	end

    local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    targetHRP = targetHRP.Position + Vector3.new(0, 100, 0)

    local duration = 1.7

    -- Kick the ball
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = (targetHRP - Ball.Position) / duration
    bv.Parent = Ball
    Debris:AddItem(bv, 0.4)

    -- Sound logic (unchanged)
    local Kick = Ball:WaitForChild("Kick")
    local power = (bv.Velocity.Magnitude / 200) ^ 1.1 - 0.075
    if power < 0.15 then power = 0.15 end
    local pitch = bv.Velocity.Magnitude / 150 + 1

    Kick.Volume = power
    Kick.PlaybackSpeed = pitch
    Kick:Play()
    MainEvent:FireServer("Sound", Ball, Kick, power, pitch, false)
end

local function getBestForward()
	local bestForward=nil
	local bestScore=-math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr~=player and plr.Team==player.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local pos=plr.Character.HumanoidRootPart.Position
			local score=(opponentGoalPos-pos).Magnitude*-1
			if score>bestScore then
				bestScore=score
				bestForward=plr
			end
		end
	end
	return bestForward
end

--====================================================
-- DEFENSIVE POSITIONING (UNCHANGED)
--====================================================
local function defensivePosition(attHRP)
	local dirToGoal = (myGoalPos - attHRP.Position).Unit
	local right = Vector3.new(-dirToGoal.Z,0,dirToGoal.X)
	local pos = attHRP.Position + dirToGoal*DEFENSIVE_BEHIND + right*ANGLE_OFFSET
	if player.Team.Name=="Home" and pos.Z>HALF_LINE_Z then pos=Vector3.new(pos.X,pos.Y,HALF_LINE_Z-1) end
	if player.Team.Name=="Away" and pos.Z<HALF_LINE_Z then pos=Vector3.new(pos.X,pos.Y,HALF_LINE_Z+1) end
	return pos
end

local function defensiveMidpoint(att1HRP, att2HRP)
	local mid=(att1HRP.Position + att2HRP.Position)/2
	local dirToGoal=(myGoalPos-mid).Unit
	local right=Vector3.new(-dirToGoal.Z,0,dirToGoal.X)
	local pos = mid + dirToGoal*DEFENSIVE_BEHIND + right*ANGLE_OFFSET
	if player.Team.Name=="Home" and pos.Z>HALF_LINE_Z then pos=Vector3.new(pos.X,pos.Y,HALF_LINE_Z-1) end
	if player.Team.Name=="Away" and pos.Z<HALF_LINE_Z then pos=Vector3.new(pos.X,pos.Y,HALF_LINE_Z+1) end
	return pos
end

local function playersNearBall(radius)
	local attackers, defenders = {},{}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local d = (plr.Character.HumanoidRootPart.Position - Ball.Position).Magnitude
			if d<=radius then
				if plr.Team ~= player.Team then
					table.insert(attackers,plr)
				else
					table.insert(defenders,plr)
				end
			end
		end
	end
	return attackers, defenders
end

--====================================================
-- YOUR CHEST + SLIDE SYSTEM
--====================================================
local function attemptTackle()

	if cd then return end
	if Ball.Owner.Value == player then return end
	if Ball:FindFirstChild("ReactDecline") and Ball.ReactDecline.Value then return end

	local dist = (Ball.Position - hrp.Position).Magnitude
	if dist > TACKLE_DISTANCE then return end

	cd = true

	for _,v in ipairs(Ball:GetChildren()) do
		if v:IsA("BodyVelocity") or v:IsA("VectorForce") then
			v:Destroy()
		end
	end

	MainFunction:InvokeServer("Ownership", Ball, Ball.Position, 100, 10, 1)

	local ballY = Ball.Position.Y
	local chestY = char:FindFirstChild("UpperTorso") and char.UpperTorso.Position.Y or char.Torso.Position.Y
	local heightDiff = ballY - chestY

	if heightDiff > 0.5 and heightDiff < 7.5 then
		
		ChestTrack:Play()
		ChestTrack:AdjustWeight(1,0)

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = hrp.CFrame.LookVector * 26
		bv.Velocity *= Vector3.new(1,0,1)
		bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
		bv.Parent = Ball
		Debris:AddItem(bv,0.3)

	else
		SlideTrack:Play(0,1,1)
		SlideTrack:AdjustWeight(1,0)

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = (hrp.CFrame * CFrame.fromEulerAnglesXYZ(0,0.75,0)).LookVector * 20.5
		bv.Velocity *= Vector3.new(1,0,1)
		bv.Velocity += Vector3.new(0,22.5,0)
		bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
		bv.Parent = Ball
		Debris:AddItem(bv,0.3)
	end

	task.wait(1)

	PassHoldTrack:Play(nil, nil, 1.11)
	isPoweringUp = true
	lastTackleTime = tick()
	canPassTime = tick() + 1.5
	hasPassed = false

	task.delay(TACKLE_COOLDOWN,function()

		-- If cooldown ends and we never passed → release but don't pass
		if isPoweringUp and not hasPassed then
			PassHoldTrack:Stop()
			PassReleaseTrack:Play(0,1,1)
			PassReleaseTrack:AdjustWeight(1,0)
		end

		isPoweringUp = false
		cd=false
	end)
end

--====================================================
-- MAIN AI LOOP (UNCHANGED LOGIC + tackle added)
--====================================================
table.insert(connections,
RunService.Heartbeat:Connect(function()

	if STOP_SCRIPT then return end
	if not Ball then return end

	humanoid.WalkSpeed = SPEED_BOOST

	local attackers, defenders = playersNearBall(DANGER_RADIUS)
	for i,v in ipairs(defenders) do 
		if v==player then 
			table.remove(defenders,i) 
			break 
		end 
	end

	local numAttackers = #attackers
	local numDefenders = #defenders + 1

	local owner = Ball.Owner.Value
	local hasBall = owner == player
	local distToBall = (Ball.Position - hrp.Position).Magnitude

	--====================================================
	-- IF TEAMMATE HAS BALL → RETREAT TO HALF
	--====================================================
	if owner and owner:IsA("Player") and owner.Team == player.Team and owner ~= player then
		
		local retreatZ = HALF_LINE_Z
		local retreatPos = Vector3.new(hrp.Position.X, hrp.Position.Y, retreatZ)

		humanoid:MoveTo(retreatPos)
		return
	end

	--====================================================
	-- IF WE HAVE BALL
	--====================================================
	if hasBall then
		
		humanoid:MoveTo(Ball.Position)

		-- If ownership changed while powering → release but don't pass
		if isPoweringUp and Ball.Owner.Value ~= player then
			PassHoldTrack:Stop()
			PassReleaseTrack:Play(0,1,1)
			isPoweringUp = false
			return
		end

		-- Only allow pass after delay
		if tick() >= canPassTime and not hasPassed then
			
			if distToBall <= TACKLE_DISTANCE then

				-- Check if safe to pass (no one close)
				local someoneClose = false
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						local d = (plr.Character.HumanoidRootPart.Position - Ball.Position).Magnitude
						if d <= SAFE_PASS_RADIUS and plr ~= player then
							someoneClose = true
							break
						end
					end
				end

				if not someoneClose then
					local forward = getBestForward()
					if forward then
						hasPassed = true
						isPoweringUp = false
						humanoid:Move(Vector3.zero)
						PassHoldTrack:Stop()
						PassReleaseTrack:Play(0,1,1)
						PassReleaseTrack:AdjustWeight(1,0)
						passToPlayer(forward)
					end
				end
			end
		end

		return
	end

	--====================================================
	-- NORMAL DEFENSIVE BEHAVIOR
	--====================================================
	humanoid:MoveTo(Ball.Position)

	if distToBall <= TACKLE_DISTANCE then
		attemptTackle()
	end

	if numAttackers==1 and numDefenders==1 then
		local attHRP=attackers[1].Character.HumanoidRootPart
		humanoid:MoveTo(defensivePosition(attHRP))
	end

	if numAttackers==2 and numDefenders==1 then
		local att1=attackers[1].Character.HumanoidRootPart
		local att2=attackers[2].Character.HumanoidRootPart
		humanoid:MoveTo(defensiveMidpoint(att1,att2))
	end

end)
)