-- GridFrame.lua

--{{{ Libraries
local print = function(msg) if msg then DEFAULT_CHAT_FRAME:AddMessage(msg) end end
local Compost = AceLibrary("Compost-2.0")
local AceOO = AceLibrary("AceOO-2.0")
local RL = AceLibrary("RosterLib-2.0")
local L = AceLibrary("AceLocale-2.2"):new("Grid")

--}}}

--{{{  locals
local indicators = {
	[1] = { type = "text", name = L["Center Text"] },
	[2] = { type = "border", name = L["Border"] },
	[3] = { type = "bar", name = L["Health Bar"] },
	[4] = { type = "corner1", name = L["Bottom Left Corner"] },
	[5] = { type = "corner2", name = L["Bottom Right Corner"] },
	[6] = { type = "corner3", name = L["Top Right Corner"] },
	[7] = { type = "corner4", name = L["Top Left Corner"] },
	[8] = { type = "icon", name = L["Center Icon"] },
	[9] = { type = "frameAlpha", name = L["Frame Alpha"] },
	[10]= { type = "manabar", name = L["Mana Bar"] },
	[11]= { type = "text2", name = L["Text 2"] }
}

--}}}
--{{{ FrameXML functions

function GridFrame_OnLoad(self)
	GridFrame:RegisterFrame(this)
end

function GridFrame_OnAttributeChanged(self, name, value)
	local frame = GridFrame.registeredFrames[self:GetName()] 

	if not frame then return end

	if name == "unit" then
		if value then
			local unitName = UnitName(value)
			frame.unitName = unitName
			frame.unit = value
			frame.frame.unit = value
			GridFrame:Debug("updated", self:GetName(), name, value, unitName)
			GridFrame:UpdateIndicators(frame)
		else
			-- unit is nil
			-- move frame to unused pile
			GridFrame:Debug("removed", self:GetName(), name, value, unitName)
			frame.unitName = nil
			frame.unit = value
		end
		--GridFrame:Grid_UpdateSort()
	end
end

-- 1.12 only
function GridFrame_OnClick(self, button)
	local unit

	if self.GetAttribute then
		unit = self:GetAttribute("unit")
	else
		unit = self.a_unit
	end

	GridFrame:Debug("GridFrame_OnClick", self:GetName(), button, unit, UnitName(unit))

	if unit and not UnitExists(unit) then
		return
	end

	if GridCustomClick and GridCustomClick(arg1, unit) then 
		return
	elseif button == "LeftButton" then
		if not UnitExists(unit) then
			return
		elseif SpellIsTargeting() then
			if button == "LeftButton" then
				SpellTargetUnit(unit)
			elseif button == "RightButton" then
				SpellStopTargeting()
			end
			return
		elseif CursorHasItem() then
			if button == "LeftButton" then
 				if unit == "player" then
					AutoEquipCursorItem()
				else
					DropItemOnUnit(unit)
				end
			else
				PutItemInBackpack()
			end
			return
		else
			TargetUnit(unit)
		end
	end
end

--}}}
--{{{ GridFrameClass

local GridFrameClass = AceOO.Class("AceEvent-2.0")

function GridFrameClass.prototype:init(frame)
	GridFrameClass.super.prototype.init(self)
	self.frame = frame
	self:CreateFrames()
	-- self:Reset()
end

function GridFrameClass.prototype:Reset()
	-- UnregisterUnitWatch(self.frame)
	-- this isn't really needed
	-- self.frame:SetAttribute("unit", nil)
	
	-- hide should be handled by UnitWatch
	-- self.frame:Hide()

	for _,indicator in ipairs(indicators) do
		self:ClearIndicator(indicator.type)
	end
end

function GridFrameClass.prototype:OnEnter()
	if GridFrame.db.profile.tooltip then
		UnitFrame_OnEnter()	
	end
end

function GridFrameClass.prototype:OnLeave()
	if GridFrame.db.profile.tooltip then
		UnitFrame_OnLeave()	
	end
end

function GridFrameClass.prototype:CreateFrames()
	
	-- create frame
	--self.frame = CreateFrame("Button", nil, UIParent)
	local f = self.frame


	f:SetScript("OnEnter",function() self:OnEnter() end)
	f:SetScript("OnLeave",function() self:OnLeave() end)
	-- f:Hide()
	f:EnableMouse(true)			
	f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
	f:SetWidth(GridFrame:GetFrameWidth())
	f:SetHeight(GridFrame:GetFrameHeight())
	
	-- only use SetScript pre-TBC
	if Grid.isTBC then
		f:SetAttribute("type1", "target")
	else
		f:SetScript("OnClick", function () GridFrame_OnClick(f, arg1) end)
		f:SetScript("OnAttributeChanged", GridFrame_OnAttributeChanged)
	end
	
	-- create border
	f:SetBackdrop({
		bgFile = "Interface\\Addons\\GridEnhanced\\white16x16", tile = true, tileSize = 16,
		edgeFile = "Interface\\Addons\\GridEnhanced\\white16x16", edgeSize = 1,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})
	f:SetBackdropBorderColor(0,0,0,0)
	f:SetBackdropColor(0,0,0,1)
	
	-- create bar BG (which users will think is the real bar, as it is the one that has a shiny color)
	-- this is necessary as there's no other way to implement status bars that grow in the other direction than normal
	f.BarBG = f:CreateTexture()
	f.BarBG:SetTexture("Interface\\Addons\\GridEnhanced\\gradient32x32")
	if GridFrame.db.profile.horizontal then
		f.BarBG:SetWidth(GridFrame:GetFrameWidth()-2)
		f.BarBG:SetHeight(GridFrame:GetFrameHeight() - (4 + GridFrame.db.profile.ManabarSize))
		f.BarBG:SetPoint("TOP", f, "TOP", 0, -2)
	else
		f.BarBG:SetWidth(GridFrame:GetFrameWidth() - (4 + GridFrame.db.profile.ManabarSize))
		f.BarBG:SetHeight(GridFrame:GetFrameHeight()-2)
		f.BarBG:SetPoint("LEFT", f, "LEFT", -2, 0)
	end

	-- create bar
	f.Bar = CreateFrame("StatusBar", nil, f)
	f.Bar:SetStatusBarTexture("Interface\\Addons\\GridEnhanced\\gradient32x32")
	if GridFrame.db.profile.horizontal then
		f.Bar:SetOrientation("HORIZONTAL")
		f.Bar:SetWidth(GridFrame:GetFrameWidth()-2)
		f.Bar:SetHeight(GridFrame:GetFrameHeight() - (4 + GridFrame.db.profile.ManabarSize))
		f.Bar:SetPoint("TOP", f, "TOP", 0, -2)
	else
		f.Bar:SetOrientation("VERTICAL")
		f.Bar:SetWidth(GridFrame:GetFrameWidth() - (4 + GridFrame.db.profile.ManabarSize))
		f.Bar:SetHeight(GridFrame:GetFrameHeight()-2)
		f.Bar:SetPoint("LEFT", f, "LEFT", -2, 0)
	end

	f.Bar:SetMinMaxValues(0,100)
	f.Bar:SetValue(100)
	f.Bar:SetStatusBarColor(0,0,0,0.8)
	f.Bar:SetFrameLevel(4)
	

	-- mana bar
	f.BarMana = CreateFrame("StatusBar", nil, f)
	f.BarMana:SetStatusBarTexture("Interface\\Addons\\GridEnhanced\\white16x16")
	if GridFrame.db.profile.horizontal then
		f.BarMana:SetOrientation("HORIZONTAL")
		f.BarMana:SetWidth(GridFrame:GetFrameWidth()-2)
		f.BarMana:SetHeight(GridFrame.db.profile.ManabarSize)
		f.BarMana:SetPoint("BOTTOM", f, "BOTTOM", 0, 2)
	else
		f.BarMana:SetOrientation("VERTICAL")
		f.BarMana:SetWidth(GridFrame.db.profile.ManabarSize)
		f.BarMana:SetHeight(GridFrame:GetFrameHeight()-2)
		f.BarMana:SetPoint("RIGHT", f, "RIGHT", 2, 0)
	end

	f.BarMana:SetMinMaxValues(0,100)
	f.BarMana:SetValue(100)
	f.BarMana:SetStatusBarColor(0,0.4,1,0.8)
	f.BarMana:SetFrameLevel(5)
	
	-- create center text
	f.Text = f.Bar:CreateFontString(nil, "ARTWORK")
	f.Text:SetFontObject(GameFontHighlightSmall)
	f.Text:SetFont(STANDARD_TEXT_FONT,GridFrame.db.profile.FontSize)
	f.Text:SetJustifyH("LEFT")
	f.Text:SetJustifyV("CENTER")
	f.Text:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)

	f.Text2 = f.Bar:CreateFontString(nil, "ARTWORK")
	f.Text2:SetFontObject(GameFontRedLarge)
	f.Text2:SetFont(STANDARD_TEXT_FONT,GridFrame.db.profile.FontSize)
	f.Text2:SetJustifyH("LEFT")
	f.Text2:SetJustifyV("CENTER")
	f.Text2:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, (GridFrame.db.profile.ManabarSize+4))
--	f.Text2:SetTextColor(1.0, 0, 0, 1)
--	f.Text2:SetText("-2548")
	
	-- create icon
	f.Icon = f.Bar:CreateTexture("Icon", "OVERLAY")
	f.Icon:SetWidth(16)
	f.Icon:SetHeight(16)
	f.Icon:SetPoint("CENTER", f, "CENTER")
	f.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	f.Icon:SetTexture(1,1,1,0) --"Interface\\Icons\\INV_Misc_Orb_02"
	
	-- set texture
	f:SetNormalTexture(1,1,1,0)
	f:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	
	self.frame = f
	--local settings = GridStatusRange.db.profile.alert_range
	-- set up click casting
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[self.frame] = true
end

function GridFrameClass.prototype:GetFrameName()
	return self.frame:GetName()
end

function GridFrameClass.prototype:GetFrameHeight()
	return self.frame:GetHeight()
end

function GridFrameClass.prototype:GetFrameWidth()
	return self.frame:GetWidth()
end

--function GridFrameClass.prototype:GetManaBarSize()
--	return self.frame:GetManaBarSize()
--end

function GridFrameClass.prototype:ShowFrame()
	return self.frame:Show()
end

function GridFrameClass.prototype:HideFrame()
	return self.frame:Hide()
end

function GridFrameClass.prototype:SetFrameParent(parentFrame)
	return self.frame:SetParent(parentFrame)
end

function GridFrameClass.prototype:SetPosition(parentFrame, x, y)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", x, y)
end

function GridFrameClass.prototype:SetUnit(name)
	local unit = RL:GetUnitIDFromName(name)
	if unit ~= self.unit then
		-- self:Reset()
		self.unit = unit

		GridFrame:Debug("Set unit for", self.frame:GetName(), "to", unit, name)

		self.frame:SetAttribute("unit", unit)
		-- RegisterUnitWatch(self.frame, true)

		self:UpdateUnit()
	end
end

function GridFrameClass.prototype:SetBar(value, max)
	if max == nil then
		max = 100
	end
	self.frame.Bar:SetValue(value/max*100)
end

function GridFrameClass.prototype:SetBarMana(value, max)
	if max == nil then
		max = 100
	end
	self.frame.BarMana:SetValue(value/max*100)
end

function GridFrameClass.prototype:SetBarManaColor(r, g, b, a)
	self.frame.BarMana:SetStatusBarColor(r, g, b, a)
end

function GridFrameClass.prototype:SetBarColor(r, g, b, a)
	if GridFrame.db.profile.invertBarColor then
		self.frame.Bar:SetStatusBarColor(r, g, b, a)
		self.frame.BarBG:SetVertexColor(0, 0, 0, 0)
	else
		self.frame.Bar:SetStatusBarColor(0, 0, 0, 0.8)
		self.frame.BarBG:SetVertexColor(r, g, b ,a)
	end
end

function GridFrameClass.prototype:InvertBarColor()
	local r, g, b, a
	if GridFrame.db.profile.invertBarColor then
		r, g, b, a = self.frame.BarBG:GetVertexColor()
	else
		r, g, b, a = self.frame.Bar:GetStatusBarColor()
	end
	self:SetBarColor(r, g, b, a)
end

function GridFrameClass.prototype:SwitchBarOrientation()
	if GridFrame.db.profile.horizontal then
		self.frame.Bar:SetOrientation("HORIZONTAL")	
	else
		self.frame.Bar:SetOrientation("VERTICAL")
	end
end

function GridFrameClass.prototype:SetText(text, color)
	text = string.sub(text, 1, 8)
	self.frame.Text:SetText(text)
	if text ~= "" then
		self.frame.Text:Show()
	else
		self.frame.Text:Hide()
	end
	if color then
		self.frame.Text:SetTextColor(color.r, color.g, color.b, color.a)
	end
end

function GridFrameClass.prototype:SetText2(text, color)
	text = string.sub(text, 1, 8)
	self.frame.Text2:SetText(text)
	if text ~= "" then
		self.frame.Text2:Show()
	else
		self.frame.Text2:Hide()
	end
	if color then
		self.frame.Text2:SetTextColor(color.r, color.g, color.b, color.a)
	end
end

function GridFrameClass.prototype:ResizeCornerIndicators()
	local size,f,corners = GridFrame.db.profile.CornerSize, self.frame
			
	if f["corner1"] then
		f["corner1"]:SetWidth(size)
		f["corner1"]:SetHeight(size)
	end

	if f["corner2"] then
		f["corner2"]:SetWidth(size)
		f["corner2"]:SetHeight(size)
	end

	if f["corner3"] then
		f["corner3"]:SetWidth(size)
		f["corner3"]:SetHeight(size)
	end

	if f["corner4"] then
		f["corner4"]:SetWidth(size)
		f["corner4"]:SetHeight(size)
	end
end

function GridFrameClass.prototype:SetFontSize()
	local size,f = GridFrame.db.profile.FontSize, self.frame
			
	f.Text:SetFont(STANDARD_TEXT_FONT,GridFrame.db.profile.FontSize)
	f.Text2:SetFont(STANDARD_TEXT_FONT,GridFrame.db.profile.FontSize)
end



function GridFrameClass.prototype:CreateIndicator(indicator)

	self.frame[indicator] = CreateFrame("Frame", nil, self.frame)
	self.frame[indicator]:SetWidth(GridFrame.db.profile.CornerSize)
	self.frame[indicator]:SetHeight(GridFrame.db.profile.CornerSize)
	self.frame[indicator]:SetBackdrop( {
				      bgFile = "Interface\\Addons\\GridEnhanced\\white16x16", tile = true, tileSize = 16,
				      edgeFile = "Interface\\Addons\\GridEnhanced\\white16x16", edgeSize = 1,
				      insets = {left = 1, right = 1, top = 1, bottom = 1},
			      })
	self.frame[indicator]:SetBackdropBorderColor(0,0,0,1)
	self.frame[indicator]:SetBackdropColor(1,1,1,1)
	self.frame[indicator]:SetFrameLevel(6)
	self.frame[indicator]:Hide()
	
	-- position indicator wherever needed
	if indicator == "corner1" then
		self.frame[indicator]:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 1, 1)
	elseif indicator == "corner2" then
		self.frame[indicator]:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -1, 1)
	elseif indicator == "corner3" then
		self.frame[indicator]:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -1, -1)
	elseif indicator == "corner4" then
		self.frame[indicator]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 1, -1)
	end
end

function GridFrameClass.prototype:SetIndicator(indicator, color, text, value, maxValue, texture)
	if not color then color = { r = 1, g = 1, b = 1, a = 1 } end
	if indicator == "border" then
		self.frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
	elseif indicator == "corner1" 
	or indicator == "corner2" 
	or indicator == "corner3" 
	or indicator == "corner4" 
	then
		-- create indicator on demand if not available yet
		if not self.frame[indicator] then
			self:CreateIndicator(indicator)
		end
		self.frame[indicator]:SetBackdropColor(color.r, color.g, color.b, color.a)
		self.frame[indicator]:Show()
	elseif indicator == "text" then
		self:SetText(text, color)
	elseif indicator == "text2" then
		self:SetText2(text, color)
	elseif indicator == "frameAlpha" then
		for x = 1, 4 do
			local corner = "corner"..x;
			if self.frame[corner] then
				self.frame[corner]:SetAlpha(color.a)
			end
		end
		self.frame:SetAlpha(color.a)
	elseif indicator == "bar" then
		if value and maxValue then
			self:SetBar(value, maxValue)
		end
		if type(color) == "table" then
			self:SetBarColor(color.r, color.g, color.b, color.a)
		end	
	elseif indicator == "manabar" then
		if value and maxValue then
			self:SetBarMana(value, maxValue)
		end
		if type(color) == "table" then
			self:SetBarManaColor(color.r, color.g, color.b, color.a)
		end	
	elseif indicator == "icon" then
		if texture then
			self.frame.Icon:SetTexture(texture)
		end
	end
end

function GridFrameClass.prototype:ClearIndicator(indicator)
	if indicator == "border" then
		self.frame:SetBackdropBorderColor(0, 0, 0, 0)
	elseif indicator == "corner1" 
	or indicator == "corner2" 
	or indicator == "corner3" 
	or indicator == "corner4" 
	then
		if self.frame[indicator] then
			self.frame[indicator]:SetBackdropColor(1, 1, 1, 1)
			self.frame[indicator]:Hide()
		end
	elseif indicator == "text" then
		self.frame:SetText("")
	elseif indicator == "text2" then
		self:SetText2("")
	elseif indicator == "frameAlpha" then
		for x = 1, 4 do
			local corner = "corner"..x;
			if self.frame[corner] then
				self.frame[corner]:SetAlpha(1)
			end
		end
		self.frame:SetAlpha(1)
	elseif indicator == "bar" then
		self:SetBar(100)
	elseif indicator == "manabar" then
		self:SetBarMana(100)
	elseif indicator == "icon" then
		self.frame.Icon:SetTexture(1,1,1,0)
	end
end

--}}}

--{{{ GridFrame

GridFrame = Grid:NewModule("GridFrame")
GridFrame.frameClass = GridFrameClass

--{{{  AceDB defaults

GridFrame.defaultDB = {
	FrameHeight = 30,
	FrameWidth = 70,
	ManabarSize = 6,
	CornerSize = 5,
	FontSize = 8,
	debug = false,
	invertBarColor = true,
	horizontal = true,
	tooltip = false,
	statusmap = {
		["text"] = {
			alert_death = false,
			unit_name = true,
			unit_healthDeficit = false,
			unit_health = false
		},
		["text2"] = {
			alert_death = false,
			unit_name = false,
			unit_healthDeficit = true,
		},
		["border"] = {
			alert_lowHealth = true,
			alert_lowMana = true,
		},
		["corner1"] = {
			alert_heals = true,
		},
		["corner2"] = {
			alert_lowMana = true,
		},
		["corner3"] = {
			debuff_poison = true,
			debuff_magic = true,
			debuff_disease = true,
			debuff_curse = true,
		},
		["corner4"] = {
			alert_range = true,
			alert_aggro = true,
		},
		["frameAlpha"] = {
			alert_death = true,
			alert_offline = true,
		},
		["bar"] = {
			unit_name = false,
			alert_lowMana = true,
			unit_health = true
		},
		["manabar"] = {
			unit_mana = true
		},
		["icon"] = {
			debuff_poison = true,
			debuff_magic = true,
			debuff_disease = true,
			debuff_curse = true,
		}
	},
}

--}}}

--{{{  AceOptions table

GridFrame.options = {
	type = "group",
	name = L["Frame"],
	desc = L["Options for GridFrame."],
	args = {
		["invert"] = {
			type = "toggle",
			name = L["Invert Bar Color"],
			desc = L["Swap foreground/background colors on bars."],
			get = function ()
				return GridFrame.db.profile.invertBarColor
			end,
			set = function (v)
				GridFrame.db.profile.invertBarColor = v
				GridFrame:InvertBarColor()
			end,
		},
		["orientation"] = {
			type = "toggle",
			name = "Horizontal Deficit",
			desc = "Swap between horizontal and veritcal bar growth.",
			get = function ()
				return GridFrame.db.profile.horizontal
			end,
			set = function (v)
				GridFrame.db.profile.horizontal = v
				GridFrame:SwitchBarOrientation()
			end,
		},
		["tooltip"] = {
			type = "toggle",
			name = "Unit Tooltips",
			desc = "Show unit tooltips.",
			get = function ()
				return GridFrame.db.profile.tooltip
			end,
			set = function (v)
				GridFrame.db.profile.tooltip = v
			end,
		},
		["corner"] = {
			type = "range",
			name = "Corner Size",
			desc = "Adjust Corner Size.",
			min = 5,
			max = 12,
			step = 1,
			isPercent = false,
			get = function ()
				      return GridFrame.db.profile.CornerSize
			      end,
			set = function (v)
				      GridFrame.db.profile.CornerSize = v
				      GridFrame:ResizeCornerIndicators()
			      end,
		},
		["dimensions"] = {
			type = "group",
			name = "Dimensions",
			desc = "Adjust Frame Dims.",
			args = {
				["height"] = {
					type = "range",
					name = "Height",
					desc = "Adjust Frame Height.",
					min = 24,
					max = 96,
					step = 2,
					isPercent = false,
					get = function ()
						      return GridFrame.db.profile.FrameHeight
					      end,
					set = function (v)
						      GridFrame.db.profile.FrameHeight = v
						      GridFrame:UpdateAllFrames()
						      GridLayout:LoadLayout(GridLayout.db.profile.layout)
					      end,
				},
				["width"] = {
					type = "range",
					name = "Width",
					desc = "Adjust Frame Width.",
					min = 24,
					max = 96,
					step = 2,
					isPercent = false,
					get = function ()
						      return GridFrame.db.profile.FrameWidth
					      end,
					set = function (v)
						      GridFrame.db.profile.FrameWidth = v
						      GridFrame:UpdateAllFrames()
						      GridLayout:LoadLayout(GridLayout.db.profile.layout)
					      end,
				},
				["manabar"] = {
					type = "range",
					name = "Mana size",
					desc = "Adjust Mana Bar Size.",
					min = 1,
					max = 24,
					step = 1,
					isPercent = false,
					get = function ()
						      return GridFrame.db.profile.ManabarSize
					      end,
					set = function (v)
						      GridFrame.db.profile.ManabarSize = v
						      GridFrame:UpdateAllFrames()
						      GridLayout:LoadLayout(GridLayout.db.profile.layout)
					      end,
				}
			}
		},
		["font_size"] = {
			type = 'range',
			name = "Font Size",
			desc = "Size of Font.",
			get = function() return GridFrame.db.profile.FontSize end,
			set = function(v) 
				GridFrame.db.profile.FontSize = v
				GridFrame:SetFontSize()
			end,
			min = 6,
			max = 14,
			step = 1,
			isPercent = false,
		},

	},

}

--}}}

function GridFrame:OnInitialize()
	self.super.OnInitialize(self)
	self.debugging = self.db.profile.debug
	self.proximity = ProximityLib:GetInstance("1")

	self.frames = Compost:Acquire()
	self.registeredFrames = Compost:Acquire()
end

function GridFrame:OnEnable()
	self:RegisterEvent("Grid_StatusGained")
	self:RegisterEvent("Grid_StatusLost")
	self:UpdateOptionsMenu()
	self:RegisterEvent("Grid_StatusRegistered", "UpdateOptionsMenu")
	self:RegisterEvent("Grid_StatusUnregistered", "UpdateOptionsMenu")
	self:UpdateAllFrames()
end

function GridFrame:OnDisable()
	self:Debug("OnDisable")
	-- should probably disable and hide all of our frames here
end

function GridFrame:Reset()
	self.super.Reset(self)
	self:UpdateOptionsMenu()
	self:UpdateAllFrames()
end

function GridFrame:ResizeCornerIndicators()
	local frame
	for _, frame in pairs(self.registeredFrames) do
		frame:ResizeCornerIndicators()
	end
end

function GridFrame:SetFontSize()
	local frame
	for _, frame in pairs(self.registeredFrames) do
		frame:SetFontSize()
	end
end

function GridFrame:RegisterFrame(frame)
	self:Debug("RegisterFrame", frame:GetName())
	
	self.registeredFrameCount = (self.registeredFrameCount or 0) + 1
	self.registeredFrames[frame:GetName()] = self.frameClass:new(frame)
end

function GridFrame:UpdateAllFrames()
	local frameName, frame
	for frameName,frame in pairs(self.registeredFrames) do
		frame:UpdateDimensions()
		if frame.unit then
			
			GridFrame:UpdateIndicators(frame)
		end
	end
end

function GridFrame:InvertBarColor()
	local frame
	for _, frame in pairs(self.registeredFrames) do
		frame:InvertBarColor()
	end
end

function GridFrame:SwitchBarOrientation()
	local frame
	for _, frame in pairs(self.registeredFrames) do
		frame:SwitchBarOrientation()
	end
end

function GridFrame:GetFrameHeight()
	return self.db.profile.FrameHeight
end

function GridFrame:GetFrameWidth()
	return self.db.profile.FrameWidth
end

--function GridFrame:GetManaBarSize()
--	return self.db.profile.ManabarSize
--end

function GridFrame:UpdateIndicators(frame)
	local indicator, status
	local unitid = frame.unit
	local name = frame.unitName

	-- self.statusmap[indicator][status]
	for indicator in pairs(self.db.profile.statusmap) do
		status = self:StatusForIndicator(unitid, indicator)
		if status then
			-- self:Debug("Showing status", status.text, "for", name, "on", indicator)
			frame:SetIndicator(indicator,
					   status.color,
					   status.text,
					   status.value,
					   status.maxValue,
					   status.texture)
		else
			--self:Debug("Clearing indicator", indicator, "for", name)
			frame:ClearIndicator(indicator)
		end
	end
end

function GridFrameClass.prototype:UpdateDimensions()
	local f = self.frame
	f:SetWidth(GridFrame:GetFrameWidth())
    f:SetHeight(GridFrame:GetFrameHeight())

    if GridFrame.db.profile.horizontal then
    	-- mana bar
    	f.BarMana:SetHeight(GridFrame.db.profile.ManabarSize)


    	-- health bar
		f.Bar:SetWidth(GridFrame:GetFrameWidth()-2)
		f.Bar:SetHeight(GridFrame:GetFrameHeight() - (4 + GridFrame.db.profile.ManabarSize))
		f.BarBG:SetWidth(GridFrame:GetFrameWidth()-2)
		f.BarBG:SetHeight(GridFrame:GetFrameHeight() - (4 + GridFrame.db.profile.ManabarSize))
	else
		-- mana bar
		f.BarMana:SetWidth(GridFrame.db.profile.ManabarSize)

		-- health bar
		f.Bar:SetWidth(GridFrame:GetFrameWidth() - (4 + GridFrame.db.profile.ManabarSize))
		f.Bar:SetHeight(GridFrame:GetFrameHeight()-2)
		f.BarBG:SetWidth(GridFrame:GetFrameWidth() - (4 + GridFrame.db.profile.ManabarSize))
		f.BarBG:SetHeight(GridFrame:GetFrameHeight()-2)
	end

	GridFrame:Debug("Manabar Size ", GridFrame.db.profile.ManabarSize)
end


function GridFrame:StatusForIndicator(unitid, indicator)
	local statusName, enabled, status, inRange
	local topPriority = 0
	local topStatus
	local statusmap = self.db.profile.statusmap[indicator]
	local name = UnitName(unitid)

	-- self.statusmap[indicator][status]

	for statusName,enabled in pairs(statusmap) do
		status = (enabled and GridStatus:GetCachedStatus(name, statusName))
		if status then
			if status.range and type(status.range) ~= "number" then
				self:Debug("range not number for", statusName)
			end
			inRange = not status.range or self:UnitInRange(unitid, status.range)
			if status.priority and type(status.priority) ~= "number" then
				self:Debug("priority not number for", statusName)
			end
			if type(topPriority) ~= "number" then
				self:Debug("topPriority not number for", statusName)
			end
			if ((status.priority or 99) > topPriority) and inRange then
				topStatus = status
				topPriority = topStatus.priority
			end
		end
	end

	return topStatus
end

function GridFrame:UnitInRange(id, yrds)
	if not id or not UnitExists(id) then return false end
	if yrds > 40 then 
		return UnitIsVisible(id)  -- about 100yrds, depending on graphic settings
	elseif yrds > 30 then
		local _,time = self.proximity:GetUnitRange(id)  -- combat log range
		if time and GetTime() - time < 6 then 
			return true 
		else 
			return false
		end
	elseif yrds > 10 then
		return CheckInteractDistance(id, 4)  -- about 28yrds
	else
		return CheckInteractDistance(id, 3) -- about 10yrds
	end
end

--{{{ Event handlers

function GridFrame:Grid_StatusGained(name, status, priority, range, color, text, value, maxValue, texture)
	-- local unitid = RL:GetUnitIDFromName(name)
	local frameName, frame

	for frameName,frame in pairs(self.registeredFrames) do
		if frame.unitName == name then
			self:UpdateIndicators(frame)
		end
	end
end

function GridFrame:Grid_StatusLost(name, status)
	-- self:Debug("StatusLost", status, "on", name)
	-- local unitid = RL:GetUnitIDFromName(name)
	local frameName, frame

	for frameName,frame in pairs(self.registeredFrames) do
		if frame.unitName == name then
			self:UpdateIndicators(frame)
		end
	end
end

--}}}

function GridFrame:UpdateOptionsMenu()
	local menu = self.options.args
	local k, indicator, status, descr, indicatorMenu

	self:Debug("UpdateOptionsMenu()")

	for k,indicator in ipairs(indicators) do
		-- create menu for indicator
		if not menu[indicator.type] then
			menu[indicator.type] = {
				type = "group",
				name = indicator.name,
				desc = "Options for " .. indicator.name,
				order = 100 + k,
				args = {}
			}
		end

		indicatorMenu = menu[indicator.type].args

		-- remove statuses that are not registered
		for status,_ in pairs(indicatorMenu) do
			if not GridStatus:IsStatusRegistered(status) then
				indicatorMenu[status] = nil
				self:Debug("Removed", indicator.type, status)
			end
		end

		-- create entry for each registered status
		for status, _, descr in GridStatus:RegisteredStatusIterator() do
			-- needs to be local for the get/set closures
			local indicatorType = indicator.type
			local statusKey = status
			
			-- self:Debug(indicator.type, status)

			if not indicatorMenu[status] then
				indicatorMenu[status] = {
					type = "toggle",
					name = descr,
					desc = "Toggle " .. descr,
					get = function ()
						      return GridFrame.db.profile.statusmap[indicatorType][statusKey]
					      end,
					set = function (v)
						      GridFrame.db.profile.statusmap[indicatorType][statusKey] = v
						      GridFrame:UpdateAllFrames()
					      end,
				}

				-- self:Debug("Added", indicator.type, status)
			end
		end
	end
end

--{{ Debugging

function GridFrame:ListRegisteredFrames()
	local frameName, frame, isUnused, unusedFrame, i, frameStatus
	self:Debug("--[ BEGIN Registered Frame List ]--")
	self:Debug("FrameName", "UnitId", "UnitName", "Status")
	for frameName,frame in pairs(self.registeredFrames) do
		frameStatus = "|cff00ff00"

		if frame.frame:IsVisible() then
			frameStatus = frameStatus .. "visible"
		elseif frame.frame:IsShown() then
			frameStatus = frameStatus .. "shown"
		else
			frameStatus = "|cffff0000"
			frameStatus = frameStatus .. "hidden"
		end

		frameStatus = frameStatus .. "|r"

		self:Debug(
			frameName == frame:GetFrameName() and
				"|cff00ff00"..frameName.."|r" or
				"|cffff0000"..frameName.."|r",
			frame.unit == frame.frame:GetAttribute("unit") and
					"|cff00ff00"..(frame.unit or "nil").."|r" or
					"|cffff0000"..(frame.unit or "nil").."|r",
			frame.unit and frame.unitName == UnitName(frame.unit) and
				"|cff00ff00"..(frame.unitName or "nil").."|r" or
				"|cffff0000"..(frame.unitName or "nil").."|r",
			frameStatus)
	end
	GridFrame:Debug("--[ END Registered Frame List ]--")
end

--}}}
