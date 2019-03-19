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

function TestSystem:onTestComponentAdded(instance, component)
    print("interest added", instance:GetFullName(), component.c)
end

function TestSystem:onTestComponentRemoved(instance, component)
    print("interest removed", instance:GetFullName(), component.c)
end

TestSystem.interest {
    interest = RECS.System.InterestType.Added,
    component = TestComponent,
    callback = TestSystem.onTestComponentAdded,
}

TestSystem.interest {
    interest = RECS.System.InterestType.Removed,
    component = TestComponent,
    callback = TestSystem.onTestComponentRemoved,
}

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
print("started")
wait(1)

game:GetService("CollectionService"):RemoveTag(workspace.Part, "Test")
print("tag removed")