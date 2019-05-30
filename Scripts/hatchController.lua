-- Declare Constants

--1 = open or opening. 0 = closed or closing
State = 0

LockChannel = 1
HingeChannel = 2
HatchOpen = 1
HatchClosed = 0
Locked = 1
Unlocked = 0

-- Tick function that will be executed every logic tick
function onTick()

	--what are we supposed to be doing again? Set the current state depending on which buttons are pressed.
	--If both buttons are pressed, or neither, then leave it in the current state. Otherwise change it.
	open = input.getNumber(1)
	close = input.getNumber(2)
	
	if open ~= close then
		if open == 1 then
			State = 1
		else if close == 1 then
			State = 0
		end
	end

	-- If State is 0, then close the hatch
	if State == 0 then
		output.setNumber(HingeChannel, HatchClosed)
		output.setNumber(LockChannel, Locked)

	end else
		-- we're opening so unlock and open
		output.setNumber(LockChannel, Unlocked)
		output.setNumber(HingeChannel, HatchOpen)
	end
end