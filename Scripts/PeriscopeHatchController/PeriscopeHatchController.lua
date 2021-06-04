-- Declare Constants
Lock = true
Unlock = false

--enumerated state 'constants'
Closed = 0
Raising = 1
SlidingOpen = 2
Deploying = 3
Open = 4
Retracting = 5
SlidingClosed = 6
Closing = 7

--Output Channels
LockChannelOut = 1
LifterChannelOut = 2
SliderChannelOut = 3
PeriscopeChannelOut = 4
PanControlChannelOut = 5
CameraOverrideChannelOut = 6

-- Global Variables
--Input Channels
HatchToggleChannelIn = 1
PanControlChannelIn = 2

-- Initialised State variables
HatchState = Open

HatchButtonPressed = false

HatchTimeCounter = 0

Initialised = false

function onTick()
	if not initialised then
		HatchTimeCounter = HatchTimeCounter + 1
		
		if HatchTimeCounter > 30 then
			HatchState = Retracting

			output.setNumber(PeriscopeChannelOut, -1)
			CameraOverride = true

			HatchTimeCounter = 0
		
			initialised = true
		end
	end
	
	-- Read the inputs
	hatchButton = input.getBool(HatchToggleChannelIn)
	panRequest = input.getNumber(PanControlChannelIn)

	-- Sets the state of the Hatch when the button is pressed.
	-- If the button is pressed for the first tick since it was last pressed, then flip the state
	-- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
	if hatchButton then
		if not HatchButtonPressed then
			HatchButtonPressed = true
			--if you're here this is the first tick that the button's been pressed, this time around. Time to start the hatch moving.
			if HatchState == Closed then
				HatchState = Raising

				output.setNumber(LifterChannelOut, 1)
				output.setBool(LockChannelOut, Unlock)

				HatchTimeCounter = 0
			elseif HatchState == Open then
				HatchState = Retracting

				output.setNumber(PeriscopeChannelOut, -1)
				CameraOverride = true

				HatchTimeCounter = 0
			end
		end
	else
		--Reset button pressed variable whenever it's not being pressed
		HatchButtonPressed = false
	end

	-- Code to run for each hatch state
	if HatchState == Raising then

		HatchTimeCounter = HatchTimeCounter + 1

		if HatchTimeCounter >= 30 then
			HatchState = SlidingOpen

			output.setNumber(LifterChannelOut, 0)
			output.setNumber(SliderChannelOut, 1)
			
			HatchTimeCounter = 0
		end
	elseif HatchState == SlidingOpen then
	
		HatchTimeCounter = HatchTimeCounter + 1

		if HatchTimeCounter >= 60 then
			HatchState = Deploying
			
			output.setNumber(SliderChannelOut, 0)
			output.setNumber(PeriscopeChannelOut, 1)
			
			HatchTimeCounter = 0
		end
	elseif HatchState == Deploying then
	
		HatchTimeCounter = HatchTimeCounter + 1

		if HatchTimeCounter >= 240 then
			HatchState = Open
			
			output.setNumber(PeriscopeChannelOut, 0)
			CameraOverride = false
			
			HatchTimeCounter = 0
		end
	elseif HatchState == Retracting then
	
		HatchTimeCounter = HatchTimeCounter + 1

		if HatchTimeCounter >= 240 then
			HatchState = SlidingClosed
			
			output.setNumber(PeriscopeChannelOut, 0)
			output.setNumber(SliderChannelOut, -1)
			output.setBool(LockChannelOut, Lock)
			
			HatchTimeCounter = 0
		end
	elseif HatchState == SlidingClosed then
	
		HatchTimeCounter = HatchTimeCounter + 1

		if HatchTimeCounter >= 60 then
			HatchState = Closing

			output.setNumber(SliderChannelOut, 0)
			output.setNumber(LifterChannelOut, -1)

			HatchTimeCounter = 0
		end
	elseif HatchState == Closing then
	
		HatchTimeCounter = HatchTimeCounter + 1

		if HatchTimeCounter >= 30 then
			HatchState = Closed

			output.setNumber(LifterChannelOut, 0)
		end
	end
	
	output.setBool(CameraOverrideChannelOut, CameraOverride)
	output.setNumber(PanControlChannelOut, panRequest)
end