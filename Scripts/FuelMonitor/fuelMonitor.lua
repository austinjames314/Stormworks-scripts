-- Declare Constants

--Input channels
SpeedChannel = 1
FuelGuageDeltaChannel = 2
--output channels
ConsumptionChannel = 1
EfficiencyChannel = 2

NumSamples = 1200

--global variable initialisation
fuelArray = {}
fuelArrIndex = 0
speedArray = {}
speedArrIndex = 0

for i = 0, NumSamples - 1 do
	fuelArray[i] = 0
	speedArray[i] = 0
end

Lp100km = 0

function onTick()
	currentFuelDelta = input.getNumber(FuelGuageDeltaChannel)
	fuelArray[fuelArrIndex] = currentFuelDelta
	fuelArrIndex = math.fmod((fuelArrIndex + 1), NumSamples)
	
	arraySum = 0
	for i = 0, NumSamples - 1 do
		arraySum = arraySum + fuelArray[i]
	end
	fuelPerSec = arraySum / (NumSamples / -60)
	fuelPerHour = fuelPerSec * 3600
	
	output.setNumber(ConsumptionChannel, fuelPerHour)
	
	
	currentSpeed = input.getNumber(SpeedChannel)
	speedArray[speedArrIndex] = currentSpeed
	speedArrIndex = math.fmod((speedArrIndex + 1), NumSamples)
	
	arraySum = 0
	for i = 0, NumSamples - 1 do
		arraySum = arraySum + speedArray[i]
	end
	avgSpeed = arraySum / NumSamples
	
	if avgSpeed ~= 0 then
		Lp100km = (100 * fuelPerHour) / avgSpeed
	end
	
	output.setNumber(EfficiencyChannel, Lp100km)
end