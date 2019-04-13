local emptyIndexSymbol = {}

local GenerationalArray = {}

function GenerationalArray.new()
    local items = {}
    local generations = {}

    local self = {}

    function self:get(genIndex)
        local index = genIndex.index
        if generations[index] ~= genIndex.generation then
            return nil
        end

        local itemAt = items[index]

        if itemAt == emptyIndexSymbol then
            return nil
        else
            return itemAt
        end
    end

    function self:set(genIndex, value)
        local index = genIndex.index

        if index > #items then
            for i = #items, index do
                items[i] = emptyIndexSymbol
            end
        end

        local currentValue = items[index]

        if currentValue == emptyIndexSymbol then
            items[index] = value
            generations[index] = 0

            return nil, nil
        else
            local currentGeneration = generations[index]
            local oldValue = items[index]
            items[index] = value
            generations[index] = genIndex.generation

            return {
                index = index,
                generation = currentGeneration,
            }, oldValue
        end
    end

    function self:remove(genIndex)
        local index = genIndex.index
        local currentGeneration = generations[index]

        if currentGeneration == nil then
            return
        end

        if currentGeneration ~= genIndex.generation then
            return
        end

        if items[index] == emptyIndexSymbol then
            return
        end

        items[index] = emptyIndexSymbol
    end

    return self
end

return GenerationalArray