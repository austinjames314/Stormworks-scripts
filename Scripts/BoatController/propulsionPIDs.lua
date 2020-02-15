--Declare Constants

local IdleRPM = 150
local MinThrottle = 0.25
local ClutchChannel = 17

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

-- To be connected to engine starters.
local EngineStartChannel = 25

-- Global Variables that need intialising
local Idle = true
local Running = false

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier
local spdSetPoint, spdProcVar, rpmSetPoint, rpmProcVar, error, error_s, iMax, iMin, smooth

function onTick()
	spdSetPoint = getN(SpdSetPointChannel)
	spdProcVar = getN(SpdProcVarChannel)
	Running = getB(EngineRunChannel)
	rpmProcVar = getN(RPMProcVarChannel)

	if not Running then
		setN(SpdPIDTable.OutC, 0)
		setN(ClutchChannel, 0)
		RPMPIDTable.I = 0
		setB(EngineStartChannel, false)
		return
	elseif rpmProcVar < 120 then
		setN(SpdPIDTable.OutC, 1)
		setB(EngineStartChannel, true)
	else
		setB(EngineStartChannel, false)
	end

	if spdSetPoint <= 0 then
		Idle = true
	else
		Idle = false
	end

	---- Section to control speed with throttle
	if Idle then
		rpmSetPoint = IdleRPM
		setN(ClutchChannel, 0)
		PID(RPMPIDTable, rpmSetPoint, rpmProcVar)
		setN(SpdPIDTable.OutC, RPMPIDTable.out)
	else
		setN(ClutchChannel, 1)
		PID(SpdPIDTable, spdSetPoint, spdProcVar)
		if SpdPIDTable.out < MinThrottle then
			SpdPIDTable.out = MinThrottle
		end
		setN(SpdPIDTable.OutC, SpdPIDTable.out)
	end
end

-- These system functions that get called a lot are put in these wrapper functions, so that the minifier can shrink the code used to call them.
function getN(channelNumber)
    return input.getNumber(channelNumber)
end

function getB(channelNumber)
    return input.getBool(channelNumber)
end

function setN(channelNumber, value)
    output.setNumber(channelNumber, value)
end

function setB(channelNumber, value)
    output.setBool(channelNumber, value)
end

function PID(PIDStructTable, setPoint, processVariable)
	--The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external inputs, to support live tuning.
	Kp = getN(PIDStructTable.KpC)
	Ki = getN(PIDStructTable.KiC)
	Kd = getN(PIDStructTable.KdC)
	iMax = getN(PIDStructTable.IMxC)
	iMin = getN(PIDStructTable.IMnC)
	smooth = getN(PIDStructTable.SmthC)

	error = setPoint - processVariable
	
	PIDStructTable.P = error * Kp
	--debug
	setN(PIDStructTable.PC, PIDStructTable.P)
	
	PIDStructTable.I = PIDStructTable.I + error * Ki
	--debug
	setN(PIDStructTable.IC, PIDStructTable.I)

	--Limit I to prevent integral windup
	PIDStructTable.I = math.min(iMax,math.max(iMin, PIDStructTable.I))
	--debug
	setN(PIDStructTable.IbC, PIDStructTable.I)
	
	error = PIDStructTable.Pv0 - processVariable
	PIDStructTable.Pv0 = processVariable
	error_s = smooth * error + (1 - smooth) * PIDStructTable.Er0
	
	PIDStructTable.D = Kd * error_s
	--To calculate D next tick
	PIDStructTable.Er0 = error_s
	--debug
	setN(PIDStructTable.DC, PIDStructTable.D)

	PIDStructTable.out = PIDStructTable.P + PIDStructTable.I + PIDStructTable.D
end