local defineRegistration = require(script.defineRegistration)

return {
    Core = require(script.Core),
    defineComponent = require(script.defineComponent),
    System = require(script.System),
    interval = defineRegistration.interval,
    event = defineRegistration.event,
}