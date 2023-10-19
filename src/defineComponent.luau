--!strict

--[[

    defineComponent is a utility function for defining a component. Given an
    argument table, it creates a component class.

    The argument table should have the following keys:
    - name (string)
    - generator (() -> table)
    - entityFilter (entity -> bool)

    The name must be a string; there are no restrictions on its value otherwise.
    However, duplicate names are not recommended, as Cores require that all
    components registered in them have unique names.

    The generator function must return a table. The exact contents of the table
    are up to the user; RECS imposes no restrictions on it. However, RECS does
    provide the className field that will refer to the class name of the
    component.

    The entity filter function must take an entity and return a boolean
    indicating whether the component can be applied to that entity. This can be
    used to ensure that a component is only attached to entities that are Roblox
    instances, or specific Roblox instances, or only abstract entities.

    If the entity filter function is not present in the args table, the
    component can be attached to any entity.

]]

type ComponentArgs = {
    name: string,
    generator: (...any) -> any,
    entityFilter: (EntityId) -> boolean,
}

local TypeDefinitions = require(script.Parent.TypeDefinitions)
local t = require(script.Parent.Parent.t)

local isComponentArgs = t.strictInterface({
    name = t.string,
    generator = t.callback,
    entityFilter = t.optional(t.callback),
})

local errorFormats = {
    nonTableDefaultPropsReturn = "The defaultProps generator for the %s component must return a table, but it returned a %s",
}

local function defineComponent(args: ComponentArgs): TypeDefinitions.ComponentClass
    assert(isComponentArgs(args))

    local definition = {}
    definition.className = args.name
    definition.entityFilter = args.entityFilter
    definition.__index = definition

    local generator = args.generator

    function definition._create(props): any
        local component = generator(props)

        if typeof(component) ~= "table" then
            error(errorFormats.nonTableDefaultPropsReturn:format(args.name, typeof(component)))
        end

        setmetatable(component, definition)
        return component
    end

    return definition
end

return defineComponent
