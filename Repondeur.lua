--[[----------------------------------------------
Repondeur rebuild by lancestre - created by Ayradyss in the first and enhanced by Chef de Loup and LenweSaralonde

The features of the mod in the following:
- multiply responses with multiply keywords for each response
- responses can be handled as text with links or as script code
- several controls for each response for input and output of a response
--]]-----------------------------------------------


--[[-----------------------------------------------
global variables
--]]-----------------------------------------------
RepondeurMainOptions = {}; -- SavedVariable - MainOptions
RepondeurOptions = {}; -- SavedVariable - Responds and Options

local Realm; -- realm of active player
local Player; -- name of active player

local getglobal = getglobal; -- Speed up ggvar

local VariablesLoaded = 1; -- flag to check if Variables was loaded
local Initialized = nil; -- flag to check if previous initialize

local ActiveOption = 1; -- position of actual respond
local AR_Version = "1.0.0 Reborn"; -- version of AR

local AR_SpamCheck = nil; -- status of spamcheck
local AR_SpamList = {}; -- each entry consists of the name of the whisperer and the time of the last whisper

--[[--------------------------------------------------------------------------------------------
functions for the main frame
--]]--------------------------------------------------------------------------------------------


--[[-----------------------------------------------
function for registering main events and slashcommands of the mod
--]]-----------------------------------------------
function Repondeur_OnLoad(event, self)
	-- register main events
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_LEAVING_WORLD");
	self:RegisterEvent("VARIABLES_LOADED");

	
	-- register slashcommand and handler function
	SlashCmdList["Repondeur"] = Repondeur_SlashHandler;
	SLASH_Repondeur1 = "/Repondeur";
	SLASH_Repondeur2 = "/rep";
	SLASH_Repondeur3 = "/respondeur";
	SLASH_Repondeur4 = "/recruitement";
	SLASH_Repondeur5 = "/recruit";
	
	VariablesLoaded = 1;
	Repondeur_InitializeSetup();
end


--[[-----------------------------------------------
function for initializing the mod
this function only works once when all needed variables are loaded
--]]-----------------------------------------------
function Repondeur_InitializeSetup()
	-- check if previous initialized or variables are not loaded
	if not Initialized and VariablesLoaded then
		-- get realm and playername
		Player = UnitFullName("player");
		Realm = GetRealmName();
	
		-- initialize SavedVariables if not given
		if RepondeurMainOptions[Realm] == nil then RepondeurMainOptions[Realm] = {}; end
		if RepondeurMainOptions[Realm][Player] == nil then
			RepondeurMainOptions[Realm][Player] = { ActiveMod = 1, InFight = nil, Scaling = 1.0, SpamCheck = nil, SpamTimer = 60.0 };
		end
		
		if(RepondeurOptions[Realm] == nil) then RepondeurOptions[Realm] = {}; end
		if(RepondeurOptions[Realm][Player] == nil) then 
			RepondeurOptions[Realm][Player] = {};
			table.insert( RepondeurOptions[Realm][Player],{ Active = nil, Script = nil, Keywords = {AUTO_RESPOND_DEFAULT_KEYWORD_TEXT}, Response = {AUTO_RESPOND_DEFAULT_RESPONSE_TEXT}, Options = { Receive = { Guild = nil, Party = nil, Raid = nil, Friends = nil, Names = {} }, Tell = { Guild = nil, Party = nil, Raid = nil } } } );
		end
	
		-- secure function for hooking 
		hooksecurefunc("SetItemRef",Repondeur_SetItemRef)
		RepondeurFrame:SetScale(RepondeurMainOptions[Realm][Player]["Scaling"]);
		
		-- Loaded Message
		DEFAULT_CHAT_FRAME:AddMessage(string.format(AUTO_RESPOND_LOADED_TEXT,AR_Version));
		Initialized = 1;
	end
	
	if VariablesLoaded and RepondeurMainOptions[Realm][Player]["ActiveMod"] then
		RepondeurFrame:RegisterEvent("CHAT_MSG_WHISPER")	
		RepondeurFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
		RepondeurFrame:RegisterEvent("GROUP_INVITE_CONFIRMATION")
		
		RepondeurFrame:SetScript("OnEvent", function(__, event, arg1, arg2, arg3, arg4)
			--[[-----------------------------------------------
			functions for handling the whisper
			--]]-----------------------------------------------		
				print (event, arg1, arg2, arg3, arg4)
			local sender = arg2
			local msg = arg1
			
			if not sender then return end
			--local formatSenderApos = sender:gsub("%'", "") -- remove ' in realm name, if any
			--local formatSenderSpc = sender:gsub(" ", "") -- remove space in realm name, if any
			--print(formatSenderSpc, formatSenderApos);
				
			if status == "GM" then
				DEFAULT_CHAT_FRAME:AddMessage("::: Repondeur ::: GM MESSAGE DETECTED, NOT REPLYING"); -- Don't want to be auto replying and such to a GM
			else
				if RepondeurMainOptions[Realm][Player]["InFight"] and UnitAffectingCombat("player") then
					SendChatMessage(AUTO_RESPOND_DEFAULT_INFIGHT_MESSAGE, "WHISPER", GetDefaultLanguage("player"), sender);
				else
					local respond_id = Repondeur_CheckMessage(msg, 1);
					print (respond_id,msg)
					if not Repondeur_SpamCheck(sender, respond_id) then
						while respond_id do
							Repondeur_SendRespond(sender, respond_id);
							respond_id = Repondeur_CheckMessage(msg, respond_id+1);
						end
					end
				end
			end
		
		
		
		end)
	end
end



function Repondeur_whispHandler(self,event,msg,sender)


end
--[[--------------------------------------------------------------------------------------------
system functions for the mod
--]]--------------------------------------------------------------------------------------------

--[[-----------------------------------------------
hook function for getting links from chat links 
Parameter:
	link - the link of the item as itemid
	text - the link as text
	button - identifier of the button that was pressed 
--]]-----------------------------------------------
function Repondeur_SetItemRef(link,text,button)
	-- check if you should include the link in responsetext
	if ( IsShiftKeyDown() ) and ( RepondeurFrame:IsVisible() ) then
		RepondeurFrame_ResponseFrame_ScrollFrameResponse_ListResponse:Insert(text);
	end
end


--[[-----------------------------------------------
slashhandler of the addon
Parameter:
	msg - the message that was given with the slashcommand
--]]-----------------------------------------------
function Repondeur_SlashHandler(msg)
	if string.find(msg,"options") then
		RepondeurOptionsFrame:Show();
	else
		-- none of these above then just show the mainframe of the mod
		RepondeurFrame:Show();
	end
end


--[[--------------------------------------------------------------------------------------------
functions for the responses
--]]--------------------------------------------------------------------------------------------


--[[-----------------------------------------------
function for checking of spam by time
the function looks through the spam list and clears out-dated entries
Parameter:
	who - the name of the whisperer
	id - id of the response if found
Return
	returns nil if whisperer is not spamming else 1 to stop sending respond
--]]-----------------------------------------------
function Repondeur_SpamCheck(who,id)
	local ret,timer = nil,RepondeurMainOptions[Realm][Player]["SpamTimer"];
	if RepondeurMainOptions[Realm][Player]["SpamCheck"] and id then
		for i,k in ipairs(AR_SpamList) do
			if GetTime() - k["Time"] >= timer then
				table.remove(AR_SpamList,i);
			else
				if k["Name"] == who then
					ret = 1;
					k["Time"] = GetTime();
				end
			end
		end
		if not ret then
			local w,t = who,GetTime();
			table.insert( AR_SpamList, { Name = w,Time = t } );
		end
	end
	return ret;
end


--[[-----------------------------------------------
function for checking the whisper to get a response to
Parameter:
	what - the message that was given in the whisper
	index - the index of the response to start from searching
Return
	returns the index of a response that have a matching keyword to the whispered text
	the returned index could be the value of the passed index or higher
	if no match can be found the return value will be nil
--]]-----------------------------------------------
function Repondeur_CheckMessage(what,index)
	local t = RepondeurOptions[Realm][Player]; 
	--print (what,getn(t))
	-- start at given respondindex until last respond
	if what then
	for i=index,getn(t) do
		-- respond is active?
		if t[i]["Active"] then
			-- check if keyword(s) is found in whisper
			--print ("t[i][Active] ",t[i]["Active"] )
			for k,v in ipairs(t[i]["Keywords"]) do
		
				--print(string.lower(what), string.lower(v))
				if string.find(string.lower(what), string.lower(v), 1, true)  then
					-- return immediately with index of matched respond 
					--print("what,v,t,i", string.lower(what))
					return i;
				else
					if v == AUTO_RESPOND_DEFAULT_KEYWORD_TEXT then
					return i;
					end
				end
			end
		end
	end
	end
	return nil;
end


--[[-----------------------------------------------
function for checking the whisper options
these options verify if the originator of the whisper is allowed to get the response
Parameter:
	who - the originator of the whisper
	index - the index of the response to start from
Return:
	nil - the originator should not get this response
	1 - response can be send
--]]-----------------------------------------------
function Repondeur_CheckCan(who,index)
	local skip,restrict = nil,nil;
	local t = RepondeurOptions[Realm][Player][index]["Options"]["Receive"];

	-- check for given names
	if t["Names"] then
	    for i,v in ipairs(t["Names"]) do
			if string.lower(v) == string.lower(who) then
			    skip = 1;
			end
		end
		restrict = 1;
	end

	-- check for group restriction
	if t["Party"] and not skip then
		for i=1,GetNumPartyMembers() do
			if UnitName("party"..i) == who then
				skip = 1;
			end
		end
		restrict = 1;
	end

	-- check for raid restriction
	if t["Raid"] and not skip then
		for i=1,GetNumRaidMembers() do
			if UnitName("raid"..i) == who then
				skip = 1;
			end
		end
		restrict = 1;
	end

	-- check for friends restriction
	if t["Friends"] and not skip then
		for i=1,GetNumFriends() do
			if GetFriendInfo(i) == who then
				skip = 1;
			end
		end
		restrict = 1;
	end

	-- check for guild restriction
	if t["Guild"] and not skip then
		for i=1, GetNumGuildMembers(true) do
			if GetGuildRosterInfo(i) == who then
				skip = 1;
			end
		end
		restrict = 1;
	end

	if not restrict then
	    return 1;
	else 
		return skip;
	end
end


--[[-----------------------------------------------
function for getting the response of a respond
Parameter: 
	index - the index of the respond the get the response from
Return:
	returns the response or nil if no response is available
--]]-----------------------------------------------
function RepondeurgetglobaletResponse(index)
	local t = nil;
	if(RepondeurOptions[Realm][Player][index]["Response"]) then
		t = RepondeurOptions[Realm][Player][index]["Response"];
	end
	return t;
end


--[[-----------------------------------------------
function for responding
Parameter: 
	who - the name of the originator to respond to
	index - the index of the respond
--]]-----------------------------------------------
function Repondeur_SendRespond(who,index)
	local formatSender = who:gsub("%'", "\\'") -- remove ' in realm name, if any (hopefully)
	-- check restrictions for originator
	if Repondeur_CheckCan(formatSender,index) then
		local t = RepondeurgetglobaletResponse(index);
		if t then
			-- if response is a script then use RunScript() else response by SendChatMessage()
			if RepondeurOptions[Realm][Player][index]["Script"] then
		    for i=1,getn(t) do
		   	   RunScript(string.gsub(t[i],"$t","'"..formatSender.."'"));
		    end
			else
				local channel,receiver = "WHISPER",formatSender;
				if RepondeurOptions[Realm][Player][index]["Options"]["Tell"]["Guild"] then
					channel = "GUILD";
					receiver = nil;
				elseif RepondeurOptions[Realm][Player][index]["Options"]["Tell"]["Party"] then
					channel = "PARTY";
					receiver = nil;
				elseif RepondeurOptions[Realm][Player][index]["Options"]["Tell"]["Raid"] then
					channel = "RAID";
					receiver = nil;
				end
				for i=1,getn(t) do
					if receiver == UnitName("player") then
						DEFAULT_CHAT_FRAME:AddMessage("::: Repondeur ::: "..string.gsub(t[i],"$t",formatSender));
					else
						SendChatMessage(string.gsub(t[i],"$t",formatSender), channel, GetDefaultLanguage("player"), receiver);
					end
				end
			end
		end
	end
end

--[[-----------------------------------------------
function to save the keyword(s) for the response
--]]-----------------------------------------------
function Repondeur_SaveKeywords()
	local text = RepondeurFrame_ResponseFrame_ListKeywords:GetText();
	if ActiveOption > 0 then
		if RepondeurOptions[Realm][Player][ActiveOption] then
			-- delete old keywords
			if RepondeurOptions[Realm][Player][ActiveOption]["Keywords"] then
				while getn(RepondeurOptions[Realm][Player][ActiveOption]["Keywords"]) > 0 do
					table.remove(RepondeurOptions[Realm][Player][ActiveOption]["Keywords"]);
				end
			end
			RepondeurOptions[Realm][Player][ActiveOption]["Keywords"] = {};
			
			-- check if text is given
			if text and (text ~= "") then
				for keyword in string.gmatch(text, "[^,]+") do
					Repondeur_SaveToTable(strtrim(keyword), RepondeurOptions[Realm][Player][ActiveOption]["Keywords"])
				end
			end
		end
	end
end


--[[-----------------------------------------------
function to update the visible keywords
--]]-----------------------------------------------
function Repondeur_UpdateKeywords()
	local text = "";
	if ActiveOption > 0 then
		if RepondeurOptions[Realm][Player][ActiveOption] and RepondeurOptions[Realm][Player][ActiveOption]["Keywords"] then
			local max = getn(RepondeurOptions[Realm][Player][ActiveOption]["Keywords"]);
			for i,v in ipairs(RepondeurOptions[Realm][Player][ActiveOption]["Keywords"]) do
				text = text..v;
				if i < max then
					text = text..", ";
				end
			end
		end
	end
	RepondeurFrame_ResponseFrame_ListKeywords:SetText(text);
end


--[[-----------------------------------------------
function setting the usability of the ButtonListKeywords
--]]-----------------------------------------------
function Repondeur_UpdateButtonListKeywords()
	if ActiveOption == 0 then
		RepondeurFrame_ResponseFrame_ButtonListKeywords:Disable();
	else
		RepondeurFrame_ResponseFrame_ButtonListKeywords:Enable();
	end
end


--[[-----------------------------------------------
function for saving the response text
--]]-----------------------------------------------
function Repondeur_SaveResponse()
	local text = RepondeurFrame_ResponseFrame_ScrollFrameResponse_ListResponse:GetText();
	if ActiveOption > 0 then
		if RepondeurOptions[Realm][Player][ActiveOption] then
			-- delete old response
			if RepondeurOptions[Realm][Player][ActiveOption]["Response"] then
				while getn(RepondeurOptions[Realm][Player][ActiveOption]["Response"]) > 0 do
					table.remove(RepondeurOptions[Realm][Player][ActiveOption]["Response"]);
				end
			end
			RepondeurOptions[Realm][Player][ActiveOption]["Response"] = {};
			
			if text and text~="" then
				for line in string.gmatch(text, "[^\r\n]+") do
					Repondeur_SaveToTable(line,RepondeurOptions[Realm][Player][ActiveOption]["Response"]);
				end
			end
		end
	end
end

function Repondeur_Flood_SaveResponse()
local text = RepondeurFloodFrame_ResponseFrame_ScrollFrameResponse_ListResponse:GetText();
		
		print(text,AF_characterConfig[message])
		if text and text~="" then
		
		--delete Old msg
		--table.remove(AF_characterConfig[Realm][Player][message]);
		--table.insert(AF_characterConfig[Realm][Player][message],text);
		Flood_Config.message = text
		
		end
end




--[[-----------------------------------------------
function for saving text in a table
Parameter:
	text - the text to save
	var - the table to save to
--]]-----------------------------------------------
function Repondeur_SaveToTable(text,var)
	if text and (text ~= "") then
		table.insert(var,text);
	end
end


--[[-----------------------------------------------
function to update the visible response
--]]-----------------------------------------------
function Repondeur_UpdateResponse()
	local text = "";
	if ActiveOption > 0 then
		if RepondeurOptions[Realm][Player][ActiveOption] and RepondeurOptions[Realm][Player][ActiveOption]["Response"] then
			local max = getn(RepondeurOptions[Realm][Player][ActiveOption]["Response"]);
			for i,v in ipairs(RepondeurOptions[Realm][Player][ActiveOption]["Response"]) do
				 text = text..v;
				 if i < max then
			     	 text = text.."\n";
				 end
			end
		end
	end
	RepondeurFrame_ResponseFrame_ScrollFrameResponse_ListResponse:SetText(text);
end




function Repondeur_UpdateButtonListResponse()
	if ActiveOption == 0 then
		RepondeurFrame_ResponseFrame_ButtonListResponse:Disable();
	else
		RepondeurFrame_ResponseFrame_ButtonListResponse:Enable();
	end
end


--[[-----------------------------------------------
functions for the link button
--]]-----------------------------------------------
function Repondeur_ButtonFloodOnShow()

end

function Repondeur_ButtonFloodOnClick()
	if RepondeurFloodFrame:IsVisible() == true then
		RepondeurFloodFrame:Hide();
	else
		RepondeurFloodFrame:Show();	
	end
end


function FrameFloodOption_OnLoad()
	
	
end
	


function RepondeurFloodFrame_ResponseFrame_OnLoad()

end

--[[-----------------------------------------------
functions for the OPTIONS button
--]]-----------------------------------------------
function Repondeur_ButtonShowOptionsOnShow()

	


end

function Repondeur_ButtonShowOptionsOnClick()
		if RepondeurOptionsFrame:IsVisible() == true then
		RepondeurOptionsFrame:Hide();
	else
		RepondeurOptionsFrame:Show();	
	end
end


--[[--------------------------------------------------------------------------------------------
functions for the options of the response
--]]--------------------------------------------------------------------------------------------


--[[-----------------------------------------------
functions for the active-option of the response
--]]-----------------------------------------------
function Repondeur_UpdateActive()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonActive:Disable();
	else
		RepondeurFrame_OptionsFrame_ButtonActive:Enable();
		RepondeurFrame_OptionsFrame_ButtonActive:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Active"]);
	end
end

function Repondeur_ToggleActive()
	RepondeurOptions[Realm][Player][ActiveOption]["Active"] = RepondeurFrame_OptionsFrame_ButtonActive:GetChecked();
end


--[[-----------------------------------------------
functions for the script-option of the response
--]]-----------------------------------------------
function Repondeur_UpdateScript()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonScript:Disable();
		RepondeurFrame_OptionsFrame_ButtonScript:SetChecked(nil);
	else
		RepondeurFrame_OptionsFrame_ButtonScript:Enable();
		RepondeurFrame_OptionsFrame_ButtonScript:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Script"]);
	end
end

function Repondeur_ToggleScript()
	RepondeurOptions[Realm][Player][ActiveOption]["Script"] = RepondeurFrame_OptionsFrame_ButtonScript:GetChecked();
end


--[[-----------------------------------------------
functions for the CanGuild-option of the response
--]]-----------------------------------------------
function Repondeur_InitCanGuild()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonCanGuild:Disable();
		RepondeurFrame_OptionsFrame_ButtonCanGuild:SetChecked(nil);
	else
		RepondeurFrame_OptionsFrame_ButtonCanGuild:Enable();
		RepondeurFrame_OptionsFrame_ButtonCanGuild:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Guild"]);
	end
end

function Repondeur_ToggleCanGuild()
	RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Guild"] = RepondeurFrame_OptionsFrame_ButtonCanGuild:GetChecked();
end


--[[-----------------------------------------------
functions for the CanParty-option of the response
--]]-----------------------------------------------
function Repondeur_InitCanParty()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonCanParty:Disable();
		RepondeurFrame_OptionsFrame_ButtonCanParty:SetChecked(nil);
	else
		RepondeurFrame_OptionsFrame_ButtonCanParty:Enable();
		RepondeurFrame_OptionsFrame_ButtonCanParty:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Party"]);
	end
end

function Repondeur_ToggleCanParty()
	RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Party"] = RepondeurFrame_OptionsFrame_ButtonCanParty:GetChecked();
end


--[[-----------------------------------------------
functions for the CanRaid-option of the response
--]]-----------------------------------------------
function Repondeur_InitCanRaid()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonCanRaid:Disable();
		RepondeurFrame_OptionsFrame_ButtonCanRaid:SetChecked(nil);
	else
		RepondeurFrame_OptionsFrame_ButtonCanRaid:Enable();
		RepondeurFrame_OptionsFrame_ButtonCanRaid:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Raid"]);
	end
end

function Repondeur_ToggleCanRaid()
	RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Raid"] = RepondeurFrame_OptionsFrame_ButtonCanRaid:GetChecked();
end


--[[-----------------------------------------------
functions for the CanFriends-option of the response
--]]-----------------------------------------------
function Repondeur_InitCanFriends()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonCanFriends:Disable();
		RepondeurFrame_OptionsFrame_ButtonCanFriends:SetChecked(nil);
	else
		RepondeurFrame_OptionsFrame_ButtonCanFriends:Enable();
		RepondeurFrame_OptionsFrame_ButtonCanFriends:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Friends"]);
	end
end

function Repondeur_ToggleCanFriends()
	RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Friends"] = RepondeurFrame_OptionsFrame_ButtonCanFriends:GetChecked();
end


--[[-----------------------------------------------
functions for the CanNames-option of the response
--]]-----------------------------------------------
function Repondeur_InitCanNames()
	local text = "";
	if ActiveOption > 0 then
		if RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Names"] then
			local max = getn(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Names"]);
			for i,v in ipairs(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Names"]) do
				text = text..v;
				if i < max then
					text = text..", ";
				end
			end
		end
	end
	RepondeurFrame_OptionsFrame_ListCanNames:SetText(text);
end

function Repondeur_SaveCanNames()
	if RepondeurOptions[Realm][Player][ActiveOption] and RepondeurOptions[Realm][Player][ActiveOption]["Options"] and RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"] then
		if RepondeurFrame_OptionsFrame_ListCanNames:GetNumLetters() > 0 then
			RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Names"] = {};
			local function towords(word) if word then table.insert(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Names"],word); end end
			if not string.find(string.gsub(RepondeurFrame_OptionsFrame_ListCanNames:GetText(), "%w+", towords), "%S") then end;
		else
			RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Receive"]["Names"] = nil;
		end
	end
end

function Repondeur_UpdateButtonListCanNames()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ListCanNames:Disable();
	else
		RepondeurFrame_OptionsFrame_ListCanNames:Enable();
	end
end


--[[-----------------------------------------------
functions for TellGuild-option of the reponse
--]]-----------------------------------------------
function Repondeur_InitTellGuild()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonTellGuild:Disable();
		RepondeurFrame_OptionsFrame_ButtonTellGuild:SetChecked(nil);
	else
		RepondeurFrame_OptionsFrame_ButtonTellGuild:Enable();
		RepondeurFrame_OptionsFrame_ButtonTellGuild:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Tell"]["Guild"]);
	end
end

function Repondeur_ToggleTellGuild()
	RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Tell"]["Guild"] = RepondeurFrame_OptionsFrame_ButtonTellGuild:GetChecked();
end


--[[-----------------------------------------------
functions for TellParty-option of the reponse
--]]-----------------------------------------------
function Repondeur_InitTellParty()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonTellParty:Disable();
		RepondeurFrame_OptionsFrame_ButtonTellParty:SetChecked(nil);
	else
		RepondeurFrame_OptionsFrame_ButtonTellParty:Enable();
		RepondeurFrame_OptionsFrame_ButtonTellParty:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Tell"]["Party"]);
	end
end

function Repondeur_ToggleTellParty()
	RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Tell"]["Party"] = RepondeurFrame_OptionsFrame_ButtonTellParty:GetChecked();
end


--[[-----------------------------------------------
functions for TellRaid-option of the reponse
--]]-----------------------------------------------
function Repondeur_InitTellRaid()
	if ActiveOption == 0 then
		RepondeurFrame_OptionsFrame_ButtonTellRaid:Disable();
		RepondeurFrame_OptionsFrame_ButtonTellRaid:SetChecked(nil);
	else
		RepondeurFrame_OptionsFrame_ButtonTellRaid:Enable();
		RepondeurFrame_OptionsFrame_ButtonTellRaid:SetChecked(RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Tell"]["Raid"]);
	end
end

function Repondeur_ToggleTellRaid()
	RepondeurOptions[Realm][Player][ActiveOption]["Options"]["Tell"]["Raid"] = RepondeurFrame_OptionsFrame_ButtonTellRaid:GetChecked();
end


--[[--------------------------------------------------------------------------------------------
functions for the whole Responds
--]]--------------------------------------------------------------------------------------------

--[[-----------------------------------------------
function to create a new respond
--]]-----------------------------------------------
function Repondeur_ButtonNew()
	RepondeurFrame:Hide();
	
	table.insert( RepondeurOptions[Realm][Player], { Active = nil, Script = nil, Keywords = {AUTO_RESPOND_DEFAULT_KEYWORD_TEXT}, Response = {AUTO_RESPOND_DEFAULT_RESPONSE_TEXT}, Options = { Receive = { Guild = nil, Party = nil, Raid = nil, Friends = nil, Names = {} }, Tell = { Guild = nil, Party = nil, Raid = nil } } } );
	
	DEFAULT_CHAT_FRAME:AddMessage(AUTO_RESPOND_ADD_NEW_TEXT);
	
	ActiveOption = getn(RepondeurOptions[Realm][Player]);
	
	RepondeurFrame:Show();
end


--[[-----------------------------------------------
function to check status for delete-button
--]]-----------------------------------------------
function Repondeur_ButtonOnShow()
	if ActiveOption == 0 and getn(RepondeurOptions[Realm][Player]) == 0 then
		RepondeurFrame_ButtonDelete:Disable();
	else
		RepondeurFrame_ButtonDelete:Enable();
	end
end


--[[-----------------------------------------------
function to delete a respond
--]]-----------------------------------------------
function Repondeur_ButtonDelete()
	local index = getn(RepondeurOptions[Realm][Player]);
	if index >= ActiveOption and index > 0 then
		RepondeurFrame:Hide();
		table.remove(RepondeurOptions[Realm][Player],ActiveOption);
		DEFAULT_CHAT_FRAME:AddMessage(AUTO_RESPOND_DELETED_TEXT);
		if(ActiveOption == index) then
			ActiveOption = ActiveOption - 1;
		end
		RepondeurFrame:Show();
	else
		DEFAULT_CHAT_FRAME:AddMessage(AUTO_RESPOND_EMPTY_LIST_TEXT);
	end
end


--[[-----------------------------------------------
function to check status for previous-button
--]]-----------------------------------------------
function Repondeur_ButtonPreviousOnShow()
	if ActiveOption <= 1 then
		RepondeurFrame_ButtonPrevious:Disable();
	else
		RepondeurFrame_ButtonPrevious:Enable();
	end
end


--[[-----------------------------------------------
function to go to previous response
--]]-----------------------------------------------
function Repondeur_ButtonPreviousOnClick()
	RepondeurFrame:Hide();
	ActiveOption = ActiveOption - 1;
	RepondeurFrame:Show();
end


--[[-----------------------------------------------
function to check status for next-button
--]]-----------------------------------------------
function Repondeur_ButtonNextOnShow()
	if ActiveOption == (getn(RepondeurOptions[Realm][Player])) then
		RepondeurFrame_ButtonNext:Disable();
	else
		RepondeurFrame_ButtonNext:Enable();
	end
end


--[[-----------------------------------------------
function to go to next response
--]]-----------------------------------------------
function Repondeur_ButtonNextOnClick()
	RepondeurFrame:Hide();
	ActiveOption = ActiveOption + 1;
	RepondeurFrame:Show();
end


--[[--------------------------------------------------------------------------------------------
functions for the main-options
--]]--------------------------------------------------------------------------------------------


--[[-----------------------------------------------
function to show the actual status of the ActiveMod option
--]]-----------------------------------------------
function RepondeurOptions_InitActiveMod()
	RepondeurOptionsFrame_ActiveMod:SetChecked(RepondeurMainOptions[Realm][Player]["ActiveMod"]);
end


--[[-----------------------------------------------
function to save the status of the ActiveMod option
--]]-----------------------------------------------
function RepondeurOptions_ToggleActiveMod()
	local active = RepondeurOptionsFrame_ActiveMod:GetChecked();
	if active then
		RepondeurFrame:RegisterEvent("CHAT_MSG_WHISPER");
	else
		RepondeurFrame:UnregisterEvent("CHAT_MSG_WHISPER");
	end
	RepondeurMainOptions[Realm][Player]["ActiveMod"] = RepondeurOptionsFrame_ActiveMod:GetChecked();
end


--[[-----------------------------------------------
function to show the status of the actual InFight option
--]]-----------------------------------------------
function RepondeurOptions_InitInFight()
	RepondeurOptionsFrame_InFight:SetChecked(RepondeurMainOptions[Realm][Player]["InFight"]);
end


--[[-----------------------------------------------
function to save the status of the InFight option
--]]-----------------------------------------------
function RepondeurOptions_ToggleInFight()
	RepondeurMainOptions[Realm][Player]["InFight"] = RepondeurOptionsFrame_InFight:GetChecked();
end


--[[-----------------------------------------------
function to show the actual scaling and texts for the scale-widget
--]]-----------------------------------------------
function RepondeurOptions_Scaling_OnShow()
	local scaling = RepondeurMainOptions[Realm][Player]["Scaling"];
	
	getglobal(RepondeurOptionsFrame_Scaling_Slider:GetName() .. "High"):SetText("150%");
	getglobal(RepondeurOptionsFrame_Scaling_Slider:GetName() .. "Low"):SetText("50%");
	getglobal(RepondeurOptionsFrame_Scaling_Slider:GetName() .. "Text"):SetText("Scaling - " .. (scaling*100));
	
	RepondeurOptionsFrame_Scaling_Slider:SetMinMaxValues(0.5, 1.5);
	RepondeurOptionsFrame_Scaling_Slider:SetValueStep(0.01);
	RepondeurOptionsFrame_Scaling_Slider:SetValue(scaling);
end


--[[-----------------------------------------------
function to save the scaling when changed
--]]-----------------------------------------------
function RepondeurOptions_Scaling_OnValueChanged()
	scaling = floor(RepondeurOptionsFrame_Scaling_Slider:GetValue()*100+0.5)/100;
	getglobal(RepondeurOptionsFrame_Scaling_Slider:GetName() .. "Text"):SetText("Scaling - " .. (scaling*100) .. "%");
	RepondeurMainOptions[Realm][Player]["Scaling"] = scaling;
	RepondeurOptions_ScaleFrame(scaling);
end


--[[-----------------------------------------------
function to set the scale of the mainframe
--]]-----------------------------------------------
function RepondeurOptions_ScaleFrame(scaling)
	RepondeurFrame:SetScale(scaling);
end


--[[-----------------------------------------------
function to init the spam check option
--]]-----------------------------------------------
function RepondeurOptions_InitSpamCheck()
	RepondeurOptionsFrame_SpamCheck:SetChecked(RepondeurMainOptions[Realm][Player]["SpamCheck"]);
end

--[[-----------------------------------------------
function to save the spam check option when changed
--]]-----------------------------------------------
function RepondeurOptions_ToggleSpamCheck()
	RepondeurMainOptions[Realm][Player]["SpamCheck"] = RepondeurOptionsFrame_SpamCheck:GetChecked();
end


--[[-----------------------------------------------
function to save the spam timer when changed
--]]-----------------------------------------------
function RepondeurOptions_SpamTimer_OnValueChanged()
	timer = RepondeurOptionsFrame_SpamTimer_Slider:GetValue();
	getglobal(RepondeurOptionsFrame_SpamTimer_Slider:GetName() .. "Text"):SetText("Spam timer - " .. (timer));
	RepondeurMainOptions[Realm][Player]["SpamTimer"] = timer;
end

--[[-----------------------------------------------
function to init the spam timer option
--]]-----------------------------------------------
function RepondeurOptions_SpamTimer_OnShow()
	local timer = RepondeurMainOptions[Realm][Player]["SpamTimer"];
	if not timer then 
		 timer = 60.0; 
	end
	getglobal(RepondeurOptionsFrame_SpamTimer_Slider:GetName().."High"):SetText("60s");
	getglobal(RepondeurOptionsFrame_SpamTimer_Slider:GetName().."Low"):SetText("1s");
	getglobal(RepondeurOptionsFrame_SpamTimer_Slider:GetName() .. "Text"):SetText("Spam timer - " .. (timer));
	
	RepondeurOptionsFrame_SpamTimer_Slider:SetMinMaxValues(1.0, 60.0);
	RepondeurOptionsFrame_SpamTimer_Slider:SetValueStep(1.0);
	RepondeurOptionsFrame_SpamTimer_Slider:SetValue(timer);
end


--[[--------------------------------------------------------------------------------------------
special functions for macros or scripts
--]]--------------------------------------------------------------------------------------------

--[[-----------------------------------------------
function to promote a response to a channel
Parameter:
	index - the index of the response to promote
	channel - the identifier of the channel to promote to
	number - only with channel "CHANNEL" where number is the numeric id of the channel to promote to
--]]-----------------------------------------------
function Repondeur_PromoteResponse(index,channel,number)
	if channel and index and (index <= getn(RepondeurOptions[Realm][Player])) then
		for i,v in RepondeurOptions[Realm][Player][index]["Response"] do
	    if channel == "CHANNEL" then
	    	if number then
					SendChatMessage(v,channel,GetDefaultLanguage("player"),number);
				else
					DEFAULT_CHAT_FRAME:AddMessage(AUTO_RESPOND_PROMOTE_CHANNEL_ERROR);
				end
			else
				SendChatMessage(v,channel,GetDefaultLanguage("player"));
			end
		end
	end
end


--[[-----------------------------------------------
function to promote all keywords of response(s) to a channel
Parameter:
	index - the index of the response, if nil all active responses will be used
	channel - the identifier of the channel to promote to
	number - only with channel "CHANNEL" where number is the numeric id of the channel to promote to
--]]-----------------------------------------------
function Repondeur_PromoteKeywords(index,channel, number)
	local s,e = 1,getn(RepondeurOptions[Realm][Player]);
	if index then
		s = index;
		e = index;
	end
	for i=s,e do
		if RepondeurOptions[Realm][Player][i] and RepondeurOptions[Realm][Player][i]["Active"] then
		   	if RepondeurOptions[Realm][Player][i]["Keywords"] then
				local text,max = "", getn(RepondeurOptions[Realm][Player][i]["Keywords"]);
				for j,v in ipairs(RepondeurOptions[Realm][Player][i]["Keywords"]) do
					text = text..v;
					if j < max then
						text = text..", ";
					end
				end
				if channel == "CHANNEL" then
					if number then
						SendChatMessage(text,channel,GetDefaultLanguage("player"),number);
					else
						DEFAULT_CHAT_FRAME:AddMessage(AUTO_RESPOND_PROMOTE_CHANNEL_ERROR);
					end
				else
					SendChatMessage(text,channel,GetDefaultLanguage("player"));
				end
			end
		end
	end
end