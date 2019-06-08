--Declare Constants

--Input channels
local SetPointChannel = 1
local ProcVarChannel = 2
local KpChannel = 3
local KiChannel = 4
local IMaxChannel = 5
local IMinChannel = 6
local KdChannel = 7
local SmoothingChannel = 8

--Output channels
local ControlOutputChannel = 1
local POutChannel = 2
local IOutChannel = 3
local IboundedOutChannel = 4
local DOutChannel = 5

-- Global Variables that need intialising
local PIDTable1 = {}
local error_0 = 0

PIDTable1[KpChannel] = KpChannel
PIDTable1[KiChannel] = KiChannel
PIDTable1[IMaxChannel] = IMaxChannel
PIDTable1[IMinChannel] = IMinChannel
PIDTable1[KdChannel] = KdChannel
PIDTable1[SmoothingChannel] = SmoothingChannel
PIDTable1[ControlOutputChannel] = ControlOutputChannel
PIDTable1[POutChannel] = POutChannel
PIDTable1[IOutChannel] = IOutChannel
PIDTable1[IboundedOutChannel] = IboundedOutChannel
PIDTable1[DOutChannel] = DOutChannel
PIDTable1.I = 0
PIDTable1.P0 = 0

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier
local error, error_s, processVariable, setPoint, PIDStructTable, smooth, text

-- These system functions that get called a lot are put in these wrapper functions, so that the minifier can shrink the code used to call them.
function getN(channelNumber)
    return input.getNumber(channelNumber)
end

function setN(channelNumber, value)
    output.setNumber(channelNumber, value)
end

function PID(PIDStructTable, setPoint, processVariable)
	--The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external inputs, to support live tuning.
	Kp = getN(PIDStructTable[KpChannel])
	Ki = getN(PIDStructTable[KiChannel])
	Kd = getN(PIDStructTable[KdChannel])
	iMax = getN(PIDStructTable[IMaxChannel])
	iMin = getN(PIDStructTable[IMinChannel])
	smooth = getN(PIDTable1[SmoothingChannel])

	error = setPoint - processVariable
	
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
	
	error_s = smooth * error + (1 - smooth) * PIDStructTable.P0
	
	PIDStructTable.D = Kd * (error_s - PIDStructTable.P0)
	--To calculate D next tick
	PIDStructTable.P0 = error_s
	--debug
	setN(DOutChannel, PIDStructTable.D)

	PIDStructTable.out = PIDStructTable.P + PIDStructTable.I + PIDStructTable.D
end

function onTick()
	setPoint = getN(SetPointChannel)
	processVariable = getN(ProcVarChannel)

	--Calculate and output result
	PID(PIDTable1, setPoint, processVariable)
	setN(ControlOutputChannel, PIDTable1.out)
end
