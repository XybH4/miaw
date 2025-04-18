

local Players = game:GetService('Players')
local Player = Players.LocalPlayer

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Aerodynamic = false
local Aerodynamic_Time = tick()

local UserInputService = game:GetService('UserInputService')
local Last_Input = UserInputService:GetLastInputType()
local VirtualInputManager = game:GetService("VirtualInputManager")

local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')

local Alive = workspace.Alive

local Vector2_Mouse_Location = nil
local Grab_Parry = nil

local Remotes = {}
local Parry_Key = nil

task.spawn(function()
    for _, Value in pairs(getgc()) do
        if type(Value) == "function" and islclosure(Value) then
            if debug.getupvalues(Value) then

            local Protos = debug.getprotos(Value)
            local Upvalues = debug.getupvalues(Value)
            local Constants = debug.getconstants(Value)

                if #Protos == 4 and #Upvalues == 24 and #Constants == 104 then   
                Remotes[debug.getupvalue(Value, 16)] = debug.getconstant(Value, 62)
                Parry_Key = debug.getupvalue(Value, 17)

                Remotes[debug.getupvalue(Value, 18)] = debug.getconstant(Value, 64)
                Remotes[debug.getupvalue(Value, 19)] = debug.getconstant(Value, 65)
                    break
                end
            end
        end
    end
end)

local Key = Parry_Key
local Parries = 0

function create_animation(object, info, value)
    local animation = game:GetService('TweenService'):Create(object, info, value)

    animation:Play()
    task.wait(info.Time)

    Debris:AddItem(animation, 0)

    animation:Destroy()
    animation = nil
end

local Animation = {}
Animation.storage = {}

Animation.current = nil
Animation.track = nil

for _, v in pairs(game:GetService("ReplicatedStorage").Misc.Emotes:GetChildren()) do
    if v:IsA("Animation") and v:GetAttribute("EmoteName") then
        local Emote_Name = v:GetAttribute("EmoteName")
        Animation.storage[Emote_Name] = v
    end
end

local Emotes_Data = {}

for Object in pairs(Animation.storage) do
    table.insert(Emotes_Data, Object)
end

table.sort(Emotes_Data)

local Auto_Parry = {}

function Auto_Parry.Parry_Animation()
    local Parry_Animation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default:FindFirstChild('GrabParry')
    local Current_Sword = Player.Character:GetAttribute('CurrentlyEquippedSword')

    if not Current_Sword then
        return
    end

    if not Parry_Animation then
        return
    end

    local Sword_Data = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)

    if not Sword_Data or not Sword_Data['AnimationType'] then
        return
    end

    for _, object in pairs(game:GetService('ReplicatedStorage').Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == Sword_Data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local sword_animation_type = 'GrabParry'

                if object:FindFirstChild('Grab') then
                    sword_animation_type = 'Grab'
                end

                Parry_Animation = object[sword_animation_type]
            end
        end
    end

    Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
    Grab_Parry:Play()
end

function Auto_Parry.Play_Animation(v)
    local Animations = Animation.storage[v]

    if not Animations then
        return false
    end

    local Animator = Player.Character.Humanoid.Animator

    if Animation.track then
        Animation.track:Stop()
    end

    Animation.track = Animator:LoadAnimation(Animations)
    Animation.track:Play()

    Animation.current = v
end

function Auto_Parry.Get_Balls()
    local Balls = {}

    local BallFolders = {
        workspace:FindFirstChild("Balls"),
        workspace:FindFirstChild("TrainingBalls")
    }

    for _, folder in ipairs(BallFolders) do
        if folder then
            for _, Instance in ipairs(folder:GetChildren()) do
                if Instance:GetAttribute("realBall") then
                    Instance.CanCollide = false
                    table.insert(Balls, Instance)
                end
            end
        end
    end

    return Balls
end


function Auto_Parry.Get_Ball()
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            return Instance
        end
    end
end

function Auto_Parry.Parry_Data(Parry_Type)
    local Events = {}
    local Camera = workspace.CurrentCamera

    if Last_Input == Enum.UserInputType.MouseButton1 or (Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard) then
        local Mouse_Location = UserInputService:GetMouseLocation()

        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end

    for _, v in pairs(workspace.Alive:GetChildren()) do
        Events[tostring(v)] = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
    end

    if Parry_Type == 'None' then
        return {0, Camera.CFrame, Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'Up' then
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.UpVector * 1000)), Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'Right' then
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.RightVector * 1000)), Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'Left' then
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - (Camera.CFrame.RightVector * 1000)), Events, Vector2_Mouse_Location}
    end
   
    if Parry_Type == 'Random' then
        return {0, CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-3000, 3000), math.random(-3000, 3000), math.random(-3000, 3000))), Events, Vector2_Mouse_Location}
    end

    return Parry_Type
end

local Parry_Method = "Remote"
local Parries = 0

local Sound_Effect = true
local sound_effect_type = "DC_15X"

local sound_assets = {
    DC_15X = 'rbxassetid://936447863',
    Neverlose = 'rbxassetid://8679627751',
    Minecraft = 'rbxassetid://8766809464',
    MinecraftHit2 = 'rbxassetid://8458185621',
    TeamfortressBonk = 'rbxassetid://8255306220',
    TeamfortressBell = 'rbxassetid://2868331684'
}

local function PlaySound()
    if not Sound_Effect then return end
    local sound_id = sound_assets[sound_effect_type]
    if not sound_id then return end

    local sound = Instance.new("Sound")
    sound.SoundId = sound_id
    sound.Volume = 1
    sound.PlayOnRemove = true
    sound.Parent = workspace
    sound:Destroy()
end

function Auto_Parry.Parry(Parry_Type)
    local Parry_Data = Auto_Parry.Parry_Data(Parry_Type)

    if Parry_Method == "Remote" then
        for Remote, Args in pairs(Remotes) do
            Remote:FireServer(Args, Key, unpack(Parry_Data))
        end
        
    elseif Parry_Method == "Keypress" then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        
    end

    if Parries > 7 then
        return false
    end

    Parries += 1

    task.delay(0.5, function()
        if Parries > 0 then
            Parries -= 1
        end
    end)
end 

local Lerp_Radians = 0
local Last_Warping = tick()

function Auto_Parry.Linear_Interpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end

local Previous_Velocity = {}
local Curving = tick()

local Runtime = workspace.Runtime

function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()

    if not Ball then
        return false
    end

    local Zoomies = Ball:FindFirstChild('zoomies')

    if not Zoomies then
        return false
    end

    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()

    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)

    local Speed = Velocity.Magnitude

    local Speed_Threshold = math.min(Speed / 100, 40)
    local Angle_Threshold = 40 * math.max(Dot, 0)

    local Direction_Difference = (Ball_Direction - Velocity).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)

    local Dot_Difference = Dot - Direction_Similarity
    local Dot_Threshold = 0.5 - Ping / 1000

    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Reach_Time = Distance / Speed - (Ping / 1000)

    local Enough_Speed = Speed > 100
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Angle_Threshold + Speed_Threshold

    table.insert(Previous_Velocity, Velocity)

    if #Previous_Velocity > 4 then
        table.remove(Previous_Velocity, 1)
    end

    if Enough_Speed and Reach_Time > Ping / 13 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 17, 17)
    end

    if Distance < Ball_Distance_Threshold then
        return false
    end

    if (tick() - Curving) < Reach_Time / 1.5 then --warn('Curving')
        return true
    end

    if Dot_Difference < Dot_Threshold then
        return true
    end

    local Radians = math.rad(math.asin(Dot))

    Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)

    if Lerp_Radians < 0.018 then
        Last_Warping = tick()
    end

    if (tick() - Last_Warping) < (Reach_Time / 1.5) then
        return true
    end

    if #Previous_Velocity == 4 then
        local Intended_Direction_Difference = (Ball_Direction - Previous_Velocity[1].Unit).Unit

        local Intended_Dot = Direction:Dot(Intended_Direction_Difference)
        local Intended_Dot_Difference = Dot - Intended_Dot

        local Intended_Direction_Difference2 = (Ball_Direction - Previous_Velocity[2].Unit).Unit

        local Intended_Dot2 = Direction:Dot(Intended_Direction_Difference2)
        local Intended_Dot_Difference2 = Dot - Intended_Dot2

        if Intended_Dot_Difference < Dot_Threshold or Intended_Dot_Difference2 < Dot_Threshold then
            return true
        end
    end

    if (tick() - Last_Warping) < (Reach_Time / 1.5) then
        return true
    end

    return Dot < Dot_Threshold
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

    if not Ball then
        return false
    end

    Auto_Parry.Closest_Player()

    local Spam_Accuracy = 0

    local Velocity = Ball.AssemblyLinearVelocity
    local Speed = Velocity.Magnitude

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Velocity.Unit)

    local Target_Position = Closest_Entity.PrimaryPart.Position
    local Target_Distance = Player:DistanceFromCharacter(Target_Position)

    local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6.5, 95)

    if self.Entity_Properties.Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    if self.Ball_Properties.Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    if Target_Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    local Maximum_Speed = 5 - math.min(Speed / 5, 5)
    local Maximum_Dot = math.clamp(Dot, -1, 0) * Maximum_Speed

    Spam_Accuracy = Maximum_Spam_Distance - Maximum_Dot

    return Spam_Accuracy
end

local Connections_Manager = {}
local Selected_Parry_Type = nil

local Parried = false
local Last_Parry = 0
local AutoParry = nil
local Auto_Spam = nil
local Target_Change = nil
local Selected_Parry_Type = nil
local Parried = false
local Last_Parry = 0

local MauaulSpam;
function ManualSpam()
	if MauaulSpam then
		MauaulSpam:Destroy();
		MauaulSpam = nil;
		return;
	end
	MauaulSpam = Instance.new("ScreenGui");
	MauaulSpam.Name = "MauaulSpam";
	MauaulSpam.Parent = game.CoreGui;
	MauaulSpam.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	MauaulSpam.ResetOnSpawn = false;
	local Main = Instance.new("Frame");
	Main.Name = "Main";
	Main.Parent = MauaulSpam;
	Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	Main.BorderColor3 = Color3.fromRGB(0, 0, 0);
	Main.BorderSizePixel = 0;
	Main.Position = UDim2.new(0.41414836, 0, 0.404336721, 0);
	Main.Size = UDim2.new(0.227479532, 0, 0.191326529, 0);
	local UICorner = Instance.new("UICorner");
	UICorner.Parent = Main;
	local IndercantorBlahblah = Instance.new("Frame");
	IndercantorBlahblah.Name = "IndercantorBlahblah";
	IndercantorBlahblah.Parent = Main;
	IndercantorBlahblah.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
	IndercantorBlahblah.BorderColor3 = Color3.fromRGB(0, 0, 0);
	IndercantorBlahblah.BorderSizePixel = 0;
	IndercantorBlahblah.Position = UDim2.new(0.0280000009, 0, 0.0733333305, 0);
	IndercantorBlahblah.Size = UDim2.new(0.0719999969, 0, 0.119999997, 0);
	local UICorner_2 = Instance.new("UICorner");
	UICorner_2.CornerRadius = UDim.new(1, 0);
	UICorner_2.Parent = IndercantorBlahblah;
	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint.Parent = IndercantorBlahblah;
	local PC = Instance.new("TextLabel");
	PC.Name = "PC";
	PC.Parent = Main;
	PC.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	PC.BackgroundTransparency = 1;
	PC.BorderColor3 = Color3.fromRGB(0, 0, 0);
	PC.BorderSizePixel = 0;
	PC.Position = UDim2.new(0.547999978, 0, 0.826666653, 0);
	PC.Size = UDim2.new(0.451999992, 0, 0.173333332, 0);
	PC.Font = Enum.Font.Unknown;
	PC.Text = "PC: P to spam";
	PC.TextColor3 = Color3.fromRGB(57, 57, 57);
	PC.TextScaled = true;
	PC.TextSize = 16;
	PC.TextWrapped = true;
	local UITextSizeConstraint = Instance.new("UITextSizeConstraint");
	UITextSizeConstraint.Parent = PC;
	UITextSizeConstraint.MaxTextSize = 16;
	local UIAspectRatioConstraint_2 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint_2.Parent = PC;
	UIAspectRatioConstraint_2.AspectRatio = 4.346;
	local IndercanotTextBlah = Instance.new("TextButton");
	IndercanotTextBlah.Name = "IndercanotTextBlah";
	IndercanotTextBlah.Parent = Main;
	IndercanotTextBlah.Active = false;
	IndercanotTextBlah.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	IndercanotTextBlah.BackgroundTransparency = 1;
	IndercanotTextBlah.BorderColor3 = Color3.fromRGB(0, 0, 0);
	IndercanotTextBlah.BorderSizePixel = 0;
	IndercanotTextBlah.Position = UDim2.new(0.164000005, 0, 0.326666653, 0);
	IndercanotTextBlah.Selectable = false;
	IndercanotTextBlah.Size = UDim2.new(0.667999983, 0, 0.346666664, 0);
	IndercanotTextBlah.Font = Enum.Font.GothamBold;
	IndercanotTextBlah.Text = "Spam";
	IndercanotTextBlah.TextColor3 = Color3.fromRGB(255, 255, 255);
	IndercanotTextBlah.TextScaled = true;
	IndercanotTextBlah.TextSize = 24;
	IndercanotTextBlah.TextWrapped = true;
	local UIGradient = Instance.new("UIGradient");
	UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 4)),ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))});
	UIGradient.Parent = IndercanotTextBlah;
	local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint");
	UITextSizeConstraint_2.Parent = IndercanotTextBlah;
	UITextSizeConstraint_2.MaxTextSize = 52;
	local UIAspectRatioConstraint_3 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint_3.Parent = IndercanotTextBlah;
	UIAspectRatioConstraint_3.AspectRatio = 3.212;
	local UIAspectRatioConstraint_4 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint_4.Parent = Main;
	UIAspectRatioConstraint_4.AspectRatio = 1.667;
	MauaulSpam.Name = "MauaulSpam";
	MauaulSpam.Parent = game.CoreGui;
	MauaulSpam.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	MauaulSpam.ResetOnSpawn = false;
	Main.Name = "Main";
	Main.Parent = MauaulSpam;
	Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	Main.BorderColor3 = Color3.fromRGB(0, 0, 0);
	Main.BorderSizePixel = 0;
	Main.Position = UDim2.new(0.41414836, 0, 0.404336721, 0);
	Main.Size = UDim2.new(0.227479532, 0, 0.191326529, 0);
	UICorner.Parent = Main;
	IndercantorBlahblah.Name = "IndercantorBlahblah";
	IndercantorBlahblah.Parent = Main;
	IndercantorBlahblah.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
	IndercantorBlahblah.BorderColor3 = Color3.fromRGB(0, 0, 0);
	IndercantorBlahblah.BorderSizePixel = 0;
	IndercantorBlahblah.Position = UDim2.new(0.0280000009, 0, 0.0733333305, 0);
	IndercantorBlahblah.Size = UDim2.new(0.0719999969, 0, 0.119999997, 0);
	UICorner_2.CornerRadius = UDim.new(1, 0);
	UICorner_2.Parent = IndercantorBlahblah;
	UIAspectRatioConstraint.Parent = IndercantorBlahblah;
	PC.Name = "PC";
	PC.Parent = Main;
	PC.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	PC.BackgroundTransparency = 1;
	PC.BorderColor3 = Color3.fromRGB(0, 0, 0);
	PC.BorderSizePixel = 0;
	PC.Position = UDim2.new(0.547999978, 0, 0.826666653, 0);
	PC.Size = UDim2.new(0.451999992, 0, 0.173333332, 0);
	PC.Font = Enum.Font.Unknown;
	PC.Text = "PC: P to spam";
	PC.TextColor3 = Color3.fromRGB(57, 57, 57);
	PC.TextScaled = true;
	PC.TextSize = 16;
	PC.TextWrapped = true;
	UITextSizeConstraint.Parent = PC;
	UITextSizeConstraint.MaxTextSize = 16;
	UIAspectRatioConstraint_2.Parent = PC;
	UIAspectRatioConstraint_2.AspectRatio = 4.346;
	IndercanotTextBlah.Name = "IndercanotTextBlah";
	IndercanotTextBlah.Parent = Main;
	IndercanotTextBlah.Active = false;
	IndercanotTextBlah.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	IndercanotTextBlah.BackgroundTransparency = 1;
	IndercanotTextBlah.BorderColor3 = Color3.fromRGB(0, 0, 0);
	IndercanotTextBlah.BorderSizePixel = 0;
	IndercanotTextBlah.Position = UDim2.new(0.164000005, 0, 0.326666653, 0);
	IndercanotTextBlah.Selectable = false;
	IndercanotTextBlah.Size = UDim2.new(0.667999983, 0, 0.346666664, 0);
	IndercanotTextBlah.Font = Enum.Font.GothamBold;
	IndercanotTextBlah.Text = "Spam";
	IndercanotTextBlah.TextColor3 = Color3.fromRGB(255, 255, 255);
	IndercanotTextBlah.TextScaled = true;
	IndercanotTextBlah.TextSize = 24;
	IndercanotTextBlah.TextWrapped = true;
	UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 4)),ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))});
	UIGradient.Parent = IndercanotTextBlah;
	UITextSizeConstraint_2.Parent = IndercanotTextBlah;
	UITextSizeConstraint_2.MaxTextSize = 52;
	UIAspectRatioConstraint_3.Parent = IndercanotTextBlah;
	UIAspectRatioConstraint_3.AspectRatio = 3.212;
	UIAspectRatioConstraint_4.Parent = Main;
	UIAspectRatioConstraint_4.AspectRatio = 1.667;
	local function HEUNEYP_fake_script()
		local script = Instance.new("LocalScript", IndercanotTextBlah);
		local button = script.Parent;
		local UIGredient = button.UIGradient;
		local NeedToChange = script.Parent.Parent.IndercantorBlahblah;
		local userInputService = game:GetService("UserInputService");
		local RunService = game:GetService("RunService");
		local green_Color = {ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 255, 0)),ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))};
		local red_Color = {ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 0)),ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))};
		local current_Color = red_Color;
		local target_Color = green_Color;
		local is_Green = false;
		local transition = false;
		local transition_Time = 1;
		local start_Time;
		local function startColorTransition()
			transition = true;
			start_Time = tick();
		end
		RunService.Heartbeat:Connect(function()
			if transition then
				local elapsed = tick() - start_Time;
				local alpha = math.clamp(elapsed / transition_Time, 0, 1);
				local new_Color = {};
				for i = 1, #current_Color do
					local start_Color = current_Color[i].Value;
					local end_Color = target_Color[i].Value;
					new_Color[i] = ColorSequenceKeypoint.new(current_Color[i].Time, start_Color:Lerp(end_Color, alpha));
				end
				UIGredient.Color = ColorSequence.new(new_Color);
				if (alpha >= 1) then
					transition = false;
					current_Color, target_Color = target_Color, current_Color;
				end
			end
		end);
		local function toggleColor()
			if not transition then
				is_Green = not is_Green;
				if is_Green then
					target_Color = green_Color;
					NeedToChange.BackgroundColor3 = Color3.new(0, 1, 0);
				else
					target_Color = red_Color;
					NeedToChange.BackgroundColor3 = Color3.new(1, 0, 0);
				end
				startColorTransition();
			end
		end
		button.MouseButton1Click:Connect(toggleColor);
		userInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return;
			end
			if (input.KeyCode == Enum.KeyCode.P) then
				toggleColor();
			end
		end);
		RunService.PreSimulation:Connect(function()
			if is_Green then
				for _ = 1, 10 do
					Auto_Parry.Parry('None');
				end
			end
		end);
	end
	coroutine.wrap(HEUNEYP_fake_script)();
	local function WWJM_fake_script()
		local script = Instance.new("LocalScript", Main);
		local UserInputService = game:GetService("UserInputService");
		local gui = script.Parent;
		local dragging;
		local dragInput;
		local dragStart;
		local startPos;
		local function update(input)
			local delta = input.Position - dragStart;
			local newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
			local TweenService = game:GetService("TweenService");
			local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
			local tween = TweenService:Create(gui, tweenInfo, {Position=newPosition});
			tween:Play();
		end
		gui.InputBegan:Connect(function(input)
			if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
				dragging = true;
				dragStart = input.Position;
				startPos = gui.Position;
				input.Changed:Connect(function()
					if (input.UserInputState == Enum.UserInputState.End) then
						dragging = false;
					end
				end);
			end
		end);
		gui.InputChanged:Connect(function(input)
			if ((input.UserInputType == Enum.UserInputType.MouseMovement) or (input.UserInputType == Enum.UserInputType.Touch)) then
				dragInput = input;
			end
		end);
		UserInputService.InputChanged:Connect(function(input)
			if (dragging and (input == dragInput)) then
				update(input);
			end
		end);
	end
	coroutine.wrap(WWJM_fake_script)();
end

local enableKilled = false
local enableWinner = false

local killedText = "Zephyr on top!"
local winnerText = "Zephyr on top!"

local Player = game.Players.LocalPlayer
local Announcer = Player:WaitForChild("PlayerGui"):WaitForChild("announcer")
local Killed = Announcer:WaitForChild("Killed")

Killed.Changed:Connect(function(property)
    if property == "Text" and enableKilled then
        Killed.Text = killedText
    end
end)

if enableKilled then
    Killed.Text = killedText
end

Announcer.ChildAdded:Connect(function(Value)
    if Value.Name == "Winner" then
        Value.Changed:Connect(function(Property)
            if Property == "Text" and enableWinner then
                Value.Text = winnerText
            end
        end)

        if enableWinner then
            Value.Text = winnerText
        end
    end
end)

                
function play_kill_effect(Part)
    task.defer(function()
        local bell = game:GetObjects("rbxassetid://17519762269")[1]

        bell.Name = 'Yeat_BELL'
        bell.Parent = workspace

        bell.Position = Part.Position - Vector3.new(0, 20, 0)
        bell:WaitForChild('Sound'):Play()

        game:GetService("TweenService"):Create(bell, TweenInfo.new(0.85, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
            Position = Part.Position + Vector3.new(0, 10, 0)
        }):Play()

        task.delay(5, function()
            game:GetService("TweenService"):Create(bell, TweenInfo.new(1.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
                Position = Part.Position + Vector3.new(0, 100, 0)
            }):Play()
        end)

        task.delay(6, function()
            bell:Destroy()
        end)
    end)
end

task.defer(function()
    workspace.Alive.ChildRemoved:Connect(function(child)
        if not workspace.Dead:FindFirstChild(child.Name) then
            return
        end

        if getgenv().kill_effect_Enabled then
            play_kill_effect(child.HumanoidRootPart)
        end
    end)
end)
                
local TweenService = game:GetService('TweenService')
                
task.defer(function()
	while task.wait(1) do
		if getgenv().night_mode_Enabled then
			TweenService:Create(game:GetService("Lighting"), TweenInfo.new(3), {ClockTime = 1.9}):Play()
		else
			TweenService:Create(game:GetService("Lighting"), TweenInfo.new(3), {ClockTime = 13.5}):Play()
		end
	end
end)
                

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local local_player = Players.LocalPlayer

RunService.Heartbeat:Connect(function()
    -- Ensure character and primary part exist
    if not local_player.Character or not local_player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local character = local_player.Character
    local primaryPart = character.HumanoidRootPart

    if getgenv().trail_Enabled then
        -- Check if trail already exists
        if not primaryPart:FindFirstChild("frost_sfx") then
            local trail = game:GetObjects("rbxassetid://17483658369")[1]
            trail.Name = "frost_sfx"

            -- Create attachments only if they don't exist
            local attachment0 = primaryPart:FindFirstChild("TrailAttachment0") or Instance.new("Attachment")
            local attachment1 = primaryPart:FindFirstChild("TrailAttachment1") or Instance.new("Attachment")

            attachment0.Name = "TrailAttachment0"
            attachment1.Name = "TrailAttachment1"

            attachment0.Position = Vector3.new(0, -2.411, 0)
            attachment1.Position = Vector3.new(0, 2.504, 0)

            attachment0.Parent = primaryPart
            attachment1.Parent = primaryPart

            trail.Attachment0 = attachment0
            trail.Attachment1 = attachment1
            trail.Parent = primaryPart
        end
    else
        -- Remove trail if it exists
        local existingTrail = primaryPart:FindFirstChild("frost_sfx")
        if existingTrail then
            existingTrail:Destroy()
        end
    end
end)
                
          
--//Visual Section\\
local imageOne = "http://www.roblox.com/asset/?id=14669260354"
local imageTwo = "http://www.roblox.com/asset/?id=14669262932"
local imageThree = "http://www.roblox.com/asset/?id=14669265393"
local imageFour = "http://www.roblox.com/asset/?id=14669267305"
local imageFive = "http://www.roblox.com/asset/?id=14669295808"
local imageSix = "http://www.roblox.com/asset/?id=14669271160"
local imageSeven = "http://www.roblox.com/asset/?id=14669277991"
local imageEight = "http://www.roblox.com/asset/?id=14669280746"
local imageNine = "http://www.roblox.com/asset/?id=14669288024"
local imageTen = "http://www.roblox.com/asset/?id=14669284236"

local animatedSkybox = {imageOne, imageTwo, imageThree, imageFour, imageFive, imageSix, imageSeven, imageEight, imageNine, imageTen}
local skyEnabled = false
local selectedSky = "Chip"
local skyInstance
local animationThread

local function createSkybox(imageId)
    local sky = Instance.new("Sky")
    sky.Name = "Skybox"
    for _, face in ipairs({"Bk", "Dn", "Ft", "Lf", "Rt", "Up"}) do
        sky["Skybox" .. face] = imageId
    end
    sky.Parent = game.Lighting
    return sky
end

local function startSkyAnimation()
    if animationThread then
        task.cancel(animationThread)
    end

    animationThread = task.spawn(function()
        while skyEnabled do
            for _, imageId in ipairs(animatedSkybox) do
                if not skyEnabled or not skyInstance then return end
                for _, face in ipairs({"Bk", "Dn", "Ft", "Lf", "Rt", "Up"}) do
                    skyInstance["Skybox" .. face] = imageId
                end
                task.wait(0.1) -- Ensure smooth transition
            end
        end
    end)
end

local function toggleSkybox(state)
    skyEnabled = state

    if not skyEnabled then
        if skyInstance then
            skyInstance:Destroy()
            skyInstance = nil
        end
        if animationThread then
            task.cancel(animationThread)
            animationThread = nil
        end
        return
    end

    if skyInstance then
        skyInstance:Destroy()
        skyInstance = nil
    end

    if selectedSky == "Chip" then
        skyInstance = createSkybox(animatedSkybox[1])
        startSkyAnimation()
    else
        local hackerSkies = {
            ["Hacker 1"] = "http://www.roblox.com/asset/?id=90813865565734",
            ["Hacker 2"] = "http://www.roblox.com/asset/?id=71456280558693",
            ["Hacker 3"] = "http://www.roblox.com/asset/?id=137755220586917",
            ["Hacker 4"] = "http://www.roblox.com/asset/?id=80535511784504",
            ["Hacker 5"] = "http://www.roblox.com/asset/?id=100744221087114",
            ["Hacker 6"] = "http://www.roblox.com/asset/?id=123041699352177",
            ["Hacker 7"] = "http://www.roblox.com/asset/?id=82605883543943",
            ["Hacker 8"] = "http://www.roblox.com/asset/?id=140731817259702",
            ["Hacker 9"] = "http://www.roblox.com/asset/?id=137954257088593",
            ["Hacker 10"] = "http://www.roblox.com/asset/?id=118281412966026",
            ["Hacker 11"] = "http://www.roblox.com/asset/?id=113549944602136",
            ["Hacker 12"] = "http://www.roblox.com/asset/?id=76617192996060"
        }
        skyInstance = createSkybox(hackerSkies[selectedSky])
    end
end
                
local Neverzen = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NeverZen/refs/heads/main/src/init.luau"))()
local Notification = Neverzen:CreateNotifier();

local Window = Neverzen.new({
	Name = "Zephyr",
	Keybind = Enum.KeyCode.LeftControl,
	Scale = UDim2.new(0, 611, 0, 396),
	Resizable = true,
	Shadow = true,
	Acrylic = true,
});
                
Window:AddLabel('Main')

local Tab1 = Window:AddTab({
	Name = "Home",
	Icon = "code"
})
               
local Tab2 = Window:AddTab({
	Name = "Misc",
	Icon = "eye"
})
                
Window:AddLabel('Settings')                
                
local Tab3 = Window:AddTab({
	Name = "Settings",
	Icon = "settings"
})
                
local Ap = Tab1:AddSection({
	Name = "Auto Parry",
	Position = "left"
})
                
Ap:AddToggle({
	Name = 'Auto Parry',
	Default = false,
	Callback = function(state)
  if state then
            Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()

                local One_Ball = Auto_Parry.Get_Ball()
                local Balls = Auto_Parry.Get_Balls()

                for _, Ball in pairs(Balls) do

                if not Ball then repeat task.wait() Balls = Auto_Parry.Get_Balls() until Balls
                    return
                end

                local Zoomies = Ball:FindFirstChild('zoomies')

                if not Zoomies then
                    return
                end

                Ball:GetAttributeChangedSignal('target'):Once(function()
                    Parried = false
                end)

                if Parried then
                    return
                end

                local Ball_Target = Ball:GetAttribute('target')
                local One_Target = One_Ball:GetAttribute('target')

                local Velocity = Zoomies.VectorVelocity

                local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
                local Speed = Velocity.Magnitude

                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10

                local Parry_Accuracy = (Speed / 3.25) + Ping
                local Curved = Auto_Parry.Is_Curved()

                if Ball_Target == tostring(Player) and Aerodynamic then
                    local Elasped_Tornado = tick() - Aerodynamic_Time

                    if Elasped_Tornado > 0.6 then
                        Aerodynamic_Time = tick()
                        Aerodynamic = false
                    end

                    return
                end

                if One_Target == tostring(Player) and Curved then
                    return
                end

                if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                    Auto_Parry.Parry(Selected_Parry_Type)
                    PlaySound()
                    Parried = true
                end

                local Last_Parrys = tick()

                repeat RunService.PreSimulation:Wait() until (tick() - Last_Parrys) >= 1 or not Parried
                    Parried = false
                end
            end)
        else
            if Connections_Manager['Auto Parry'] then
                Connections_Manager['Auto Parry']:Disconnect()
                Connections_Manager['Auto Parry'] = nil
            end
        end
 end,  
}) 
                
Ap:AddKeybind({
	Name = "Keybind Parry Toggle",
	Default = "",
	Callback = function(state)
  if state then
            Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()

                local One_Ball = Auto_Parry.Get_Ball()
                local Balls = Auto_Parry.Get_Balls()

                for _, Ball in pairs(Balls) do

                if not Ball then repeat task.wait() Balls = Auto_Parry.Get_Balls() until Balls
                    return
                end

                local Zoomies = Ball:FindFirstChild('zoomies')

                if not Zoomies then
                    return
                end

                Ball:GetAttributeChangedSignal('target'):Once(function()
                    Parried = false
                end)

                if Parried then
                    return
                end

                local Ball_Target = Ball:GetAttribute('target')
                local One_Target = One_Ball:GetAttribute('target')

                local Velocity = Zoomies.VectorVelocity

                local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
                local Speed = Velocity.Magnitude

                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10

                local Parry_Accuracy = (Speed / 3.25) + Ping
                local Curved = Auto_Parry.Is_Curved()

                if Ball_Target == tostring(Player) and Aerodynamic then
                    local Elasped_Tornado = tick() - Aerodynamic_Time

                    if Elasped_Tornado > 0.6 then
                        Aerodynamic_Time = tick()
                        Aerodynamic = false
                    end

                    return
                end

                if One_Target == tostring(Player) and Curved then
                    return
                end

                if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                    Auto_Parry.Parry(Selected_Parry_Type)
                    PlaySound()
                    Parried = true
                end

                local Last_Parrys = tick()

                repeat RunService.PreSimulation:Wait() until (tick() - Last_Parrys) >= 1 or not Parried
                    Parried = false
                end
            end)
        else
            if Connections_Manager['Auto Parry'] then
                Connections_Manager['Auto Parry']:Disconnect()
                Connections_Manager['Auto Parry'] = nil
            end
        end
	end,
})
                
Ap:AddDropdown({
	Name = "Parry Curve Method",
	Values = {"None","Random","Left","Right","High","Dot"},
	Default = "Random",
	Callback = function(call)
		Selected_Parry_Type = call
 end,  
})
                
Ap:AddSlider({
	Name = "Parry Accuracy",
	Min = 0,
	Max = 100,
	Round = 1,
	Default = 0,
	Type = "%",
	Callback = function(v)
		local Adjusted_Value = v / 5.5
 getgenv().Parry_Accuracy = Adjusted_Value
 end, 
})
                
Ap:AddDropdown({
	Name = "Parry Method",
	Values = {'Remote','Keypress'},
	Default = 'Remote',
	Callback = function(state)
		Parry_Method = state
 end, 
})
 
Parry_Method = "Remote"
                               
Ap:AddDropdown({
	Name = "Auto Parry methods",
	Values = {'Blatant','Non-Blatant','Legit','Ranked'},
	Default = 'Legit',
	Callback = function()
		
 end,  
})         
                
local s = Tab1:AddSection({
	Name = "Lobby Parry",
	Position = "left"
})
                
s:AddToggle({
	Name = 'Lobby Parry',
	Default = false,
	Callback = function()
		
 end,  
})  
                
   
                                 
local Lp = Tab1:AddSection({
	Name = "Parry Detection",
	Position = "left"
})

Lp:AddToggle({
	Name = 'Parry Detection',
	Default = false,
	Callback = function()
		
 end,  
}) 
                
Lp:AddDropdown({
	Name = "Detections",
	Values = {'Phantom','Sheild'},
	Default = 'Sheild',
	Callback = function()
		
 end,  
})
                
local As = Tab1:AddSection({
	Name = "Auto Spam",
	Position = "right"
})
                
As:AddToggle({
	Name = 'Auto Spam',
	Default = false,
	Callback = function(state)
		 if state then
            Connections_Manager['Auto Spam'] = RunService.PreSimulation:Connect(function()
                local Ball = Auto_Parry.Get_Ball()

                if not Ball then
                    return
                end

                local Zoomies = Ball:FindFirstChild('zoomies')

                if not Zoomies then
                    return
                end

                Auto_Parry.Closest_Player()

                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
                local Ping_Threshold = math.clamp(Ping / 10, 10, 16)

                local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                local Entity_Properties = Auto_Parry:Get_Entity_Properties()

                local Spam_Accuracy = Auto_Parry.Spam_Service({
                    Ball_Properties = Ball_Properties,
                    Entity_Properties = Entity_Properties,
                    Ping = Ping_Threshold
                })

                local Distance = Player:DistanceFromCharacter(Ball.Position)

                local Target_Position = Closest_Entity.PrimaryPart.Position
                local Target_Distance = Player:DistanceFromCharacter(Target_Position)

                local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                local Ball_Direction = Zoomies.VectorVelocity.Unit

                local Dot = Direction:Dot(Ball_Direction)
                local Ball_Target = Alive:FindFirstChild(Ball:GetAttribute('target'))

                if not Ball_Target then
                    return
                end

                if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                    return
                end

                local Ball_Targeted_Distance = Player:DistanceFromCharacter(Ball_Target.PrimaryPart.Position)

                if Distance <= Spam_Accuracy and Parries > 1 then
                    Auto_Parry.Parry(Selected_Parry_Type)
                    PlaySound()
                end
            end)
        else
            if Connections_Manager['Auto Spam'] then
                Connections_Manager['Auto Spam']:Disconnect()
                Connections_Manager['Auto Spam'] = nil
            end
        end
 end,  
}) 
                
As:AddSlider({
	Name = "Spam Accuracy",
	Min = 0,
	Max = 100,
	Round = 1,
	Default = 0,
	Type = "%",
	Callback = function(v)
		Spam_Accuracy = v
 end, 
})
                
local Ms = Tab1:AddSection({
	Name = "Manual Spam",
	Position = "right"
})
                
Ms:AddToggle({
	Name = 'Manual Spam',
	Default = false,
	Callback = function()
		ManualSpam()
 end,  
}) 
                
Ms:AddKeybind({
	Name = "Keybind Spam Toggle",
	Default = "",
	Callback = function(call)
	enabled = call
if enabled then
    table.insert(manspamcons, game:GetService("RunService").PreRender:Connect(function()
        for _ = 1, manualspamspeed do
           Auto_Parry.Parry('None')
        end
    end))
else
    for _, v in ipairs(manspamcons) do
        v:Disconnect()
    end
    table.clear(manspamcons)
end
	end,
})
   
Ms:AddSlider({
	Name = "Spam Speed",
	Min = 0,
	Max = 100,
	Round = 1,
	Default = 15,
	Type = "%",
	Callback = function(call)
		 manualspamspeed = tonumber(call)
 end, 
})
                
local D = Tab1:AddSection({
	Name = "Debug",
	Position = "right"
})
                
D:AddButton({
	Name = "Debug Gui",
	Callback = function()
		loadstring(game:HttpGet("https://pastebin.com/raw/cUeuDEAD"))()
	end,
})
 
local se = Tab2:AddSection({
	Name = "Hit sound",
	Position = "left"
})
                
se:AddToggle({
	Name = 'Hit sound',
	Default = false,
	Callback = function(state)
		Sound_Effect = state
 end,  
}) 
    
se:AddDropdown({
	Name = "Hit sound Type",
	Values = {'DC_15X','Neverlose','Minecraft','MinecraftHit2','TeamfortressBonk','TeamfortressBell'},
	Default = 'DC_15X',
	Callback = function(call)
		sound_effect_type = call
 end,  
})
                
local sean = Tab2:AddSection({
	Name = "Skybox",
	Position = "left"
})
                
sean:AddToggle({
	Name = 'Skybox',
	Default = false,
	Callback = function(state)
		toggleSkybox(state)
 end,  
}) 
    
sean:AddDropdown({
	Name = "Skybox Type",
	Values = {'Chip'},
	Default = 'Chip',
	Callback = function(call)
		selectedSky = selected
        if skyEnabled then
       toggleSkybox(true)
     end
 end,  
})
                
local e = Tab2:AddSection({
	Name = "Animations",
	Position = "right"
})
                
e:AddToggle({
	Name = 'Animations',
	Default = false,
	Callback = function(state)
		getgenv().Animations = state

    if getgenv().Animations then
        Connections_Manager['Animations'] = RunService.Heartbeat:Connect(function()

            if not Player.Character.PrimaryPart then
                return
            end

            local Speed = Player.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude

            if Speed > 30 then
                if Animation.track then
                    Animation.track:Stop()

                    Animation.track:Destroy()
                    Animation.track = nil
                    end
                else
                    if not Animation.track and Animation.current then
                        Auto_Parry.Play_Animation(Animation.current)
                    end
            end
        end)
        else
            if Animation.track then
                Animation.track:Stop()
                Animation.track:Destroy()

                Animation.track = nil
            end

            if Connections_Manager['Animations'] then
                Connections_Manager['Animations']:Disconnect()
                Connections_Manager['Animations'] = nil
            end
        end
 end,  
}) 
    
e:AddDropdown({
	Name = "Animation Type",
	Values = Emotes_Data,
	Default = 'None',
	Callback = function(selected)
		Auto_Parry.Play_Animation(selected)
 end,  
})
                
local seee = Tab2:AddSection({
	Name = "Trail",
	Position = "right"
})
                
seee:AddToggle({
	Name = 'Trail',
	Default = false,
	Callback = function(state)
		getgenv().trail_Enabled = state
 end,  
}) 
                
local sexee = Tab2:AddSection({
Name = "Kill effect",
	Position = "right"
})
                
sexee:AddToggle({
	Name = 'kill effect',
	Default = false,
	Callback = function(state)
		getgenv().kill_effect_Enabled = state
 end,  
}) 
                
               
local sexeex = Tab2:AddSection({
	Name = "No render",
	Position = "left"
})
                
sexeex:AddToggle({
	Name = 'No render',
	Default = false,
	Callback = function(state)
		Player.PlayerScripts.EffectScripts.ClientFX.Disabled = state

    if state then
        Connections_Manager['No Render'] = workspace.Runtime.ChildAdded:Connect(function(Value)
            Debris:AddItem(Value, 0)
        end)
    else
        if Connections_Manager['No Render'] then
                Connections_Manager['No Render']:Disconnect()
                Connections_Manager['No Render'] = nil
            end
        end
 end,  
}) 
                
local gg = Tab2:AddSection({
	Name = "Announcer",
	Position = "left"
})
                
gg:AddToggle({
	Name = 'Kill text',
	Default = false,
	Callback = function(state)
enableKilled = state
 end,  
})
                
gg:AddToggle({
	Name = 'Winner text',
	Default = false,
	Callback = function(state)
enableWinner = state
 end,  
}) 
                
gg:AddDropdown({
	Name = "Winner Text type",
	Values = {'Zephyr on top!','GG ZEPHYR WON THIS ROUND'},
	Default = 'Zephyr on top!',
	Callback = function(call)
	  winnerText = call
 end,  
})
                
gg:AddDropdown({
	Name = "Kill Text type",
	Values = {'Zephyr on top!','Nigga died of Zephyr'},
	Default = 'Zephyr on top!',
	Callback = function(call)
	  killedText = call
 end,  
})

local ggt = Tab3:AddSection({
	Name = "Frame",
	Position = "left"
})
             
ggt:AddSlider({
	Name = "Slider",
	Min = 0,
	Max = 1000,
	Round = 1,
	Default = 50,
	Type = "%",
	Callback = function(v)
	  setfpscap(v)
 end,  
})
                
                
Notification.new('Loaded Zephyr','Zypher had been succesfully loaded :3',10)                
                               
ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
    if root.Parent and root.Parent ~= Player.Character then
        if root.Parent.Parent ~= workspace.Alive then
            return
        end
    end

    Auto_Parry.Closest_Player()

    local Ball = Auto_Parry.Get_Ball()

    if not Ball then
        return
    end

    if not Grab_Parry then
        return
    end

    Grab_Parry:Stop()
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if Player.Character.Parent ~= workspace.Alive then
        return
    end

    if not Grab_Parry then
        return
    end

    Grab_Parry:Stop()
end)

Runtime.ChildAdded:Connect(function(Value)
    if Value.Name == 'Tornado' then
        Aerodynamic_Time = tick()
        Aerodynamic = true
    end
end)

workspace.Balls.ChildAdded:Connect(function()
    Parried = false
end)

workspace.Balls.ChildRemoved:Connect(function()
    Parries = 0
    Parried = false

    if Connections_Manager['Target Change'] then
        Connections_Manager['Target Change']:Disconnect()
        Connections_Manager['Target Change'] = nil
    end
end)
