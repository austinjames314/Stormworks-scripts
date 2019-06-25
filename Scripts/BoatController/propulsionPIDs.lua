--Declare Constants

local ClutchRPM = 200
local IdleRPM = 130
local MinimumKPH = 55
local StallCounterLimit = 120

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

--Input channels
local ClchSetPointChannel = 17
local ClchProcVarChannel = 18
local ClchPIDTable = {}
ClchPIDTable.KpC = 19
ClchPIDTable.KiC = 20
ClchPIDTable.IMxC = 21
ClchPIDTable.IMnC = 22
ClchPIDTable.KdC = 23
ClchPIDTable.SmthC = 24
--output channels
ClchPIDTable.OutC = 17
ClchPIDTable.PC = 18
ClchPIDTable.IC = 19
ClchPIDTable.IbC = 20
ClchPIDTable.DC = 21
--PID variables
ClchPIDTable.I = 0
ClchPIDTable.Er0 = 0
ClchPIDTable.Pv0 = 0

-- This is one is for the on/off switch. Should get fed a boolean. If true, it starts the engine. Shuts down if false.
local EngineRunChannel = 25


--Output channels

-- To be connected to engine starters.
local EngineStartChannel = 25

-- Global Variables that need intialising
local ClutchMode = true
local Idle = true
local Running = false
local RPM0 = 0
local StallCounter = 0

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier
local spdSetPoint, spdProcVar, rpmSetPoint, rpmProcVar, spdAdj, offset, stall, rpmDiff, error, error_s, iMax, iMin, smooth

function onTick()
	spdSetPoint = getN(SpdSetPointChannel)
	spdProcVar = getN(SpdProcVarChannel)
	Running = getB(EngineRunChannel)
	rpmProcVar = getN(RPMProcVarChannel)

	if not Running then
		setN(SpdPIDTable.OutC, 0)
		setN(ClchPIDTable.OutC, 0)
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
		ClutchMode = true
	else
		Idle = false
	end

	---- Section to control RPM

	--This block checks:
	-- If we're in idle mode, set the target RPM to the Idle RPM
	-- otherwise, put the RPM up to the clutchMode RPM, but scale it back towards the stall speed as we get closer to the clutch being fully engaged (minimumKPH)
	--The issue is that if it kept trying to keep the RPM high, it'd way overshoot the speed where the clutch _could_ be fully engaged.
	if Idle then
		rpmSetPoint = IdleRPM
	else
		--The idea here to end up with an RPM at IdleRPM when speed hits MinimumKPH
		spdAdj = math.min(1,math.max(0, spdProcVar / MinimumKPH))
		offset = spdAdj * (ClutchRPM - IdleRPM)
		rpmSetPoint = ClutchRPM - offset
	end
	
	PID(RPMPIDTable, rpmSetPoint, rpmProcVar)
	if ClutchMode then
		setN(SpdPIDTable.OutC, RPMPIDTable.out)
	end

    ---- Section to control speed with clutch

	--This looks at the rate of RPM change. The idea is to set the 'stall' flag to true if we're 2 ticks away from hitting the stall speed.
	rpmDiff = RPM0 - rpmProcVar
	RPM0 = rpmProcVar
	stall = false
	if (rpmProcVar - 120) <= (rpmDiff * 2) or rpmProcVar <= 122.5 then
		stall = true
	end

	--This block progressively eases back on the target speed, when we get close to the stall speed, so that that PID controller eases off the clutch a little.
	--The aim being to not stall the damn thing so much.
	if stall then
		--StallCounter = math.min(StallCounter + 10, StallCounterLimit)
		--ClchPIDTable.I = ClchPIDTable.I * 0.99^10
		ClchPIDTable.I = ClchPIDTable.I * 0.95
	elseif StallCounter > 0 then
		--StallCounter = math.max(StallCounter - 1, 0)
		--ClchPIDTable.I = ClchPIDTable.I / 0.99
	end
	--spdSetPoint = spdSetPoint * (1 - StallCounter / StallCounterLimit)
	PID(ClchPIDTable, spdSetPoint, spdProcVar)

	--Whether or not to use the PID's output on the clutch, or whether to lock it open or closed.
	if Idle or rpmProcVar < 115 then
		setN(ClchPIDTable.OutC, 0)
	elseif ClutchMode then
		setN(ClchPIDTable.OutC, ClchPIDTable.out)
	else
		setN(ClchPIDTable.OutC, 1)
	end

    ---- Section to control speed with throttle
	PID(SpdPIDTable, spdSetPoint, spdProcVar)


	if not ClutchMode then
		setN(SpdPIDTable.OutC, SpdPIDTable.out)
	end


	-- changes to make when transitioning from clutch mode to cruise mode
	if ClutchMode and (ClchPIDTable.out >= 1.0) then
		ClutchMode = false
		SpdPIDTable.I = 0.45
	end

	-- changes to make when transitioning from cruise mode to clutch mode
	if not ClutchMode and (rpmProcVar <= 125) then
		ClutchMode = true
		--[[ The idea here was to hand the throttle setting over from the cruise controller to the RPM controller for clutch mode
			but to bump it a little bit to overcome Stormworks' fuckiness in that the torque _increases_ at first, as you release
			the clutch. But ub the end I just hardcoded it, and it seems to work now.
		--]]
		RPMPIDTable.I = 0.8
		-- This is the appropriate I value for when clutch mode is sitting at just below the changeover speed.
		ClchPIDTable.I = 0.7
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