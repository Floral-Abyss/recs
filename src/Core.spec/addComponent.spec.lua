local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    local ComponentClass = defineComponent("TestComponent", function()
        return {}
    end)

    it("should add components", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
    end)

    it("should return the added component", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        local addedNew, component = core:addComponent(entity, ComponentClass)
        expect(addedNew).to.equal(true)
        expect(component).to.be.ok()
        expect(component.name).to.equal("TestComponent")
    end)

    it("should return false plus the existing component if the component already exists", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        local _, addedComponent = core:addComponent(entity, ComponentClass)
        local addedNew, component = core:addComponent(entity, ComponentClass)
        expect(addedNew).to.equal(false)
        expect(component).to.equal(addedComponent)
    end)

    it("should throw if the component has not been registered", function()
        local core = Core.new()
        local entity = core:createEntity()

        expect(function()
            core:addComponent(entity, ComponentClass)
        end).to.throw()
    end)
end