--!strict

--[[

A time stepper is responsible for stepping systems in a deterministic order at a set interval.

]]

local TypeDefinitions = require(script.Parent.TypeDefinitions)

local TimeStepper = {}
TimeStepper.__index = TimeStepper

function TimeStepper.new(interval: number, systems: TypeDefinitions.Systems)
    local self = setmetatable({
        _systems = systems,
        _interval = interval,
    }, TimeStepper)

    return self
end

function TimeStepper:start()
    coroutine.resume(coroutine.create(function()
        while true do
            local timeStep, _ = wait(self._interval)
            for _, system in ipairs(self._systems) do
                system:step(timeStep)
            end
        end
    end))
end

return TimeStepper
