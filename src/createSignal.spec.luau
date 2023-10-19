--!strict

local createSignal = require(script.Parent.createSignal)

return function()
    it("should return a signal and a function", function()
        local signal, fire = createSignal()
        expect(signal).to.be.ok()
        expect(typeof(signal.Connect)).to.equal("function")
        expect(typeof(signal.connect)).to.equal("function")
        expect(typeof(fire)).to.equal("function")
    end)

    describe("Connect", function()
        it("should connect to the signal", function()
            local signal, fire = createSignal()
            local fired = false
            signal:Connect(function(value)
                expect(value).to.equal(1)
                fired = true
            end)

            fire(1)
            expect(fired).to.equal(true)
        end)

        it("should wrap all listeners in coroutines to avoid blocking", function()
            local signal, fire = createSignal()
            local done = false

            signal:Connect(function()
                wait(1)
                done = true
            end)

            fire()
            expect(done).to.equal(false)
        end)
    end)

    describe("connections", function()
        it("should be returned from Connect", function()
            local signal, _ = createSignal()
            local connection = signal:Connect(function() end)

            expect(connection).to.be.ok()
            expect(connection.Connected).to.equal(true)
        end)

        it("should disconnect the listener when Disconnect is called", function()
            local signal, fire = createSignal()
            local callCount = 0
            local connection = signal:Connect(function()
                callCount = callCount + 1
            end)

            expect(connection).to.be.ok()
            expect(connection.Connected).to.equal(true)

            fire()
            expect(callCount).to.equal(1)

            connection:Disconnect()
            expect(connection.Connected).to.equal(false)
            fire()
            expect(callCount).to.equal(1)
        end)
    end)

    describe("fire", function()
        it("should invoke listeners", function()
            local signal, fire = createSignal()
            local fired = false
            signal:Connect(function(value)
                expect(value).to.equal(1)
                fired = true
            end)

            fire(1)
            expect(fired).to.equal(true)
        end)

        it("should not serialize arguments", function()
            local testValue = {}
            local signal, fire = createSignal()

            signal:Connect(function(value)
                expect(value).to.equal(testValue)
            end)

            fire(testValue)
        end)
    end)
end
