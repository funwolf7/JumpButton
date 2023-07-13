--!strict

--[[
	JumpButton by funwolf7
	Version 1.0.0
]]

local Players: Players = game:GetService("Players")
local RunService: RunService = game:GetService("RunService")

local LocalPlayer: Player? = Players.LocalPlayer
assert(LocalPlayer, "JumpButton must only be required on the client.")

local defaultBufferDuration: number?
local shouldAutoKillOnJump: boolean = true

local isPressed: boolean = false
local bufferStart: number?

local OnPressBindable: BindableEvent = Instance.new("BindableEvent")
local OnReleaseBindable: BindableEvent = Instance.new("BindableEvent")

RunService:BindToRenderStep("JumpButtonRunner", Enum.RenderPriority.Input.Value + 1, function(): ()
	local character: Model? = LocalPlayer.Character
	if character then
		local humanoid: Humanoid? = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local newState: boolean = humanoid.Jump

			if newState ~= isPressed then
				isPressed = newState

				if newState then
					bufferStart = os.clock()
					OnPressBindable:Fire()
				else
					bufferStart = nil
					OnReleaseBindable:Fire()
				end
			end
		end
	end
end)

local JumpButton = {}

--[[
	An RBXScriptSignal that fires whenever the result of `JumpButton.isPressed` changes from false to true.
]]
JumpButton.OnPress = OnPressBindable.Event
--[[
	An RBXScriptSignal that fires whenever the result of `JumpButton.isPressed` changes from true to false.
]]
JumpButton.OnRelease = OnReleaseBindable.Event

--[[
	Sets the default buffer duration for the library.
	The default buffer duration is used for `JumpButton.useIsBuffered` and `JumpButton.peekIsBuffered`.
	If newBufferDuration is nil, these functions will not have a maximum time.
]]
function JumpButton.setDefaultBufferDuration(newBufferDuration: number?): ()
	defaultBufferDuration = newBufferDuration
end

--[[
	Sets if it should automatically kill the buffer when Humanoid.Jumping fires on the local player's humanoid.
	Defaults to true.
]]
function JumpButton.setAutoKillOnJump(shouldAutoKill: boolean): ()
	shouldAutoKillOnJump = shouldAutoKill
end


--[[
	Returns true if the jump button is currently being held down, false otherwise.
]]
function JumpButton.isPressed(): boolean
	return isPressed
end

--[[
	Sets the current buffer start to nil, effectively preventing code from detecting a buffer.
	It will be set to a number when the jump button is pressed again.
]]
function JumpButton.killBuffer(): ()
	bufferStart = nil
end

--[[
	Returns the current buffer start, if any.
	The buffer start is a timestamp from os.clock.
	It is not affected by the default buffer duration.

	This function will not affect the buffer start.
	If you want to automatically kill the buffer, use `JumpButton.useBufferStart`.
]]
function JumpButton.peekBufferStart(): number?
	return bufferStart
end

--[[
	Returns the current buffer start, if any.
	The buffer start is a timestamp from os.clock.
	It is not affected by the default buffer duration.

	This function will automatically kill the buffer.
	If you do not wish to do so, use `JumpButton.peekBufferStart`.
]]
function JumpButton.useBufferStart(): number?
	local currentBufferStart: number? = bufferStart
	JumpButton.killBuffer()
	return currentBufferStart
end

--[[
	Returns whether or not there is a buffer, based on the default buffer duration.
	Specifically, if the time since the buffer began is less than or equal to the default buffer duration.
	If there is no default buffer duration, it will return true if there is a buffer start, false otherwise.

	This function will not affect the buffer start.
	If you want to automatically kill the buffer, use `JumpButton.useIsBuffered`.
]]
function JumpButton.peekIsBuffered(): boolean
	if not bufferStart then
		return false
	end
	if not defaultBufferDuration then
		return true
	end
	return os.clock() - bufferStart <= defaultBufferDuration
end

--[[
	Returns whether or not there is a buffer, based on the default buffer duration.
	Specifically, if the time since the buffer began is less than or equal to the default buffer duration.
	If there is no default buffer duration, it will return true if there is a buffer start, false otherwise.

	This function will automatically kill the buffer.
	If you do not wish to do so, use `JumpButton.peekIsBuffered`.
]]
function JumpButton.useIsBuffered(): boolean
	local isBuffered: boolean = JumpButton.peekIsBuffered()
	JumpButton.killBuffer()
	return isBuffered
end

do -- Automatically kill buffers on Humanoid.Jumping
	local globalConnection: RBXScriptConnection?
	local function onCharacterAdded(character: Model?): ()
		if not character then
			return
		end

		if globalConnection then
			globalConnection:Disconnect()
			globalConnection = nil
		end

		local newConnection: RBXScriptConnection?
		newConnection = character.ChildAdded:Connect(function(newChild: Instance)
			if newChild:IsA("Humanoid") and newConnection then
				newConnection:Disconnect()
				if globalConnection == newConnection then
					globalConnection = nil
				end
				newConnection = nil

				newChild.Jumping:Connect(function(isActive: boolean)
					if isActive and shouldAutoKillOnJump then
						JumpButton.killBuffer()
					end
				end)
			end
		end)
		globalConnection = newConnection
	end
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	onCharacterAdded(LocalPlayer.Character)
end

table.freeze(JumpButton)
return JumpButton