-- Namespaces
local _, core = ...
core.Config = {}

-- Saved Variables
if not RedshiftRoster then
	RedshiftRoster = {}
end

if not GuildMemberLookup then
	GuildMemberLookup = {}
end


-- Local variables
local Config = core.Config
local RRMT
local rosterSize = 0
local gridCount = 0
local RosterList = {}
local GuildList = {}
local tempAttendance = {}
local gridFramePool = {}
local tabFrameContent1, tabFrameContent2, tabFrameContent3 = nil

-- Sort function
local sort_func = function( a,b ) return a < b end

-- Defaults
local defaults = {
	theme = {
		r = 0.541,
		g = 0.094,
		b = 0.102,
		hex = "8a181a"
	}
}

local ATTENDANCE_VALUE_COLORS = { }
ATTENDANCE_VALUE_COLORS["On Time"] = {
	r = 0,
	g = 1,
	b = 0,
	hex = "00ff00"
}
ATTENDANCE_VALUE_COLORS["Late"] = {
	r = 1,
	g = 1,
	b = 0,
	hex = "ffff00"
}
ATTENDANCE_VALUE_COLORS["Excused"] = {
	r = 1,
	g = 0.521,
	b = 0.2,
	hex = "ff8533"
}
ATTENDANCE_VALUE_COLORS["Absent"] = {
	r = 1,
	g = 0,
	b = 0,
	hex = "ff0000"
}


-- Config Functions
function Config:Toggle()
	local window = RRMT or Config:CreateWindow()
	window:SetShown(not window:IsShown())
end

function Config:GetThemeColor()
	local c = defaults.theme
	return c.r, c.g, c.b, c.hex
end

function Config:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)
	local btn = CreateFrame("Button", nil, relativeFrame, "GameMenuButtonTemplate")
	btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset)
	btn:SetSize(100, 30)
	btn:SetText(text)
	btn:SetNormalFontObject("GameFontNormalLarge")
	btn:SetHighlightFontObject("GameFontHighlightLarge")
	return btn
end

local function ScrollFrame_OnMouseWheel(self, delta)
	local newValue = self:GetVerticalScroll() - (delta * 20)

	if (newValue < 0) then
		newValue = 0;
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange();
	end

	self:SetVerticalScroll(newValue)
end

local function Tab_OnClick(self)
	PanelTemplates_SetTab(self:GetParent(), self:GetID())

	local scrollChild = RRMT.ScrollFrame:GetScrollChild()
	if (scrollChild) then
		scrollChild:Hide()
	end
	--if (self:GetID() == 1) then
	--	RRMT.ScrollFrame.ScrollBar:Hide()
	--else
	--	RRMT.ScrollFrame.ScrollBar:Show()
	--end

	RRMT.ScrollFrame.ScrollBar:Hide()
	RRMT.ScrollFrame:SetScrollChild(self.content)
	self.content:Show()
end

local function SetTabs(frame, numTabs, ...)
	frame.numTabs = numTabs
	local contents = {}
	local frameName = frame:GetName()

	for i = 1, numTabs do
		local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "CharacterFrameTabButtonTemplate")
		tab:SetID(i)
		tab:SetText(select(i, ...))
		tab:SetScript("OnClick", Tab_OnClick)

		tab.content = CreateFrame("Frame", nil, RRMT.ScrollFrame)
		tab.content:SetSize(508, 400)
		tab.content:Hide()

		table.insert(contents, tab.content)

		if (i == 1) then
			tab:SetPoint("TOPLEFT", RRMT, "BOTTOMLEFT", 5, 7)
			--tab.content:SetSize(508, 400)
		else
			tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i - 1)], "TOPRIGHT", -14, 0)
		end
	end

	Tab_OnClick(_G[frameName.."Tab1"])

	return unpack(contents)
end


--------------------------------------------------------------
--On Load functions
--------------------------------------------------------------

-- OnLoad for Guild list
function GuildListBox_OnLoad()
	GuildList = {}
	for i=1,GetNumGuildMembers() do
		nameRealm, rank, _, _, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
		local name = string.gsub(nameRealm, "-Illidan", "")
		if not GuildMemberLookup[name] then
		  	GuildMemberLookup[name] = {}
		end
	  	GuildMemberLookup[name]["Rank"] = rank
	  	GuildMemberLookup[name]["Class"] = class
		if not GuildList[i] then GuildList[i] = name end
	end
	table.sort(GuildList, sort_func)
	GuildRosterListBoxScrollFrame:Show()
end

-- OnLoad for Roster list
function RosterListBox_OnLoad()
	local i = 0
	for k, v in pairs(RedshiftRoster) do
		i = i+1
		RosterList[i] = k
	end
	rosterSize = i
	table.sort(RosterList, sort_func)
	RaidRosterListBoxScrollFrame:Show()
	if RedshiftRoster[RosterList[1]]["Attendance"]["Detail"][date("%m/%d/%Y")] then
		tabFrameContent2.SubmitAttendanceBtn:Disable()
		tabFrameContent2.OnTimeBtn:Disable()
		tabFrameContent2.ExcusedBtn:Disable()
		tabFrameContent2.LateBtn:Disable()
		tabFrameContent2.AbsentBtn:Disable()
	end
end

function AttendanceRosterScrollFrame_OnLoad()
	for i=1,25 do
		grid = GetGrid()
		grid.used = false
		grid:Hide()
	end
end

function GetGrid()
	for _,grid in pairs(gridFramePool) do
		if not grid.used then
			grid.used = true
			return grid
		end
	end
	-- All current frames used, create a new one
	gridCount = gridCount + 1
	local grid = CreateFrame("Frame", "grid"..gridCount, getglobal("AttendanceRosterChild"), "ButtonGridTemplate")
	grid.used = true
	table.insert(gridFramePool, grid)
	return grid
end

function WipeGrids()
	for _,grid in pairs(gridFramePool) do
		grid:Hide()
		grid.used = nil
	end
end


--------------------------------------------------------------
--Update Functions
--------------------------------------------------------------

function ListBoxScrollFrame_Update()
	if name == "RaidRoster" then
		RosterListBoxScrollFrame_Update()
	elseif name == "GuildRoster" then
		GuildListBoxScrollFrame_Update()
	end
end

-- Update Roster and Guild Footers
function Roster_Update()
	getglobal("RaidRosterFooterText"):SetText("Total Raiders: "..rosterSize)
	getglobal("GuildRosterFooterText"):SetText("Total Members: "..GetNumGuildMembers())
	getglobal("AttendanceRosterFooterText"):SetText("Total Raiders: "..rosterSize)
end

-- Update Roster Listbox
function RosterListBoxScrollFrame_Update()
	RosterListBox_OnLoad()
	local line -- 1 through 20 of our window to scroll
	local lineplusoffset -- an index into our data calculated from the scroll offset
	FauxScrollFrame_Update(RaidRosterListBoxScrollFrame,rosterSize,20,16)
	for line=1,20 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(RaidRosterListBoxScrollFrame)
		if lineplusoffset <= rosterSize then
			getglobal("RaidRosterListBoxButton"..line):SetText(RosterList[lineplusoffset])
			local font = CreateFont("RaidRosterListBoxButtonFont"..line)
			font:SetFontObject(getglobal("RaidRosterListBoxButton"..line):GetNormalFontObject())
			local c = RAID_CLASS_COLORS[GuildMemberLookup[RosterList[lineplusoffset]]["Class"]]
			font:SetTextColor(c.r, c.g, c.b)
			getglobal("RaidRosterListBoxButton"..line):SetNormalFontObject(font)
			getglobal("RaidRosterListBoxButton"..line):EnableMouse(true)
			getglobal("RaidRosterListBoxButton"..line):Show()
		else
		  	getglobal("RaidRosterListBoxButton"..line):Hide()
		end
	end
	Roster_Update()
end

-- Update Attendance Roster Listbox
function AttendanceRosterScrollFrame_Update()
	WipeGrids()
	for i=1,rosterSize do
		local yoffset = -16*(i-1)
		grid = GetGrid()
		getglobal(grid:GetName()):ClearAllPoints()
		getglobal(grid:GetName()):SetPoint("TOPLEFT", getglobal("AttendanceRosterChild"), "TOPLEFT", -3, yoffset)
		grid.memberButton:SetText(RosterList[i])
		local memberFont = CreateFont("AttendanceRosterMemberButtonFont"..i)
		memberFont:SetFontObject(grid.memberButton:GetNormalFontObject())
		local c = RAID_CLASS_COLORS[GuildMemberLookup[RosterList[i]]["Class"]]
		memberFont:SetTextColor(c.r, c.g, c.b)
		grid.memberButton:SetNormalFontObject(memberFont)
		grid.memberButton:EnableMouse(true)
		grid.memberButton:Show()
		if not tempAttendance[RosterList[i]] then
			if not RedshiftRoster[grid.memberButton:GetText()]["Attendance"]["Detail"][date("%m/%d/%Y")] then
				tempAttendance[RosterList[i]] = "On Time"
			else
				tempAttendance[RosterList[i]] = RedshiftRoster[grid.memberButton:GetText()]["Attendance"]["Detail"][date("%m/%d/%Y")]
			end
		end
		grid.attendanceValueText:SetText(tempAttendance[RosterList[i]])
		--local attendanceValueFont = CreateFont(grid:GetName().."AttendanceRosterValueFont")
		--attendanceValueFont:SetFontObject(grid.attendanceValueText:GetFontObject())
		--local c = ATTENDANCE_VALUE_COLORS[tempAttendance[RosterList[i]]]
		--attendanceValueFont:SetTextColor(c.r, c.g, c.b)
		--grid.attendanceValueText:SetFontObject(attendanceValueFont)
		grid:Show()
	end
end

-- Update Guild Listbox
function GuildListBoxScrollFrame_Update()
	GuildListBox_OnLoad()
	local line -- 1 through 20 of our window to scroll
	local lineplusoffset -- an index into our data calculated from the scroll offset
	FauxScrollFrame_Update(GuildRosterListBoxScrollFrame,GetNumGuildMembers(),20,16)
	for line=1,20 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(GuildRosterListBoxScrollFrame)
		if lineplusoffset <= GetNumGuildMembers() then
			getglobal("GuildRosterListBoxButton"..line):SetText(GuildList[lineplusoffset])
			local font = CreateFont("GuildRosterListBoxButtonFont"..line)
			font:SetFontObject(getglobal("GuildRosterListBoxButton"..line):GetNormalFontObject())
			local c = RAID_CLASS_COLORS[GuildMemberLookup[GuildList[lineplusoffset]]["Class"]]
			font:SetTextColor(c.r, c.g, c.b)
			getglobal("GuildRosterListBoxButton"..line):SetNormalFontObject(font)
			getglobal("GuildRosterListBoxButton"..line):EnableMouse(true)
			getglobal("GuildRosterListBoxButton"..line):Show()
		else
			getglobal("GuildRosterListBoxButton"..line):Hide()
		end
	end
	Roster_Update()
end

--------------------------------------------------------------
-- Creation --------------------------------------------------
--------------------------------------------------------------

-- Main Window
function Config:CreateWindow()
	RRMT = CreateFrame("Frame", "RedshiftRaidManagementTool", UIParent, "UIPanelDialogTemplate")
	RRMT:SetSize(550, 450)
	RRMT:SetPoint("CENTER")
	RRMT:SetMovable(true)
	RRMT:EnableMouse(true)
	RRMT:RegisterForDrag("LeftButton")
	RRMT:SetScript("OnDragStart", RRMT.StartMoving)
	RRMT:SetScript("OnDragStop", RRMT.StopMovingOrSizing)
	
	RRMT.Title:ClearAllPoints()
	RRMT.Title:SetFontObject("GameFontHighlight")
	RRMT.Title:SetPoint("LEFT", RedshiftRaidManagementToolTitleBG, "LEFT", 5, 0)
	RRMT.Title:SetText("Redshift Raid Management Tool")

	RRMT.ScrollFrame = CreateFrame("ScrollFrame", nil, RRMT, "UIPanelScrollFrameTemplate")
	RRMT.ScrollFrame:SetPoint("TOPLEFT", RedshiftRaidManagementToolDialogBG, "TOPLEFT", 4, -8)
	RRMT.ScrollFrame:SetPoint("BOTTOMRIGHT", RedshiftRaidManagementToolDialogBG, "BOTTOMRIGHT", -3, 4)
	RRMT.ScrollFrame:SetClipsChildren(true)
	RRMT.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)

	RRMT.ScrollFrame.ScrollBar:ClearAllPoints()
	RRMT.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", RRMT.ScrollFrame, "TOPRIGHT", -12, -18)
	RRMT.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", RRMT.ScrollFrame, "BOTTOMRIGHT", -7, 18)

	-- Frames

	tabFrameContent1, tabFrameContent2, tabFrameContent3, tabFrameContent4 = SetTabs(RRMT, 4, "Roster", "Attendance", "Performance", "Contributions")

	CreateRosterTabFrames()

	CreateAttendanceTabFrames(self)

	CreateContributionsTabFrames()

	------------------------------------------------------------
	------------------------------------------------------------

	RRMT:Hide()
	return RRMT
end


------------------------------------------------------------
-- Roster Tab ----------------------------------------------
------------------------------------------------------------

--This function creates the frames and ui elements for the Roster Tab
function CreateRosterTabFrames()
	tabFrameContent1.raidRoster = CreateListBox("RaidRoster", tabFrameContent1, "ListBoxTemplate", "CENTER", "CENTER", -115, 0, RosterListBox_OnLoad, RosterListBoxScrollFrame_Update)
	getglobal("RaidRosterHeaderText"):SetText("Raid Roster")
	getglobal("RaidRosterFooterText"):SetText("Total Raiders:")
	tabFrameContent1.guildRoster = CreateListBox("GuildRoster", tabFrameContent1, "ListBoxTemplate", "CENTER", "CENTER", 135, 0, GuildListBox_OnLoad, GuildListBoxScrollFrame_Update)
	getglobal("GuildRosterHeaderText"):SetText("Guild Roster")
	getglobal("GuildRosterFooterText"):SetText("Total Members:")
end

function CreateListBox(frameName, relFrame, xmlTemplate, anchorPoint, relAnchorPoint, xOffset, yOffset, onEventScriptFunc, onVertScrollScriptFunc)
	frame = CreateFrame("Frame", frameName, relFrame, xmlTemplate)
	frame:SetPoint(anchorPoint, relFrame, relAnchorPoint, xOffset, yOffset)
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", onEventScriptFunc)
	getglobal(frameName.."ListBoxScrollFrame"):SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, onVertScrollScriptFunc) end)
	frame:SetScript("OnShow", onVertScrollScriptFunc)

	return frame
end

-------------------------------------
-- Roster Listbox Button Functions --
-------------------------------------

-- Handler for XML template
function ListBoxButtonHandler(text, button)
	parent = button:GetParent():GetName()
	if parent == "RaidRoster" then
		RemoveMemberFromRoster(text, button)
	elseif parent == "GuildRoster" then
		AddMemberToRoster(text)
	end
end

-- Add to the Roster
function AddMemberToRoster(name)
	if not RedshiftRoster[name] then
		RedshiftRoster[name] = BuildMemberTable(name)
		rosterSize = rosterSize + 1
		table.insert(RosterList, name)
		RosterListBoxScrollFrame_Update()
	end
end

-- Build the multidimensional table scheme for documenting member data
function BuildMemberTable(name)
	local t = {}
	t["Rank"] = GuildMemberLookup[name]["Rank"]
	t["Class"] = GuildMemberLookup[name]["Class"]
	t["RaidDays"] = 0
	t["Performance"] = BuildPerformanceTable()
	t["Attendance"] = BuildAttendanceTable()
	return t
end

-- Build the performance data table
function BuildPerformanceTable()
	local t = {}
	t["Numbers"] = 0
	t["Mechanics"] = 0
	t["Attitude"] = 0
	return t
end

-- Build the attendance data table
function BuildAttendanceTable()
	local t = {}
	t["On Time"] = 0
	t["Late"] = 0
	t["Excused"] = 0
	t["Absent"] = 0
	t["Detail"] = {}
	return t
end

-- Remove member from the Roster
function RemoveMemberFromRoster(name, button)
	if name then
		button:EnableMouse(false)
		rosterSize = rosterSize - 1
		RedshiftRoster[name] = nil
		local index={}
		for k,v in pairs(RosterList) do
		   index[v]=k
		end
		table.remove(RosterList, index[name])
		RosterListBoxScrollFrame_Update()
		AttendanceRosterScrollFrame_Update()
	end
end

------------------------------------------------------------
-- Attendance Tab ------------------------------------------
------------------------------------------------------------

--This function creates the frames and ui elements for the Attendance Tab
function CreateAttendanceTabFrames(window)
	--Roster frame to hold checkboxes
	tabFrameContent2.attendanceRoster = CreateAttendanceListBox(tabFrameContent2, "RRMTFrameTemplate", "CENTER")

	--Populate the roster
	AttendanceRosterScrollFrame_OnLoad()
	AttendanceRosterScrollFrame_Update()

	--Attendance Value Buttons
	tabFrameContent2.OnTimeBtn = window:CreateButton("TOPLEFT", tabFrameContent2.attendanceRoster, "TOPRIGHT", 35, 0, "On Time")
	tabFrameContent2.OnTimeBtn:SetScript("OnClick", function(self, arg1) ModifyAttendanceValues("On Time") end)
	tabFrameContent2.ExcusedBtn = window:CreateButton("LEFT", tabFrameContent2.OnTimeBtn, "RIGHT", 10, 0, "Excused")
	tabFrameContent2.ExcusedBtn:SetScript("OnClick", function(self, arg1) ModifyAttendanceValues("Excused") end)
	tabFrameContent2.LateBtn = window:CreateButton("TOP", tabFrameContent2.OnTimeBtn, "BOTTOM", 0, -10, "Late")
	tabFrameContent2.LateBtn:SetScript("OnClick", function(self, arg1) ModifyAttendanceValues("Late") end)
	tabFrameContent2.AbsentBtn = window:CreateButton("LEFT", tabFrameContent2.LateBtn, "RIGHT", 10, 0, "Absent")
	tabFrameContent2.AbsentBtn:SetScript("OnClick", function(self, arg1) ModifyAttendanceValues("Absent") end)
	tabFrameContent2.SubmitAttendanceBtn = window:CreateButton("TOP", tabFrameContent2.AbsentBtn, "BOTTOM", -55, -10, "Submit")
	tabFrameContent2.SubmitAttendanceBtn:SetScript("OnClick", function(self, arg1) SubmitAttendanceValues() end)

	--Attendance Detail Frame
	tabFrameContent2.DetailFrame = CreateFrame("Frame", "AttendanceDetailFrame", tabFrameContent2, "RRMTFrameTemplate")
	tabFrameContent2.DetailFrame:SetPoint("TOP", tabFrameContent2.SubmitAttendanceBtn, "BOTTOM", 0, -20)
	tabFrameContent2.DetailFrame:SetPoint("BOTTOM", tabFrameContent2, "BOTTOM", 0, 32)
	getglobal("AttendanceDetailFrameHeaderText"):SetPoint("TOPLEFT", tabFrameContent2.DetailFrame, "TOPLEFT", 10, -40)
	getglobal("AttendanceDetailFrameHeaderText"):SetText("Attendance Detail:")
	getglobal("AttendanceDetailFrameFooterText"):Hide()
end

function CreateAttendanceListBox(relFrame, xmlTemplate, anchorPoint)
	frame = CreateFrame("Frame", "AttendanceRoster", relFrame, xmlTemplate)
	frame:SetPoint(anchorPoint, relFrame, anchorPoint, -115, 0)
	frame.ScrollFrame = CreateFrame("ScrollFrame", "AttendanceRosterScrollFrame", frame, "UIPanelScrollFrameTemplate")
	frame.ScrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -8)
	frame.ScrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 8)
	frame.ScrollFrame:SetScript("OnShow", AttendanceRosterScrollFrame_Update)
	frame.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
	frame.ScrollFrame.ScrollBar:ClearAllPoints()
	frame.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", frame.ScrollFrame, "TOPRIGHT", -32, -16)
	frame.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", frame.ScrollFrame, "BOTTOMRIGHT", 0, 16)

	childFrame = CreateFrame("Frame", "AttendanceRosterChild", frame.ScrollFrame)
	childFrame:SetSize(200, (rosterSize * 22)+10)
	frame.ScrollFrame:SetScrollChild(childFrame)

	getglobal("AttendanceRosterHeaderText"):SetText("Raid Roster")
	getglobal("AttendanceRosterFooterText"):SetText("Total Raiders:")

	return frame
end

function ModifyAttendanceValues(newValue)
 	for _,grid in pairs(gridFramePool) do
 		if grid.used then
	 		if grid.checkButton:GetChecked() then
	 			grid.attendanceValueText:SetText(newValue)
	 			tempAttendance[grid.memberButton:GetText()] = newValue
	 			grid.checkButton:SetChecked(false)
	 		end
	 	end
 	end
 	AttendanceRosterScrollFrame_Update()
end

function SubmitAttendanceValues()
	for _, grid in pairs(gridFramePool) do
		if grid.used then
			member = RedshiftRoster[grid.memberButton:GetText()]["Attendance"]
			val = grid.attendanceValueText:GetText()
			member[val] = member[val] + 1
			member["Detail"][date("%m/%d/%Y")] = val
		end
	end
end

-- Compute attendance percentage
function ComputeAttendance(member)
	local attendanceValues = Attendance[member]
	local convertedAbsences = attendanceValues[4] + math.floor(attendanceValues[3] / 2) + math.floor(attendanceValues[2] / 3)
	local percentage = math.floor((((RedshiftRoster[member] - convertedAbsences) / RedshiftRoster[member]) * 100) + 0.5)
	return percentage
end

------------------------------------------------------------
-- Contributions Tab ---------------------------------------
------------------------------------------------------------

--This function creates the frames and ui elements for the Contributions Tab
function CreateContributionsTabFrames()
end