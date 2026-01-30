---@param miliseconds number
---@return void
local function sleep (miliseconds)
	local current = getTickCount ();

	repeat
		coroutine.yield ();
	until (getTickCount () - current) >= miliseconds;
end

---@class Prioritys
---@field low { pulsing: number, frame: number }
---@field normal { pulsing: number, frame: number }
---@field high { pulsing: number, frame: number }
local THREADS_PRIORITYS = {
	low = { pulsing = 50, frame = 10 },
	normal = { pulsing = 100, frame = 20 },
	high = { pulsing = 200, frame = 40 },
};

---@class Thread
---@field routine thread
---@field arguments table<any>
---@field paused boolean

---@class Threads
---@field threads table<number, Thread>
---@field nextId number
---@field priority 'low' | 'normal' | 'high'
---@field timer userdata | nil
---@field add fun(self: Threads, func: fun(...: any): any, ...: any): number
---@field remove fun(self: Threads, id: number): boolean
---@field pause fun(self: Threads, id: number): boolean
---@field resume fun(self: Threads, id: number): boolean
---@field setPriority fun(self: Threads, priority: 'low' | 'normal' | 'high'): boolean
Threads = {
	---@param self Threads
	---@return Threads
	new = function ()
		local self = setmetatable ({ }, { __index = Threads });
		self.threads = { };

		self.nextId = 0;
		self.priority = 'normal';

		self.timer = nil;
		return self;
	end,

	---@param self Threads
	---@param func fun(...: any): any
	---@param ... any
	---@return number
	add = function (self, func, ...)
		---@type Thread
		local thread = {
			routine = coroutine.create (func),
			arguments = { ... },

			paused = false,
		};

		local newId = (self.nextId + 1);
		self.nextId = newId;

		self.threads[newId] = thread;
		return newId;
	end,

	---@param self Threads
	---@param id number
	---@return boolean
	remove = function (self, id)
		---@type Thread
		local thread = self.threads[id];
		if (not thread) then
			return false;
		end

		if (type (thread.routine) == 'thread') then
			coroutine.close (thread.routine);
		end

		self.threads[id] = nil;
		return true;
	end,

	---@param self Threads
	---@param id number
	---@return boolean
	pause = function (self, id)
		---@type Thread
		local thread = self.threads[id];
		if (not thread) then
			return false;
		end

		if (thread.paused) then
			return false;
		end

		thread.paused = true;
		return true;
	end,

	---@param self Threads
	---@param id number
	---@return boolean
	resume = function (self, id)
		---@type Thread
		local thread = self.threads[id];
		if (not thread) then
			return false;
		end

		if (not thread.paused) then
			return false;
		end

		thread.paused = false;
		return true;
	end,

	---@param self Threads
	---@param priority 'low' | 'normal' | 'high'
	---@return boolean
	setPriority = function (self, priority)
		local priorityType = type (priority);
		if (priorityType ~= 'string') then
			return false;
		end

		if (not THREADS_PRIORITYS[priority]) or (self.priority == priority) then
			return false;
		end

		self.priority = priority;
		return true;
	end,
};