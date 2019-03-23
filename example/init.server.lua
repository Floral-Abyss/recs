local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RECS = require(ReplicatedStorage.RECS)

local core = RECS.Core.new()

local TestComponent = RECS.defineComponent("Test", function()
    return {
        a = 1,
        b = true,
        c = "test",
        tab = {
            a = 1,
        },
    }
end)

local TestSystem = RECS.System:extend("TestSystem")

function TestSystem:init()
    print("system init")

    self.maid.testComponentAddedConnection = self.core:getComponentAddedSignal(TestComponent):Connect(function(testComponent, instance)
        print("test component added to " .. instance:GetFullName(), testComponent.c)
    end)

    self.maid.testComponentRemovingConnection = self.core:getComponentRemovingSignal(TestComponent):Connect(function(testComponent, instance)
        print("test component removed from " .. instance:GetFullName(), testComponent.c)
    end)
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
    RECS.interval(1, {
        TestSystem,
    }),
    RECS.event(game:GetService("Workspace").Baseplate.Changed, {
        HandleChangeSystem,
    }),
})

core:start()
print("started")
wait(1)

game:GetService("CollectionService"):RemoveTag(workspace.Part, "Test")
print("tag removed")