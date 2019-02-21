-- Namespace
local _, core = ...

-- Custom Slash Commands
core.commands = {
	["help"] = function()
		print(" ")
		core:Print("Slash Command List:")
		core:Print("|cff32cd32/rmt|r - Toggle the Raid Management Tool window.")
		core:Print("|cff32cd32/rmt help|r - Print help text to the chat frame.")
		core:Print("|cff32cd32/rmt config|r - Toggle config window for RRMT options.")
		core:Print("|cff32cd32/rl|r - Alias for /reloadui.")
		core:Print("|cff32cd32/fs|r - Alias for toggling the framestack blizzard debug tools")
		print(" ")
	end,


}

local function HandleSlashCommands(str)
	if (#str == 0) then
		core.Config.Toggle()
		return
	end

	local args = {}
	for _, arg in pairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg)
		end
	end

	local path = core.commands

	for id, arg in ipairs(args) do
		arg = string.lower(arg)

		if (path[arg]) then
			if (type(path[arg]) == "function") then
				path[arg](select(id + 1, unpack(args)))
				return
			elseif (type(path[arg]) == "table") then
				path = path[arg]
			else
				core.commands.help()
				return
			end
		else
			core.commands.help()
			return
		end
	end
end

function core:Print(...)
	local hex = select(4, core.Config:GetThemeColor())
	local prefix = string.format("|cff%s%s|r", hex:upper(), "Redshift RMT:")
	DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...))
end

function core:init(event, name)
	if (name ~= "RedshiftRaidManagementTool") then return end

	-- allows using left and right buttons to move through chat 'edit' box
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
	end

	-- Register Slash Commands
	SLASH_RELOADUI1 = "/rl"
	SlashCmdList.RELOADUI = ReloadUI

	SLASH_FRAMESTK1 = "/fs"
	SlashCmdList.FRAMESTK = function()
		LoadAddOn("Blizzard_DebugTools")
		FrameStackTooltip_Toggle()
	end

	SLASH_RedshiftRaidManagementTool1 = "/rmt"
	SlashCmdList.RedshiftRaidManagementTool = HandleSlashCommands

	core:Print("Welcome back", UnitName("player").."!")
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", core.init)