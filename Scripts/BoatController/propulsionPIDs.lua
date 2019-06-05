--Declare Constants
local 
ClutchRPM, --= 200
IdleRPM, --= 150
MinimumKPH, --= 55

--Input channels
SpdSetPointChannel, --= 1
SpdProcVarChannel, --= 2
SpdKpChannel, --= 3
SpdKiChannel, --= 4
SpdKiMaxChannel, --= 5
SpdKiMinChannel, --= 6
SpdKdChannel, --= 7

RPMSetPointChannel, --= 9
RPMProcVarChannel, --= 10
RPMKpChannel, --= 11
RPMKiChannel, --= 12
RPMKiMaxChannel, --= 13
RPMKiMinChannel, --= 14
RPMKdChannel, --= 15

ClchSetPointChannel, --= 17
ClchProcVarChannel, --= 18
ClchKpChannel, --= 19
ClchKiChannel, --= 20
ClchKiMaxChannel, --= 21
ClchKiMinChannel, --= 22
ClchKdChannel, --= 23

-- This is one is for the on/off switch. Should get fed a boolean. If true, it starts the engine. Shuts down if false.
EngineRunChannel, --= 24

--Output channels
SpdControlOutput, --= 1
SpdPOut, --= 2
SpdIOut, --= 3
SpdIboundedOut, --= 4
SpdDOut, --= 5

RPMControlOutput, --= 9
RPMPOut, --= 10
RPMIOut, --= 11
RPMIboundedOut, --= 12
RPMDOut, --= 13

ClchControlOutput, --= 17
ClchPOut, --= 18
ClchIOut, --= 19
ClchIboundedOut, --= 20
ClchDOut, --= 21

--To be connected to engine starters.
EngineStartChannel, --= 22

-- Global Variables
SpdI, --= 0
SpdP0, --= 0

RPMI, --= 0
RPMP0, --= 0
RPMSmoothed, --= 0

ClchI, --= 0
ClchP0, --= 0

ClutchMode, --= true
Idle, --= true
Running, --= false

clchOut --= 0

= 200, 150, 55, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24,
1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 17, 18, 19, 21, 22,
0, 0, 0, 0, 0, 0, 0, true, true, false, 0

--Local variables declared here to help the minifier
local
spdSetPoint, spdProcVar, rpmProcVar, rpmDiff, rpmSetPoint, spdAdj, offset, error, Kp, Ki, Kd, KiMaxC, KiMinC, stall

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

function onTick()
	spdSetPoint = getN(SpdSetPointChannel)
	spdProcVar = getN(SpdProcVarChannel)
	Running = getB(EngineRunChannel)
	rpmProcVar = getN(RPMProcVarChannel)
	rpmDiff = RPMP0 - rpmProcVar


	if not Running then
		setN(SpdControlOutput, 0)
		setN(ClchControlOutput, 0)
	elseif rpmProcVar < 120 then
		setN(SpdControlOutput, 1)
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


	--section to control RPM
	if Idle then
		rpmSetPoint = IdleRPM
	else
		spdAdj = math.min(1,math.max(0, spdProcVar / MinimumKPH))
		offset = spdAdj * (20 + ClutchRPM - IdleRPM)
		rpmSetPoint = ClutchRPM - offset
    end
    
    --The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external.
	Kp = getN(RPMKpChannel)
	Ki = getN(RPMKiChannel)
	Kd = getN(RPMKdChannel)
	KiMaxC = getN(RPMKiMaxChannel)
	KiMinC = getN(RPMKiMinChannel)

	error = rpmSetPoint - rpmProcVar

	P = error * Kp
    --debug
    setN(RPMPOut, P)
    
    RPMI = RPMI + (error * Ki)
    --debug
	setN(RPMIOut, RPMI)
    --Limit I to prevent integral windup
	RPMI = math.min(KiMaxC,math.max(KiMinC, RPMI))

	D = Kd * rpmDiff
	RPMP0 = rpmProcVar
	if ClutchMode then
		setN(SpdControlOutput, P + RPMI + D)
	end

    --section to control speed with clutch
    --The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external.
	Kp = getN(ClchKpChannel)
	Ki = getN(ClchKiChannel)
	Kd = getN(ClchKdChannel)
	KiMaxC = getN(ClchKiMaxChannel)
	KiMinC = getN(ClchKiMinChannel)

	stall = false
	if (rpmProcVar - 120) < rpmDiff then
		stall = true
	end

	error = spdSetPoint - spdProcVar

    P = error * Kp
    --debug
	setN(ClchPOut, P)

	if stall then
		ClchI = ClchI - error * Ki
	else
		ClchI = ClchI + error * Ki
	end
	setN(ClchIOut, ClchI)

	ClchI = math.min(KiMaxC,math.max(KiMinC, ClchI))
	setN(ClchIboundedOut, ClchI)

	D = Kd * (ClchP0 - spdProcVar)
	ClchP0 = spdProcVar
	setN(ClchDOut, D)
	
	D2 = Kd * -1/math.abs(rpmProcVar - 120)

	if stall then
		clchOut = 0
	else
		clchOut = P + ClchI + D + D2
	end

	if Idle then
		setN(ClchControlOutput, 0)
	elseif ClutchMode then
		setN(ClchControlOutput, clchOut)
	else
		setN(ClchControlOutput, 1)
	end

    --section to control speed with throttle
    --The gains are pulled in each tick. External ciruit logic either uses constants, or live variables from external.
	Kp = getN(SpdKpChannel)
	Ki = getN(SpdKiChannel)
	Kd = getN(SpdKdChannel)
	KiMaxC = getN(SpdKiMaxChannel)
	KiMinC = getN(SpdKiMinChannel)

	error = spdSetPoint - spdProcVar

	P = error * Kp
	setN(SpdPOut, P)

	SpdI = SpdI + error * Ki
	setN(SpdIOut, SpdI)

	SpdI = math.min(KiMaxC,math.max(KiMinC, SpdI))
	setN(SpdIboundedOut, SpdI)

	D = Kd * (SpdP0 - spdProcVar)
	SpdP0 = spdProcVar
	setN(SpdDOut, D)

	out = P + SpdI + D
	if not ClutchMode then
		setN(SpdControlOutput, out)
	end

	if ClutchMode and (clchOut >= 1.0) then
		ClutchMode = false
	end

	if not ClutchMode and (rpmProcVar <= 125) then
		ClutchMode = true
	end
end