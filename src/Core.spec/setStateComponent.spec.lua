local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    local ComponentClass = defineComponent({
        name = "TestComponent",
        generator = function()
            return {
                x = 0,
                y = 0,
            }
        end
    })

    it("should set all the fields provided", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        core:setStateComponent(entity, ComponentClass, { x = 10, y = 20 })
    end)

    it("should return the added component", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        local success, component = core:setStateComponent(entity, ComponentClass, { x = 10, y = 20 })

        expect(success).to.equal(true)
        expect(component.x).to.equal(10)
        expect(component.y).to.equal(20)
    end)

    it("should set only the fields provided", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        local success, component = core:setStateComponent(entity, ComponentClass, { x = 10 })

        expect(success).to.equal(true)
        expect(component.x).to.equal(10)
        expect(component.y).to.equal(0)
    end)

    it("should remove fields when given Core.None", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        core:addComponent(entity, ComponentClass)
        local success, component = core:setStateComponent(entity, ComponentClass, { x = 10, y = core.None })

        expect(success).to.equal(true)
        expect(component.x).to.equal(10)
        expect(component.y).to.equal(nil)
    end)

    it("should throw if the component has not been registered", function()
        local core = Core.new()
        local entity = core:createEntity()

        expect(function()
            core:setStateComponent(entity, ComponentClass, { x = 0 })
        end).to.throw()
    end)

    it("should throw if the component has not been added to the entity", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)
        local entity = core:createEntity()

        expect(function()
            core:setStateComponent(entity, ComponentClass, { x = 0 })
        end).to.throw()
    end)

end
