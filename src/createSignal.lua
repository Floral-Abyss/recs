local function createSignal()
    local listeners = {}
    local signal = {}

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

    local function fire(...)
        for listener, _ in pairs(listeners) do
            coroutine.wrap(listener)(...)
        end
    end

    return signal, fire
end

return createSignal