local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    local ComponentA = defineComponent("A", function()
        return {}
    end)

    local ComponentB = defineComponent("B", function()
        return {}
    end)

    local ComponentC = defineComponent("C", function()
        return {}
    end)

    it("should remove components", function()
        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)
        core:registerComponent(ComponentC)

        local entity = core:createEntity()
        core:batchAddComponents(entity, ComponentA, ComponentB, ComponentC)
        expect(core:hasComponent(entity, ComponentA)).to.equal(true)
        expect(core:hasComponent(entity, ComponentB)).to.equal(true)
        expect(core:hasComponent(entity, ComponentC)).to.equal(true)

        core:batchRemoveComponents(entity, ComponentA, ComponentB)
        expect(core:hasComponent(entity, ComponentA)).to.equal(false)
        expect(core:hasComponent(entity, ComponentB)).to.equal(false)
        expect(core:hasComponent(entity, ComponentC)).to.equal(true)
    end)

    it("should work even if the components don't exist on the entity", function()
        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)
        core:registerComponent(ComponentC)

        local entity = core:createEntity()
        core:batchRemoveComponents(entity, ComponentA, ComponentB)
        expect(core:hasComponent(entity, ComponentA)).to.equal(false)
        expect(core:hasComponent(entity, ComponentB)).to.equal(false)
    end)

    it("should fire events before removing any components", function()
        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)
        core:registerComponent(ComponentC)

        local signalA = core:getComponentRemovingSignal(ComponentA)
        signalA:connect(function(entityId, _)
            expect(core:hasComponent(entityId, ComponentB)).to.equal(true)
            expect(core:hasComponent(entityId, ComponentC)).to.equal(true)
        end)

        local signalB = core:getComponentRemovingSignal(ComponentB)
        signalB:connect(function(entityId, _)
            expect(core:hasComponent(entityId, ComponentA)).to.equal(true)
            expect(core:hasComponent(entityId, ComponentC)).to.equal(true)
        end)

        local signalC = core:getComponentRemovingSignal(ComponentC)
        signalC:connect(function(entityId, _)
            expect(core:hasComponent(entityId, ComponentA)).to.equal(true)
            expect(core:hasComponent(entityId, ComponentB)).to.equal(true)
        end)

        local entity = core:createEntity()
        core:batchAddComponents(entity, ComponentA, ComponentB, ComponentC)
        expect(core:hasComponent(entity, ComponentA)).to.equal(true)
        expect(core:hasComponent(entity, ComponentB)).to.equal(true)
        expect(core:hasComponent(entity, ComponentC)).to.equal(true)

        core:batchRemoveComponents(entity, ComponentA, ComponentB, ComponentC)
    end)

    it("should throw if any of the components have not been registered", function()
        local core = Core.new()
        local entity = core:createEntity()

        expect(function()
            core:batchRemoveComponents(entity, ComponentA)
        end).to.throw()

        core:registerComponent(ComponentA)

        expect(function()
            core:batchRemoveComponents(entity, ComponentA, ComponentB)
        end).to.throw()

        core:registerComponent(ComponentC)

        expect(function()
            core:batchRemoveComponents(entity, ComponentA, ComponentB, ComponentC)
        end).to.throw()
    end)
end