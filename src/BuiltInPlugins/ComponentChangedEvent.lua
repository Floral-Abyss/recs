--!strict

local TypeDefinitions = require(script.Parent.Parent.TypeDefinitions)
local createSignal = require(script.Parent.Parent.createSignal)

local componentChangedEventPlugin = {}

local function addUpdateMethod(core, component)
    function component.updateProperty(componentInstance, key, newValue)
        local oldValue = componentInstance[key]

        if oldValue == newValue then
            return
        end

        componentInstance[key] = newValue

        componentInstance.raisePropertyChanged(key, newValue, oldValue)
    end
end

function componentChangedEventPlugin:componentRegistered(core, componentClass)
    addUpdateMethod(core, componentClass)
end

function componentChangedEventPlugin:componentAdded(core, entityId: TypeDefinitions.EntityId, componentInstance)
    local propertyChangedSignal, raisePropertyChanged = createSignal()

    componentInstance.changed = propertyChangedSignal
    componentInstance.raisePropertyChanged = raisePropertyChanged
end

function componentChangedEventPlugin:singletonAdded(core, componentInstance)
    addUpdateMethod(core, componentInstance)

    local propertyChangedSignal, raisePropertyChanged = createSignal()

    componentInstance.changed = propertyChangedSignal
    componentInstance.raisePropertyChanged = raisePropertyChanged
end

return componentChangedEventPlugin
