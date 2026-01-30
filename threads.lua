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
---@field start fun(self: Threads): boolean
---@field pause fun(self: Threads, id: number): boolean
---@field resume fun(self: Threads, id: number): boolean
---@field process fun(self: Threads): void
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

		self:start ();
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
	---@return boolean
	start = function (self)
		if (isTimer (self.timer)) then
			return false;
		end

		self.timer = setTimer (
			function ()
				self:process ();
			end, THREADS_PRIORITYS[self.priority].pulsing, 0
		);
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

		self:start ();
		return true;
	end,

	---@param self Threads
	---@return void
	process = function (self)
		local frames = 0;

		local activeThreads = false;
		---@param thread Thread
		for id, thread in pairs (self.threads) do
			if (frames >= THREADS_PRIORITYS[self.priority].frame) then
				activeThreads = true;

				break
			end

			local status = coroutine.status (thread.routine);
			if (status == 'dead') then
				self:remove (id);
			elseif (not thread.paused) then
				activeThreads = true;

				local success, error = coroutine.resume (thread.routine, unpack (thread.arguments));
				if (not success) then
					error ('[Threads] Thread ID ' .. id .. ' error: ' .. tostring (error));
					self:remove (id);
				else
					frames = (frames + 1);
				end
			else
				activeThreads = true;
			end
		end

		if (not activeThreads) and (isTimer (self.timer)) then
			killTimer (self.timer);
			self.timer = nil;
		end
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
		if (isTimer (self.timer)) then
			killTimer (self.timer);
		end

		self:start ();
		return true;
	end,
};