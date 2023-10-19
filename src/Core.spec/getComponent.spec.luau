local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    local ComponentClass = defineComponent({
        name = "TestComponent",
        generator = function()
            return {}
        end,
    })

    it("should get components", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        expect(core:getComponent(entity, ComponentClass)).to.be.ok()
    end)

    it("should return the same component that was added", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        local _, addedComponent = core:addComponent(entity, ComponentClass)
        expect(core:getComponent(entity, ComponentClass)).to.equal(addedComponent)
    end)

    it("should always return the same component", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)

        local firstCall = core:getComponent(entity, ComponentClass)
        local secondCall = core:getComponent(entity, ComponentClass)
        expect(firstCall).to.equal(secondCall)
    end)

    it("should not create components", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        local component = core:getComponent(entity, ComponentClass)
        expect(component).to.equal(nil)
    end)

    it("should throw if the component has not been registered", function()
        local core = Core.new()
        local entity = core:createEntity()

        expect(function()
            core:getComponent(entity, ComponentClass)
        end).to.throw()
    end)
end
