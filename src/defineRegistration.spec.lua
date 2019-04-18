local defineRegistration = require(script.Parent.defineRegistration)
local System = require(script.Parent.System)

return function()
    describe("interval", function()
        it("should create stepper definitions", function()
            local TestSystem = System:extend("TestSystem")

            expect(defineRegistration.interval(1, {
                TestSystem,
            })).to.be.ok()
        end)

        it("should throw if given a non-number as the first argument", function()
            expect(function()
                defineRegistration.interval(false, {})
            end).to.throw()
        end)

        it("should throw if given a non-positive number as the first argument", function()
            expect(function()
                defineRegistration.interval(-1, {})
            end).to.throw()
        end)

        it("should throw if given a non-table as the second argument", function()
            expect(function()
                defineRegistration.interval(1, false)
            end).to.throw()
        end)

        it("should throw if the systems table has an element that is not a system class", function()
            expect(function()
                defineRegistration.interval(1, {
                    false
                })
            end).to.throw()
        end)
    end)

    describe("event", function()
        it("should create stepper definitions", function()
            local TestSystem = System:extend("TestSystem")

            local bindableEvent = Instance.new("BindableEvent")
            local event = bindableEvent.Event
            expect(defineRegistration.event(event, {
                TestSystem,
            })).to.be.ok()
        end)

        it("should throw if given a non-event as the first argument", function()
            expect(function()
                defineRegistration.event(false, {})
            end).to.throw()
        end)

        it("should throw if given a non-table as the second argument", function()
            local bindableEvent = Instance.new("BindableEvent")
            local event = bindableEvent.Event

            expect(function()
                defineRegistration.event(event, false)
            end).to.throw()
        end)

        it("should throw if the systems table has an element that is not a system class", function()
            local bindableEvent = Instance.new("BindableEvent")
            local event = bindableEvent.Event

            expect(function()
                defineRegistration.event(event, {
                    false
                })
            end).to.throw()
        end)
    end)
end