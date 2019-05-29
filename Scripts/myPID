KpC = property.getNumber('Kp')
KiC = property.getNumber('Ki')
KiMaxC = property.getNumber('KiMax')
KiMinC = property.getNumber('KiMin')
KdC = property.getNumber('Kd')
lower = property.getNumber('Upper Lower Bound')
upper = property.getNumber('Upper Output Bound')
I = 0
P0 = 0

function onTick()
	--in normal use these are the only two inputs used.
	setPoint = input.getNumber(1)
	procVar = input.getNumber(2)
	
	--if the channel 3 bool is true, then take the PID congfig values from the composite input in real time (good for tuning the PID controller). Otherwise we just need to adjust the gains 
	if input.getBool(3) then
		Kp = input.getNumber(2) / setPoint
		Ki = input.getNumber(3) / setPoint
		Kd = input.getNumber(4) / setPoint
		KiMinC = input.getNumber(5)
		KiMaxC = input.getNumber(6)
		lower = input.getNumber(7)
		upper = input.getNumber(8)
	else
		Kp = KpC / setPoint
		Ki = KiC / setPoint
		Kd = KdC / setPoint
	end
	
	error = setPoint - procVar
	
	P = error * Kp
	--debug
	output.setNumber(2, P)
	
	I = I + error * Ki

	--debug
	output.setNumber(3, I)

	--Limit I to prevent integral windup
		I = math.min(KiMaxC,math.max(KiMinC, I))
	
	--debug
	output.setNumber(4, I)
	
	D = Kd * (P0 - procVar)
	--To calculate D next tick
	P0 = procVar
	--debug
	output.setNumber(5, D)
	
	out = P + I + D
	--debug
	output.setNumber(6, out)
	
	--Keep the output inside the bounds specified in the property fields
	out = math.min(upper,math.max(lower, out))
	
	--Output result
	output.setNumber(1, out)
end