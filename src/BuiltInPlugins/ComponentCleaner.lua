--!strict

local createCleaner = require(script.Parent.Parent.createCleaner)

--[[
	Plugin
]]

local componentCleaner = {}

function componentCleaner:componentAdded(core, entityId, componentInstance)
	componentInstance._cleaner = createCleaner()
end

function componentCleaner:componentRemoving(core, entityId, componentInstance)
	componentInstance._cleaner:clean()
	componentInstance._cleaner = nil
end

return componentCleaner
