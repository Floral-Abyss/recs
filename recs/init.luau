--!strict

local defineRegistration = require(script.defineRegistration)

return {
    Core = require(script.Core),
    createSignal = require(script.createSignal),
    createCleaner = require(script.createCleaner),
    defineComponent = require(script.defineComponent),
    defineRegistration = require(script.defineRegistration),
    System = require(script.System),
    BuiltInPlugins = require(script.BuiltInPlugins),
    TypeDefinitions = require(script.TypeDefinitions),
    interval = defineRegistration.interval,
    event = defineRegistration.event,
}
