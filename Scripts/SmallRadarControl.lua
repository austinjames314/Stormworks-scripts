--Declare Constants

--Input channels
local GPSxChannel = 1
local GPSyChannel = 2
local AltChannel = 3
local HeadingChannel = 4
local PitchChannel = 5
local RollChannel = 6
local SignalStrengthChannel = 7

--output channels
FOVChannel = 1
YawChannel = 2

-- Global Variables that need intialising

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier

-- These system functions that get called a lot are put in these wrapper functions, so that the minifier can shrink the code used to call them.
function getN(channelNumber)
    return input.getNumber(channelNumber)
end

function setN(channelNumber, value)
    output.setNumber(channelNumber, value)
end

function onTick()
	hold = input.getBool(OnOffChannel)
	if State then
		if not hold then
			State = Off
			setPoint = 0
		end
	else
		if hold then
			State = On
			--Determine Setpoint
			setPoint = getN(ProcVarChannel)
			PIDTable1.I = getN(CurrentCollectiveChannel)
		end
	end
	setN(SetPointOutChannel, setPoint)
	
	if State then
		processVariable = getN(ProcVarChannel)

		--Calculate and output result
		PID(PIDTable1, setPoint, processVariable)
		setN(PIDTable1.OutC, PIDTable1.out)
	end
end

asin( (sin(x*pi2)) / (sin((90-y) * (pi/180))) )*(180/pi)