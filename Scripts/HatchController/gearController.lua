-- Declare Constants
DoorOpen = 1
DoorClosed = 0
GearUp = 1
GearDown = 0

--enumerated state 'constants'
Retracted = 0
Opening = 1
Lowering = 2
ClosingDown = 3
Deployed = 4
OpeningDown = 5
Raising = 6
Closing = 7

--Output Channels
DoorChannelOut = 1
GearChannelOut = 2

-- Global Variables
--Input Channels
GearToggleChannelIn = 1

-- State variables
GearState = Deployed

GearButtonPressed = false

GearTimeCounter = 0

function onTick()
	-- Read the inputs
	gearButton = input.getBool(GearToggleChannelIn)

	-- Sets the state of the Gear when the button is pressed.
	-- If the button is pressed for the first tick since it was last pressed, then flip the state
	-- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
	if gearButton then
		if not GearButtonPressed then
			GearButtonPressed = true
			--if you're here this is the first tick that the button's been pressed, this time around. Time to start the hatch moving.
			if GearState == Deployed then
				GearState = OpeningDown

				output.setNumber(DoorChannelOut, DoorOpen)

				GearTimeCounter = 0
			elseif GearState == Retracted then
				GearState = Opening

				output.setNumber(DoorChannelOut, DoorOpen)

				GearTimeCounter = 0
			end
		end
	else
		--Reset button pressed variable whenever it's not being pressed
		GearButtonPressed = false
	end

	-- Code to run for each hatch state
	if GearState == Opening then

		GearTimeCounter = GearTimeCounter + 1

		if GearTimeCounter >= 60 then
			GearState = Lowering

			output.setNumber(GearChannelOut, GearDown)
			
			GearTimeCounter = 0
		end
	elseif GearState == Lowering then
	
		GearTimeCounter = GearTimeCounter + 1

		if GearTimeCounter >= 60 then
			GearState = ClosingDown

			output.setNumber(DoorChannelOut, DoorClosed)
		end
	elseif GearState == ClosingDown then
	
		GearTimeCounter = GearTimeCounter + 1

		if GearTimeCounter >= 60 then
			GearState = Deployed

			GearTimeCounter = 0
		end
	elseif GearState == OpeningDown then
	
		GearTimeCounter = GearTimeCounter + 1

		if GearTimeCounter >= 60 then
			GearState = Raising

			output.setNumber(GearChannelOut, GearUp)

			GearTimeCounter = 0
		end
	elseif GearState == Raising then
	
		GearTimeCounter = GearTimeCounter + 1

		if GearTimeCounter >= 60 then
			GearState = Closing

			output.setNumber(DoorChannelOut, DoorClosed)

			GearTimeCounter = 0
		end
	elseif GearState == Closing then
	
		GearTimeCounter = GearTimeCounter + 1

		if GearTimeCounter >= 60 then
			GearState = Retracted

			GearTimeCounter = 0
		end
	end
end