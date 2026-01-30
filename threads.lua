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
---@field started boolean

---@class Threads
---@field threads table<number, Thread>
---@field nextId number
---@field currentId number
---@field type 'concurrent' | 'sequential'
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

		self.nextId, self.currentId = 0, -1;
		self.type, self.priority = 'concurrent', 'normal';

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
			started = false,
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

		if (self.currentId == id) then
			self.currentId = -1;
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

		local theType = self.type;
		if (theType == 'concurrent') then
			local activeThread = false;
			for id, thread in pairs (self.threads) do
				if (frames >= THREADS_PRIORITYS[self.priority].frame) then
					activeThread = true;
					break
				end

				local status = coroutine.status (thread.routine);
				if (status == 'dead') then
					self:remove (id);
				elseif (not thread.paused) then
					activeThread = true;

					local success, error;
					if (not thread.started) then
						success, error = coroutine.resume (thread.routine, unpack (thread.arguments));
						thread.started = true;
					else
						success, error = coroutine.resume (thread.routine);
					end

					if (not success) then
						error ('[Threads] Thread ID ' .. id .. ' error: ' .. tostring (error));
						self:remove (id);
					else
						frames = (frames + 1);
					end
				else
					activeThread = true;
				end
			end
		elseif (theType == 'sequential') then
			if (not self.threads[self.currentId]) then
				self.currentId = -1;
				
				for id, _ in pairs (self.threads) do
					self.currentId = id;
					break
				end
				
				if (self.currentId < 1) then
					if (isTimer (self.timer)) then
						killTimer (self.timer);
						self.timer = nil;
					end
					return
				end
			end

			---@type Thread
			local thread = self.threads[self.currentId];
			if (not thread) then
				self.currentId = -1;
				return
			end

			if (thread.paused) then
				return
			end

			while (frames < THREADS_PRIORITYS[self.priority].frame) do
				local status = coroutine.status (thread.routine);
				
				if (status == 'dead') then
					self:remove (self.currentId);
					break
				end

				local success, error;
				if (not thread.started) then
					success, error = coroutine.resume (thread.routine, unpack (thread.arguments));
					thread.started = true;
				else
					success, error = coroutine.resume (thread.routine);
				end

				if (not success) then
					error ('[Threads] Thread ID ' .. self.currentId .. ' error: ' .. tostring (error));
					self:remove (self.currentId);
					break
				end

				frames = (frames + 1);
				if (coroutine.status (thread.routine) == 'dead') then
					self:remove (self.currentId);
					break
				end
			end
		end
	end,

	---@param self Threads
	---@param style 'concurrent' | 'sequential'
	---@return boolean
	setType = function (self, style)
		local theType = type (style);
		if (theType ~= 'string') then
			return false;
		end

		local AVAILABLE_TYPES = {
			['concurrent'] = true,
			['sequential'] = true,
		};

		style = style:lower ();
		if (not AVAILABLE_TYPES[style]) or (self.type == style) then
			return false;
		end

		self.type = style;
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
		if (isTimer (self.timer)) then
			killTimer (self.timer);
		end

		self:start ();
		return true;
	end,
};