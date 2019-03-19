--[[

A RECS Core is the root of a RECS setup. It contains systems, entities, and
component registrations, and is responsible for managing all of these.

]]

local CollectionService = game:GetService("CollectionService")

local EventStepper = require(script.Parent.EventStepper)
local TimeStepper = require(script.Parent.TimeStepper)
local createCleaner = require(script.Parent.createCleaner)
local System = require(script.Parent.System)

local Core = {}
Core.__index = Core

function Core.new(args)
    args = args or {}
    local plugins = args.plugins or {}

    local self = setmetatable({
        cleaner = createCleaner(),
        _steppers = {},
        _systems = {},
        _addedInterests = {},
        _removedInterests = {},
        _components = {},
        _componentDefs = {},
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

        if stepperDefinition.type == "interval" then
            table.insert(steppers, TimeStepper.new(stepperDefinition.interval, systemInstances))
        elseif stepperDefinition.type == "event" then
            table.insert(steppers, EventStepper.new(stepperDefinition.event, systemInstances))
        end
    end

    self._steppers = steppers
end

function Core:start()
    for _, system in ipairs(self._systems) do
        if system.init then
            system:init()
        end

        for _, interest in ipairs(system.interests) do
            local tagName = interest.component.tagName

            if interest.kind == System.InterestType.Added then
                -- Run the callback for all the currently added systems.
                for robloxInstance, componentInstance in pairs(self._components[tagName]) do
                    interest.callback(system, robloxInstance, componentInstance)
                end

                if self._addedInterests[tagName] == nil then
                    self._addedInterests[tagName] = {}
                end

                -- We don't store the system in an accessible fashion.
                -- Bind a callback that pulls the system in.
                table.insert(self._addedInterests[tagName], function(instance, component)
                    interest.callback(system, instance, component)
                end)
            elseif interest.kind == System.InterestType.Removed then
                if self._removedInterests[tagName] == nil then
                    self._removedInterests[tagName] = {}
                end

                -- We don't store the system in an accessible fashion.
                -- Bind a callback that pulls the system in.
                table.insert(self._removedInterests[tagName], function(instance, component)
                    interest.callback(system, instance, component)
                end)
            end
        end
    end

    for _, stepper in ipairs(self._steppers) do
        stepper:start()
    end
end

function Core:registerComponent(componentDefinition)
    local tagName = componentDefinition.tagName

    if self._componentDefs[tagName] then
        error(("Core has already registered a component with name %s"):format(tagName), 2)
    end

    self._componentDefs[tagName] = componentDefinition
    self._components[tagName] = {}

    local addedSignal = CollectionService:GetInstanceAddedSignal(tagName)
    local removedSignal = CollectionService:GetInstanceRemovedSignal(tagName)

    for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
        self:_addComponent(instance, tagName)
    end

    self.cleaner["componentTagAdded." .. tagName] = addedSignal:Connect(function(instance)
        local component = self:_addComponent(instance, tagName)

        -- Call the interested callbacks after the component has been added.
        local interestedCallbacks = self._addedInterests[tagName]
        if interestedCallbacks ~= nil then
            for _, callback in ipairs(interestedCallbacks) do
                callback(instance, component)
            end
        end
    end)

    self.cleaner["componentTagRemoved." .. tagName] = removedSignal:Connect(function(instance)
        -- Before we remove the component, call the interested callbacks.
        local component = self._components[componentDefinition.tagName][instance]
        local interestedCallbacks = self._removedInterests[tagName]
        if interestedCallbacks ~= nil then
            for _, callback in ipairs(interestedCallbacks) do
                callback(instance, component)
            end
        end

        self:_removeComponent(instance, tagName)
    end)

    for _, plugin in ipairs(self._plugins) do
        if plugin.componentRegistered then
            plugin.componentRegistered(componentDefinition)
        end
    end
end

function Core:getComponent(instance, componentDefinition)
    local component = self._components[componentDefinition.tagName][instance]
    return component
end

function Core:hasComponent(instance, componentDefinition)
    return self:getComponent(instance, componentDefinition) ~= nil
end

function Core:components(...)
    local componentDefs = { ... }
    local count = #componentDefs

    return coroutine.wrap(function()
        local firstDefinition = componentDefs[1]
        local result = { nil, nil, nil }

        for instance, component in pairs(self._components[firstDefinition.tagName]) do
            debug.profilebegin("Core:components iterator")
            result[1] = instance
            result[2] = component

            local hasAllComponents = true

            for i = 2, count do
                local definition = componentDefs[i]
                local otherComponent = self._components[definition.tagName][instance]
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

    local singleton = componentDefinition:_create()
    self._singletonComponents[componentDefinition.tagName] = singleton

    for _, plugin in ipairs(self._plugins) do
        if plugin.singletonRegistered then
            plugin.singletonRegistered(singleton)
        end
    end
end

function Core:getSingletonComponent(componentDefinition)
    local component = self._singletonComponents[componentDefinition.tagName]
    return component
end

function Core:_addComponent(instance, tagName)
    if self._components[tagName][instance] ~= nil then
        return
    end

    local componentDefinition = self._componentDefs[tagName]
    local component = componentDefinition:_create(instance)
    self._components[tagName][instance] = component
    return component
end

function Core:_removeComponent(instance, tagName)
    if self._components[tagName][instance] == nil then
        return
    end

    self._components[tagName][instance] = nil
end

return Core