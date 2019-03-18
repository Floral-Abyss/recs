local function interval(interval)
    return function(systemsArray)
        return {
            type = "interval",
            interval = interval,
            systemClasses = systemsArray,
        }
    end
end

local function event(event)
    return function(systemsArray)
        return {
            type = "event",
            event = event,
            systemClasses = systemsArray,
        }
    end
end

return {
    interval = interval,
    event = event,
}