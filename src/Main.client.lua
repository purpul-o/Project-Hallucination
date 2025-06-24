-- Constants
local FIXED_TIME_STEP = 1 / 60

-- Variables
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local modules = replicatedStorage.Modules

local utility = modules.Utility
local presets = modules.Presets

local vehicle = require(utility.Vehicle)
local preset = require(presets.Toyota)

local accumulated = 0

local instance = vehicle.new("Toyota", preset)

-- Functions
table.insert(instance.MetaConnections, runService.PostSimulation:Connect(function(deltaTimeSim: number)
	accumulated += deltaTimeSim

	while accumulated >= FIXED_TIME_STEP do
		accumulated -= FIXED_TIME_STEP
		instance:Handle(FIXED_TIME_STEP, true)
	end
end))
