local Core = require(script.Parent.Parent.Core)
local defineComponent = require(script.Parent.Parent.defineComponent)

return function()
    local ComponentClass = defineComponent({
        name = "TestComponent",
        generator = function(props)
            props = props or {
                a = 0,

            }
            return {
                a = props.a + 1,
            }
        end
    })

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
    end)

    it("should add components with props", function()
        local core = Core.new()
        core:registerComponent(ComponentClass)

        local entity = core:createEntity()
        local _, component = core:addComponent(entity, ComponentClass, {
            a = 1
        })

        expect(component.a).to.equal(2)
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

    it("should throw if the component's entityFilter forbids the addition", function()
        local core = Core.new()
        local entity = core:createEntity()

        local FilteredComponent = defineComponent({
            name = "Filtered",
            generator = function()
                return {}
            end,
            entityFilter = function(testEntity)
                expect(testEntity).to.equal(entity)
                return false
            end,
        })

        core:registerComponent(FilteredComponent)

        expect(function()
            core:addComponent(entity, FilteredComponent)
        end).to.throw()
    end)
end
