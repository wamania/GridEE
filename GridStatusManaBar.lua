--{{{ Libraries

local RL = AceLibrary("RosterLib-2.0")
local L = AceLibrary("AceLocale-2.2"):new("Grid")
local Compost = AceLibrary("Compost-2.0")

--}}}

GridStatusManaBar = GridStatus:NewModule("GridStatusManaBar")
GridStatusManaBar.menuName = L["Mana Bar"]

--{{{ AceDB defaults

GridStatusManaBar.defaultDB = {
	debug = false,
	unit_mana = {
		enable = true,
		color = { r = 0, g = 0.4, b = 1, a = 1 },
		priority = 30,
		range = true,
	}
}

function GridStatusManaBar:OnInitialize()
	self.super.OnInitialize(self)
	self.deathCache = Compost:Acquire()
	self:RegisterStatus("unit_mana", L["Unit Mana"])
end

function GridStatusManaBar:OnEnable()
	self:RegisterEvent("Grid_UnitJoined")
	self:RegisterBucketEvent("UNIT_MANA", 0.2)
end

function GridStatusManaBar:Reset()
	self.super.Reset(self)
	self:UpdateAllUnits()
end

function GridStatusManaBar:UpdateAllUnits()
	local name, status, statusTbl

	self.deathCache = Compost:Erase(self.deathCache)

	for name, status, statusTbl in self.core:CachedStatusIterator("unit_mana") do
		self:Grid_UnitJoined(name)
	end
end

function GridStatusManaBar:UNIT_MANA(units)
	local unitid
	local settings = self.db.profile.unit_mana

	for unitid in pairs(units) do
		self:UpdateUnit(unitid)
	end
end

function GridStatusManaBar:Grid_UnitJoined(name)
	local unitid = RL:GetUnitIDFromName(name)
	if unitid then
		self:UpdateUnit(unitid, true)
		self:UpdateUnit(unitid)
	end

end

function GridStatusManaBar:UnitPowerColor(powerType)
	GridStatusManaBar:Debug("Type ", powerType)
	local color = { r = 0, g = 0.4, b = 1, a = 1 }
	-- energy
	if powerType == 3 then
		color = { r = 0, g = 1, b = 0, a = 0.5 }
	-- rage
	elseif powerType == 1 then
		color = { r = 1, g = 0, b = 0, a = 1 }
	end

	GridStatusManaBar:Debug("Color ", color)

	return color
end

function GridStatusManaBar:UpdateUnit(unitid, ignoreRange)
	local cur, max = UnitMana(unitid), UnitManaMax(unitid)
	local name = UnitName(unitid)
	local settings = self.db.profile.unit_mana
	local priority = settings.priority
	local powerType = UnitPowerType(unitid);
	
	if not name then return end
	
	if UnitIsDeadOrGhost(unitid) then
		cur = 0
	end

	self.core:SendStatusGained(name, "unit_mana",
	    priority,
	    (not ignoreRange and settings.range and 40),
	    (self:UnitPowerColor(powerType) or settings.color),
		nil,
		cur, max,
		nil)
end