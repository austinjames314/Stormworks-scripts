-- Declare Constants
Lock = true
Unlock = false

--enumerated state 'constants'
Closed = 0
Raising = 1
SlidingOpen = 2
Open = 3
SlidingClosed = 4
Closing = 5

--state constants for the cargo lift
Down = 0
Lifting = 1
Up = 2
Lowering = 3

--Output Channels
LockChannelOut = 1
LifterChannelOut = 2
SliderChannelOut = 3
PlatformChannelOut = 4

-- Global Variables
--Input Channels
HatchToggleChannelIn = 1
PlatformToggleChannelIn = 2

-- State variables
HatchState = 0
LiftState = 0

HatchButtonPressed = false
LiftButtonPressed = false

HatchTimeCounter = 0
LiftTimeCounter = 0

function onTick()
	-- Read the inputs
	hatchButton = input.getBool(HatchToggleChannelIn)
	platformButton = input.getBool(PlatformToggleChannelIn)
	output.setNumber(5, LiftState)
	output.setNumber(6, LiftTimeCounter)

	-- Sets the state of the Hatch when the button is pressed.
	-- If the button is pressed for the first tick since it was last pressed, then flip the state
	-- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
	if hatchButton and LiftState == Down then
		if not HatchButtonPressed then
			HatchButtonPressed = true
			--if you're here this is the first tick that the button's been pressed, this time around. Time to start the hatch moving.
			if HatchState == Closed then
				HatchState = Raising

				output.setNumber(LifterChannelOut, 1)
				output.setBool(LockChannelOut, Unlock)

				HatchTimeCounter = 0
			elseif HatchState == Open then
				HatchState = SlidingClosed

				output.setNumber(SliderChannelOut, -1)

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

		if HatchTimeCounter >= 150 then
			HatchState = Open

			output.setNumber(SliderChannelOut, 1)
		end
	elseif HatchState == SlidingClosed then
	
		HatchTimeCounter = HatchTimeCounter + 1

		if HatchTimeCounter >= 150 then
			HatchState = Closing

			output.setNumber(SliderChannelOut, 0)
			output.setNumber(LifterChannelOut, -1)
			output.setBool(LockChannelOut, Lock)

			HatchTimeCounter = 0
		end
	elseif HatchState == Closing then
	
		HatchTimeCounter = HatchTimeCounter + 1

		if HatchTimeCounter >= 30 then
			HatchState = Closed

			output.setNumber(LifterChannelOut, 0)
		end
	end

	-- Sets the state of the Cargo lift when the button is pressed.
	-- If the button is pressed for the first tick since it was last pressed, then flip the state
	-- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
	if platformButton and HatchState == Open then
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