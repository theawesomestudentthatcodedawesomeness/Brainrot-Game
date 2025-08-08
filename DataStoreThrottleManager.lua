-- DataStoreThrottleManager.lua - Handles all DataStore operations with proper throttling
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataStoreThrottleManager = {}

-- Throttling configuration
local CONFIG = {
	MAX_REQUESTS_PER_MINUTE = 60, -- Conservative limit
	BATCH_SAVE_INTERVAL = 10, -- seconds
	MAX_RETRIES = 3,
	RETRY_DELAY = 2, -- seconds
}

-- Request tracking
local requestQueue = {}
local requestTimestamps = {}
local batchSaveQueue = {}
local isProcessing = false

-- Helper: Clean old timestamps
local function cleanOldTimestamps()
	local now = os.time()
	for i = #requestTimestamps, 1, -1 do
		if now - requestTimestamps[i] >= 60 then
			table.remove(requestTimestamps, i)
		else
			break -- timestamps are ordered, so we can stop here
		end
	end
end

-- Helper: Check if we can make a request
local function canMakeRequest()
	cleanOldTimestamps()
	return #requestTimestamps < CONFIG.MAX_REQUESTS_PER_MINUTE
end

-- Helper: Record a request
local function recordRequest()
	table.insert(requestTimestamps, os.time())
end

-- Safe DataStore call with throttling
function DataStoreThrottleManager.SafeCall(operation, ...)
	local args = {...}

	-- Wait if we're over the limit
	while not canMakeRequest() do
		warn("DataStore throttling: Waiting before making request...")
		wait(1)
	end

	-- Record the request
	recordRequest()

	-- Try the operation with retries
	for attempt = 1, CONFIG.MAX_RETRIES do
		local success, result = pcall(operation, unpack(args))

		if success then
			return true, result
		else
			warn(string.format("DataStore operation failed (attempt %d/%d): %s", 
				attempt, CONFIG.MAX_RETRIES, tostring(result)))

			if attempt < CONFIG.MAX_RETRIES then
				wait(CONFIG.RETRY_DELAY * attempt) -- Exponential backoff
			end
		end
	end

	return false, "All retries failed"
end

-- Batched save system
function DataStoreThrottleManager.QueueBatchSave(dataStore, key, data)
	if not batchSaveQueue[dataStore] then
		batchSaveQueue[dataStore] = {}
	end

	batchSaveQueue[dataStore][key] = {
		data = data,
		timestamp = os.time()
	}
end

-- Process batch saves
local function processBatchSaves()
	if isProcessing then return end
	isProcessing = true

	for dataStore, saves in pairs(batchSaveQueue) do
		for key, saveData in pairs(saves) do
			if canMakeRequest() then
				spawn(function()
					local success, result = DataStoreThrottleManager.SafeCall(function()
						return dataStore:SetAsync(key, saveData.data)
					end)

					if success then
						batchSaveQueue[dataStore][key] = nil
						print("? Batch saved:", key)
					else
						warn("? Batch save failed:", key)
					end
				end)
			else
				break -- Stop if we hit the rate limit
			end
		end
	end

	isProcessing = false
end

-- Start batch save processor
spawn(function()
	while true do
		wait(CONFIG.BATCH_SAVE_INTERVAL)
		processBatchSaves()
	end
end)

return DataStoreThrottleManager