--Declare Constants
On = true
Off = false
--Input channels
local ProcVarChannel = 1
local OnOffChannel = 2
local CurrentCollectiveChannel = 9
local PIDTable1 = {}
PIDTable1.KpC = 3
PIDTable1.KiC = 4
PIDTable1.IMxC = 5
PIDTable1.IMnC = 6
PIDTable1.KdC = 7
PIDTable1.SmthC = 8
--output channels
OutChannel = 1
SetPointOutChannel = 6
PIDTable1.OutC = OutChannel
PIDTable1.PC = 2
PIDTable1.IC = 3
PIDTable1.IbC = 4
PIDTable1.DC = 5
--PID variables
PIDTable1.I = 0
PIDTable1.P0 = 0

-- Global Variables that need intialising
local State = Off
local setPoint = 0

-- Global Variables that don't need initialising, plus variables that don't need to be global that are declared here, to help the minifier
local processVariable, error, error_s, iMax, iMin, smooth

-- These system functions that get called a lot are put in these wrapper functions, so that the minifier can shrink the code used to call them.
function GetN(channelNumber)
    return input.getNumber(channelNumber)
end

function SetN(channelNumber, value)
    output.setNumber(channelNumber, value)
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
	
	error_s = smooth * error + (1 - smooth) * PIDStructTable.P0
	
	PIDStructTable.D = Kd * (error_s - PIDStructTable.P0)
	--To calculate D next tick
	PIDStructTable.P0 = error_s
	--debug
	SetN(PIDStructTable.DC, PIDStructTable.D)

	PIDStructTable.out = PIDStructTable.P + PIDStructTable.I + PIDStructTable.D
end

function onTick()
	-- Flip State
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
			setPoint = GetN(ProcVarChannel)
			PIDTable1.I = GetN(CurrentCollectiveChannel)
		end
	end
	SetN(SetPointOutChannel, setPoint)
	
	if State then
		processVariable = GetN(ProcVarChannel)

		--Calculate and output result
		PID(PIDTable1, setPoint, processVariable)
		SetN(PIDTable1.OutC, PIDTable1.out)
	end
end
