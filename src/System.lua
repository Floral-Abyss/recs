local createCleaner = require(script.Parent.createCleaner)

local System = {}

System.InterestType = {
    Added = 1,
    Removed = 2,
}

-- luacheck: ignore self
function System:extend(systemName)
    local systemClass = setmetatable({
        className = systemName,
    }, {
        __index = System,
    })

    function systemClass._create(core)
        local systemInstance = setmetatable({
            core = core,
            className = systemName,
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