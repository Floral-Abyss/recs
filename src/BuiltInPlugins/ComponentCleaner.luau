--!strict

local createCleaner = require(script.Parent.Parent.createCleaner)

--[[
	Plugin
]]

local componentCleaner = {}

function componentCleaner:componentAdded(core, entityId, componentInstance)
    componentInstance.maid = createCleaner()
end

function componentCleaner:componentRemoving(core, entityId, componentInstance)
    componentInstance.maid:clean()
    componentInstance.maid = nil
end

return componentCleaner
