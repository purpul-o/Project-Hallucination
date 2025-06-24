-- Variables
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local debris = game:GetService("Debris")

local vehicles = replicatedStorage.Vehicles

local vehicle = {}
vehicle.__index = vehicle

-- Functions
function vehicle.new(modelName: string, preset)
	assert(typeof(modelName) == "string", "Invalid type for argument 'modelName'")
	
	local model: Model? = vehicles:FindFirstChild(modelName)
	if model then
		model = model:Clone()
		model.Parent = workspace
		
		local instance = setmetatable({
			MetaConnections = {},
			SuspensionLengthMemory = {W1 = 0.5, W2 = 0.5, W3 = 0.5, W4 = 0.5},
			SteerDirection = CFrame.Angles(0, 0, 0),
			Throttle = 0,
			Model = model,
			
			CFrameCorrection = preset.CFrameCorrection,
			DriveWheels = preset.DriveWheels,
			WheelRadius = preset.WheelRadius,
			WheelFriction = preset.WheelFriction,
			MaxSteerY = preset.MaxSteerY,
			SteeringY = preset.SteeringY,
			MaxForce = preset.MaxForce,
			ForwardForce = preset.ForwardForce,
			BackwardForce = preset.BackwardForce,
			SuspensionMaxLength = preset.SuspensionMaxLength,
			SuspensionDamping = preset.SuspensionDamping,
			SuspensionStiffness = preset.SuspensionStiffness,
			RelativeWheelPositions = preset.RelativeWheelPositions
		}, vehicle)

		return instance
	else
		error("Model does not exist")
	end
end

function vehicle:Handle(delta: number, visual: boolean)
	assert(typeof(delta) == "number", "Invalid type for argument 'delta'")
	local primaryPart: BasePart = self.Model.PrimaryPart
	local primaryPartCFrame = primaryPart.CFrame * self.CFrameCorrection
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {self.Model}
	
	local isForward = userInputService:IsKeyDown(Enum.KeyCode.Up)
	local isLeft = userInputService:IsKeyDown(Enum.KeyCode.Left)
	local isRight = userInputService:IsKeyDown(Enum.KeyCode.Right)
	local isBackward = userInputService:IsKeyDown(Enum.KeyCode.Down)
	local isJump = userInputService:IsKeyDown(Enum.KeyCode.Space)
	
	if isRight and self.SteerDirection.Y < self.MaxSteerY then
		self.SteerDirection *= CFrame.Angles(0, self.SteeringY, 0)
	elseif isLeft and self.SteerDirection.Y > -self.MaxSteerY then
		self.SteerDirection *= CFrame.Angles(0, -self.SteeringY, 0)
	else
		self.SteerDirection = self.SteerDirection:Lerp(CFrame.Angles(0, 0, 0), 0.9)
	end
		
	for wheelName, relativeCFrame in pairs(self.RelativeWheelPositions) do
		local origin = primaryPartCFrame:ToWorldSpace(relativeCFrame).Position
		local direction = -primaryPartCFrame.UpVector * (self.SuspensionMaxLength + self.WheelRadius)

		local raycast = workspace:Raycast(origin, direction, raycastParams)
		if raycast then
			local distance = (origin - raycast.Position).Magnitude

			local suspensionLength = math.clamp(distance - self.WheelRadius, 0, self.SuspensionMaxLength)
			local suspensionCompression = self.SuspensionMaxLength - suspensionLength

			local stiffnessForce = suspensionCompression * self.SuspensionStiffness
			local suspensionVelocity = (self.SuspensionLengthMemory[wheelName] - suspensionLength) / delta

			local dampingForce = suspensionVelocity * self.SuspensionDamping
			
			local direction = raycast.Normal
			local suspensionForce = direction * (stiffnessForce + dampingForce)
						
			local suspensionImpulse = suspensionForce * (delta * 60)

			local wheelDirectionCFrame = CFrame.lookAt(Vector3.zero, primaryPartCFrame.LookVector, primaryPartCFrame.UpVector)

			local velocity = primaryPart:GetVelocityAtPosition(raycast.Position)
			local localVelocity = wheelDirectionCFrame:VectorToObjectSpace(velocity)

			local xForce = primaryPartCFrame.RightVector * -localVelocity.X * self.WheelFriction
			local zForce = primaryPartCFrame.LookVector * localVelocity.Z * (self.WheelFriction / 3)
			local frictionImpulse = (xForce + zForce) * (delta * 60)
			
			if isForward and table.find(self.DriveWheels, wheelName) then
				self.Throttle = math.min(self.Throttle + self.ForwardForce, self.MaxForce)

				local combinedCFrame = primaryPartCFrame * self.SteerDirection

				local lookVector = combinedCFrame.LookVector
				local direction = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

				local impulse = direction * self.Throttle * (delta * 60)
				primaryPart:ApplyImpulseAtPosition(impulse, raycast.Position)
			end
			
			if isBackward and table.find(self.DriveWheels, wheelName) then
				self.Throttle = math.max(self.Throttle - self.BackwardForce, -(self.MaxForce / 2))

				local combinedCFrame = primaryPartCFrame * self.SteerDirection

				local lookVector = combinedCFrame.LookVector
				local direction = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

				local impulse = direction * self.Throttle * (delta * 60)
				primaryPart:ApplyImpulseAtPosition(impulse, raycast.Position)
			end
			
			if isJump then
				suspensionForce = (direction * (stiffnessForce + dampingForce) * 15)
				suspensionImpulse = suspensionForce * (delta * 60)
			end
			
			if not isForward and not isBackward then
				self.Throttle = math.max(self.Throttle - frictionImpulse.Magnitude, 0)
			end
			
			primaryPart:ApplyImpulseAtPosition(suspensionImpulse + frictionImpulse, raycast.Position)
			self.SuspensionLengthMemory[wheelName] = suspensionLength
		else
			self.SuspensionLengthMemory[wheelName] = self.SuspensionMaxLength
		end
		
		if visual then
			local hit = raycast ~= nil
			local color = hit and Color3.new(0,1,0) or Color3.new(1,0,0)
			local endPosition = hit and raycast.Position or (origin + direction)
			self:Line(origin, endPosition, color, delta)

			if hit then
				local distance = (origin - raycast.Position).Magnitude - self.WheelRadius
				self:Cylinder(raycast.Position, distance, delta)
			end
		end
	end
end

function vehicle:Line(startPosition: Vector3, endPosition: Vector3, color: Color3, delta: number)
	local distance = (startPosition - endPosition).Magnitude
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = Vector3.new(0.05, distance, 0.05)
	part.CFrame = CFrame.lookAt(startPosition, endPosition) * CFrame.Angles(math.rad(90), 0, 0)
	part.Parent = self.Model
	
	debris:AddItem(part, delta)
end

function vehicle:Cylinder(bottomPosition: Vector3, height: Vector3, delta: number)
	local cylinder = Instance.new("Part")
	cylinder.Shape = Enum.PartType.Cylinder
	cylinder.Anchored = true
	cylinder.CanCollide = false
	cylinder.Material = Enum.Material.Neon
	cylinder.Color = Color3.new()
	cylinder.Size = Vector3.new(0.05, 0.2, 0.2)
	cylinder.CFrame = CFrame.new(
		bottomPosition,
		bottomPosition + Vector3.new(0, 1, 0)
	) * CFrame.Angles(0, math.rad(90), 0)
	cylinder.Parent = self.Model
	
	debris:AddItem(cylinder, delta)
end

return vehicle
