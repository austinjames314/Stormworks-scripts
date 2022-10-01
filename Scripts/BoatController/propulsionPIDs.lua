--Declare Constants

local IdleRPM = property.getNumber("Idle RPM")
local MinThrottle = property.getNumber("Min Throttle")
local SwitchGearLowRPM = property.getNumber("SwitchLow")
local SwitchGearHighRPM = property.getNumber("SwitchHigh")
local GearRatio = property.getNumber("Gear Ratio")

--Input channels
local SpdSetPointChannel = 1
local SpdProcVarChannel = 2
local SpdPIDTable = {}
SpdPIDTable.KpC = 3
SpdPIDTable.KiC = 4
SpdPIDTable.IMxC = 5
SpdPIDTable.IMnC = 6
SpdPIDTable.KdC = 7
SpdPIDTable.SmthC = 8
--output channels
SpdPIDTable.OutC = 1
SpdPIDTable.PC = 2
SpdPIDTable.IC = 3
SpdPIDTable.IbC = 4
SpdPIDTable.DC = 5
--PID variables
SpdPIDTable.I = 0
SpdPIDTable.Er0 = 0
SpdPIDTable.Pv0 = 0

--Input channels
local RPMSetPointChannel = 9
local RPMProcVarChannel = 10
local RPMPIDTable = {}
RPMPIDTable.KpC = 11
RPMPIDTable.KiC = 12
RPMPIDTable.IMxC = 13
RPMPIDTable.IMnC = 14
RPMPIDTable.KdC = 15
RPMPIDTable.SmthC = 16
--output channels
RPMPIDTable.OutC = 9
RPMPIDTable.PC = 10
RPMPIDTable.IC = 11
RPMPIDTable.IbC = 12
RPMPIDTable.DC = 13
--PID variables
RPMPIDTable.I = 0
RPMPIDTable.Er0 = 0
RPMPIDTable.Pv0 = 0

-- This is one is for the on/off switch. Should get fed a boolean. If true, it starts the engine. Shuts down if false.
local EngineRunChannel = 25

--Output channels
local ClutchChannel = 17
local LowGearChannel = 18

-- To be connected to engine starters.
local EngineStartChannel = 25

-- Global Variables that need intialising
local Idle = true
local Running = false
local GearLow = true

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier
local spdSetPoint, spdProcVar, rpmSetPoint, rpmProcVar, error, error_s, iMax, iMin, smooth

function onTick()
	spdSetPoint = GetN(SpdSetPointChannel)
	spdProcVar = GetN(SpdProcVarChannel)
	Running = GetB(EngineRunChannel)
	rpmProcVar = GetN(RPMProcVarChannel)

	if not Running then
		SetN(SpdPIDTable.OutC, 0)
		SetN(ClutchChannel, 0)
		RPMPIDTable.I = 0
		SetB(EngineStartChannel, false)
		return
	elseif rpmProcVar < 120 then
		SetN(SpdPIDTable.OutC, 1)
		SetB(EngineStartChannel, true)
	else
		SetB(EngineStartChannel, false)
	end

	if Idle then
		if spdSetPoint > 0 then
			Idle = false
			SpdPIDTable.I = MinThrottle
		end
	else
		if spdSetPoint <= 0 then
			Idle = true
			SpdPIDTable.I = MinThrottle
		end
	end

	---- Section to control speed with throttle
	if Idle then
		rpmSetPoint = IdleRPM
		SetN(ClutchChannel, 0)
		PID(RPMPIDTable, rpmSetPoint, rpmProcVar)
		SetN(SpdPIDTable.OutC, RPMPIDTable.out)
	else
		SetN(ClutchChannel, 1)
		PID(SpdPIDTable, spdSetPoint, spdProcVar)
		if SpdPIDTable.out < MinThrottle then
			SpdPIDTable.I = MinThrottle
		end
		SetN(SpdPIDTable.OutC, SpdPIDTable.out)
	end

	---- Section to manage gear changes
	if GearLow then
		if rpmProcVar > SwitchGearHighRPM then
			GearLow = false
			SpdPIDTable.I = SpdPIDTable.I * (GearRatio * 0.62)
		end
	else
		if rpmProcVar < SwitchGearLowRPM then
			GearLow = true
			SpdPIDTable.I = SpdPIDTable.I / (GearRatio * 0.62)
		end
	end
	SetB(LowGearChannel, GearLow)
end

-- These system functions that get called a lot are put in these wrapper functions, so that the minifier can shrink the code used to call them.
function GetN(channelNumber)
    return input.getNumber(channelNumber)
end

function GetB(channelNumber)
    return input.getBool(channelNumber)
end

function SetN(channelNumber, value)
    output.setNumber(channelNumber, value)
end

function SetB(channelNumber, value)
    output.setBool(channelNumber, value)
end

function PID(PIDStructTable, setPoint, processVariable)
	--The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external inputs, to support live tuning.
	Kp = GetN(PIDStructTable.KpC)
	Ki = GetN(PIDStructTable.KiC)
	Kd = GetN(PIDStructTable.KdC)
	iMax = GetN(PIDStructTable.IMxC)
	iMin = GetN(PIDStructTable.IMnC)
	smooth = GetN(PIDStructTable.SmthC)

	error = setPoint - processVariable
	
	PIDStructTable.P = error * Kp
	--debug
	SetN(PIDStructTable.PC, PIDStructTable.P)
	
	PIDStructTable.I = PIDStructTable.I + error * Ki
	--debug
	SetN(PIDStructTable.IC, PIDStructTable.I)

	--Limit I to prevent integral windup
	PIDStructTable.I = math.min(iMax,math.max(iMin, PIDStructTable.I))
	--debug
	SetN(PIDStructTable.IbC, PIDStructTable.I)
	
	error = PIDStructTable.Pv0 - processVariable
	PIDStructTable.Pv0 = processVariable
	error_s = smooth * error + (1 - smooth) * PIDStructTable.Er0
	
	PIDStructTable.D = Kd * error_s
	--To calculate D next tick
	PIDStructTable.Er0 = error_s
	--debug
	SetN(PIDStructTable.DC, PIDStructTable.D)

	PIDStructTable.out = PIDStructTable.P + PIDStructTable.I + PIDStructTable.D
end