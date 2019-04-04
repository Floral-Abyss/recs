--[[

A RECS Core is the root of a RECS setup. It contains systems, entities, and
component registrations, and is responsible for managing all of these.

]]

local CollectionService = game:GetService("CollectionService")

local EventStepper = require(script.Parent.EventStepper)
local TimeStepper = require(script.Parent.TimeStepper)
local createCleaner = require(script.Parent.createCleaner)
local createSignal = require(script.Parent.createSignal)

--[[
    Resolves a tag name from a "component identifier", which may be either a
    tag name or a Component itself. Cores use tag names to identify components.
]]
local function resolveComponentByIdentifier(componentIdentifier)
    if typeof(componentIdentifier) == "string" then
        return componentIdentifier
    elseif typeof(componentIdentifier) == "table" then
        return componentIdentifier.tagName
    else
        error(
            ("Component identifier %q of type %s is not usable"):format(
                tostring(componentIdentifier),
                typeof(componentIdentifier)),
            0)
    end
end

local function getComponentSignal(componentIdentifier, eventCache)
    local tagName = resolveComponentByIdentifier(componentIdentifier)

    local signal = eventCache[tagName]
    if signal == nil then
        signal = createSignal()
        eventCache[tagName] = signal
    end

    return signal
end

local Core = {}
Core.__index = Core

function Core.new(args)
    args = args or {}
    local plugins = args.plugins or {}

    local self = setmetatable({
        args = args,
        cleaner = createCleaner(),
        _steppers = {},
        _systems = {},
        _components = {},
        _componentDefs = {},
        _componentAddedSignals = {},
        _componentRemovingSignals = {},
        _singletonComponents = {},
        _plugins = plugins,
    }, Core)

    for _, plugin in ipairs(plugins) do
        if plugin.coreInit then
            plugin.coreInit(self)
        end
    end

    return self
end

function Core:registerSystems(systemRegistration)
    local steppers = {}

    for _, stepperDefinition in ipairs(systemRegistration) do
        local systemInstances = {}

        for _, class in ipairs(stepperDefinition.systemClasses) do
            local systemInstance = class._create(self)
            table.insert(self._systems, systemInstance)
            table.insert(systemInstances, systemInstance)
        end

        if stepperDefinition.type == "event" then
            table.insert(steppers, EventStepper.new(stepperDefinition.event, systemInstances))
        elseif stepperDefinition.type == "interval" then
            table.insert(steppers, TimeStepper.new(stepperDefinition.interval, systemInstances))
        else
            error(("Unknown stepper definition kind %s"):format(stepperDefinition.type), 0)
        end
    end

    self._steppers = steppers
end

function Core:start()
    for _, system in ipairs(self._systems) do
        if system.init then
            system:init()
        end
    end

    for _, componentDefinition in pairs(self._componentDefs) do
        self:_initiateComponent(componentDefinition)
    end

    for _, stepper in ipairs(self._steppers) do
        stepper:start()
    end
end

function Core:getComponentAddedSignal(componentIdentifier)
    return getComponentSignal(componentIdentifier, self._componentAddedSignals)
end

function Core:getComponentRemovingSignal(componentIdentifier)
    return getComponentSignal(componentIdentifier, self._componentRemovingSignals)
end

function Core:_initiateComponent(componentDefinition)
    local tagName = componentDefinition.tagName
    local addedSignal = CollectionService:GetInstanceAddedSignal(tagName)
    local removedSignal = CollectionService:GetInstanceRemovedSignal(tagName)

    for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
        self:_addComponent(instance, tagName)
    end

    self.cleaner["componentTagAdded." .. tagName] = addedSignal:Connect(function(instance)
        self:_addComponent(instance, tagName)
    end)

    self.cleaner["componentTagRemoved." .. tagName] = removedSignal:Connect(function(instance)
        self:_removeComponent(instance, tagName)
    end)
end

function Core:registerComponent(componentDefinition)
    local tagName = componentDefinition.tagName

    if self._componentDefs[tagName] then
        error(("Core has already registered a component with name %s"):format(tagName), 2)
    end

    self._componentDefs[tagName] = componentDefinition
    self._components[tagName] = {}

    for _, plugin in ipairs(self._plugins) do
        if plugin.componentRegistered then
            plugin.componentRegistered(self, componentDefinition)
        end
    end
end

function Core:registerComponentsFromFolder(folder)
    for _, module in pairs(folder:GetChildren()) do
        if module:IsA("ModuleScript") then
            self:registerComponent(require(module))
        end
    end
end

function Core:getComponent(instance, componentIdentifier)
    local component = self._components[resolveComponentByIdentifier(componentIdentifier)][instance]
    return component
end

function Core:hasComponent(instance, componentIdentifier)
    return self._components[resolveComponentByIdentifier(componentIdentifier)][instance] ~= nil
end

function Core:components(...)
    local count = select("#", ...)
    local tagNames = {}

    for i = 1, count do
        tagNames[i] = resolveComponentByIdentifier(select(i, ...))
    end

    return coroutine.wrap(function()
        local firstName = tagNames[1]
        local result = { nil, nil, nil }

        for instance, component in pairs(self._components[firstName]) do
            debug.profilebegin("Core:components iterator")
            result[1] = instance
            result[2] = component

            local hasAllComponents = true

            for i = 2, count do
                local otherName = tagNames[i]
                local otherComponent = self._components[otherName][instance]
                if otherComponent ~= nil then
                    result[i + 1] = otherComponent
                else
                    hasAllComponents = false
                    break
                end
            end
            debug.profileend()

            if hasAllComponents then
                coroutine.yield(unpack(result))
            end
        end
    end)
end

function Core:registerSingletonComponent(componentDefinition)
    if self._singletonComponents[componentDefinition.tagName] then
        error(("Core has already registered a singleton component with name %s"):format(componentDefinition.tagName), 2)
    end

    local singleton = componentDefinition._create()
    self._singletonComponents[componentDefinition.tagName] = singleton

    for _, plugin in ipairs(self._plugins) do
        if plugin.singletonRegistered then
            plugin.singletonRegistered(singleton)
        end
    end
end

function Core:getSingletonComponent(componentIdentifier)
    local component = self._singletonComponents[resolveComponentByIdentifier(componentIdentifier)]
    return component
end

function Core:_addComponent(instance, tagName)
    if self._components[tagName][instance] ~= nil then
        return
    end

    local componentDefinition = self._componentDefs[tagName]
    local component = componentDefinition._create(instance)
    self._components[tagName][instance] = component

    if componentDefinition.added then
        componentDefinition.added(component, instance)
    end

    if self._componentAddedSignals[tagName] ~= nil then
        self._componentAddedSignals[tagName]:Fire(component, instance)
    end

    return component
end

function Core:_removeComponent(instance, tagName)
    if self._components[tagName][instance] == nil then
        return
    end

    local componentDefinition = self._componentDefs[tagName]
    local component = self._components[tagName][instance]

    if self._componentRemovingSignals[tagName] ~= nil then
        self._componentRemovingSignals[tagName]:Fire(component, instance)
    end

    if componentDefinition.removing then
        componentDefinition.removing(component, instance)
    end

    component.maid:clean()

    self._components[tagName][instance] = nil
end

return Core
