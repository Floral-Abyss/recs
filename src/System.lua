local createCleaner = require(script.Parent.createCleaner)

local System = {}
System.__index = System
System._kind = System

-- luacheck: ignore self
function System:extend(systemName)
    local systemClass = setmetatable({
        name = systemName,
    }, System)

    function systemClass._create(core)
        local systemInstance = setmetatable({
            core = core,
            maid = createCleaner(),
        }, {
            __index = systemClass
        })

        return systemInstance
    end

    setmetatable(systemClass, System)
    return systemClass
end

function System:step()
    error("override System:step() to provide functionality for your system", 0)
end

return System