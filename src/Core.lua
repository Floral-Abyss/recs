--[[

    A RECS Core is the root of a RECS setup. It contains systems, entities, and
    component registrations, and is responsible for managing all of these.

    Many Core methods operate on the concept of a "component identifier", which
    can be two different things, for ease of use. A component identifier is
    either a component class itself or the name of one.

]]

local HttpService = game:GetService("HttpService")

local EventStepper = require(script.Parent.EventStepper)
local TimeStepper = require(script.Parent.TimeStepper)
local createSignal = require(script.Parent.createSignal)

local errorMessages = {
    invalidIdentifier = "%q, a %s, is not a valid identifier for a component class",
    componentNotRegistered = "The component %q is not registered in this Core",
    componentClassAlreadyRegistered = "The component class %q is already registered in this Core",
    singletonAlreadyAdded = "A singleton component for class %q is already added to this Core",
    singletonNotPresent = "The singleton component for class %q does not exist in this Core",
    systemNotRegistered = "The system %q is not registered in this Core",
    systemClassAlreadyRegistered = "The system class %q is already registered in this Core",
    unknownStepperType = "Unknown stepper type %q. This is a RECS bug; please report it",
}

--[[

    Resolves a class name from a "component identifier", which may be either a
    class name or a component definition. Cores use class names to index
    components internally.

]]
local function resolveComponentByIdentifier(componentIdentifier)
    if typeof(componentIdentifier) == "string" then
        return componentIdentifier
    elseif typeof(componentIdentifier) == "table" then
        -- Assume it's a component class for efficiency / zoomies
        return componentIdentifier.name
    else
        error(errorMessages.invalidIdentifier:format(
            tostring(componentIdentifier),
            typeof(componentIdentifier)),
        3)
    end
end

local Core = {}
Core.__index = Core

function Core.new()
    local self = setmetatable({
        -- All component instances in the core. Structure:
        -- [componentClassName] = {
        --     [entityId] = componentInstance,
        -- }
        _components = {},
        -- A map of component class names to component class definitions.
        _componentClasses = {},
        -- A map of singleton component class names to singleton component instances.
        -- Singleton components are instances of regular component classes that
        -- are not attached to an entity.
        _singletons = {},
        -- A map of system class names to system instances.
        _systems = {},
        -- An array of all the steppers in the system.
        _steppers = {},
    }, Core)

    return self
end

--[[

    Registers a component class with the core. This method will throw if a
    component class with the same name has already been registered.

]]
function Core:registerComponent(componentClass)
    if self._componentClasses[componentClass.name] ~= nil then
        error(errorMessages.componentClassAlreadyRegistered:format(
            componentClass.name
        ), 2)
    end

    self._componentClasses[componentClass.name] = componentClass
    self._components[componentClass.name] = {}
end

--[[

    Creates a new entity and returns an identifier for the entity that can be
    used in calls to other Core methods.

    Do not rely upon any details of the return type. The only guarantee RECS
    makes about the return value of this function is that it is serializable
    as-is.

]]
function Core:createEntity()
    -- The core is using a hash map for storing component records.
    -- HttpService::GenerateGUID may be too slow for use, and can be replaced
    -- later if need be.
    return HttpService:GenerateGUID(true)
end

--[[

    Given an entity ID, destroys the entity, removing all components from it.
    This method will do nothing if the entity ID is invalid, was not part of
    this core, or was destroyed already.

]]
function Core:destroyEntity(entityId)
    -- TODO: Tell systems the components are being destroyed to let them clean up stuff?
    for componentClassName, componentInstances in pairs(self._components) do
        componentInstances[entityId] = nil
    end
end

--[[

    Given an entity ID and a component identifier, returns the component
    attached to the entity, or nil.

    Throws if the identified component class isn't registered in the core.

]]
function Core:getComponent(entityId, componentIdentifier)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)
    local componentInstances = self._components[componentIdentifier]

    if componentInstances ~= nil then
        return componentInstances[entityId]
    else
        error(errorMessages.componentNotRegistered:format(componentIdentifier), 2)
    end
end

--[[

    Given an entity ID and a component identifier, returns a boolean indicating
    whether the entity has an instance of the component attached to it.

    Throws if the identified component class isn't registered in the core.

]]
function Core:hasComponent(entityId, componentIdentifier)
    -- We could implement this in terms of getComponent but then the stack level
    -- for getComponent's error message would be wrong - it would point at this
    -- component, not the caller of hasComponent. Thus, hasComponent is built
    -- from the ground up here.
    local componentInstances = self._components[componentIdentifier]

    if componentInstances ~= nil then
        return componentInstances[entityId] ~= nil
    else
        error(errorMessages.componentNotRegistered:format(componentIdentifier), 2)
    end
end

--[[

    Given an entity ID and a component identifier, adds a new instance of the
    component to the entity. Returns a boolean that is true if the component
    was added, and false if it already existed on the entity, followed by the
    added component.

    Throws if the identified component class isn't registered in the core.

]]
function Core:addComponent(entityId, componentIdentifier)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)
    local componentClass = self._componentClasses[componentIdentifier]

    if componentClass ~= nil then
        local componentInstances = self._components[componentIdentifier]
        local componentInstance = componentInstances[entityId]

        if componentInstance ~= nil then
            -- Don't re-create the component or overwrite what's already there!
            return false, componentInstance
        else
            componentInstance = componentClass._create()
            componentInstances[entityId] = componentInstance
        end

        return true, componentInstance
    else
        error(errorMessages.componentNotRegistered:format(componentIdentifier), 2)
    end
end

--[[

    Given an entity ID and a component identifier, removes the component
    instance from the entity. Returns true plus the removed component if there
    was a component instance attached to the entity, or false if there wasn't.

    Throws if the identified component class isn't registered in the core.

]]
function Core:removeComponent(entityId, componentIdentifier)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)
    local componentInstances = self._components[componentIdentifier]

    if componentInstances ~= nil then
        local component = componentInstances[entityId]
        componentInstances[entityId] = nil
        -- We don't have to branch on component ~= nil because of this!
        return component ~= nil, component
    else
        error(errorMessages.componentNotRegistered:format(componentIdentifier), 2)
    end
end

--[[

    Adds a singleton component to the core. Returns the component instance.

    Throws if the singleton component already exists on the core.

]]
function Core:addSingleton(componentClass)
    local singletonIdentifier = componentClass.name

    if self._singletons[singletonIdentifier] == nil then
        local singleton = componentClass._create()
        self._singletons[singletonIdentifier] = singleton
        return singleton
    else
        error(errorMessages.singletonAlreadyAdded:format(singletonIdentifier), 2)
    end
end

--[[

    Given a component identifier, returns the singleton component attached to
    this core.

    Throws if the singleton doesn't exist on the core.

]]
function Core:getSingleton(componentIdentifier)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)

    local singleton = self._singletons[componentIdentifier]

    if singleton == nil then
        error(errorMessages.singletonNotPresent:format(componentIdentifier), 2)
    end

    return singleton
end

--[[

    Registers a system class with the Core and creates an internal instance of
    the system. The system's init method will not be called until Core::start is
    called.

    Throws if the system class has already been registered in the Core.

]]
function Core:registerSystem(systemClass)
    if self._systems[systemClass.name] ~= nil then
        error(errorMessages.systemClassAlreadyRegistered:format(systemClass.name), 2)
    end

    local system = systemClass._create(self)
    self._systems[systemClass.name] = system
end

--[[

    Given a table of system classes, registers all of them with the Core.

    Throws if one of the system classes has already been registered in the Core.

]]
function Core:registerSystems(systems)
    -- Deliberately use pairs to accept either a map or an array.
    for _, systemClass in pairs(systems) do
        self:registerSystem(systemClass)
    end
end

--[[

    Given an instance, traverses its children. If a child is a ModuleScript, it
    is required and the return result is passed to registerSystem. If a child is
    a Folder, its children are inspected using the same process. Other classes
    are ignored.

    Throws if one of the system classes has already been registered in the Core.

]]
function Core:registerSystemsInInstance(rootInstance)
    for _, child in ipairs(rootInstance:GetChildren()) do
        if child:IsA("ModuleScript") then
            self:registerSystem(require(child))
        elseif child:IsA("Folder") then
            self:registerSystemsInInstance(child)
        end
    end
end

--[[

    Registers a stepper definition in the Core. The same stepper definition may
    be registered multiple times, though this is likely not intentional. This
    method must be called after all systems being stepped have been registered.

    Throws if one of the systems being stepped has not been registered yet.

    Throws if given an unknown stepper type. This error indicates a RECS bug.

]]
function Core:registerStepper(stepperDefinition)
    local systemInstances = {}

    for _, class in ipairs(stepperDefinition.systemClasses) do
        local instance = self._systems[class.name]

        if instance == nil then
            error(errorMessages.systemNotRegistered:format(class.name), 2)
        end

        table.insert(systemInstances, instance)
    end

    if stepperDefinition.type == "event" then
        table.insert(self._steppers, EventStepper.new(stepperDefinition.event, systemInstances))
    elseif stepperDefinition.type == "interval" then
        table.insert(self._steppers, TimeStepper.new(stepperDefinition.interval, systemInstances))
    else
        error(errorMessages.unknownStepperType:format(stepperDefinition.type), 2)
    end
end

--[[

    Given a table of stepper definitions, registers all of them in the Core.

    Throws if one of the systems being stepped has not been registered yet.

    Throws if given an unknown stepper type. This error indicates a RECS bug.

]]
function Core:registerSteppers(steppers)
    -- Deliberately use pairs to accept either a map or an array.
    for _, stepperDefinition in pairs(steppers) do
        self:registerStepper(stepperDefinition)
    end
end

--[[

    Starts the Core, calling init on all systems that possess the method and
    starting all steppers. After calling this method, the Core and all
    functionality represented by it will begin running your game's code.

    The order in which systems are initialized and steppers are started is not
    to be relied upon. Structure your code such that you do not depend on
    ordering in this case.

]]
function Core:start()
    -- TODO: Give plugins the ability to do work before systems init.
    -- Initialize all systems first.
    for _, system in ipairs(self._systems) do
        -- Systems are not required to declare an init method, and a no-op one
        -- is not provided in the default System class.
        if system.init ~= nil then
            system:init()
        end
    end

    -- Now start all steppers.
    for _, stepper in ipairs(self._steppers) do
        stepper:start()
    end
end

return Core
