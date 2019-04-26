--[[

    defineComponent is a utility function for defining a component. Given an
    argument table, it creates a component class.

    The argument table should have the following keys:
    - name (string)
    - generator (() -> table)

    The name must be a string; there are no restrictions on its value otherwise.
    However, duplicate names are not recommended, as Cores require that all
    components registered in them have unique names.

    The generator function must return a table. The exact contents of the table
    are up to the user; RECS imposes no restrictions on it. However, RECS does
    provide the className field that will refer to the class name of the
    component.

]]

local t = require(script.Parent.Parent.t)

local isComponentArgs = t.strictInterface({
    name = t.string,
    generator = t.callback,
})

local errorFormats = {
    nonTableDefaultPropsReturn =
        "The defaultProps generator for the %s component must return a table, but it returned a %s",
}

local function defineComponent(args)
    assert(isComponentArgs(args))

    local definition = {}
    definition.className = args.name
    definition.__index = definition

    local generator = args.generator

    function definition._create()
        local component = generator()

        if typeof(component) ~= "table" then
            error(errorFormats.nonTableDefaultPropsReturn:format(args.name, typeof(component)))
        end

        setmetatable(component, definition)
        return component
    end

    return definition
end

return defineComponent