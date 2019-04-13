--[[

Implements generational indexing!

Typedefs:
GenerationalIndex {
    index: uint,
    generation: uint,
}

AllocatorEntry {
    generation: uint,
    live: bool,
}

ArrayEntry<T> {
    value: T,
    generation: uint,
}

]]

local GenerationalAllocator = {}
GenerationalAllocator.__index = GenerationalAllocator

function GenerationalAllocator.new()
    local self = setmetatable({
        -- array<AllocatorEntry>
        _entries = {},
        -- array<uint>
        -- used as a stack; append to end and remove from end to avoid shifting
        -- and hopefully avoiding reallocation as much as possible
        _free = {},
    }, GenerationalAllocator)

    return self
end

function GenerationalAllocator:allocate()
    local freeIndex = self._free[#self._free]

    if freeIndex ~= nil then
        table.remove(self._free, freeIndex)
        local existingEntry = self._entries[freeIndex]
        assert(not existingEntry.live)

        local allocatorEntry = {
            live = true,
            generation = existingEntry.generation + 1,
        }

        self._entries[freeIndex] = allocatorEntry
        return {
            index = freeIndex,
            generation = allocatorEntry.generation,
        }
    else
        local index = #self._entries + 1
        local allocatorEntry = {
            live = true,
            generation = 0,
        }

        self._entries[index] = allocatorEntry
        return {
            index = index,
            generation = 0,
        }
    end
end

function GenerationalAllocator:free(index)
    if index.index > #self._entries then
        return false
    end

    local storedEntry = self._entries[index.index]
    if not storedEntry.live then
        return false
    end

    storedEntry.live = false
    storedEntry.generation = storedEntry.generation + 1
    table.insert(self._free, index.index)
end

function GenerationalAllocator:isLive(index)
    if index.index > #self._entries then
        return false
    end

    local storedEntry = self._entries[index.index]
    return storedEntry.live and storedEntry.generation == index.generation
end

return GenerationalAllocator