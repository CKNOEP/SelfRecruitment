MessageQueue = {}

local queue = {}
local updaterFrame
local queueFrame
local pixelFrame
local flashTimer

-- ============================================
-- Compatibility layer for TBC and Wrath
-- ============================================
local WOW_PROJECT_ID = WOW_PROJECT_MAINLINE
local isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)

-- Timer compatibility - DISABLED FOR TBC
local function StartFlashTimer()
	-- Flash timer disabled - not critical for addon functionality
	-- This timer was only used to flash the client icon
end

local function CancelFlashTimer()
	if flashTimer then
		if flashTimer.Cancel then
			flashTimer:Cancel()
		else
			flashTimer:Hide()
		end
	end
end

-- FlashClientIcon is a WoW C function that flashes the client icon
-- We'll call it safely if it exists
local function SafeSafeFlashClientIcon()
	if _G.FlashClientIcon then
		_G.SafeFlashClientIcon()
	end
end

-- SetColorTexture compatibility (may not exist in TBC, use SetTexture as fallback)
local function SetTextureSafe(texture, r, g, b, a)
	if texture.SetColorTexture then
		texture:SetColorTexture(r, g, b, a)
	else
		-- TBC fallback
		texture:SetTexture(1, 1, 1)
		texture:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, a)
	end
end

-- Frame method compatibility for gamepad (doesn't exist in TBC)
local function EnableGamePadSafe(frame)
	if frame.EnableGamePadButton then
		frame:EnableGamePadButton(true)
	end
	if frame.EnableGamePadStick then
		frame:EnableGamePadStick(true)
	end
end

-- Script compatibility for gamepad events
local function SetGamePadScriptsSafe(frame)
	if frame.SetScript then
		if not isTBC then
			frame:SetScript("OnGamePadButtonDown", MessageQueue.Run)
			frame:SetScript("OnGamePadButtonUp", MessageQueue.Run)
			frame:SetScript("OnGamePadStick", MessageQueue.Run)
		end
	end
end

--- Main initialization
--
MessageQueue.Init = function()
	-- Create gray pixel frame at the top left corner for external key triggering
	pixelFrame = CreateFrame('Frame', 'MessageQueuePixelFrame')
	pixelFrame:SetSize(1, 1)
	pixelFrame:SetPoint('TOPLEFT')
	pixelFrame:Hide()
	pixelFrame.texture = pixelFrame:CreateTexture('MessageQueueFrameTexture', 'OVERLAY', nil, 7)
	SetTextureSafe(pixelFrame.texture, 0.2, 0.2, 0.2, 1) -- #333333
	pixelFrame.texture:SetAllPoints()

	-- Create queue frame to capture hardware events and proceed with the queue
	queueFrame = CreateFrame('Frame', 'MessageQueueFrame')
	queueFrame:SetPoint('TOPLEFT')
	queueFrame:SetPoint('BOTTOMRIGHT')
	queueFrame:Hide()

	-- Enable any possible hardware control
	queueFrame:EnableMouse(true)
	queueFrame:EnableMouseWheel(true)
	queueFrame:SetMouseMotionEnabled(true)
	EnableGamePadSafe(queueFrame)
	queueFrame:EnableKeyboard(true)
	queueFrame:SetPropagateKeyboardInput(true)

	-- Capture any possible hardware event
	queueFrame:SetScript("OnMouseDown", MessageQueue.Run)
	queueFrame:SetScript("OnMouseUp", MessageQueue.Run)
	queueFrame:SetScript("OnMouseWheel", MessageQueue.Run)
	SetGamePadScriptsSafe(queueFrame)
	queueFrame:SetScript("OnKeyDown", MessageQueue.Run)
	queueFrame:SetScript("OnKeyUp", MessageQueue.Run)

	-- Create updater frame
	updaterFrame = CreateFrame('Frame')
	updaterFrame:SetScript('OnUpdate', function()
		if #queue > 0 then
			local frameLevel = UIParent:GetFrameLevel() + 1000
			queueFrame:SetFrameStrata('TOOLTIP')
			queueFrame:SetFrameLevel(frameLevel)
			queueFrame:Show()
			pixelFrame:SetFrameStrata('TOOLTIP')
			pixelFrame:SetFrameLevel(frameLevel)
			pixelFrame:Show()
		else
			queueFrame:Hide()
			pixelFrame:Hide()
		end
	end)

	-- Declare commands
	SlashCmdList["MESSAGEQUEUE"] = MessageQueue.Run
	SLASH_MESSAGEQUEUE1 = "/mq"
	SLASH_MESSAGEQUEUE2 = "/msgqueue"
	SLASH_MESSAGEQUEUE3 = "/messagequeue"
end

--- Enqueue a function
-- @param f (function)
MessageQueue.Enqueue = function(f)
	table.insert(queue, f)
	StartFlashTimer()
end

--- Enqueue a chat message.
-- Same parameters as the regular SendChatMessage
-- Allows an optional callback that will run after the message has been sent.
-- The callback sould not contain any other hardware triggered function.
-- @param msg (string)
-- @param chatType (string)
-- @param [languageID (string)]
-- @param [channel (string)]
-- @param [callback (function)]
MessageQueue.SendChatMessage = function(msg, chatType, languageID, channel, callback)
	
			
	if chatType == 'CHANNEL' or chatType == 'SAY' or chatType == 'YELL' then
	print (msg)	
	MessageQueue.Enqueue(function()
			SendChatMessage(msg, chatType, languageID, channel)
			if callback then
				callback()
			end
		end)
	
	else
	print (msg)
		SendChatMessage(msg, chatType, languageID, channel)
		if callback then
			callback()
		end
	
	end
		
end

--- Run the first item in the queue
-- Should be triggered by a hardware event
MessageQueue.Run = function()
	CancelFlashTimer()
	while #queue > 0 do
		table.remove(queue, 1)()
	end
end

--- Returns the number of messages awaiting in queue
-- @return numPendingMessages (number)
MessageQueue.GetNumPendingMessages = function()
	return #queue
end

-- Initialize on startup
MessageQueue.Init()
