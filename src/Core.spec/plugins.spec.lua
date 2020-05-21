local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)
local System = require(script.Parent.Parent.System)

return function()
    it("should call plugin methods in order", function()
        local callIndex = 1

        local pluginA = {
            coreInit = function()
                expect(callIndex).to.equal(1)
                callIndex = 1
            end
        }

        local pluginB = {
            coreInit = function()
                expect(callIndex).to.equal(1)
                callIndex = 2
            end
        }

        local pluginC = {
            coreInit = function()
                expect(callIndex).to.equal(2)
                callIndex = 3
            end
        }

        Core.new({ pluginA, pluginB, pluginC })
        expect(callIndex).to.equal(3)
    end)

    it("should call plugin methods once per execution scenario", function()
        local callCount = 0

        local plugin = {
            coreInit = function()
                callCount = callCount + 1
            end
        }

        Core.new({ plugin })
        expect(callCount).to.equal(1)
    end)

    describe("coreInit", function()
        it("should be called on Core creation", function()
            local callCount = 0

            local plugin = {
                coreInit = function()
                    callCount = callCount + 1
                end
            }

            Core.new({ plugin })
            expect(callCount).to.equal(1)
        end)

        it("should be called with the Core", function()
            local callCount = 0
            local calledCore = nil

            local plugin
            plugin = {
                coreInit = function(self, core)
                    callCount = callCount + 1
                    calledCore = core

                    expect(self).to.equal(plugin)
                end
            }

            local core = Core.new({ plugin })
            expect(callCount).to.equal(1)
            expect(calledCore).to.equal(core)
        end)
    end)

    describe("componentRegistered", function()
        it("should be called when a component is registered", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local callCount = 0

            local plugin = {
                componentRegistered = function(self, core, componentClass)
                    callCount = callCount + 1
                    expect(componentClass).to.equal(ComponentClass)
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)
            expect(callCount).to.equal(1)
        end)
    end)

    describe("componentAdded", function()
        it("should be called when a component is added to an entity", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local callCount = 0
            local calledEntity = nil
            local calledComponentInstance = nil
            local calledComponentProps = nil

            local plugin = {
                componentAdded = function(self, core, entityId, componentInstance, componentProps)
                    expect(componentInstance.className).to.equal("TestComponent")

                    callCount = callCount + 1
                    calledEntity = entityId
                    calledComponentInstance = componentInstance
                    calledComponentProps = componentProps
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)
            local entity = core:createEntity()
            local props = {
                foo = "bar",
            }
            local _, componentInstance = core:addComponent(entity, ComponentClass, props)

            expect(callCount).to.equal(1)
            expect(entity).to.equal(calledEntity)
            expect(componentInstance).to.equal(calledComponentInstance)
            expect(props).to.equal(calledComponentProps)
        end)

        it("should be called before events are fired in addComponent", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local eventFired = false

            local plugin = {
                componentAdded = function(self, core, entityId, componentInstance)
                    expect(eventFired).to.equal(false)
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)

            local signal = core:getComponentAddedSignal(ComponentClass)
            signal:connect(function()
                eventFired = true
            end)

            local entity = core:createEntity()
            core:addComponent(entity, ComponentClass)
        end)

        it("should be called before events are fired in batchAddComponents", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local eventFired = false

            local plugin = {
                componentAdded = function(self, core, entityId, componentInstance)
                    expect(eventFired).to.equal(false)
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)

            local signal = core:getComponentAddedSignal(ComponentClass)
            signal:connect(function()
                eventFired = true
            end)

            local entity = core:createEntity()
            core:batchAddComponents(entity, ComponentClass)
        end)
    end)

    describe("componentStateSet", function()
        it("should be called when a component's state is set", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local callCount = 0
            local calledEntity = nil
            local calledComponentInstance = nil

            local plugin = {
                componentStateSet = function(self, core, entityId, componentIdentifier, componentInstance)
                    expect(componentIdentifier).to.equal("TestComponent")

                    callCount = callCount + 1
                    calledEntity = entityId
                    calledComponentInstance = componentInstance
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)
            local entity = core:createEntity()
            core:addComponent(entity, ComponentClass)
            local _, componentInstance = core:setStateComponent(entity, ComponentClass, {})

            expect(callCount).to.equal(1)
            expect(entity).to.equal(calledEntity)
            expect(componentInstance).to.equal(calledComponentInstance)
        end)

        it("should be called before events are fired in setStateComponent", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local eventFired = false

            local plugin = {
                componentStateSet = function(self, core, entityId, componentInstance)
                    expect(eventFired).to.equal(false)
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)

            local signal = core:getComponentStateSetSignal(ComponentClass)
            signal:connect(function()
                eventFired = true
            end)

            local entity = core:createEntity()
            core:addComponent(entity, ComponentClass)
            core:setStateComponent(entity, ComponentClass, {})
        end)
    end)

    describe("singletonSetState", function()
        it("should be called when a singleton's state is set", function()
            local mySingletonIdentifier = defineComponent({
                name = "singleton",
                generator = function()
                    return {}
                end
            })

            local callCount = 0
            local calledSingletonIdentifier = nil
            local calledComponentInstance = nil

            local plugin = {
                singletonStateSet = function(self, core, singletonIdentifier, singletonInstance)
                    callCount = callCount + 1
                    calledSingletonIdentifier = singletonIdentifier
                    calledComponentInstance = singletonInstance
                end,
            }

            local core = Core.new({ plugin })
            core:addSingleton(mySingletonIdentifier)
            local _, componentInstance = core:setStateSingleton(mySingletonIdentifier, {})

            expect(callCount).to.equal(1)
            expect(calledSingletonIdentifier).to.equal(mySingletonIdentifier)
            expect(componentInstance).to.equal(calledComponentInstance)
        end)
    end)

    describe("componentRemoving", function()
        it("should be called when a component is removed from an entity", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local callCount = 0
            local calledEntity = nil
            local calledComponentInstance = nil

            local plugin = {
                componentRemoving = function(self, core, entityId, componentInstance)
                    expect(componentInstance.className).to.equal("TestComponent")

                    callCount = callCount + 1
                    calledEntity = entityId
                    calledComponentInstance = componentInstance
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)
            local entity = core:createEntity()
            core:addComponent(entity, ComponentClass)
            local _, componentInstance = core:removeComponent(entity, ComponentClass)

            expect(callCount).to.equal(1)
            expect(entity).to.equal(calledEntity)
            expect(componentInstance).to.equal(calledComponentInstance)
        end)

        it("should be called when an entity is destroyed", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local callCount = 0
            local calledEntity = nil
            local calledComponentInstance = nil

            local plugin = {
                componentRemoving = function(self, core, entityId, componentInstance)
                    expect(componentInstance.className).to.equal("TestComponent")

                    callCount = callCount + 1
                    calledEntity = entityId
                    calledComponentInstance = componentInstance
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)
            local entity = core:createEntity()
            local _, componentInstance = core:addComponent(entity, ComponentClass)
            core:destroyEntity(entity)

            expect(callCount).to.equal(1)
            expect(entity).to.equal(calledEntity)
            expect(componentInstance).to.equal(calledComponentInstance)
        end)

        it("should be called after events are fired in removeComponent", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local eventFired = false

            local plugin = {
                componentRemoving = function(self, core, entityId, componentInstance)
                    expect(eventFired).to.equal(true)
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)

            local signal = core:getComponentRemovingSignal(ComponentClass)
            signal:connect(function()
                eventFired = true
            end)

            local entity = core:createEntity()
            core:addComponent(entity, ComponentClass)
            core:removeComponent(entity, ComponentClass)
        end)

        it("should be called after events are fired in batchRemoveComponents", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local eventFired = false

            local plugin = {
                componentRemoving = function(self, core, entityId, componentInstance)
                    expect(eventFired).to.equal(true)
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)

            local signal = core:getComponentRemovingSignal(ComponentClass)
            signal:connect(function()
                eventFired = true
            end)

            local entity = core:createEntity()
            core:addComponent(entity, ComponentClass)
            core:batchRemoveComponents(entity, ComponentClass)
        end)

        it("should be called after events are fired in destroyEntity", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local eventFired = false

            local plugin = {
                componentRemoving = function(self, core, entityId, componentInstance)
                    expect(eventFired).to.equal(true)
                end,
            }

            local core = Core.new({ plugin })
            core:registerComponent(ComponentClass)

            local signal = core:getComponentRemovingSignal(ComponentClass)
            signal:connect(function()
                eventFired = true
            end)

            local entity = core:createEntity()
            core:addComponent(entity, ComponentClass)
            core:destroyEntity(entity)
        end)
    end)

    describe("singletonAdded", function()
        it("should be called when a singleton is added", function()
            local ComponentClass = defineComponent({
                name = "TestComponent",
                generator = function()
                    return {}
                end
            })

            local callCount = 0
            local calledSingleton = nil

            local plugin = {
                singletonAdded = function(self, core, singleton)
                    callCount = callCount + 1
                    calledSingleton = singleton
                end,
            }

            local core = Core.new({ plugin })
            local singleton = core:addSingleton(ComponentClass)

            expect(callCount).to.equal(1)
            expect(calledSingleton).to.equal(singleton)
        end)
    end)

    describe("beforeSystemStart", function()
        it("should be called before systems init", function()
            local systemsInitialized = false
            local SystemClass = System:extend("SystemClass")

            function SystemClass:init()
                systemsInitialized = true
            end

            local plugin = {
                beforeSystemStart = function(self, core)
                    expect(systemsInitialized).to.equal(false)
                end
            }

            local core = Core.new({ plugin })
            core:registerSystem(SystemClass)
            core:start()
            expect(systemsInitialized).to.equal(true)
        end)
    end)

    describe("afterSystemStart", function()
        it("should be called after systems init", function()
            local systemsInitialized = false
            local SystemClass = System:extend("SystemClass")

            function SystemClass:init()
                systemsInitialized = true
            end

            local plugin = {
                afterSystemStart = function(self, core)
                    expect(systemsInitialized).to.equal(true)
                end
            }

            local core = Core.new({ plugin })
            core:registerSystem(SystemClass)
            core:start()
            expect(systemsInitialized).to.equal(true)
        end)
    end)

    describe("afterStepperStart", function()
        it("should be called after systems init", function()
            local systemsInitialized = false
            local SystemClass = System:extend("SystemClass")

            function SystemClass:init()
                systemsInitialized = true
            end

            local plugin = {
                afterStepperStart = function(self, core)
                    expect(systemsInitialized).to.equal(true)
                end
            }

            local core = Core.new({ plugin })
            core:registerSystem(SystemClass)
            core:start()
            expect(systemsInitialized).to.equal(true)
        end)
    end)
end
