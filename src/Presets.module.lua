return {
	WheelRadius = 1.72,
	WheelFriction = 11.5,
	SuspensionMaxLength = 1.1,
	SuspensionDamping = 4,
	SuspensionStiffness = 550,
	CFrameCorrection = CFrame.Angles(0, math.rad(90), 0),
	DriveWheels = {"W3", "W4"},
	SteeringY = math.rad(0.55),
	MaxSteerY = math.rad(25),
	MaxForce = 350,
	ForwardForce = 6.5,
	BackwardForce = 5.5,
	RelativeWheelPositions = {
		W1 = CFrame.new(3.35, 0.25, -6.50),
		W2 = CFrame.new(-3.39, 0.25, -6.50),
		W3 = CFrame.new(-3.39, 0.40, 5.74),
		W4 = CFrame.new(3.35, 0.40, 5.74)
	}
}
