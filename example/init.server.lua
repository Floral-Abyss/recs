local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RECS = require(ReplicatedStorage.RECS)

local core = RECS.Core.new()

local TestComponent = RECS.defineComponent("Test", {
    a = 1,
    b = true,
    c = "test"
})

local TestSystem = RECS.System:extend("TestSystem")

function TestSystem:init()
    print("system init")
end

function TestSystem:step(deltaTime)
    for instance, testComponent in self.core:components(TestComponent) do
        testComponent.a = testComponent.a + deltaTime
        print(testComponent.a)
    end
end

local HandleChangeSystem = RECS.System:extend("HandleChangeSystem")

function HandleChangeSystem:step(property)
    print(property)
end

core:registerComponent(TestComponent)

core:registerSystems({
    RECS.interval(1) {
        TestSystem,
    },
    RECS.event(game:GetService("Workspace").Baseplate.Changed) {
        HandleChangeSystem,
    },
})

core:start()
