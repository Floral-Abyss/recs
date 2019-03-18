local System = {}
System.__index = System

-- luacheck: ignore self
function System:extend(systemName)
    local systemClass = {
        className = systemName,
    }

    function systemClass._create(core)
        local systemInstance = setmetatable({
            core = core,
            className = systemName,
        }, {
            __index = systemClass
        })

        return systemInstance
    end

    setmetatable(systemClass, System)
    return systemClass
end

function System:step()
end

return System