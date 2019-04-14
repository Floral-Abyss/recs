local defineComponent = require(script.Parent.defineComponent)

return function()
    it("should create component classes", function()
        expect(defineComponent("test", function() end)).to.be.ok()
    end)

    it("should create component classes with a name and creator", function()
        local component = defineComponent("Test", function() end)
        expect(typeof(component.name)).to.equal("string")
        expect(component.name).to.equal("Test")

        expect(typeof(component._create)).to.equal("function")
    end)

    it("should throw if given a non-string name", function()
        expect(function()
            defineComponent(123, function()
            end)
        end).to.throw()
    end)

    it("should throw if given a non-function generator", function()
        expect(function()
            defineComponent("test", true)
        end).to.throw()
    end)
end