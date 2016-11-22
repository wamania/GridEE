local L = AceLibrary("AceLocale-2.2"):new("Grid")
GridStatusRange = GridStatus:NewModule("GridStatusRange")
GridStatusRange.menuName = "Range"

--{{{ AceDB defaults

GridStatusRange.defaultDB = {
    debug = false,
    alert_range = {
        text = "Range",
        enable = true,
        color = { r = 1, g = 0, b = 0, a = 1 },
        priority = 99,
        interval = 0.5,
    },
}

--}}}

GridStatusRange.options = false

--{{{ additional options
local rangeOptions = {
    ["interval"] = {
        type = "range",
        name = "Range Check Interval",
        desc = "Set the range check interval.",
        max = 5,
        min = 0.25,
        step = 0.25,
        get = function ()
                  return GridStatusRange.db.profile.alert_range.interval
              end,
        set = function (v)
                  GridStatusRange.db.profile.alert_range.interval = v
                  GridStatusRange:UpdateRangeFrequency()
              end,
    },
    ["range"] = false,
}

local ClassSpellArray = {PALADIN = "Spell_Holy_HolyBolt", PRIEST = "Spell_Holy_FlashHeal", DRUID = "Spell_Restoration_HealingTouch", SHAMAN = "Spell_Nature_HealingWaveGreater"}
local isLooting = false
local spellSlot = nil

function GridStatusRange:OnInitialize()
    self.super.OnInitialize(self)
end

function GridStatusRange:OnEnable()
    self:RegisterStatus("alert_range", "Range alert", rangeOptions, true)
    self:ScheduleRepeatingEvent("GridEnhancedRangeCheck", self.RangeCheck, GridStatusRange.db.profile.alert_range.interval, self)
    self:RegisterEvent("LOOT_OPENED", "LOOT_OPENED")
    self:RegisterEvent("LOOT_CLOSED", "LOOT_CLOSED")
    self.SearchSpellSlot
end

function GridStatusRange:SearchSpellSlot()
	-- check which spell to search in action bar
    local _,PlayerClass = UnitClass("player")
    local SpellCheck = ClassSpellArray[PlayerClass]

	-- search spell in action bar
    for i = 1, 120 do t = GetActionTexture(i)
        if (t and string.find(t, SpellCheck)) then 
            spellSlot=i
            --DEFAULT_CHAT_FRAME:AddMessage("-Slot_40:"..i)
            --DEFAULT_CHAT_FRAME:AddMessage("-Texture_40:"..t)
            break
        end
    end
end
    
function GridStatusRange:RangeCheck()
    --local settings = self.db.profile.alert_range
    --if not settings.enable then return end
    local settings = self.db.profile.alert_range
    if not settings.enable then return end

    for frameName,frame in pairs(GridFrame.registeredFrames) do
        if frame.unit then

        	local isInRange = 0

        	-- standard function, quick and easy, but false
            if CheckInteractDistance(frame.unit, 4) then
            	isInRange = 1

            else
	            local targetchanged = false

	            if not UnitExists("target") or UnitExists("target") and not UnitIsUnit("target", frame.unit) then
	                TargetUnit(frame.unit)
	                targetchanged = true
	            end

	            
	            local unitcheck = UnitExists(frame.unit) and UnitIsVisible(frame.unit) and UnitIsConnected(frame.unit) and not UnitIsGhost(frame.unit)
	            
	            if unitcheck then
	                isInRange = IsActionInRange(SpellSlot) 
	            end

	            if targetchanged then
	                TargetLastTarget()
	            end
	        end

            if isInRange==1 then
                self.core:SendStatusLost(frame.unitName, "alert_range")
                
                --if frame.frame:GetAlpha() ~= 1 then
                    
                    --frame.frame.BarBG:SetAlpha(1)
                    --frame.frame.Bar:SetAlpha(1)
                --  frame.frame:SetAlpha(1)
                --end
            else                
                self.core:SendStatusGained(frame.unitName, "alert_range",
                    settings.priority,
                    nil,
                    settings.color,
                    settings.text,
                    nil,
                    nil,
                    nil)


                --if frame.frame:GetAlpha() ~= settings.opacity then
                    --frame.frame.BarBG:SetAlpha(settings.opacity)
                    --frame.frame.Bar:SetAlpha(settings.opacity)
                --  frame.frame:SetAlpha(settings.opacity)
                --end
            end
        end
    end
end

function GridStatusRange:LOOT_OPENED(event, arg)
	self:Debug("Looting: true")
	isLooting = true
end

function GridStatusRange:LOOT_CLOSED(event, arg)
	self:Debug("Looting: false")
	isLooting = false
end

function GridStatusRange:UpdateRangeFrequency()
    local settings = self.db.profile.alert_range
    self:CancelScheduledEvent("GridEnhancedRangeCheck")
    
    self:ScheduleRepeatingEvent("GridEnhancedRangeCheck", self.RangeCheck, settings.interval, self)
end