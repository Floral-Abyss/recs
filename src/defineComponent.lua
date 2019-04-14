--[[

defineComponent is a utility function for defining a component.

]]

local errorFormats = {
    nonStringName = "name (1) must be a string, is a %s",
    nonFunctionDefaultProps = "defaultPropsGenerator (2) must be a function, is a %s",
    nonTableDefaultPropsReturn =
        "The defaultProps generator for the %s component must return a table, but it returned a %s",
}

local function defineComponent(name, defaultPropsGenerator)
    assert(
        typeof(name) == "string",
        errorFormats.nonStringName:format(typeof(name)))

    assert(
        typeof(defaultPropsGenerator) == "function",
        errorFormats.nonFunctionDefaultProps:format(typeof(defaultPropsGenerator)))

    local definition = {}
    definition.name = name

    function definition._create()
        local component = defaultPropsGenerator()

        if typeof(component) ~= "table" then
            error(errorFormats.nonTableDefaultPropsReturn:format(name, typeof(component)))
        end

        component.name = name
        return component
    end

    return definition
end

return defineComponent