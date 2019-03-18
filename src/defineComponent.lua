--[[

todo lol

]]

function defineComponent(tagName, defaultProps)
    assert(typeof(tagName) == "string", "tagName (1) must be a string, is a " .. typeof(tagName))

    local definition = {}
    definition.tagName = tagName
    definition.defaultProps = defaultProps or {}

    function definition:_create(instance)
        local component = {}

        for key, value in pairs(definition.defaultProps) do
            component[key] = value
        end

        component.tagName = tagName
        component.instance = instance

        if definition.init then
            definition.init(component, instance)
        end

        return component
    end

    return definition
end

return defineComponent