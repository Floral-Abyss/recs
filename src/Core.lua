--[[

    A RECS Core is the root of a RECS setup. It contains systems, entities, and
    component registrations, and is responsible for managing all of these.

    Many Core methods operate on the concept of a "component identifier", which
    can be two different things, for ease of use. A component identifier is
    either a component class itself or the name of one.

    Cores have a notion of plugins, which allow running code during some steps
    of the Core that you wouldn't otherwise be able to. Plugins allow you to
    bypass some of the separation of concerns that RECS normally encourages.
    When taking advantage of this, you should be very careful - the structure
    that RECS encourages is there for a reason, and you should think carefully
    about whether you _need_ to bypass it.

    Plugins are specified in the Core constructor as an array. A plugin must
    be a table with a set of methods. Currently, the following plugin methods
    are supported by the Core:

    - coreInit(Core): Called when the Core initializes.
    - componentRegistered(Core, componentClass): Called when a component class
      is registered in the core.
    - componentAdded(Core, entityId, componentInstance, props): Called when a component
      instance is added to an entity. Called before the addition signal for that
      component has been fired.
    - componentRemoving(Core, entityId, componentInstance): Called when a
      component instance is being removed from an entity, i.e. during entity
      destruction or when removing a component. Called after the removal signal
      for that component has been fired.
    - singletonAdded(Core, singletonInstance): Called when a singleton component
      is added to the Core.
    - beforeSystemStart(Core): Called during Core::start, before systems' init
      methods have been called.
    - afterSystemStart(Core): Called during Core::start, after systems' init
      methods have been called but before steppers start.
    - afterStepperStart(Core): Called during Core::start, after steppers start.

    All plugin methods are optional.

]]

local HttpService = game:GetService("HttpService")

local EventStepper = require(script.Parent.EventStepper)
local TimeStepper = require(script.Parent.TimeStepper)
local createSignal = require(script.Parent.createSignal)

local errorMessages = {
    invalidIdentifier = "%q, a %s, is not a valid identifier for a component class",
    componentNotRegistered = "The component %q is not registered in this Core",
    componentClassAlreadyRegistered = "The component class %q is already registered in this Core",
    componentNotApplicable = "The component %q cannot be added to the entity %q of type %s",
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
        return componentIdentifier.className
    else
        error(errorMessages.invalidIdentifier:format(
            tostring(componentIdentifier),
            typeof(componentIdentifier)),
        3)
    end
end

local Core = {}
Core.__index = Core

--[[

    Given an optional array of plugins, creates a new RECS Core. A Core is,
    functionally, the entire ECS.

]]
function Core.new(plugins)
    local self = setmetatable({
        -- All component instances in the Core. Structure:
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
        -- An array of all the steppers in the Core.
        _steppers = {},
        -- A map of component class names to component added signals.
        _componentAddedSignals = {},
        -- A map of component class names to component removing signals.
        _componentRemovingSignals = {},
        -- A map of signals to raise functions.
        _signalRaisers = {},
        -- An array of all the plugins that the Core is using.
        _plugins = plugins or {},
    }, Core)

    self:__callPluginMethod("coreInit")

    return self
end

--[[

    An internal method that calls a method on all plugins, if present, in the
    order specified, with given arguments. Used to make plugins more ergonomic.

    Plugin methods are called with the Core as the first argument.

]]
function Core:__callPluginMethod(methodName, ...)
    for _, plugin in ipairs(self._plugins) do
        if plugin[methodName] ~= nil then
            plugin[methodName](plugin, self, ...)
        end
    end
end

--[[

    Tests if a component can be added to an entity.

    Throws if this is not the case.

]]
function Core:__checkIfCanAddComponentToEntity(componentClass, entityId)
    if componentClass.entityFilter ~= nil and not componentClass.entityFilter(entityId) then
        error(
            errorMessages.componentNotApplicable:format(
                componentClass.className,
                tostring(entityId),
                typeof(entityId)),
        3)
    end
end

--[[

    Registers a component class with the Core. This method will throw if a
    component class with the same name has already been registered.

]]
function Core:registerComponent(componentClass)
    local name = componentClass.className

    if self._componentClasses[name] ~= nil then
        error(errorMessages.componentClassAlreadyRegistered:format(
            name
        ), 2)
    end

    self._componentClasses[name] = componentClass
    self._components[name] = {}

    local addedSignal, raiseAdded = createSignal()
    local removingSignal, raiseRemoved = createSignal()

    self._componentAddedSignals[name] = addedSignal
    self._componentRemovingSignals[name] = removingSignal
    self._signalRaisers[addedSignal] = raiseAdded
    self._signalRaisers[removingSignal] = raiseRemoved

    self:__callPluginMethod("componentRegistered", componentClass)
end

--[[

    Given an instance, traverses its children. If a child is a ModuleScript, it
    is required and the return result is passed to registerComponent. If a child
    is a Folder, its children are inspected using the same process. Other
    instance classes are ignored.

    Throws if one of the component classes has already been registered in the Core.

]]
function Core:registerComponentsInInstance(rootInstance)
    for _, child in ipairs(rootInstance:GetChildren()) do
        if child:IsA("ModuleScript") then
            self:registerComponent(require(child))
        elseif child:IsA("Folder") then
            self:registerComponentsInInstance(child)
        end
    end
end

--[[

    Given a component class name, gets the class that was registered in the Core.

    Throws if the component class has not been registered.

]]
function Core:getComponentClass(className)
    local componentClass = self._componentClasses[className]

    if componentClass == nil then
        error(errorMessages.componentNotRegistered:format(className), 2)
    end

    return componentClass
end

--[[

    Returns all components classes registered in the Core.
    The table is a map of name -> class.

    Do not mutate the returned value of this function.

]]
function Core:getRegisteredComponents()
    return self._componentClasses
end

--[[

    Creates a new entity and returns an identifier for the entity that can be
    used in calls to other Core methods.

    Do not rely upon any details of the return type. The only guarantee RECS
    makes about the return value of this function is that it is serializable
    as-is.

]]
function Core:createEntity()
    -- The Core is using a hash map for storing component records.
    -- HttpService::GenerateGUID may be too slow for use, and can be replaced
    -- later if need be.
    return HttpService:GenerateGUID(true)
end

--[[

    Given an entity ID, destroys the entity, removing all components from it.
    This method will do nothing if the entity ID is invalid, was not part of
    this Core, or was destroyed already.

]]
function Core:destroyEntity(entityId)
    -- Call plugin methods and fire removal signals before disturbing the
    -- actual component.
    for componentClassName, componentInstances in pairs(self._components) do
        local componentInstance = componentInstances[entityId]

        if componentInstance ~= nil then
            local removingSignal = self._componentRemovingSignals[componentClassName]
            local raise = self._signalRaisers[removingSignal]
            raise(entityId, componentInstance)

            self:__callPluginMethod("componentRemoving", entityId, componentInstance)
        end
    end

    for componentClassName, componentInstances in pairs(self._components) do
        componentInstances[entityId] = nil
    end
end

--[[

    Given an entity ID and a component identifier, returns the component
    attached to the entity, or nil.

    Throws if the identified component class isn't registered in the Core.

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

    Throws if the identified component class isn't registered in the Core.

]]
function Core:hasComponent(entityId, componentIdentifier)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)

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

    Throws if the identified component class isn't registered in the Core.

]]
function Core:addComponent(entityId, componentIdentifier, props)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)
    local componentClass = self._componentClasses[componentIdentifier]

    if componentClass ~= nil then
        self:__checkIfCanAddComponentToEntity(componentClass, entityId)

        local componentInstances = self._components[componentIdentifier]
        local componentInstance = componentInstances[entityId]

        if componentInstance ~= nil then
            -- Don't re-create the component or overwrite what's already there!
            return false, componentInstance
        else
            componentInstance = componentClass._create(props)
            componentInstances[entityId] = componentInstance

            self:__callPluginMethod("componentAdded", entityId, componentInstance, props)

            local signal = self._componentAddedSignals[componentIdentifier]
            self._signalRaisers[signal](entityId, componentInstance)
        end

        return true, componentInstance
    else
        error(errorMessages.componentNotRegistered:format(componentIdentifier), 2)
    end
end

--[[

    Given an entity ID and a tuple of component identifiers, adds all the
    components to the entity. Returns nothing, unlike addComponent.
    batchAddComponents will add all components to an entity before firing
    any added signals or invoking plugins' componentAdded callbacks.

    Throws if any of the identified component classes aren't registered in the Core.

]]
function Core:batchAddComponents(entityId, ...)
    local createdInstances = {}
    local identifierCount = select("#", ...)

    for i = 1, identifierCount do
        local rawIdentifier = select(i, ...)
        local convertedIdentifier = resolveComponentByIdentifier(rawIdentifier)
        local componentClass = self._componentClasses[convertedIdentifier]

        if componentClass == nil then
            error(errorMessages.componentNotRegistered:format(convertedIdentifier), 2)
        end

        self:__checkIfCanAddComponentToEntity(componentClass, entityId)

        local componentInstances = self._components[convertedIdentifier]

        -- It's possible that you could call batchAddComponents when a component
        -- already exists on the entity, so we should avoid leaking existing
        -- components if they exist.
        if componentInstances[entityId] == nil then
            local componentInstance = componentClass._create()
            createdInstances[convertedIdentifier] = componentInstance
            componentInstances[entityId] = componentInstance
        end
    end

    for identifier, componentInstance in pairs(createdInstances) do
        self:__callPluginMethod("componentAdded", entityId, componentInstance)

        local addedSignal = self._componentAddedSignals[identifier]
        self._signalRaisers[addedSignal](entityId, componentInstance)
    end
end

--[[

    Given an entity ID and a component identifier, removes the component
    instance from the entity. Returns true plus the removed component if there
    was a component instance attached to the entity, or false if there wasn't.

    Throws if the identified component class isn't registered in the Core.

]]
function Core:removeComponent(entityId, componentIdentifier)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)
    local componentInstances = self._components[componentIdentifier]

    if componentInstances ~= nil then
        local componentInstance = componentInstances[entityId]

        if componentInstance == nil then
            return false
        end

        local signal = self._componentRemovingSignals[componentIdentifier]
        self._signalRaisers[signal](entityId, componentInstance)

        self:__callPluginMethod("componentRemoving", entityId, componentInstance)

        componentInstances[entityId] = nil
        return true, componentInstance
    else
        error(errorMessages.componentNotRegistered:format(componentIdentifier), 2)
    end
end

--[[

    Given an entity ID and a series of component identifiers, removes all
    specified component instances from the entity. Unlike removeComponent, does
    not return anything. batchRemoveComponents will fire all removal signals and
    invoke all plugins before actually removing components.

    Throws if any of the identified component classes aren't registered in the Core.

]]
function Core:batchRemoveComponents(entityId, ...)
    local toRemove = {}
    local identifierCount = select("#", ...)

    for i = 1, identifierCount do
        local rawIdentifier = select(i, ...)
        local convertedIdentifier = resolveComponentByIdentifier(rawIdentifier)
        local componentInstances = self._components[convertedIdentifier]

        if componentInstances == nil then
            error(errorMessages.componentNotRegistered:format(convertedIdentifier), 2)
        end

        local componentInstance = componentInstances[entityId]

        if componentInstance ~= nil then
            local removingSignal = self._componentRemovingSignals[convertedIdentifier]
            self._signalRaisers[removingSignal](entityId, componentInstance)

            self:__callPluginMethod("componentRemoving", entityId, componentInstance)

            table.insert(toRemove, componentInstances)
        end
    end

    for _, instances in ipairs(toRemove) do
        instances[entityId] = nil
    end
end

--[[

    Given a tuple of component identifiers, returns an iterator function over
    all the entities with a given set of components. The iterator function, when
    called, will yield the entity ID, followed by each component in the order
    specified. Callers should avoid adding or removing components in the set
    the iterator is using; RECS does not guarantee that the iterator will remain
    stable in this case.

    The iterator is not ordered in any way, and you should not rely on the order
    that the iterator returns entity IDs. Return values will be ordered, but the
    order of iteration is undefined.

    Throws if any of the identified component classes aren't registered in the Core.

]]
function Core:components(...)
    local count = select("#", ...)

    -- We don't have to do a lot of work if there's only one component!
    -- Most of the bulk of this method is handling multiple arguments; when
    -- there's only one, the workload is much lighter.
    if count == 1 then
        local rawIdentifier = ...
        local convertedIdentifier = resolveComponentByIdentifier(rawIdentifier)

        local map = self._components[convertedIdentifier]

        if map == nil then
            error(errorMessages.componentNotRegistered:format(convertedIdentifier), 2)
        end

        -- Pairs returns an iterator (or something that can be used as one, anyways)
        return pairs(map)
    end

    -- Use a constant table to accumulate results in to avoid unnecessary table
    -- allocations and resizing
    local result = {}
    local componentMaps = {}

    -- Convert the supplied identifiers to internal keys and look up the
    -- component maps. Also perform error checking now, since it's a relatively
    -- cheap place to do it.
    for i = 1, count do
        local rawIdentifier = select(i, ...)
        local convertedIdentifier = resolveComponentByIdentifier(rawIdentifier)

        local map = self._components[convertedIdentifier]

        if map == nil then
            error(errorMessages.componentNotRegistered:format(convertedIdentifier), 2)
        end

        componentMaps[i] = map
    end

    -- We iterate over this map to get entity IDs.
    local firstMap = componentMaps[1]

    -- Coroutine iterators are cool!
    -- Wrapping the function in coroutine.wrap and outputting values with
    -- coroutine.yield means we can write _almost_ the same code that we would
    -- to generate a table, except it's an iterator!
    return coroutine.wrap(function()
        -- For now, we iterate over the first component. There is an
        -- optimization that we can do: pick the component map with the least
        -- number of entities in it, and iterate over that. All other maps are
        -- indexed into using the entity ID we get from here, so iterating over
        -- the smallest map should improve performance!
        -- Since maps have no notion of size, we have to track it separately,
        -- but it should be pretty easy to do this sort of bookkeeping in
        -- addComponent and removeComponent, and it shouldn't desynchronize.
        for entityId, firstComponent in pairs(firstMap) do
            local entityHasAllComponents = true

            result[1] = entityId
            result[2] = firstComponent

            -- We don't need to iterate over any other map because we already
            -- have a key to look up.
            for i = 2, count do
                local otherMap = componentMaps[i]
                local otherComponent = otherMap[entityId]

                if otherComponent == nil then
                    entityHasAllComponents = false
                    -- No reason to continue looking; we already know this
                    -- entity doesn't fit the criteria.
                    break
                else
                    -- Increment i by 1, since index 1 is the entity ID.
                    result[i + 1] = otherComponent
                end
            end

            -- Only yield the coroutine if we have a full results table.
            if entityHasAllComponents then
                coroutine.yield(unpack(result))
            end
        end
    end)
end

--[[

    Gets a signal that fires whenever a component is added to an entity. The
    signal will be fired with the entity ID and the component that was added.

    Throws if the identified component class isn't registered in the Core.

]]
function Core:getComponentAddedSignal(componentIdentifier)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)

    local signal = self._componentAddedSignals[componentIdentifier]
    if signal == nil then
        error(errorMessages.componentNotRegistered:format(componentIdentifier), 2)
    end

    return signal
end

--[[

    Gets a signal that fires whenever a component is removed from an entity. The
    signal will be fired with the entity ID and the component that was removed.

    Throws if the identified component class isn't registered in the Core.

]]
function Core:getComponentRemovingSignal(componentIdentifier)
    componentIdentifier = resolveComponentByIdentifier(componentIdentifier)

    local signal = self._componentRemovingSignals[componentIdentifier]
    if signal == nil then
        error(errorMessages.componentNotRegistered:format(componentIdentifier), 2)
    end

    return signal
end

--[[

    Adds a singleton component to the Core. Returns the component instance.

    Throws if the singleton component already exists on the Core.

]]
function Core:addSingleton(componentClass)
    local singletonIdentifier = componentClass.className

    if self._singletons[singletonIdentifier] == nil then
        local singleton = componentClass._create()
        self._singletons[singletonIdentifier] = singleton

        self:__callPluginMethod("singletonAdded", singleton)

        return singleton
    else
        error(errorMessages.singletonAlreadyAdded:format(singletonIdentifier), 2)
    end
end

--[[

    Given a component identifier, returns the singleton component attached to
    this Core.

    Throws if the singleton doesn't exist on the Core.

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
    self:__callPluginMethod("beforeSystemStart")

    -- Initialize all systems first.
    for _, system in pairs(self._systems) do
        -- Systems are not required to declare an init method, and a no-op one
        -- is not provided in the default System class.
        if system.init ~= nil then
            system:init()
        end
    end

    self:__callPluginMethod("afterSystemStart")

    -- Now start all steppers.
    for _, stepper in ipairs(self._steppers) do
        stepper:start()
    end

    self:__callPluginMethod("afterStepperStart")
end

return Core
