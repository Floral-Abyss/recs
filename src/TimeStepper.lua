--[[

A time stepper is responsible for stepping systems in a deterministic order at a set interval.

]]

local TimeStepper = {}
TimeStepper.__index = TimeStepper

function TimeStepper.new(interval, systems)
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
