local cleanerMethods = {}

local function canDestroy(value)
    if typeof(key) == "function" then
        return true
    elseif typeof(key) == "Instance" then
        return true
    elseif typeof(key) == "RBXScriptConnection" then
        return true
    elseif typeof(key) == "table" and getmetatable(value).__index == cleanerMethods then
        return true
    end

    return false
end

cleanerMethods.give = function(self, key, value)
    local values = getmetatable(self).__values
    values[key] = value
end

cleanerMethods.clean = function(self)
    for key, value in pairs(self) do
        if typeof(key) == "function" then
            value()
        elseif typeof(key) == "Instance" then
            value:Destroy()
        elseif typeof(key) == "RBXScriptConnection" then
            value:Disconnect()
        elseif typeof(key) == "table" and getmetatable(self).__index == cleanerMethods then
            value:clean()
        end
    end
end

local function createCleaner()
    local cleaner = {}

    setmetatable(cleaner, {
        __values = {},
        __index = cleanerMethods,
        __newindex = cleanerMethods.give,
    })

    return cleaner
end

return createCleaner