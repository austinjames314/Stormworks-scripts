--Declare Constants

ClutchRPM = 200
IdleRPM = 150
MinimumKPH = 55

--Input channels
SpdSetPointChannel = 1
SpdProcVarChannel = 2
SpdKpChannel = 3
SpdKiChannel = 4
SpdKiMaxChannel = 5
SpdKiMinChannel = 6
SpdKdChannel = 7

RPMSetPointChannel = 9
RPMProcVarChannel = 10
RPMKpChannel = 11
RPMKiChannel = 12
RPMKiMaxChannel = 13
RPMKiMinChannel = 14
RPMKdChannel = 15

ClchSetPointChannel = 17
ClchProcVarChannel = 18
ClchKpChannel = 19
ClchKiChannel = 20
ClchKiMaxChannel = 21
ClchKiMinChannel = 22
ClchKdChannel = 23

EngineRunChannel = 24

--Output channels
SpdControlOutput = 1
SpdPOut = 2
SpdIOut = 3
SpdIboundedOut = 4
SpdDOut = 5

RPMControlOutput = 9
RPMPOut = 10
RPMIOut = 11
RPMIboundedOut = 12
RPMDOut = 13

ClchControlOutput = 17
ClchPOut = 18
ClchIOut = 19
ClchIboundedOut = 20
ClchDOut = 21

EngineStartChannel = 22

-- Global Variables
SpdI = 0
SpdP0 = 0

RPMI = 0
RPMP0 = 0
RPMSmoothed = 0

ClchI = 0
ClchP0 = 0

ClutchMode = true
Idle = true
Running = false

clchOut = 0

function onTick()
	spdSetPoint = input.getNumber(SpdSetPointChannel)
	spdProcVar = input.getNumber(SpdProcVarChannel)
	Running = input.getBool(EngineRunChannel)
	rpmProcVar = input.getNumber(RPMProcVarChannel)
	rpmDiff = RPMP0 - rpmProcVar


	if not Running then
		output.setNumber(SpdControlOutput, 0)
		output.setNumber(ClchControlOutput, 0)
	elseif rpmProcVar < 120 then
		output.setNumber(SpdControlOutput, 1)
		output.setBool(EngineStartChannel, true)
	else
		output.setBool(EngineStartChannel, false)
	end

	if spdSetPoint <= 0 then
		Idle = true
		ClutchMode = true
	else
		Idle = false
	end


	--section to control RPM
	if Idle then
		rpmSetPoint = IdleRPM
	else
		spdAdj = math.min(1,math.max(0, spdProcVar / MinimumKPH))
		offset = spdAdj * (20 + ClutchRPM - IdleRPM)
		rpmSetPoint = ClutchRPM - offset
	end

	Kp = input.getNumber(RPMKpChannel)
	Ki = input.getNumber(RPMKiChannel)
	Kd = input.getNumber(RPMKdChannel)
	KiMaxC = input.getNumber(RPMKiMaxChannel)
	KiMinC = input.getNumber(RPMKiMinChannel)

	error = rpmSetPoint - rpmProcVar

	P = error * Kp

	RPMI = RPMI + (error * Ki)
	RPMI = math.min(KiMaxC,math.max(KiMinC, RPMI))

	D = Kd * rpmDiff
	RPMP0 = rpmProcVar
	if ClutchMode then
		output.setNumber(SpdControlOutput, P + RPMI + D)
	end

	--section to control speed with clutch
	Kp = input.getNumber(ClchKpChannel)
	Ki = input.getNumber(ClchKiChannel)
	Kd = input.getNumber(ClchKdChannel)
	KiMaxC = input.getNumber(ClchKiMaxChannel)
	KiMinC = input.getNumber(ClchKiMinChannel)

	stall = false
	if (rpmProcVar - 120) < rpmDiff then
		stall = true
	end

	error = spdSetPoint - spdProcVar

	P = error * Kp
	output.setNumber(ClchPOut, P)

	if stall then
		ClchI = ClchI - error * Ki
	else
		ClchI = ClchI + error * Ki
	end
	output.setNumber(ClchIOut, ClchI)

	ClchI = math.min(KiMaxC,math.max(KiMinC, ClchI))
	output.setNumber(ClchIboundedOut, ClchI)

	D = Kd * (ClchP0 - spdProcVar)
	ClchP0 = spdProcVar
	output.setNumber(ClchDOut, D)
	
	D2 = Kd * -1/math.abs(rpmProcVar - 120)

	if stall then
		clchOut = 0
	else
		clchOut = P + ClchI + D + D2
	end

	if Idle then
		output.setNumber(ClchControlOutput, 0)
	elseif ClutchMode then
		output.setNumber(ClchControlOutput, clchOut)
	else
		output.setNumber(ClchControlOutput, 1)
	end

	--section to control speed with throttle
	Kp = input.getNumber(SpdKpChannel)
	Ki = input.getNumber(SpdKiChannel)
	Kd = input.getNumber(SpdKdChannel)
	KiMaxC = input.getNumber(SpdKiMaxChannel)
	KiMinC = input.getNumber(SpdKiMinChannel)

	error = spdSetPoint - spdProcVar

	P = error * Kp
	output.setNumber(SpdPOut, P)

	SpdI = SpdI + error * Ki
	output.setNumber(SpdIOut, SpdI)

	SpdI = math.min(KiMaxC,math.max(KiMinC, SpdI))
	output.setNumber(SpdIboundedOut, SpdI)

	D = Kd * (SpdP0 - spdProcVar)
	SpdP0 = spdProcVar
	output.setNumber(SpdDOut, D)

	out = P + SpdI + D
	if not ClutchMode then
		output.setNumber(SpdControlOutput, out)
	end

	if ClutchMode and (clchOut >= 1.0) then
		ClutchMode = false
	end

	if not ClutchMode and (rpmProcVar <= 125) then
		ClutchMode = true
	end
end