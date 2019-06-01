-- Declare Constants

--Input channels
SpeedChannel = 1
FuelGuageDeltaChannel = 2
--output channels
ConsumptionChannel = 1
EfficiencyChannel = 2

NumSamples = 300

--global variable initialisation
fuelSum = 0
speedSum = 0

Lp100km = 0

function onTick()
	currentFuelDelta = input.getNumber(FuelGuageDeltaChannel)
	
	fuelSum = fuelSum - (fuelSum / NumSamples)
	fuelSum = fuelSum + currentFuelDelta

	fuelPerSec = fuelSum / (NumSamples / -60)
	fuelPerHour = fuelPerSec * 3600
	
	output.setNumber(ConsumptionChannel, fuelPerHour)
	
	
	currentSpeed = input.getNumber(SpeedChannel)
	speedSum = speedSum - (speedSum / NumSamples)
	speedSum = speedSum + currentSpeed
	
	avgSpeed = speedSum / NumSamples
	
	if avgSpeed ~= 0 then
		Lp100km = (100 * fuelPerHour) / avgSpeed
	end
	
	output.setNumber(EfficiencyChannel, Lp100km)
end