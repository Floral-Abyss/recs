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

        expect(core:getComponentStateSetSignal(ComponentClass)).to.be.ok()
    end)

    it("should always get the same signal", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local signalA = core:getComponentStateSetSignal(ComponentClass)
        local signalB = core:getComponentStateSetSignal(ComponentClass)
        expect(signalA).to.equal(signalB)
    end)

    it("should fire when the component is added to an entity", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local callCount = 0
        local signal = core:getComponentStateSetSignal(ComponentClass)
        signal:connect(function(entityId, componentInstance)
            callCount = callCount + 1
        end)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        core:setStateComponent(entity, ComponentClass, {})

        expect(callCount).to.equal(1)
    end)

    it("should be fired with the entity ID and the component instance", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entityId = core:createEntity()
        local addedEntityId, addedComponentInstance = nil, nil

        local signal = core:getComponentStateSetSignal(ComponentClass)
        signal:connect(function(signalEntityId, signalComponentInstance)
            addedEntityId = signalEntityId
            addedComponentInstance = signalComponentInstance
        end)

        core:addComponent(entityId, ComponentClass)
        local _, componentInstance = core:setStateComponent(entityId, ComponentClass, {})
        expect(entityId).to.equal(addedEntityId)
        expect(componentInstance).to.equal(addedComponentInstance)
    end)

    it("should throw if the component has not been registered", function()
        local core = Core.new()

        expect(function()
            core:getComponentStateSetSignal(ComponentClass)
        end).to.throw()
    end)
end