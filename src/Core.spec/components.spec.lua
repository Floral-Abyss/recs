local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    it("should iterate over entities", function()
        local ComponentClass = defineComponent("TestComponent", function()
            return {}
        end)

        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        local _, addedComponent = core:addComponent(entity, ComponentClass)

        for iteratedEntity, iteratedComponent in core:components(ComponentClass) do
            -- There is only one entity that fits the constraints, so these expectations are valid.
            expect(iteratedEntity).to.equal(entity)
            expect(iteratedComponent).to.equal(addedComponent)
        end
    end)

    it("should return components in the order specified", function()
        local ComponentA = defineComponent("A", function()
            return {}
        end)

        local ComponentB = defineComponent("B", function()
            return {}
        end)

        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)

        local entity = core:createEntity()
        local _, addedA = core:addComponent(entity, ComponentA)
        local _, addedB = core:addComponent(entity, ComponentB)

        for iteratedEntity, iteratedA, iteratedB in core:components(ComponentA, ComponentB) do
            -- There is only one entity that fits the constraints, so these expectations are valid.
            expect(iteratedEntity).to.equal(entity)
            expect(iteratedA).to.equal(addedA)
            expect(iteratedB).to.equal(addedB)
        end

        for iteratedEntity, iteratedB, iteratedA in core:components(ComponentB, ComponentA) do
            expect(iteratedEntity).to.equal(entity)
            expect(iteratedA).to.equal(addedA)
            expect(iteratedB).to.equal(addedB)
        end
    end)

    it("should exclude entities that do not have all the components", function()
        local ComponentA = defineComponent("A", function()
            return {}
        end)

        local ComponentB = defineComponent("B", function()
            return {}
        end)

        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)

        local entityA = core:createEntity()
        local _, addedA = core:addComponent(entityA, ComponentA)
        local _, addedB = core:addComponent(entityA, ComponentB)

        local entityB = core:createEntity()
        core:addComponent(entityB, ComponentA)

        local entityC = core:createEntity()
        core:addComponent(entityC, ComponentB)

        for iteratedEntity, iteratedA, iteratedB in core:components(ComponentA, ComponentB) do
            expect(iteratedEntity).to.equal(entityA)
            expect(iteratedA).to.equal(addedA)
            expect(iteratedB).to.equal(addedB)
        end
    end)

    it("should include entities that have components that are not specified", function()
        local ComponentA = defineComponent("A", function()
            return {}
        end)

        local ComponentB = defineComponent("B", function()
            return {}
        end)

        local core = Core.new()
        core:registerComponent(ComponentA)
        core:registerComponent(ComponentB)

        local entityA = core:createEntity()
        local _, addedA = core:addComponent(entityA, ComponentA)
        core:addComponent(entityA, ComponentB)

        for iteratedEntity, iteratedA in core:components(ComponentA) do
            expect(iteratedEntity).to.equal(entityA)
            expect(iteratedA).to.equal(addedA)
        end
    end)
end