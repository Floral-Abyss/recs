local CollectionService = game:GetService("CollectionService")

local function createCollectionServicePlugin()
    local collectionServicePlugin = {}
    local components = {}

    function collectionServicePlugin:componentRegistered(_, componentClass)
        components[#components + 1] = componentClass
    end

    function collectionServicePlugin:beforeSystemStart(core)
        for _, componentClass in ipairs(components) do
            local name = componentClass.className

            for _, instance in ipairs(CollectionService:GetTagged(name)) do
                core:addComponent(instance, name)
            end

            local instanceAddedSignal = CollectionService:GetInstanceAddedSignal(name)
            instanceAddedSignal:Connect(function(instance)
                core:addComponent(instance, name)
            end)

            local instanceRemovedSignal = CollectionService:GetInstanceRemovedSignal(name)
            instanceRemovedSignal:Connect(function(instance)
                core:removeComponent(instance, name)
            end)
        end
    end

    return collectionServicePlugin
end

return createCollectionServicePlugin
