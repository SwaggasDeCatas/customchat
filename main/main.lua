local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local active = true
local inputconn = nil
local heartbeatconn = nil

local function getTeams()
    if not player.Team then return end
    
    local myTeam = player.Team
    local enemyTeam
    
    if myTeam == game.Teams.Home then
        enemyTeam = game.Teams.Away
    else
        enemyTeam = game.Teams.Home
    end
    
    return myTeam, enemyTeam
end

local function getCharacterHRP(plr)
    if plr.Character then
        return plr.Character:FindFirstChild("HumanoidRootPart")
    end
end

local function evaluatePass(targetHRP, myHRP, defenders)
    local score = 0
    
    local distance = (targetHRP.Position - myHRP.Position).Magnitude
    
    -- Prefer medium range
    score += math.clamp(100 - distance, 0, 100)
    
    -- Defender proximity penalty
    for _, def in pairs(defenders) do
        local dHRP = getCharacterHRP(def)
        if dHRP then
            local dist = (dHRP.Position - targetHRP.Position).Magnitude
            if dist < 20 then
                score -= (20 - dist) * 4
            end
        end
    end
    
    return score
end

local function highlightPosition(pos, color, size)
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.5
    part.Size = size or Vector3.new(4,1,4)
    part.Color = color
    part.Position = pos
    part.Parent = workspace
    
    task.delay(0.1, function()
        part:Destroy()
    end)
end

local function detectGaps(defenders)
    local gaps = {}
    
    for i = 1, #defenders do
        for j = i+1, #defenders do
            local hrp1 = getCharacterHRP(defenders[i])
            local hrp2 = getCharacterHRP(defenders[j])
            
            if hrp1 and hrp2 then
                local midpoint = (hrp1.Position + hrp2.Position) / 2
                local gapSize = (hrp1.Position - hrp2.Position).Magnitude
                
                if gapSize > 25 then
                    table.insert(gaps, midpoint)
                end
            end
        end
    end
    
    return gaps
end

local function suggestRun(gaps)
    if #gaps == 0 then return end
    
    local bestGap = gaps[1]
    
    highlightPosition(bestGap, Color3.fromRGB(0,255,0), Vector3.new(6,1,6))
end

local function suggestPass(myHRP, teammates, defenders)
    local bestScore = -math.huge
    local bestTarget
    
    for _, mate in pairs(teammates) do
        if mate ~= player then
            local hrp = getCharacterHRP(mate)
            if hrp then
                local score = evaluatePass(hrp, myHRP, defenders)
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = hrp
                end
            end
        end
    end
    
    if bestTarget then
        highlightPosition(bestTarget.Position, Color3.fromRGB(0,170,255))
    end
end

local function detectDribbleSpace(myHRP, defenders)
    local forward = myHRP.CFrame.LookVector * 20
    local target = myHRP.Position + forward
    
    local blocked = false
    
    for _, def in pairs(defenders) do
        local hrp = getCharacterHRP(def)
        if hrp and (hrp.Position - target).Magnitude < 10 then
            blocked = true
        end
    end
    
    if not blocked then
        highlightPosition(target, Color3.fromRGB(255,255,0))
    end
end

heartbeatconn = RunService.Heartbeat:Connect(function()
    if not active then return end
    
    local myTeam, enemyTeam = getTeams()
    if not myTeam then return end
    
    local myHRP = getCharacterHRP(player)
    if not myHRP then return end
    
    local teammates = myTeam:GetPlayers()
    local defenders = enemyTeam:GetPlayers()
    
    suggestPass(myHRP, teammates, defenders)
    
    local gaps = detectGaps(defenders)
    suggestRun(gaps)
    
    detectDribbleSpace(myHRP, defenders)
end)

inputconn = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.F3 then
        active = false
		if inputconn then inputconn:Disconnect() inputconn = nil end
		if heartbeatconn then heartbeatconn:Disconnect() heartbeatconn = nil end
        print("Tactical Assist Disabled")
    end
end)
