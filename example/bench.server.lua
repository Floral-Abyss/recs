local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GenerationalAllocator = require(ReplicatedStorage.RECS.GenerationalAllocator)
local GenerationalArray = require(ReplicatedStorage.RECS.GenerationalArray)

local BENCH_OUTPUT_FORMAT = [[
Benchmark %s:
    iterations: %d
    total time: %.12f
    average time: %.12f]]

local function benchmark(name, iterations, benchFunc)
    local startTick = tick()

    for i = 1, iterations do
        benchFunc(i)
    end

    local endTick = tick()
    local delta = endTick - startTick
    local averageTime = delta / iterations
    print(BENCH_OUTPUT_FORMAT:format(
        name,
        iterations,
        delta,
        averageTime
    ))
end

wait(1)
print("Starting benchmarking")

local iterations = 2500

do
    local allocator = GenerationalAllocator.new()
    local array = GenerationalArray.new()
    local indexes = {}

    benchmark("GenAllocator: alloc new", iterations, function()
        for _ = 1, iterations do
            table.insert(indexes, allocator:allocate())
        end
    end)

    wait(0)

    benchmark("GenArray: get (unallocated)", iterations, function(i)
        array:get(indexes[i])
    end)

    wait(0)

    benchmark("GenArray: set", iterations, function(i)
        array:set(indexes[i], i)
    end)

    wait(0)

    benchmark("GenArray: get (assigned)", iterations, function(i)
        array:get(indexes[i])
    end)

    wait(0)

    benchmark("GenArray: remove", iterations, function(i)
        array:remove(indexes[i])
    end)

    wait(0)

    benchmark("GenArray: get (cleared)", iterations, function(i)
        array:get(indexes[i])
    end)

    wait(0)

    benchmark("GenAllocator: free", iterations, function(i)
        allocator:free(indexes[i])
    end)
end

do
    local keys = {}

    for i = 1, iterations do
        keys[i] = HttpService:GenerateGUID()
    end

    local map = {}

    benchmark("Hashmap: get (nil)", iterations, function(i)
        local _ = map[keys[i]]
    end)

    benchmark("Hashmap: set", iterations, function(i)
        map[keys[i]] = i
    end)

    benchmark("Hashmap: get (set)", iterations, function(i)
        local _ = map[keys[i]]
    end)

    benchmark("Hashmap: clear", iterations, function(i)
        map[keys[i]] = nil
    end)
end

print("Benchmarks done")