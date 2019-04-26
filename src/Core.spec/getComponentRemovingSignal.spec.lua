local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    local ComponentClass = defineComponent({
        name = "TestComponent",
        generator = function()
            return {}
        end
    })

    it("should get a signal", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        expect(core:getComponentRemovingSignal(ComponentClass)).to.be.ok()
    end)

    it("should always get the same signal", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local signalA = core:getComponentRemovingSignal(ComponentClass)
        local signalB = core:getComponentRemovingSignal(ComponentClass)
        expect(signalA).to.equal(signalB)
    end)

    it("should fire when the component is removed from an entity", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local callCount = 0
        local signal = core:getComponentRemovingSignal(ComponentClass)
        signal:connect(function(entityId, componentInstance)
            callCount = callCount + 1
        end)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        expect(callCount).to.equal(0)

        core:removeComponent(entity, ComponentClass)
        expect(callCount).to.equal(1)
    end)

    it("should not fire when removeComponent is called but the component does not exist", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local callCount = 0
        local signal = core:getComponentRemovingSignal(ComponentClass)
        signal:connect(function(entityId, componentInstance)
            callCount = callCount + 1
        end)

        local entity = core:createEntity()
        core:removeComponent(entity, ComponentClass)
        expect(callCount).to.equal(0)
    end)

    it("should be fired with the entity ID and the component instance", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entityId = core:createEntity()
        local removedEntityId, removedComponentInstance = nil, nil

        local signal = core:getComponentRemovingSignal(ComponentClass)
        signal:connect(function(signalEntityId, signalComponentInstance)
            removedEntityId = signalEntityId
            removedComponentInstance = signalComponentInstance
        end)

        core:addComponent(entityId, ComponentClass)
        local _, componentInstance = core:removeComponent(entityId, ComponentClass)
        expect(entityId).to.equal(removedEntityId)
        expect(componentInstance).to.equal(removedComponentInstance)
    end)

    it("should be fired when destroying an entity", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entityId = core:createEntity()
        local callCount = 0
        local removedEntityId, removedComponentInstance = nil, nil

        local signal = core:getComponentRemovingSignal(ComponentClass)
        signal:connect(function(signalEntityId, signalComponentInstance)
            callCount = callCount + 1
            removedEntityId = signalEntityId
            removedComponentInstance = signalComponentInstance
        end)

        local _, componentInstance = core:addComponent(entityId, ComponentClass)
        core:destroyEntity(entityId)

        expect(callCount).to.equal(1)
        expect(entityId).to.equal(removedEntityId)
        expect(componentInstance).to.equal(removedComponentInstance)
    end)

    it("should throw if the component has not been registered", function()
        local core = Core.new()

        expect(function()
            core:getComponentRemovingSignal(ComponentClass)
        end).to.throw()
    end)
end