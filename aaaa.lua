-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ScreenGui
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "ModernGUI"
gui.ResetOnSpawn = false

-- Drag Function
local function makeDraggable(frame)
	local dragging, dragInput, mousePos, framePos

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			frame.Position = UDim2.new(
				framePos.X.Scale, framePos.X.Offset + delta.X,
				framePos.Y.Scale, framePos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Main Frame
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 350, 0, 200)
frame.Position = UDim2.new(0.5, -175, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.BackgroundTransparency = 0
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Visible = true
frame.Name = "MainFrame"

-- Corner
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

makeDraggable(frame)

-- Close Button
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
closeBtn.BorderSizePixel = 0

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
	TweenService:Create(frame, TweenInfo.new(0.4), {Transparency = 1, Position = frame.Position + UDim2.new(0, 0, 0.1, 0)}):Play()
	wait(0.4)
	gui:Destroy()
end)

-- Paragraph Text
local paragraph = Instance.new("TextLabel", frame)
paragraph.Size = UDim2.new(1, -40, 0, 80)
paragraph.Position = UDim2.new(0, 20, 0, 40)
paragraph.BackgroundTransparency = 1
paragraph.Text = "Press Copy Scripts To Get New Scripts!!"
paragraph.TextColor3 = Color3.fromRGB(230, 230, 240)
paragraph.Font = Enum.Font.Gotham
paragraph.TextSize = 16
paragraph.TextWrapped = true
paragraph.TextXAlignment = Enum.TextXAlignment.Left

-- Copy Button
local copyBtn = Instance.new("TextButton", frame)
copyBtn.Size = UDim2.new(0.5, 0, 0, 40)
copyBtn.Position = UDim2.new(0.25, 0, 1, -50)
copyBtn.Text = "Copy Scripts"
copyBtn.TextSize = 16
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)

Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 10)

copyBtn.MouseButton1Click:Connect(function()
	setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/NodeX-Enc/NodeX/main/Main.lua"))()') 
	copyBtn.Text = "Copied!"
	wait(1.5)
	copyBtn.Text = "Copy Scripts"
end)
