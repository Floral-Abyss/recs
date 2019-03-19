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
        interests = {},
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

    function systemClass.interest(args)
        assert(typeof(args) == "table", "args must be a table")
        assert(typeof(args.interest) == "number" and (args.interest == System.InterestType.Added or args.interest == System.InterestType.Removed), "args.interest must be System.InterestType")
        assert(typeof(args.component == "table"), "args.component must be a ComponentDefinition")
        assert(typeof(args.callback == "function", "args.callback must be a function"))
        
        table.insert(systemClass.interests, {
            kind = args.interest,
            component = args.component,
            callback = args.callback,
        })
    end

    setmetatable(systemClass, System)
    return systemClass
end

function System:step()
    error("override System:step() to provide functionality for your system", 0)
end

return System