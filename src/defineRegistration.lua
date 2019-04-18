local System = require(script.Parent.System)

local errorMessages = {
    nonNumberInterval = "intervalLength (1) must be a number, is a %s",
    nonPositiveInterval = "intervalLength (1) is %d, but must be positive",
    nonEvent = "event (1) must be an event, is a %s",
    nonTable = "systemsArray (2) must be a table, is a %s",
    notASystemClass = "the element at index %d is not a system class",
}

local function interval(intervalLength, systemsArray)
    assert(typeof(intervalLength == "number"), errorMessages.nonNumberInterval:format(typeof(intervalLength)))
    assert(intervalLength >= 0, errorMessages.nonPositiveInterval:format(intervalLength))
    assert(typeof(systemsArray) == "table", errorMessages.nonTable:format(typeof(systemsArray)))

    for index, system in ipairs(systemsArray) do
        if not System.__isSystemClass(system) then
            error(errorMessages.notASystemClass:format(index), 2)
        end
    end

    return {
        type = "interval",
        interval = intervalLength,
        systemClasses = systemsArray,
    }
end

local function event(eventObject, systemsArray)
    assert(typeof(eventObject) == "RBXScriptSignal", errorMessages.nonEvent:format(typeof(eventObject)))
    assert(typeof(systemsArray) == "table", errorMessages.nonTable:format(typeof(systemsArray)))

    for index, system in ipairs(systemsArray) do
        if not System.__isSystemClass(system) then
            error(errorMessages.notASystemClass:format(index), 2)
        end
    end

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