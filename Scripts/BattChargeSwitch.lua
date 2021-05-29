-- Declare Constants
ChargeOn = true
ChargeOff = false

--enumerated state 'constants'
On = 0
Off = 1

--Output Channels
SwitchChannelOut = 1

-- Global Variables
--Input Channels
BatteryChannelIn = 1
OnLevelChannelIn = 2
OffLevelChannelIn = 3

-- State variables
SwitchState = Off

function onTick()
	-- Read the inputs
    battLevel = input.getNumber(BatteryChannelIn)
    offLevel = input.getNumber(OffLevelChannelIn)
    onLevel = input.getNumber(OnLevelChannelIn)

	-- Switches the state on and off when BattLevel crosses upper and lower bounds
	if SwitchState == Off then
        if battLevel > onLevel then
        
            SwitchState = On

            output.setBool(SwitchChannelOut, ChargeOn)
		end
	else
        if battLevel < offLevel then
        
            SwitchState = Off

            output.setBool(SwitchChannelOut, ChargeOff)
		end
	end
end