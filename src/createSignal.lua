local function createSignal()
    local listeners = {}
    local signal = {}

    -- luacheck: push ignore 212
    function signal:Connect(listener)
        listeners[listener] = true

        local connection = {
            Connected = true,
        }

        function connection.Disconnect()
            connection.Connected = false
            listeners[listener] = nil
        end

        connection.disconnect = connection.Disconnect
        return connection
    end
    signal.connect = signal.Connect

    function signal:Fire(...)
        for listener, _ in pairs(listeners) do
            coroutine.wrap(listener)(...)
        end
    end
    -- luacheck: pop
    signal.fire = signal.Fire

    return signal
end

return createSignal