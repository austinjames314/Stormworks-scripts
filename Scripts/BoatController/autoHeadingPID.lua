--Declare Constants

--Input channels
local HeadingResetChannel = 9

local SetPointChannel = 1
local ProcVarChannel = 2
local PIDTable = {}
PIDTable.KpC = 3
PIDTable.KiC = 4
PIDTable.IMxC = 5
PIDTable.IMnC = 6
PIDTable.KdC = 7
PIDTable.SmthC = 8
--output channels
PIDTable.OutC = 1
PIDTable.PC = 2
PIDTable.IC = 3
PIDTable.IbC = 4
PIDTable.DC = 5
--PID variables
PIDTable.I = 0
PIDTable.Er0 = 0
PIDTable.Pv0 = 0

-- Global Variables that need intialising

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier
local error, error_s, processVariable, setPoint, PIDStructTable, iMax, iMin, smooth

-- These system functions that get called a lot are put in these wrapper functions, so that the minifier can shrink the code used to call them.
local function getN(channelNumber)
    return input.getNumber(channelNumber)
end

local function setN(channelNumber, value)
    output.setNumber(channelNumber, value)
end

function PID(PIDStructTable, setPoint, processVariable)
	--The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external inputs, to support live tuning.
	Kp = getN(PIDStructTable.KpC)
	Ki = getN(PIDStructTable.KiC)
	Kd = getN(PIDStructTable.KdC)
	iMax = getN(PIDStructTable.IMxC)
	iMin = getN(PIDStructTable.IMnC)
	smooth = getN(PIDStructTable.SmthC)

	--this one is special, as if pV = 001, and setPoint = 357, error should be -4, not 356
	error = setPoint - processVariable
	if error > 180 then
		error = error - 360
	elseif error < -180 then
		error = error + 360
	end
	
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
	--debug
	setN(PIDStructTable.OutC, PIDStructTable.out)
end

function onTick()
	setPoint = getN(SetPointChannel) -- This is OK, as external circuit logic stores the setpoint when it's reset
	processVariable = getN(ProcVarChannel)
	--reset the integral value when resetting the heading
	if input.getBool(HeadingResetChannel) then
		PIDTable.I = 0
	end

	--Calculate and output result
	PID(PIDTable, setPoint, processVariable)
	setN(PIDTable.OutC, PIDTable.out)
end