local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    local ComponentClass = defineComponent({
        name = "TestComponent",
        generator = function()
            return {}
        end
    })

    it("should remove components", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        core:removeComponent(entity, ComponentClass)
    end)

    it("should return the removed component", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        local _, component = core:addComponent(entity, ComponentClass)
        expect(component).to.be.ok()

        local success, removedComponent = core:removeComponent(entity, ComponentClass)
        expect(success).to.equal(true)
        expect(removedComponent).to.equal(component)
    end)

    it("should return false if the component doesn't exist on the entity", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        local success, removedComponent = core:removeComponent(entity, ComponentClass)
        expect(success).to.equal(false)
        expect(removedComponent).to.equal(nil)
    end)

    it("should throw if the component has not been registered", function()
        local core = Core.new()
        local entity = core:createEntity()

        expect(function()
            core:removeComponent(entity, ComponentClass)
        end).to.throw()
    end)
end