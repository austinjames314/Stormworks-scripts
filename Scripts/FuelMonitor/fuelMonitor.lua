--Declare Constants

--Input channels
SpeedChannel = 1
FuelGuageDeltaChannel = 2
FuelSmoothingChannel = 3
SpeedSmoothingChannel = 4
SmoothingLimitsChannel = 5

--output channels
ConsumptionChannel = 1
EfficiencyChannel = 2

TicksPerHour = 60*60*60

--global variable initialisation
fuelSt = 0
speedSt = 0
Lp100km = 0

function onTick()
	limit = input.getNumber(SmoothingLimitsChannel)

	currentFuelDelta = input.getNumber(FuelGuageDeltaChannel)
	smooth = input.getNumber(FuelSmoothingChannel)
	
	fuelSt = currentFuelDelta * smooth + (1 - smooth) * fuelSt
	if math.abs(fuelSt) > (limit / TicksPerHour) then
		fuelSt = limit / TicksPerHour
	end
	fuelPerHour = fuelSt * (-TicksPerHour)
	
	output.setNumber(ConsumptionChannel, fuelPerHour)
	
	
	currentSpeed = input.getNumber(SpeedChannel)
	smooth = input.getNumber(SpeedSmoothingChannel)
	
	speedSt = currentSpeed * smooth + (1 - smooth) * speedSt
	if speedSt ~= 0 then
		Lp100km = (100 * fuelPerHour) / speedSt
	end
	
	output.setNumber(EfficiencyChannel, Lp100km)
end