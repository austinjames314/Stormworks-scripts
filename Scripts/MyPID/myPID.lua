--Declare Constants

--Input channels
local SetPointChannel = 1
local ProcVarChannel = 2
local KpChannel = 3
local KiChannel = 4
local KiMaxChannel = 5
local KiMinChannel = 6
local KdChannel = 7

--Output channels
local ControlOutputChannel = 1
local POut = 2
local IOut = 3
local IboundedOut = 4
local DOut = 5

-- Global Variables that need intialising
local I = 0

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier
local P0, error, processVariable, setPoint

-- These system functions that get called a lot are put in these wrapper functions, so that the minifier can shrink the code used to call them.
function getN(channelNumber)
    return input.getNumber(channelNumber)
end

--Looks like I don't need this one for the PID code
--[[
function getB(channelNumber)
    return input.getBool(channelNumber)
end
--]]

function setN(channelNumber, value)
    output.setNumber(channelNumber, value)
end

--Looks like I don't need this one for the PID code
--[[
function setB(channelNumber, value)
    output.setBool(channelNumber, value)
end
--]]

function PID(KpChannel, KiChannel, KdChannel, IMaxChannel, IMinChannel, setPoint, processVariable, POut, IOut, IboundedOut, DOut)
	--The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external.
	Kp = getN(KpChannel)
	Ki = getN(KiChannel)
	Kd = getN(KdChannel)
	iMax = getN(IMaxChannel)
	iMin = getN(IMinChannel)

	error = setPoint - processVariable
	
	P = error * Kp
	--debug
	setN(POut, P)
	
	I = I + error * Ki
	--debug
	setN(IOut, I)

	--Limit I to prevent integral windup
	I = math.min(iMax,math.max(iMin, I))
	--debug
	setN(IboundedOut, I)
	
	D = Kd * (error - P0)
	--To calculate D next tick
	P0 = error
	--debug
	setN(DOut, D)

	return P + I + D
end

function onTick()
	setPoint = getN(SetPointChannel)
	processVariable = getN(ProcVarChannel)

	--Calculate and output result
	setN(ControlOutputChannel, PID(Kp, Ki, Kd, KiMax, KiMin, setPoint, processVariable, POut, IOut, IboundedOut, DOut))
end