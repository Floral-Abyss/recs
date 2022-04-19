--!strict

local TypeDefinitions = require(script.Parent.Parent.TypeDefinitions)

type ComponentClasses = {TypeDefinitions.ComponentClass}

local CollectionService = game:GetService("CollectionService")

local function createCollectionServicePlugin()
    local collectionServicePlugin = {}
    local componentClasses: ComponentClasses = {}

    function collectionServicePlugin:componentRegistered(_, componentClass)
        table.insert(componentClasses, componentClass)
    end

    function collectionServicePlugin:beforeSystemStart(core)
        for _, componentClass: TypeDefinitions.ComponentClass in ipairs(componentClasses) do
            local name: string = componentClass.className

            for _, instance: Instance in ipairs(CollectionService:GetTagged(name)) do
                core:addComponent(instance, name)
            end

            local instanceAddedSignal = CollectionService:GetInstanceAddedSignal(name)
            instanceAddedSignal:Connect(function(instance: Instance)
                core:addComponent(instance, name)
            end)

            local instanceRemovedSignal = CollectionService:GetInstanceRemovedSignal(name)
            instanceRemovedSignal:Connect(function(instance: Instance)
                core:removeComponent(instance, name)
            end)
        end
    end

    return collectionServicePlugin
end

return createCollectionServicePlugin
