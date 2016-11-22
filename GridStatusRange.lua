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
		interval = 0.25,
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
function GridStatusRange:OnInitialize()
	self.super.OnInitialize(self)

end

function GridStatusRange:OnEnable()
	self:RegisterStatus("alert_range", "Range alert", rangeOptions, true)
	self:ScheduleRepeatingEvent("GridEnhancedRangeCheck", self.RangeCheck, GridStatusRange.db.profile.alert_range.interval, self)	
	
end
	
function GridStatusRange:RangeCheck()
	--local settings = self.db.profile.alert_range
	--if not settings.enable then return end
	local settings = self.db.profile.alert_range
    if not settings.enable then return end

    --local now = GetTime()

    for frameName,frame in pairs(GridFrame.registeredFrames) do
		if frame.unit then
			if CheckInteractDistance(frame.unit, 4) then
				self.core:SendStatusLost(frame.unitName, "alert_range")
				
				--if frame.frame:GetAlpha() ~= 1 then
					
					--frame.frame.BarBG:SetAlpha(1)
					--frame.frame.Bar:SetAlpha(1)
				--	frame.frame:SetAlpha(1)
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
				--	frame.frame:SetAlpha(settings.opacity)
			 	--end
			end
		end
	end
end

function GridStatusRange:UpdateRangeFrequency()
	local settings = self.db.profile.alert_range
	self:CancelScheduledEvent("GridEnhancedRangeCheck")
	
	self:ScheduleRepeatingEvent("GridEnhancedRangeCheck", self.RangeCheck, settings.interval, self)
end