--Declare Constants

--Input channels
SetPointChannel = 1
ProcVarChannel = 2
KpChannel = 3
KiChannel = 4
KiMaxChannel = 5
KiMinChannel = 6
KdChannel = 7

--Output channels
ControlOutput = 1
POut = 2
IOut = 3
IboundedOut = 4
DOut = 5

-- Global Variables
I = 0
P0 = 0

function onTick()
	--in normal use these are the only two inputs used.
	setPoint = input.getNumber(SetPointChannel)
	procVar = input.getNumber(ProcVarChannel)
	
	--if the channel 3 bool is true, then take the PID congfig values from the composite input in real time (good for tuning the PID controller).
	--Otherwise we just need to adjust the gains each tick, depending on the setpoint (better stability with very wide setpoint ranges).
	Kp = input.getNumber(KpChannel)
	Ki = input.getNumber(KiChannel)
	Kd = input.getNumber(KdChannel)
	KiMinC = input.getNumber(KiMaxChannel)
	KiMaxC = input.getNumber(KiMinChannel)

	error = setPoint - procVar
	
	P = error * Kp
	--debug
	output.setNumber(POut, P)
	
	I = I + error * Ki
	--debug
	output.setNumber(IOut, I)

	--Limit I to prevent integral windup
	I = math.min(KiMaxC,math.max(KiMinC, I))
	--debug
	output.setNumber(IboundedOut, I)
	
	D = Kd * (P0 - procVar)
	--To calculate D next tick
	P0 = procVar
	--debug
	output.setNumber(DOut, D)

	out = P + I + D
	--Output result
	output.setNumber(ControlOutput, out)
end