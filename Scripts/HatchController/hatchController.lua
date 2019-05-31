-- Declare Constants

-- 1 = open or opening. 0 = closed or closing
State = 0
-- State variable to track if the button was already pressed
ButtonPressed = false

LockChannel = 1
HingeChannel = 2
HatchOpen = 1
HatchClosed = 0
Locked = true
Unlocked = false

function onTick()
	-- If the button is pressed for the first tick since it was last pressed, then flip the state
	-- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
	button = input.getBool(1)
	
	if button then
		if not ButtonPressed then
			
			ButtonPressed = true
			
			if State == 0 then
				State = 1
			elseif State == 1 then
				State = 0
			end
		end
	else
		ButtonPressed = false
	end

	-- If State is 0, then close the hatch
	if State == 0 then
		output.setNumber(HingeChannel, HatchClosed)
		output.setBool(LockChannel, Locked)
	else
		-- we're opening so unlock and open
		output.setNumber(HingeChannel, HatchOpen)
		output.setBool(LockChannel, Unlocked)
	end
end