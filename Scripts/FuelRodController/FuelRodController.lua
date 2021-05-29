-- Declare Constants
--Lock = true
--Unlock = false

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

	-- Sets the state of the Rods when the button is pressed.
	-- If the button is pressed for the first tick since it was last pressed, then flip the state
	-- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
	if activateButton and ReactorState == Shutdown then
		if not ActivateButtonPressed then
			ActivateButtonPressed = true
			--if you're here this is the first tick that the button's been pressed, this time around. Time to start the rods moving.
			if ReactorState == Shutdown then
				ReactorState = Inserting

				output.setNumber(SliderChannelOut, 1)
				output.setBool(HoldOpenUnlockOut, true)

				SliderTimeCounter = 0
			elseif ReactorState == Running then
				ReactorState = Extracting

				output.setNumber(SliderChannelOut, -1)
				output.setBool(FuelRodUnlockOut, true)

				SliderTimeCounter = 0
			end
		end
	else
		--Reset button pressed variable whenever it's not being pressed
		ActivateButtonPressed = false
	end

	-- Code to run for each hatch state
	if ReactorState == Raising then

		SliderTimeCounter = SliderTimeCounter + 1

		if SliderTimeCounter >= 30 then
			ReactorState = SlidingOpen

			output.setNumber(LifterChannelOut, 0)
			output.setNumber(SliderChannelOut, 1)
			
			SliderTimeCounter = 0
		end
	elseif ReactorState == SlidingOpen then
	
		SliderTimeCounter = SliderTimeCounter + 1

		if SliderTimeCounter >= 150 then
			ReactorState = Open

			output.setNumber(SliderChannelOut, 1)
		end
	elseif ReactorState == SlidingClosed then
	
		SliderTimeCounter = SliderTimeCounter + 1

		if SliderTimeCounter >= 150 then
			ReactorState = Closing

			output.setNumber(SliderChannelOut, 0)
			output.setNumber(LifterChannelOut, -1)
			output.setBool(LockChannelOut, Lock)

			SliderTimeCounter = 0
		end
	elseif ReactorState == Closing then
	
		SliderTimeCounter = SliderTimeCounter + 1

		if SliderTimeCounter >= 30 then
			ReactorState = Closed

			output.setNumber(LifterChannelOut, 0)
		end
	end

	-- Sets the state of the Cargo lift when the button is pressed.
	-- If the button is pressed for the first tick since it was last pressed, then flip the state
	-- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
	if platformButton and ReactorState == Open then
		if not LiftButtonPressed then
			LiftButtonPressed = true
			--if you're here this is the first tick that the button's been pressed, this time around. Time to start the hatch moving.
			if LiftState == Down then
				LiftState = Lifting

				output.setNumber(PlatformChannelOut, 1)

				LiftTimeCounter = 0
			elseif LiftState == Up then
				LiftState = Lowering

				output.setNumber(PlatformChannelOut, -1)

				LiftTimeCounter = 0
			end
		end
	else
		--Reset button pressed variable whenever it's not being pressed
		LiftButtonPressed = false
	end

	-- Code to run for each hatch state
	if LiftState == Lifting then

		LiftTimeCounter = LiftTimeCounter + 1

		if LiftTimeCounter >= 80 then
			LiftState = Up

			output.setNumber(PlatformChannelOut, 0)
		end
	elseif LiftState == Lowering then
		
		LiftTimeCounter = LiftTimeCounter + 1
	
		if LiftTimeCounter >= 80 then
			LiftState = Down
	
			output.setNumber(PlatformChannelOut, 0)
		end
	end
end