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

    it("should add components", function()
        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)
        core:registerComponent(ComponentC)

        local entity = core:createEntity()
        core:batchAddComponents(entity, ComponentA, ComponentB, ComponentC)
        expect(core:hasComponent(entity, ComponentA)).to.equal(true)
        expect(core:hasComponent(entity, ComponentB)).to.equal(true)
        expect(core:hasComponent(entity, ComponentC)).to.equal(true)
    end)

    it("should not replace components", function()
        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)
        core:registerComponent(ComponentC)

        local entity = core:createEntity()
        local _, addedA = core:addComponent(entity, ComponentA)
        core:batchAddComponents(entity, ComponentA, ComponentB, ComponentC)

        expect(core:hasComponent(entity, ComponentA)).to.equal(true)
        expect(core:hasComponent(entity, ComponentB)).to.equal(true)
        expect(core:hasComponent(entity, ComponentC)).to.equal(true)
        expect(core:getComponent(entity, ComponentA)).to.equal(addedA)
    end)

    it("should fire events after all components have been added", function()
        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)
        core:registerComponent(ComponentC)

        local signalA = core:getComponentAddedSignal(ComponentA)
        signalA:connect(function(entityId, _)
            expect(core:hasComponent(entityId, ComponentB)).to.equal(true)
            expect(core:hasComponent(entityId, ComponentC)).to.equal(true)
        end)

        local signalB = core:getComponentAddedSignal(ComponentB)
        signalB:connect(function(entityId, _)
            expect(core:hasComponent(entityId, ComponentA)).to.equal(true)
            expect(core:hasComponent(entityId, ComponentC)).to.equal(true)
        end)

        local signalC = core:getComponentAddedSignal(ComponentC)
        signalC:connect(function(entityId, _)
            expect(core:hasComponent(entityId, ComponentA)).to.equal(true)
            expect(core:hasComponent(entityId, ComponentB)).to.equal(true)
        end)

        local entity = core:createEntity()
        core:batchAddComponents(entity, ComponentA, ComponentB, ComponentC)
        expect(core:hasComponent(entity, ComponentA)).to.equal(true)
        expect(core:hasComponent(entity, ComponentB)).to.equal(true)
        expect(core:hasComponent(entity, ComponentC)).to.equal(true)
    end)

    it("should throw if any of the components have not been registered", function()
        local core = Core.new()
        local entity = core:createEntity()

        expect(function()
            core:batchAddComponents(entity, ComponentA)
        end).to.throw()

        core:registerComponent(ComponentA)

        expect(function()
            core:batchAddComponents(entity, ComponentA, ComponentB)
        end).to.throw()

        core:registerComponent(ComponentC)

        expect(function()
            core:batchAddComponents(entity, ComponentA, ComponentB, ComponentC)
        end).to.throw()
    end)
end