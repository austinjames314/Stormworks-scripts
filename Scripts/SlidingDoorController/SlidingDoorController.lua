-- Declare Constants
DoorOpen = -1
DoorClose = 1
DoorStop = 0

--enumerated state 'constants'
Closed = 0
Opening = 1
Open = 2
Closing = 3

--Output Channels
DoorChannelOut = 1

-- Global Variables
--Input Channels
DoorToggleChannelIn = 1
DoorDelayChannelIn = 2

-- State variables
DoorState = Closing

DoorButtonPressed = false

DoorTimeCounter = 0

function onTick()
	-- Read the inputs
    doorButton = input.getBool(DoorToggleChannelIn)
    doorDelay = input.getNumber(DoorDelayChannelIn) * 60

	-- Sets the state of the Gear when the button is pressed.
	-- If the button is pressed for the first tick since it was last pressed, then flip the state
	-- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
	if doorButton then
        if not DoorButtonPressed then
        
            DoorButtonPressed = true
        
			--if you're here this is the first tick that the button's been pressed, this time around. Time to start the hatch moving.
			if DoorState == Open then
				DoorState = Closing

				output.setNumber(DoorChannelOut, DoorClose)

				DoorTimeCounter = 0
			elseif DoorState == Closed then
				DoorState = Opening

				output.setNumber(DoorChannelOut, DoorOpen)

				DoorTimeCounter = 0
			end
		end
	else
		--Reset button pressed variable whenever it's not being pressed
        DoorButtonPressed = false
    
	end

	-- Code to run for each hatch state
	if DoorState == Opening then

		DoorTimeCounter = DoorTimeCounter + 1

		if DoorTimeCounter >= doorDelay then
			DoorState = Open

			output.setNumber(DoorChannelOut, DoorStop)
			
			DoorTimeCounter = 0
		end
	elseif DoorState == Closing then
	
		DoorTimeCounter = DoorTimeCounter + 1

		if DoorTimeCounter >= doorDelay then
			DoorState = Closed

            output.setNumber(DoorChannelOut, DoorStop)
            
			DoorTimeCounter = 0
		end
	end
end