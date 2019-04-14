local createCleaner = require(script.Parent.createCleaner)

return function()
    it("should create cleaners", function()
        expect(createCleaner()).to.be.ok()
    end)

    describe("Cleaner", function()
        it("should allow retrieval of given objects", function()
            local testInstance = Instance.new("Folder")
            local cleaner = createCleaner()
            cleaner.Test = testInstance

            expect(cleaner.Test).to.equal(testInstance)
        end)

        describe("give", function()
            it("should accept instances", function()
                local cleaner = createCleaner()
                expect(function()
                    cleaner:give("Test", Instance.new("Folder"))
                end).to.never.throw()
            end)

            it("should accept functions", function()
                local cleaner = createCleaner()
                expect(function()
                    cleaner:give("Test", function() end)
                end).to.never.throw()
            end)

            it("should accept connections", function()
                local event = Instance.new("BindableEvent")
                local connection = event.Event:Connect(function()
                end)

                local cleaner = createCleaner()
                expect(function()
                    cleaner:give("Test", connection)
                end).to.never.throw()
            end)

            it("should accept other cleaners", function()
                local cleaner = createCleaner()
                expect(function()
                    cleaner:give("Test", createCleaner())
                end).to.never.throw()
            end)

            local methods = { "destroy", "Destroy", "disconnect", "Disconnect" }
            for _, methodName in ipairs(methods) do
                it("should accept tables with " .. methodName .. " functions", function()
                    local cleaner = createCleaner()
                    expect(function()
                        cleaner.Test = {
                            [methodName] = function()
                            end,
                        }
                    end).to.never.throw()
                end)
            end

            it("should throw if given an uncleanable value", function()
                local cleaner = createCleaner()
                expect(function()
                    cleaner:give("uncleanable", 1)
                    cleaner:give("uncleanable2", true)
                    cleaner:give("uncleanable3", {})
                end).to.throw()
            end)

            it("should throw if you try to override a method", function()
                local cleaner = createCleaner()
                expect(function()
                    cleaner:give("give", function() end)
                    cleaner:give("clean", function() end)
                end).to.throw()
            end)

            it("should be bound to __newindex", function()
                local cleaner = createCleaner()
                local event = Instance.new("BindableEvent")
                local connection = event.Event:Connect(function()
                end)

                expect(function()
                    cleaner.Instance = Instance.new("Folder")
                    cleaner.Function = function() end
                    cleaner.Connection = connection
                    cleaner.destroy = {
                        destroy = function() end,
                    }
                    cleaner.Destroy = {
                        Destroy = function() end,
                    }
                    cleaner.disconnect = {
                        disconnect = function() end,
                    }
                    cleaner.Disconnect = {
                        Disconnect = function() end,
                    }
                end).to.never.throw()

                expect(function()
                    cleaner.give = function() end
                    cleaner.clean = function() end
                end).to.throw()

                expect(function()
                    cleaner.Uncleanable = 1
                end).to.throw()
            end)
        end)

        describe("clean", function()
            it("should clear the cleaner", function()
                local testInstance = Instance.new("Folder")
                local cleaner = createCleaner()
                cleaner.Test = testInstance

                cleaner:clean()
                expect(cleaner.Test).to.equal(nil)
            end)

            it("should destroy instances", function()
                local testParent = Instance.new("Folder")
                local testInstance = Instance.new("Folder")
                testInstance.Name = "Test"
                testInstance.Parent = testParent

                local cleaner = createCleaner()
                cleaner.Test = testInstance

                cleaner:clean()
                expect(testParent:FindFirstChild("Test")).to.equal(nil)
            end)

            it("should call functions", function()
                local callCount = 0

                local cleaner = createCleaner()
                cleaner.Test = function()
                    callCount = callCount + 1
                end

                cleaner:clean()
                expect(callCount).to.equal(1)
            end)

            it("should disconnect connections", function()
                local event = Instance.new("BindableEvent")
                local connection = event.Event:Connect(function()
                end)

                local cleaner = createCleaner()
                cleaner.Test = connection

                cleaner:clean()
                expect(connection.Connected).to.equal(false)
            end)

            it("should clean up cleaners", function()
                local innerCleanCalled = false

                local cleaner = createCleaner()
                local innerCleaner = createCleaner()
                innerCleaner.Test = function()
                    innerCleanCalled = true
                end

                cleaner.Cleaner = innerCleaner
                cleaner:clean()
                expect(innerCleanCalled).to.equal(true)
            end)

            local methods = { "destroy", "Destroy", "disconnect", "Disconnect" }
            for _, methodName in ipairs(methods) do
                it("should call " .. methodName .. " on tables with it", function()
                    local methodCalled = false
                    local cleaner = createCleaner()
                    cleaner.Test = {
                        [methodName] = function()
                            methodCalled = true
                        end,
                    }

                    cleaner:clean()
                    expect(methodCalled).to.equal(true)
                end)
            end
        end)
    end)
end