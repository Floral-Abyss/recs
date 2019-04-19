--[[

    defineRegistration provides constructors for stepper definitions, which are
    instructions that Cores can use to create a stepper object to step systems
    in a defined order.

    The stepper definitions contain the kind of stepper to be created, any
    parameters that the stepper needs, and an array of system classes. When the
    Core creates a stepper, it maps the system classes to system instances that
    were created when the system classes were registered with the Core.

    Each stepper definition must have two fields:
    - type (string): The type of stepper that this definition refers to. Current
      valid values are "interval" and "event".
    - systemClasses (array): An array of system classes that the stepper will
      step when it is created.

    Any other fields are determined by the value of the type field.

    Cores will throw an error if they don't understand the value of the type
    field. Since stepper definitions are created using functions defined in this
    file, this shouldn't be encountered in normal use cases.

]]

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