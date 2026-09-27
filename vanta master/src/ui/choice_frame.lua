-- Vanta Choice Frame UI
-- Adapted from Project Rain ChoiceFrame with Vanta styling

local ChoiceFrame = {
	["_ChoiceFrameUI"] = Instance.new("ScreenGui");
	["_Frame"] = Instance.new("Frame");
	["_TextLabel"] = Instance.new("TextLabel");
	["_Yes"] = Instance.new("TextButton");
	["_UIGradient"] = Instance.new("UIGradient");
	["_No"] = Instance.new("TextButton");
	["_UIGradient1"] = Instance.new("UIGradient");
	["_UIPadding"] = Instance.new("UIPadding");
	["_UIGradient2"] = Instance.new("UIGradient");
	["_UIStroke"] = Instance.new("UIStroke");
}

-- Screen GUI Setup (Vanta themed)
ChoiceFrame["_ChoiceFrameUI"].IgnoreGuiInset = true
ChoiceFrame["_ChoiceFrameUI"].SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
ChoiceFrame["_ChoiceFrameUI"].ScreenInsets = Enum.ScreenInsets.None
ChoiceFrame["_ChoiceFrameUI"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ChoiceFrame["_ChoiceFrameUI"].Name = "VantaChoiceFrame"
ChoiceFrame["_ChoiceFrameUI"].Parent = game:GetService("CoreGui")

-- Main Frame (Dark purple theme matching Vanta #7C5CBF)
ChoiceFrame["_Frame"].AnchorPoint = Vector2.new(0.5, 0.5)
ChoiceFrame["_Frame"].BackgroundColor3 = Color3.fromRGB(30, 25, 50) -- Dark purple
ChoiceFrame["_Frame"].BorderColor3 = Color3.fromRGB(0, 0, 0)
ChoiceFrame["_Frame"].BorderSizePixel = 2
ChoiceFrame["_Frame"].Position = UDim2.new(0.5, 0, 0.5, 0)
ChoiceFrame["_Frame"].Size = UDim2.new(0, 300, 0, 180)
ChoiceFrame["_Frame"].Parent = ChoiceFrame["_ChoiceFrameUI"]

-- Text Label
ChoiceFrame["_TextLabel"].Font = Enum.Font.GothamSemibold
ChoiceFrame["_TextLabel"].Text = "Proceed with this action?"
ChoiceFrame["_TextLabel"].TextColor3 = Color3.fromRGB(220, 215, 235)
ChoiceFrame["_TextLabel"].TextSize = 15
ChoiceFrame["_TextLabel"].TextStrokeTransparency = 0
ChoiceFrame["_TextLabel"].TextWrapped = true
ChoiceFrame["_TextLabel"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ChoiceFrame["_TextLabel"].BackgroundTransparency = 1
ChoiceFrame["_TextLabel"].BorderColor3 = Color3.fromRGB(0, 0, 0)
ChoiceFrame["_TextLabel"].BorderSizePixel = 0
ChoiceFrame["_TextLabel"].Size = UDim2.new(1, 0, 1, -30)
ChoiceFrame["_TextLabel"].Parent = ChoiceFrame["_Frame"]

-- Yes Button
ChoiceFrame["_Yes"].Font = Enum.Font.GothamBold
ChoiceFrame["_Yes"].Text = "Yes"
ChoiceFrame["_Yes"].TextColor3 = Color3.fromRGB(220, 215, 235)
ChoiceFrame["_Yes"].TextSize = 13
ChoiceFrame["_Yes"].BackgroundColor3 = Color3.fromRGB(50, 35, 80) -- Purple
ChoiceFrame["_Yes"].BorderColor3 = Color3.fromRGB(124, 92, 191) -- Vanta accent
ChoiceFrame["_Yes"].BorderSizePixel = 2
ChoiceFrame["_Yes"].Position = UDim2.new(0, 5, 1, -25)
ChoiceFrame["_Yes"].Size = UDim2.new(0.5, -7, 0, 20)
ChoiceFrame["_Yes"].Name = "Yes"
ChoiceFrame["_Yes"].Parent = ChoiceFrame["_Frame"]

-- Yes Button Gradient
ChoiceFrame["_UIGradient"].Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 92, 191)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 60, 150))
}
ChoiceFrame["_UIGradient"].Rotation = 90
ChoiceFrame["_UIGradient"].Parent = ChoiceFrame["_Yes"]

-- No Button
ChoiceFrame["_No"].Font = Enum.Font.GothamBold
ChoiceFrame["_No"].Text = "No"
ChoiceFrame["_No"].TextColor3 = Color3.fromRGB(220, 215, 235)
ChoiceFrame["_No"].TextSize = 13
ChoiceFrame["_No"].BackgroundColor3 = Color3.fromRGB(50, 35, 80)
ChoiceFrame["_No"].BorderColor3 = Color3.fromRGB(100, 100, 120)
ChoiceFrame["_No"].BorderSizePixel = 2
ChoiceFrame["_No"].Position = UDim2.new(0.5, 2, 1, -25)
ChoiceFrame["_No"].Size = UDim2.new(0.5, -7, 0, 20)
ChoiceFrame["_No"].Name = "No"
ChoiceFrame["_No"].Parent = ChoiceFrame["_Frame"]

-- No Button Gradient
ChoiceFrame["_UIGradient1"].Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 70, 90))
}
ChoiceFrame["_UIGradient1"].Rotation = 90
ChoiceFrame["_UIGradient1"].Parent = ChoiceFrame["_No"]

-- Padding
ChoiceFrame["_UIPadding"].PaddingBottom = UDim.new(0, 6)
ChoiceFrame["_UIPadding"].PaddingLeft = UDim.new(0, 6)
ChoiceFrame["_UIPadding"].PaddingRight = UDim.new(0, 6)
ChoiceFrame["_UIPadding"].PaddingTop = UDim.new(0, 6)
ChoiceFrame["_UIPadding"].Parent = ChoiceFrame["_Frame"]

-- Frame Gradient (subtle accent)
ChoiceFrame["_UIGradient2"].Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 35, 80)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 25, 50))
}
ChoiceFrame["_UIGradient2"].Rotation = 90
ChoiceFrame["_UIGradient2"].Parent = ChoiceFrame["_Frame"]

-- UI Stroke (Vanta accent color)
ChoiceFrame["_UIStroke"].Color = Color3.fromRGB(124, 92, 191) -- Vanta accent
ChoiceFrame["_UIStroke"].LineJoinMode = Enum.LineJoinMode.Miter
ChoiceFrame["_UIStroke"].Thickness = 2
ChoiceFrame["_UIStroke"].ZIndex = 0
ChoiceFrame["_UIStroke"].Parent = ChoiceFrame["_Frame"]

-- Public API
return {
	set = function(prompt_text, yes_callback, no_callback, yes_text, no_text)
		local ready = false

		-- Update text
		ChoiceFrame["_TextLabel"].Text = prompt_text or "Proceed with this action?"
		ChoiceFrame["_No"].Text = no_text or "No"
		ChoiceFrame["_Yes"].Text = yes_text or "Yes"

		-- Yes Button Handler
		ChoiceFrame["_Yes"].Activated:Connect(function()
			task.spawn(xpcall, yes_callback or function() end, warn)
			ChoiceFrame["_ChoiceFrameUI"]:Destroy()
			ready = true
		end)

		-- No Button Handler
		ChoiceFrame["_No"].Activated:Connect(function()
			task.spawn(xpcall, no_callback or function() end, warn)
			ChoiceFrame["_ChoiceFrameUI"]:Destroy()
			ready = true
		end)

		-- Wait for user response
		repeat task.wait() until ready
	end
}
