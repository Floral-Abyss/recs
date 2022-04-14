--!strict

--[[
    Type Definitions
]]

type AllowedFunctionValue = (...any) -> ...any
type AllowedTableValue =
    { destroy: AllowedFunctionValue } |
    { Destroy: AllowedFunctionValue } |
    { disconnect: AllowedFunctionValue } |
    { Disconnect: AllowedFunctionValue } |
    { clean: AllowedFunctionValue }
type AllowedValues = AllowedFunctionValue | AllowedTableValue | Instance | RBXScriptConnection

--[[
    Implementation
]]

local errorMessages = {
    cannotDestroy = "Cleaner cannot destroy %q of type %s (key %q)",
    overridingKey = "Cannot override built-in method %s",
}

local cleanerMethods = {}

local function hasFunction(table: { [any]: any }, key: string): boolean
    return table[key] ~= nil and typeof(table[key]) == "function"
end

local function canDestroy(value: any): boolean
    if typeof(value) == "function" then
        return true
    elseif typeof(value) == "Instance" then
        return true
    elseif typeof(value) == "RBXScriptConnection" then
        return true
    elseif typeof(value) == "table"
        and getmetatable(value) ~= nil
        and getmetatable(value).__index == cleanerMethods then

        return true
    elseif typeof(value) == "table" then
        return hasFunction(value, "destroy")
            or hasFunction(value, "Destroy")
            or hasFunction(value, "disconnect")
            or hasFunction(value, "Disconnect")
    end

    return false
end

cleanerMethods.give = function(self, key: string, value: AllowedValues)
    assert(cleanerMethods[key] == nil, errorMessages.overridingKey:format(tostring(key)))

    if value ~= nil then
        assert(canDestroy(value), errorMessages.cannotDestroy:format(tostring(value), typeof(value), tostring(key)))
    end

    rawset(self, key, value)
end

cleanerMethods.clean = function(self)
    for key, value in pairs(self) do
        if typeof(value) == "function" then
            value()
        elseif typeof(value) == "Instance" then
            value:Destroy()
        elseif typeof(value) == "RBXScriptConnection" then
            value:Disconnect()
        elseif typeof(value) == "table"
            and getmetatable(value) ~= nil
            and getmetatable(value).__index == cleanerMethods then

            value:clean()
        elseif typeof(value) == "table" then
            if value.destroy ~= nil then
                value.destroy()
            elseif value.Destroy ~= nil then
                value.Destroy()
            elseif value.disconnect ~= nil then
                value.disconnect()
            elseif value.Disconnect ~= nil then
                value.Disconnect()
            end
        end

        rawset(self, key, nil)
    end
end

local function createCleaner()
    local cleaner = {}

    setmetatable(cleaner, {
        __index = cleanerMethods,
        __newindex = cleanerMethods.give,
    })

    return cleaner
end

return createCleaner
