-- luacheck: std +testez
local Core = require(script.Parent.Core)
local defineComponent = require(script.Parent.defineComponent)
local System = require(script.Parent.System)

return function()
    describe("new", function()
        it("should create new cores", function()
            local core = Core.new()
            expect(core).to.be.ok()
        end)
    end)

    describe("createEntity", function()
        it("should return a value", function()
            local core = Core.new()
            expect(core:createEntity()).to.be.ok()
        end)

        it("should return different values each time", function()
            local core = Core.new()
            local seenValues = {}

            for i = 1, 100 do
                local entityId = core:createEntity()
                assert(seenValues[entityId] == nil, "createEntity returned a duplicate value")
                seenValues[entityId] = true
            end
        end)
    end)

    describe("registerComponent", function()
        local component = defineComponent("TestComponent", function()
            return {}
        end)

        it("should succeed when called", function()
            local core = Core.new()
            core:registerComponent(component)
        end)

        it("should throw when registering a component repeatedly", function()
            local core = Core.new()
            core:registerComponent(component)

            expect(function()
                core:registerComponent(component)
            end).to.throw()
        end)
    end)

    describe("addSingleton", function()
        local component = defineComponent("TestSingleton", function()
            return {}
        end)

        it("should add singleton components", function()
            local core = Core.new()
            local singleton = core:addSingleton(component)
            expect(singleton).to.be.ok()
            expect(core:getSingleton(component)).to.be.ok()
            expect(core:getSingleton(component)).to.equal(singleton)
        end)

        it("should throw if the singleton is already added", function()
            local core = Core.new()
            core:addSingleton(component)

            expect(function()
                core:addSingleton(component)
            end).to.throw()
        end)
    end)

    describe("getSingleton", function()
        local component = defineComponent("TestSingleton", function()
            return {}
        end)

        it("should get singleton components", function()
            local core = Core.new()
            local singleton = core:addSingleton(component)
            expect(singleton).to.be.ok()
            expect(core:getSingleton(component)).to.be.ok()
            expect(core:getSingleton(component)).to.equal(singleton)
        end)

        it("should throw if the singleton isn't added", function()
            local core = Core.new()

            expect(function()
                core:getSingleton(component)
            end).to.throw()
        end)
    end)

    describe("registerSystem", function()
        it("should succeed when called", function()
            local TestSystem = System:extend("TestSystem")
            local core = Core.new()
            core:registerSystem(TestSystem)
        end)

        it("should throw when registering a system repeatedly", function()
            local TestSystem = System:extend("TestSystem")
            local core = Core.new()
            core:registerSystem(TestSystem)

            expect(function()
                core:registerSystem(TestSystem)
            end).to.throw()
        end)

        it("should not call System:init", function()
            local TestSystem = System:extend("TestSystem")

            function TestSystem:init()
                error("System:init was called")
            end

            local core = Core.new()
            core:registerSystem(TestSystem)
        end)
    end)
end