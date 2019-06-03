--Declare Constants

ClutchRPM = 200
IdleRPM = 130

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

ClchI = 0
ClchP0 = 0

ClutchMode = true
Idle = true

clchOut = 0

function onTick()
	
	spdSetPoint = input.getNumber(SpdSetPointChannel)
	
	--If the target speed is zero, then go to idle mode
	if spdSetPoint == 0 then
		Idle = true
		ClutchMode = true
	else
		Idle = false
	end
	
	if ClutchMode then
		--In this mode, RPM is held constant, and the clutch is varied to control speed.
		if Idle then
			rpmSetPoint = IdleRPM
		else 
			rpmSetPoint = ClutchRPM
		end
		
		--PID to control RPM
		rpmProcVar = input.getNumber(RPMProcVarChannel)

		Kp = input.getNumber(RPMKpChannel)
		Ki = input.getNumber(RPMKiChannel)
		Kd = input.getNumber(RPMKdChannel)
		KiMinC = input.getNumber(RPMKiMaxChannel)
		KiMaxC = input.getNumber(RPMKiMinChannel)

		error = rpmSetPoint - rpmProcVar
	
		P = error * Kp
		--debug
		output.setNumber(RPMPOut, P)
	
		RPMI = RPMI + error * Ki
		--debug
		output.setNumber(RPMIOut, I)

		--Limit I to prevent integral windup
		I = math.min(RPMKiMaxC,math.max(RPMKiMinC, I))
		--debug
		output.setNumber(RPMIboundedOut, I)
	
		D = Kd * (RPMP0 - rpmProcVar)
		--To calculate D next tick
		RPMP0 = rpmProcVar
		--debug
		output.setNumber(RPMDOut, D)

		out = P + I + D
		--Output result, NOTE: this is to control throttle so it needs to use same output channel as for Speed.
		output.setNumber(SpdControlOutput, out)
		
		if Idle then
			--fully disengage clutch
			output.setNumber(ClchControlOutput, 0)
		else
			--PID to control speed with clutch
			clchOut = 0
		end
	else
		--In this mode, the clutch has fully engaged. We're just using throttle to control speed.
		
		--PID to control throttle/speed
	end
	
	--If the clutch has been fully engaged, leave clutchmode
	--Need to add in the clutch output var here!!!
	if ClutchMode and (clchOut >= 1.0) then
		ClutchMode = false
	end
	
	--If not in clutchmode and the RPM drops to 125 (stalls at 120), then pop the clutch
	if ~ClutchMode and (rpmProcVar <= 125) then
		ClutchMode = true
	end
end