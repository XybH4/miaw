-- Last Changed: April 20, 2025 6:10 AM
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local Humanoid = Character:FindFirstChildOfClass("Humanoid");
local Workspace = game:GetService("Workspace");
local ServerStatsItem = game:GetService("Stats").Network.ServerStatsItem
local Player = Players.LocalPlayer;
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Aerodynamic = false;
local Aerodynamic_Time = tick();
local Last_Input = UserInputService:GetLastInputType();
local Debris = game:GetService("Debris");
local RunService = game:GetService("RunService");
local Alive = workspace.Alive;
local Vector2_Mouse_Location = nil;
local Grab_Parry = nil;
local pingBased = true
local Remotes = {};
local Parry_Key = nil;
task.spawn(function()
	for _, Value in pairs(getgc()) do
		if ((type(Value) == "function") and islclosure(Value)) then
			if debug.getupvalues(Value) then
				local Protos = debug.getprotos(Value);
				local Upvalues = debug.getupvalues(Value);
				local Constants = debug.getconstants(Value);
				if ((# Protos == 4) and (# Upvalues == 24) and (# Constants == 104)) then -- if patched then #Constants == 102
					Remotes[debug.getupvalue(Value, 16)] = debug.getconstant(Value, 62);
					Parry_Key = debug.getupvalue(Value, 17);
					Remotes[debug.getupvalue(Value, 18)] = debug.getconstant(Value, 64);
					Remotes[debug.getupvalue(Value, 19)] = debug.getconstant(Value, 65);
					break;
				end
			end
		end
	end
end);
local Key = Parry_Key;
print(Key)
local Parries = 0;
local Auto_Parry = {};
Auto_Parry.Parry_Animation = function()
	local Parry_Animation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry");
	local Current_Sword = Player.Character:GetAttribute("CurrentlyEquippedSword");
	if not Current_Sword then
		return;
	end
	if not Parry_Animation then
		return;
	end
	local Sword_Data = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword);
	if (not Sword_Data or not Sword_Data['AnimationType']) then
		return;
	end
	for _, object in pairs(game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection:GetChildren()) do
		if (object.Name == Sword_Data['AnimationType']) then
			if (object:FindFirstChild("GrabParry") or object:FindFirstChild("Grab")) then
				local sword_animation_type = "GrabParry";
				if object:FindFirstChild("Grab") then
					sword_animation_type = "Grab";
				end
				Parry_Animation = object[sword_animation_type];
			end
		end
	end
	Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation);
	Grab_Parry:Play();
end;
Auto_Parry.Play_Animation = function(v)
	local Animations = Animation.storage[v];
	if not Animations then
		return false;
	end
	local Animator = Player.Character.Humanoid.Animator;
	if Animation.track then
		Animation.track:Stop();
	end
	Animation.track = Animator:LoadAnimation(Animations);
	Animation.track:Play();
	Animation.current = v;
end;
Auto_Parry.Get_Balls = function()
    local Balls = {}
    local BallFolder

    -- Check if the local player is alive
    if workspace.Alive:FindFirstChild(tostring(Player)) then
        BallFolder = workspace:FindFirstChild("Balls")
    else
        BallFolder = workspace:FindFirstChild("TrainingBalls")
    end

    if not BallFolder then return Balls end

    for _, ball in pairs(BallFolder:GetChildren()) do
        if ball:GetAttribute("realBall") then
            ball.CanCollide = false
            table.insert(Balls, ball)
        end
    end

    return Balls
end
Auto_Parry.Get_Ball = function()
    local BallFolder
    if Alive:FindFirstChild(tostring(Player)) then
        BallFolder = workspace:FindFirstChild("Balls")
    else
        BallFolder = workspace:FindFirstChild("TrainingBalls")
    end

    if not BallFolder then return end

    for _, ball in pairs(BallFolder:GetChildren()) do
        if ball:GetAttribute("realBall") then
            ball.CanCollide = false
            return ball
        end
    end
end
Auto_Parry.Parry_Data = function()
	local Camera = workspace.CurrentCamera
	if not Camera then
		return {
			0,
			CFrame.new(),
			{},
			{
				0,
				0
			}
		}
	end
	local Character = Player.Character
	local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
	local CameraCF = Camera.CFrame
	local CamPos = CameraCF.Position
	local Look = CameraCF.LookVector
	local Right = CameraCF.RightVector
	local Up = CameraCF.UpVector
	local MouseLocation = (Last_Input == Enum.UserInputType.MouseButton1 or Last_Input == Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard) and UserInputService:GetMouseLocation() or Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
	Vector2_Mouse_Location = {
		MouseLocation.X,
		MouseLocation.Y
	}
	local Alive = workspace.Alive:GetChildren()
	local Events = table.create(# Alive)
	for i = 1, # Alive do
		local v = Alive[i]
		local pp = v.PrimaryPart
		if pp then
			Events[tostring(v)] = Camera:WorldToScreenPoint(pp.Position)
		end
	end
	local DirectionCF
	if Selected_Parry_Type == "Custom" then
		DirectionCF = CameraCF
	elseif Selected_Parry_Type == "Random" then
		DirectionCF = CFrame.new(CamPos, Vector3.new(math.random(-3000, 3000), math.random(-3000, 3000), math.random(-3000, 3000)))
	elseif Selected_Parry_Type == "Straight" then
		DirectionCF = CFrame.new(CamPos, CamPos + Look * 1000)
	elseif Selected_Parry_Type == "Up" then
		DirectionCF = CFrame.new(CamPos, CamPos + Up * 1000)
	elseif Selected_Parry_Type == "Right" then
		DirectionCF = CFrame.new(CamPos, CamPos + Right * 1000)
	elseif Selected_Parry_Type == "Left" then
		DirectionCF = CFrame.new(CamPos, CamPos - Right * 1000)
	elseif Selected_Parry_Type == "Backwards" then
		DirectionCF = CFrame.new(CamPos, CamPos - Look * 1000)
	elseif Selected_Parry_Type == "Dot" then
		local dir = HRP and HRP.CFrame.LookVector or Look
		DirectionCF = CFrame.new(CamPos, CamPos + (dir + Vector3.new(0.25, 0, - 0.35)).Unit * 1000)
	else
		DirectionCF = CameraCF
	end
	return {
		0,
		DirectionCF,
		Events,
		Vector2_Mouse_Location
	}
end
Auto_Parry.Parry = function()
	local Parry_Data = Auto_Parry.Parry_Data();
	for Remote, Args in pairs(Remotes) do
		Remote:FireServer(Args, Key, Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4]); -- if patched then Args == nil
	end
	if (Parries > 7) then
		return false;
	end
	Parries += 1
	task.delay(0.5, function()
		if (Parries > 0) then
			Parries -= 1
		end
	end);
end;
local Lerp_Radians = 0
local Previous_Velocity = {}
local Last_Warping = tick()
local Curving = tick()
Auto_Parry.Linear_Interpolation = function(a, b, tV)
	return a + ((b - a) * tV)
end
Auto_Parry.Is_Curved = function()
	local Ball = Auto_Parry.Get_Ball()
	if not Ball then return false end
	local Zoomies = Ball:FindFirstChild("zoomies")
	if not Zoomies then return false end
	local Velocity = Zoomies.VectorVelocity
	local BallDir = Velocity.Unit
	local Char = LocalPlayer.Character
	local HRP = Char and Char.PrimaryPart
	if not HRP then return false end
	local HRPPos = HRP.Position
	local BallPos = Ball.Position
	local Direction = (HRPPos - BallPos).Unit
	local Dot = Direction:Dot(BallDir)
	local Speed = Velocity.Magnitude
	local Distance = (HRPPos - BallPos).Magnitude

	if not pingBased then
		return Speed >= 100 and Distance <= 100 and Dot < 0.8
	end

	local Ping = ServerStatsItem["Data Ping"]:GetValue()
	local SpeedThreshold = math.min(Speed/100,40)
	local AngleThreshold = 40 * math.max(Dot,0)
	local DirDiff = (BallDir - Velocity).Unit
	local DirSim = Direction:Dot(DirDiff)
	local DotDiff = Dot - DirSim
	local DotThreshold = 0.5 - (Ping/1000)
	local ReachTime = (Distance/Speed) - (Ping/1000)
	local EnoughSpeed = Speed > 100
	local BallDistThreshold = ((math.max(Ping/10,15) - math.min(Distance/1000,15)) + AngleThreshold + SpeedThreshold) * (1+Ping/950)

	table.insert(Previous_Velocity, Velocity)
	if #Previous_Velocity > 4 then
		table.remove(Previous_Velocity,1)
	end

	if EnoughSpeed and ReachTime > Ping/10 then
		BallDistThreshold = math.max(BallDistThreshold-15,15)
	end

	if Distance < BallDistThreshold then
		return false
	end

	local now = tick()

	if (now-Curving)<(ReachTime/1.5) or DotDiff<DotThreshold then
		return true
	end

	local Rad = math.rad(math.asin(Dot))
	Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Rad, 0.8)
	if Lerp_Radians < 0.018 then
		Last_Warping = now
	end

	if (now-Last_Warping)<(ReachTime/1.5) then
		return true
	end

	if #Previous_Velocity == 4 then
		local Diff1 = (BallDir - Previous_Velocity[1].Unit).Unit
		local Diff2 = (BallDir - Previous_Velocity[2].Unit).Unit
		local DotDiff1 = Dot - Direction:Dot(Diff1)
		local DotDiff2 = Dot - Direction:Dot(Diff2)
		if DotDiff1 < DotThreshold or DotDiff2 < DotThreshold then
			return true
		end
	end

	return Dot < DotThreshold
end
local Closest_Entity = nil
function Auto_Parry.Closest_Player()
	local Max_Distance = math.huge
	for _, Entity in pairs(workspace.Alive:GetChildren()) do
		if tostring(Entity) ~= tostring(Player) then
			local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
			if Distance < Max_Distance then
				Max_Distance = Distance
				Closest_Entity = Entity
			end
		end
	end
	return Closest_Entity
end
function Auto_Parry:Get_Entity_Properties()
	Auto_Parry.Closest_Player()
	if not Closest_Entity then
		return false
	end
	local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity
	local Entity_Direction = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
	local Entity_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
	return {
		Velocity = Entity_Velocity,
		Direction = Entity_Direction,
		Distance = Entity_Distance
	}
end
function Auto_Parry:Get_Ball_Properties()
	local Ball = Auto_Parry.Get_Ball()
	local Ball_Velocity = Vector3.zero
	local Ball_Origin = Ball
	local Ball_Direction = (Player.Character.PrimaryPart.Position - Ball_Origin.Position).Unit
	local Ball_Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
	local Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit)
	return {
		Velocity = Ball_Velocity,
		Direction = Ball_Direction,
		Distance = Ball_Distance,
		Dot = Ball_Dot
	}
end
function Auto_Parry:Spam_Service()
	local Ball = Auto_Parry.Get_Ball()
	if not Ball then return 0 end
	Auto_Parry.Closest_Player()

	local Vel = Ball.AssemblyLinearVelocity
	local Speed = Vel.Magnitude
	local Char = Player.Character
	local HRP = Char and Char.PrimaryPart
	if not HRP then return 0 end

	local Dir = (HRP.Position - Ball.Position).Unit
	local Dot = Dir:Dot(Vel.Unit)
	local TargetPos = Closest_Entity and Closest_Entity.PrimaryPart and Closest_Entity.PrimaryPart.Position
	local TargetDist = TargetPos and Player:DistanceFromCharacter(TargetPos) or math.huge
	local Ping = ServerStatsItem["Data Ping"]:GetValue()
	local PingFactor = math.clamp(Ping/10,4,15)
	local SpeedFactor = math.min(Speed/4.5,120)

	local FPS = 1/RunService.Heartbeat:Wait()
	local MaxDist = (PingFactor+SpeedFactor)*math.clamp(60/FPS,0.75,1.25)

	if self.Entity_Properties.Distance > MaxDist or self.Ball_Properties.Distance > MaxDist or TargetDist > MaxDist then
		return 0
	end

	local SpeedReduction = math.max(3.5-(Speed/7),0.15)
	local DotFactor = math.clamp(Dot,-1,0)*SpeedReduction
	local PredictionTime = TargetDist/Speed
	local PredBallPos = Ball.Position + Vel * PredictionTime

	local PlayerDir = (TargetPos - HRP.Position).Unit
	local PlayerSpeed = Char:FindFirstChild("HumanoidRootPart") and Char.HumanoidRootPart.AssemblyLinearVelocity.Magnitude or 0
	local PredPlayerPos = HRP.Position + PlayerDir * PlayerSpeed * PredictionTime

	local PredictedDist = (PredBallPos - PredPlayerPos).Magnitude
	return math.max(MaxDist - PredictedDist,5)
end
local visualizerEnabled = false
local visualizer = Instance.new("Part")
visualizer.Shape = Enum.PartType.Ball
visualizer.Anchored = true
visualizer.CanCollide = false
visualizer.Material = Enum.Material.ForceField
visualizer.Transparency = 0.5
visualizer.Parent = Workspace
visualizer.Size = Vector3.zero
visualizer.CastShadow = false
local function calculate_visualizer_radius(ball)
	local velocity = ball and ball.Velocity.Magnitude or 0
	return math.clamp((velocity / 2.4) + 10, 15, 200)
end
local function toggle_visualizer(state)
	visualizerEnabled = state
	if not state then
		visualizer.Size = Vector3.zero  -- Hide visualizer instantly
	end
end
RunService.RenderStepped:Connect(function()
	if not visualizerEnabled then
		return
	end
	local char = Player.Character or Player.CharacterAdded:Wait()
	local primaryPart = char and char.PrimaryPart
	local ball = Auto_Parry.Get_Ball()
	if not (primaryPart and ball) then
		visualizer.Size = Vector3.zero
		return
	end
	local target = ball:GetAttribute("target")
	local isTargetingPlayer = (target == LocalPlayer.Name)
	local radius = calculate_visualizer_radius(ball)
	visualizer.Size = Vector3.new(radius, radius, radius)
	visualizer.CFrame = primaryPart.CFrame
	visualizer.Color = isTargetingPlayer and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
end)
local EffectClasses = {
	["ParticleEmitter"] = true,
	["Beam"] = true,
	["Trail"] = true,
	["Explosion"] = true
}
local Connections_Manager = {};
local Selected_Selected_Parry_Type = nil;
local Parried = false;
local Last_Parry = 0;
local NoRender = nil;

local ScreenGui = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")


ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling


ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ImageButton.BorderSizePixel = 0
ImageButton.Position = UDim2.new(0.120833337, 0, 0.0952890813, 0)
ImageButton.Size = UDim2.new(0, 50, 0, 50)
ImageButton.Image = "rbxassetid://7279137105"
ImageButton.Draggable = true


UICorner.Parent = ImageButton


ImageButton.MouseButton1Click:Connect(function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
end)

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/CodeE4X-dev/Library/refs/heads/main/FluentRemake.lua"))();

local Window = Fluent:CreateWindow({
    Title = "Blade Ball - QuantumX",
    SubTitle = " by Q",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 500),
    Acrylic = false,
    Theme = "Midnight",
    MinimizeKey = Enum.KeyCode.LeftControl
})
local Options = Fluent.Options
local Tabs = {
    Main = Window:AddTab({Title = "Main", Icon = "swords"}),

}
Window:SelectTab(1)

Tabs.Main:AddButton({
    Title = "Copy Discord Link",
    Description = "",
    Callback = function()
        setclipboard('https://discord.gg/mzZd4JpDGC')
        Fluent:Notify({
            Title = "Join our Discord",
            Content = "",
            SubContent = "",
            Duration = 10
    })
    end
})
local AutoParry = Tabs.Main:AddToggle("AutoParry", {Title="Auto Parry",Default=true});
AutoParry:OnChanged(function(state)
    if state then
        local Runtime = workspace:FindFirstChild("Runtime")
        Connections_Manager["Auto Parry"] = RunService.PreSimulation:Connect(function()
            local char = Player.Character or Player.CharacterAdded:Wait()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local Cond1 = hrp and hrp:FindFirstChild("SingularityCape") -- Detection for if singularity is being used.
            if Cond1 then -- if it's being used then
                return -- stop parrying
            end
            local One_Ball = Auto_Parry.Get_Ball()
            local Balls = Auto_Parry.Get_Balls()
            for _, Ball in pairs(Balls) do
                if not Ball then
                    return
                end
                local Zoomies = Ball:FindFirstChild("zoomies")
                if not Zoomies then
                    return
                end
                Ball:GetAttributeChangedSignal("target"):Once(function()
                    Parried = false
                end)
                if Parried then
                    return
                end
                local Ball_Target = Ball:GetAttribute("target")
                local One_Target = One_Ball:GetAttribute("target")
                local Velocity = Zoomies.VectorVelocity
                local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
                local Speed = Velocity.Magnitude
                local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10
                local Parry_Accuracy = (Speed / 3.1) + Ping
                local Curved = Auto_Parry.Is_Curved()
                if Ball_Target == tostring(Player) and Aerodynamic then
                    if tick() - Aerodynamic_Time > 0.6 then
                        Aerodynamic_Time = tick()
                        Aerodynamic = false
                    end
                    return
                end
                if One_Target == tostring(Player) and Curved then
                    return
                end
                if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                    Auto_Parry.Parry(Selected_Selected_Parry_Type)
                    Parried = true
                end
            end
        end)
    elseif Connections_Manager["Auto Parry"] then
        Connections_Manager["Auto Parry"]:Disconnect()
        Connections_Manager["Auto Parry"] = nil
    end
end);
local AutoSpam = Tabs.Main:AddToggle("AutoSpam", {Title="Auto Spam",Default=true});
local autoSpamCoroutine = nil;
local targetPlayer = nil;
AutoSpam:OnChanged(function(state)
    if state then
        Connections_Manager["Auto Spam"] = RunService.PreSimulation:Connect(function(deltaTime)
            local Ball = Auto_Parry.Get_Ball()
            if not Ball or Auto_Parry.Is_Curved() then
                return
            end
            local Zoomies = Ball:FindFirstChild("zoomies")
            if not Zoomies then
                return
            end
            Auto_Parry.Closest_Player()
            local Ping = ServerStatsItem["Data Ping"]:GetValue()
            local FPS = 1 / deltaTime
            local Ping_Adjusted = math.clamp(Ping / 10 * (60 / FPS), 6, 13)
            local Ball_Properties = Auto_Parry:Get_Ball_Properties()
            local Entity_Properties = Auto_Parry:Get_Entity_Properties()
            local Spam_Accuracy = Auto_Parry.Spam_Service({
                Ball_Properties = Ball_Properties,
                Entity_Properties = Entity_Properties,
                Ping = Ping_Adjusted
            })
            local Distance = (Player.Character and Player.Character.PrimaryPart) and (Ball.Position - Player.Character.PrimaryPart.Position).Magnitude or math.huge
            local ClosestPrimary = Closest_Entity and Closest_Entity.PrimaryPart
            local Target_Distance = ClosestPrimary and (ClosestPrimary.Position - Player.Character.PrimaryPart.Position).Magnitude or math.huge
            local BallTargetName = Ball:GetAttribute("target")
            local Ball_Target = BallTargetName and Alive:FindFirstChild(BallTargetName)
            if not Ball_Target or not Ball_Target.PrimaryPart then
                return
            end
            local Ball_Targeted_Distance = (Ball_Target.PrimaryPart.Position - Player.Character.PrimaryPart.Position).Magnitude
            local Trigger_Distance = math.max(Spam_Accuracy * 0.845, 25)
            if (Distance <= Trigger_Distance or Target_Distance <= Trigger_Distance) and Parries > 1 then
                Auto_Parry.Parry(Selected_Selected_Parry_Type)
            end
        end)
    else
        local Connection = Connections_Manager["Auto Spam"]
        if Connection then
            Connection:Disconnect()
            Connections_Manager["Auto Spam"] = nil
        end
    end
end);

Auto_Parry.Parry_Type = "Default"

local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
    Title = "Curve ",
    Description = "",
    Values = {"Random", "Backwards","Up"},
    Multi = false,
    Default = 3,
    Callback = function(selected)
        Selected_Parry_Type = selected
    end
})



ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
	if (root.Parent and (root.Parent ~= Player.Character)) then
		if (root.Parent.Parent ~= workspace.Alive) then
			return;
		end
	end
	Auto_Parry.Closest_Player();
	local Ball = Auto_Parry.Get_Ball();
	if not Ball then
		return;
	end
	if not Grab_Parry then
		return;
	end
	Grab_Parry:Stop();
end);
ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
	if (Player.Character.Parent ~= workspace.Alive) then
		return;
	end
	if not Grab_Parry then
		return;
	end
	Grab_Parry:Stop();
end);
local Runtime = workspace.Runtime
Runtime.ChildAdded:Connect(function(Value)
	if (Value.Name == "Tornado") then
		Aerodynamic_Time = tick();
		Aerodynamic = true;
	end
end);
workspace.Balls.ChildAdded:Connect(function()
	Parried = false;
end);
workspace.Balls.ChildRemoved:Connect(function()
	Parries = 0;
	Parried = false;
	if Connections_Manager["Target Change"] then
		Connections_Manager["Target Change"]:Disconnect();
		Connections_Manager["Target Change"] = nil;
	end
end);
