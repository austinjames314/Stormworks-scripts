-- Declare Constants
TopSpeed = 9 -- m/s
SteeringScale = 0.8 -- how much to reduce steering by at topspeed

--Output Channels
LeftTrackChannelOut = 3
RightTrackChannelOut = 4

--Input Channels
ForwardAxisChannelIn = 1
SteeringAxisChannelIn = 2
SpeedSensorChannelIn = 3

function onTick()
    fwdAxis = input.getNumber(ForwardAxisChannelIn)
    strAxis = input.getNumber(SteeringAxisChannelIn)
    speed = input.getNumber(SpeedSensorChannelIn)
    
	steeringScaled = strAxis * (1 - math.min(SteeringScale, (speed/TopSpeed)*SteeringScale))

    left = fwdAxis + steeringScaled
    right = fwdAxis - steeringScaled
    
    output.setNumber(LeftTrackChannelOut, left)
    output.setNumber(RightTrackChannelOut, right)
end