local createSignal = require(script.Parent.Parent.createSignal)

local componentEventPlugin = {}

function componentEventPlugin:componentRegistered(core, componentClass)
    function componentClass.updateProperty(componentInstance, key, newValue)
        local oldValue = componentInstance[key]

        componentInstance[key] = newValue

        print("componentInstance.raisePropertyChanged")

        componentInstance.raisePropertyChanged(key, newValue, oldValue)
    end
end

function componentEventPlugin:componentAdded(core, entityId, componentInstance)
    local propertyChangedSignal, raisePropertyChanged = createSignal()

    componentInstance.changed = propertyChangedSignal
    componentInstance.raisePropertyChanged = raisePropertyChanged
end

return componentEventPlugin
