local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    local ComponentClass = defineComponent({
        name = "TestComponent",
        generator = function()
            return {}
        end,
    })

    it("should get a signal", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        expect(core:getComponentAddedSignal(ComponentClass)).to.be.ok()
    end)

    it("should always get the same signal", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local signalA = core:getComponentAddedSignal(ComponentClass)
        local signalB = core:getComponentAddedSignal(ComponentClass)
        expect(signalA).to.equal(signalB)
    end)

    it("should fire when the component is added to an entity", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local callCount = 0
        local signal = core:getComponentAddedSignal(ComponentClass)
        signal:connect(function(entityId, componentInstance)
            callCount = callCount + 1
        end)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)

        expect(callCount).to.equal(1)
    end)

    it("should not fire when addComponent is called but the component already exists", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local callCount = 0
        local signal = core:getComponentAddedSignal(ComponentClass)
        signal:connect(function(entityId, componentInstance)
            callCount = callCount + 1
        end)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        core:addComponent(entity, ComponentClass)

        expect(callCount).to.equal(1)
    end)

    it("should be fired with the entity ID and the component instance", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entityId = core:createEntity()
        local addedEntityId, addedComponentInstance = nil, nil

        local signal = core:getComponentAddedSignal(ComponentClass)
        signal:connect(function(signalEntityId, signalComponentInstance)
            addedEntityId = signalEntityId
            addedComponentInstance = signalComponentInstance
        end)

        local _, componentInstance = core:addComponent(entityId, ComponentClass)
        expect(entityId).to.equal(addedEntityId)
        expect(componentInstance).to.equal(addedComponentInstance)
    end)

    it("should throw if the component has not been registered", function()
        local core = Core.new()

        expect(function()
            core:getComponentAddedSignal(ComponentClass)
        end).to.throw()
    end)
end
