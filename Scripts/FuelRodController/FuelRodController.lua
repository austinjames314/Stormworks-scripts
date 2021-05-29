-- Declare Constants
SlideTime = 180 -- 3 seconds to cycle rods (should only take 2)

--enumerated state 'constants'
Shutdown = 0
Inserting = 1
Running = 2
Extracting = 3

--Output Channels
FuelRodUnlockOut = 1
SliderChannelOut = 2
HoldOpenUnlockOut = 3

--Input Channels
ActivateChannelIn = 1

-- Global Variables
-- State variables
ReactorState = Shutdown
ActivateButtonPressed = false
SliderTimeCounter = 0

function onTick()
	-- Read the inputs
	activateButton = input.getBool(ActivateChannelIn)

	if activateButton then
		-- reactor is set to run
		if ReactorState == Shutdown then
			-- begin startup
			output.setNumber(SliderChannelOut, 1)
			output.setBool(HoldOpenUnlockOut, true)
			ReactorState = Inserting
			SliderTimeCounter = 0
		end
	else
		-- reactor is set to shutdown
		if ReactorState == Running then
			-- begin shutdown
			output.setNumber(SliderChannelOut, -1)
			output.setBool(FuelRodUnlockOut, true)
			ReactorState = Extracting
			SliderTimeCounter = 0
		end
	end

	if ReactorState == Inserting then
		if SliderTimeCounter > SlideTime then
			-- looks like startup is complete
			output.setNumber(SliderChannelOut, 0)
			output.setBool(HoldOpenUnlockOut, false)
			ReactorState = Running
		else
			-- keep going
			SliderTimeCounter = SliderTimeCounter + 1
		end
	end

	if ReactorState == Extracting then
		if SliderTimeCounter > SlideTime then
			-- looks like shutdown is complete
			output.setNumber(SliderChannelOut, 0)
			output.setBool(FuelRodUnlockOut, false)
			ReactorState = Shutdown
		else
			-- keep going
			SliderTimeCounter = SliderTimeCounter + 1
		end
	end
end