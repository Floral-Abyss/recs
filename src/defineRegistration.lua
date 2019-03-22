local function interval(intervalLength, systemsArray)
    return {
        type = "interval",
        interval = intervalLength,
        systemClasses = systemsArray,
    }
end

local function event(eventObject, systemsArray)
    return {
        type = "event",
        event = eventObject,
        systemClasses = systemsArray,
    }
end

return {
    interval = interval,
    event = event,
}