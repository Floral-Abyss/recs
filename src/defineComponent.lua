--[[

todo lol

]]

local errorFormats = {
    nonStringName = "tagName (1) must be a string, is a %s",
    nonTableDefaultProps = "defaultProps (2) must be a table or nil, is a %s",
    nonModuleScriptPropOverride = "Component property override module %s must be a ModuleScript, is a %s",
    nonTableRootPropOverride = "Component property override module %s must return a table, returned a %s",
    nonTableComponentPropOverride = "Component property override entry %s from module %s must return a table, returned a %s",
    overrideNonexistentKey = "Component property override module %s is trying to override %s.%s, which does not exist in the %s component.",
}

function defineComponent(tagName, defaultProps)
    assert(
        typeof(tagName) == "string",
        errorFormats.nonStringName(typeof(tagName)))
    
    assert(
        defaultProps == nil or typeof(defaultProps) == "table",
        errorFormats.nonTableDefaultProps:format(typeof(defaultProps)))

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

        local componentPropsModule = instance:FindFirstChild("ComponentProps")
        if componentPropsModule ~= nil then
            local fullName = componentPropsModule:GetFullName()
            assert(
                componentPropsModule:IsA("ModuleScript"),
                errorFormats.nonModuleScriptPropOverride:format(fullName, componentPropsModule.ClassName))

            local componentProps = require(componentPropsModule)
            assert(
                typeof(componentProps) == "table",
                errorFormats.nonTableRootPropOverride:format(fullName, typeof(componentProps)))

            local specificComponentProps = componentProps[tagName]
            assert(
                specificComponentProps == nil or typeof(specificComponentProps) == "table",
                errorFormats.nonTableComponentPropOverride:format(tagName, fullName, typeof(specificComponentProps)))

            if specificComponentProps ~= nil then
                for overrideKey, overrideValue in pairs(specificComponentProps) do
                    assert(
                        definition.defaultProps[overrideKey] ~= nil,
                        errorFormats.overrideNonexistentKey:format(fullName, tagName, overrideKey, tagName))
                    
                    component[overrideKey] = overrideValue
                end
            end
        end

        if definition.init then
            definition.init(component, instance)
        end

        return component
    end

    return definition
end

return defineComponent