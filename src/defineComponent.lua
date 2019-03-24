--[[

defineComponent is a utility function for defining a component.

]]

local createCleaner = require(script.Parent.createCleaner)

local errorFormats = {
    nonStringName = "tagName (1) must be a string, is a %s",
    nonFunctionDefaultProps = "defaultProps (2) must be a function or nil, is a %s",
    nonTableDefaultPropsReturn = "The defaultProps generator for the %s component must return a function, but returned a %s",
    nonModuleScriptPropOverride = "Component property override module %s must be a ModuleScript, is a %s",
    nonFunctionRootPropOverride = "Component property override module %s must return a function, returned a %s",
    nonTableComponentPropOverride = "Component property override entry %s from module %s must be a table, but is a %s",
}

local function defineComponent(tagName, defaultProps)
    assert(
        typeof(tagName) == "string",
        errorFormats.nonStringName:format(typeof(tagName)))

    assert(
        defaultProps == nil or typeof(defaultProps) == "function",
        errorFormats.nonFunctionDefaultProps:format(typeof(defaultProps)))

    local definition = {}
    definition.tagName = tagName

    function definition._create(instance)
        local component = {}
        if defaultProps then
            component = defaultProps()
            assert(
                type(component) == "table",
                errorFormats.nonTableDefaultPropsReturn:format(tagName, type(component)))
        end
        component.tagName = tagName
        component.instance = instance
        component.maid = createCleaner()

        local componentPropsModule = instance:FindFirstChild("ComponentProps")
        if componentPropsModule ~= nil then
            local fullName = componentPropsModule:GetFullName()
            assert(
                componentPropsModule:IsA("ModuleScript"),
                errorFormats.nonModuleScriptPropOverride:format(fullName, componentPropsModule.ClassName))

            local componentProps = require(componentPropsModule)
            assert(
                typeof(componentProps) == "function",
                errorFormats.nonFunctionRootPropOverride:format(fullName, typeof(componentProps)))

            local componentPropsOverride = componentProps()
            local specificComponentProps = componentPropsOverride[tagName]
            assert(
                specificComponentProps == nil or typeof(specificComponentProps) == "table",
                errorFormats.nonTableComponentPropOverride:format(tagName, fullName, typeof(specificComponentProps)))

            if specificComponentProps ~= nil then
                for overrideKey, overrideValue in pairs(specificComponentProps) do
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