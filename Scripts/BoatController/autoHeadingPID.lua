--Declare Constants

--Input channels
local SetPointChannel = 1
local ProcVarChannel = 2
local KpChannel = 3
local KiChannel = 4
local IMaxChannel = 5
local IMinChannel = 6
local KdChannel = 7
local HeadingResetChannel = 8

--Output channels
local ControlOutputChannel = 1
local POutChannel = 2
local IOutChannel = 3
local IboundedOutChannel = 4
local DOutChannel = 5

-- Global Variables that need intialising
local PIDTable1 = {}
local error_0 = 0

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier
local error, processVariable, setPoint, PIDStructTable, heading1, heading2, text

-- These system functions that get called a lot are put in these wrapper functions, so that the minifier can shrink the code used to call them.
local function getN(channelNumber)
    return input.getNumber(channelNumber)
end

local function setN(channelNumber, value)
    output.setNumber(channelNumber, value)
end

	--For heading error, hdg2 = target heading, hdg1 = current heading
	--For heading change, hdg2 = new heading, hd1 = old heading
local function headingDiff(heading1, heading2)
	return heading2 - heading1
end
	

function PID(PIDStructTable, setPoint, processVariable)
	--The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external inputs, to support live tuning.
	Kp = getN(PIDStructTable[KpChannel])
	Ki = getN(PIDStructTable[KiChannel])
	Kd = getN(PIDStructTable[KdChannel])
	iMax = getN(PIDStructTable[IMaxChannel])
	iMin = getN(PIDStructTable[IMinChannel])

	--this one is special, as if pV = 001, and setPoint = 357, error should be -4, not 356
	error = setPoint - processVariable
	if error > 180 then
		error = error - 360
	elseif error < -180 then
		error = error + 360
	end
	
	PIDStructTable.P = error * Kp
	--debug
	setN(POutChannel, PIDStructTable.P)
	
	PIDStructTable.I = PIDStructTable.I + error * Ki
	--debug
	setN(IOutChannel, PIDStructTable.I)

	--Limit I to prevent integral windup
	PIDStructTable.I = math.min(iMax,math.max(iMin, PIDStructTable.I))
	--debug
	setN(IboundedOutChannel, PIDStructTable.I)
	
	error = 0.1 * error + (0.9) * error_0
	
	PIDStructTable.D = Kd * (error - PIDStructTable.P0)
	--To calculate D next tick
	PIDStructTable.P0 = error
	--debug
	setN(DOutChannel, PIDStructTable.D)

	PIDStructTable.out = PIDStructTable.P + PIDStructTable.I + PIDStructTable.D
end

function getB(channelNumber)
    return input.getBool(channelNumber)
end

function onTick()
	-- On the first tick ever, initialise the PID table with the appropriate values
	if PIDTable1[KpChannel] == nil then
		PIDTable1[KpChannel] = KpChannel
		PIDTable1[KiChannel] = KiChannel
		PIDTable1[IMaxChannel] = IMaxChannel
		PIDTable1[IMinChannel] = IMinChannel
		PIDTable1[KdChannel] = KdChannel
		PIDTable1[ControlOutputChannel] = ControlOutputChannel
		PIDTable1[POutChannel] = POutChannel
		PIDTable1[IOutChannel] = IOutChannel
		PIDTable1[IboundedOutChannel] = IboundedOutChannel
		PIDTable1[DOutChannel] = DOutChannel
		PIDTable1.I = 0
		PIDTable1.P0 = 0
	end
	setPoint = getN(SetPointChannel)
	processVariable = getN(ProcVarChannel)
	--reset the integral value when resetting the heading
	if input.getBool(HeadingResetChannel) then
		PIDTable1.I = 0
	end

	--Calculate and output result
	PID(PIDTable1, setPoint, processVariable)
	setN(ControlOutputChannel, PIDTable1.out)
end
