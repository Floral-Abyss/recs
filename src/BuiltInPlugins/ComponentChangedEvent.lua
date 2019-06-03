local createSignal = require(script.Parent.Parent.createSignal)

local componentChangedEventPlugin = {}

function componentChangedEventPlugin:componentRegistered(core, componentClass)
    function componentClass.updateProperty(componentInstance, key, newValue)
        local oldValue = componentInstance[key]

        componentInstance[key] = newValue

        componentInstance.raisePropertyChanged(key, newValue, oldValue)
    end
end

function componentChangedEventPlugin:componentAdded(core, entityId, componentInstance)
    local propertyChangedSignal, raisePropertyChanged = createSignal()

    componentInstance.changed = propertyChangedSignal
    componentInstance.raisePropertyChanged = raisePropertyChanged
end

return componentChangedEventPlugin
