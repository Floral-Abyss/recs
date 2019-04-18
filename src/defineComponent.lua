--[[

    defineComponent is a utility function for defining a component. Given a name
    and a function that returns a table, it creates a component class that can
    be registered with a Core.

    The name must be a string; there are no restrictions on its value otherwise.
    However, duplicate names are not recommended, as Cores require that all
    components registered in them have unique names.

    The creator function must return a table. The exact contents of the table
    are up to the user; RECS imposes no restrictions on it.

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

        return component
    end

    return definition
end

return defineComponent