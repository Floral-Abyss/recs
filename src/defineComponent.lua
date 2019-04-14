--[[

defineComponent is a utility function for defining a component.

]]

local errorFormats = {
    nonStringName = "name (1) must be a string, is a %s",
    nonFunctionDefaultProps = "defaultPropsGenerator (2) must be a function or nil, is a %s",
    nonTableDefaultPropsReturn =
        "The defaultProps generator for the %s component must return a table, but it returned a %s",
}

local function defineComponent(name, defaultPropsGenerator)
    assert(
        typeof(name) == "string",
        errorFormats.nonStringName:format(typeof(name)))

    assert(
        defaultPropsGenerator == nil or typeof(defaultPropsGenerator) == "function",
        errorFormats.nonFunctionDefaultProps:format(typeof(defaultPropsGenerator)))

    local definition = {}
    definition.name = name
    definition.defaultProps = defaultPropsGenerator

    function definition._create()
        local component = {}
        if definition.defaultProps then
            component = definition.defaultProps()

            if typeof(component) ~= "table" then
                error(errorFormats.nonTableDefaultPropsReturn:format(name, typeof(component)))
            end
        end

        component.name = name
        return component
    end

    return definition
end

return defineComponent