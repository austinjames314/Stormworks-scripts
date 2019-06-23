--[[Modified from Daffles' Door Controller]]

--Declare 'Constants'
Open = 1
Closed = 0

--Input Channels
DoorButtonChannel = 1
DoorTimeChannel = 2

--'Global' variables
SleepTimer = 0
ButtonPressed = false

--State variables
DoorState = Closed

function onTick()
    -- Read inputs
    button = input.getBool(DoorButtonChannel)

    -- If the button is pressed for the first tick since it was last pressed, then flip the state
    -- Also record that the button is currently pressed, so it can be ignored until it's been released and then pressed again.
    if button then
        if not ButtonPressed then
            -- Change the ButtonPressed flag so that this block cannot be entered again until the button is first released.
            ButtonPressed = true
            
            -- Change the door state to open.
            DoorState = Open
            SleepTimer = 0
        end
    else
        -- When the button is released, reset the ButtonPressed flag.
        ButtonPressed = false
    end
    
    -- If the door state is 'open' then run the timer and close it when appropriate, resetting the timer when closing the door.
    if DoorState == Open then
        SleepTimer = SleepTimer + 1
        output.setBool(1, true)
        
        -- when time is up, close the door.
        if SleepTimer >= input.getNumber(DoorTimeChannel) then
            output.setBool(1, false)
            DoorState = Closed
        end
    end
end