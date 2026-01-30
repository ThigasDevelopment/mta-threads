# MTA Async Task Manager

A lightweight **coroutine-based async task system** for MTA:SA servers. Distribute heavy workloads across multiple frames without blocking the server using **cooperative multitasking**.

> **⚠️ Important:** This is **not true multithreading** or parallel execution. It uses Lua coroutines for cooperative task scheduling - only one task executes at a time, but control is yielded between tasks to prevent server freezing.

## What This Is

- ✅ **Coroutine-based**: Uses Lua's `coroutine` API for cooperative multitasking
- ✅ **Async execution**: Tasks yield control and resume later (not parallel)
- ✅ **Frame distribution**: Spreads heavy work across multiple server ticks
- ✅ **Non-blocking**: Prevents server lag by breaking up long operations

## What This Is NOT

- ❌ **Not real threads**: No parallel execution or CPU core utilization
- ❌ **Not simultaneous**: Only one task executes at any given moment
- ❌ **Not preemptive**: Tasks must manually yield control (cooperative)

## Features

- ✅ **Two execution modes**: Concurrent (interleaved) and Sequential (queue-based)
- ✅ **Priority system**: Low, Normal, High with configurable performance profiles
- ✅ **Task control**: Pause, resume, and remove tasks dynamically
- ✅ **Simple API**: Easy to use with coroutines and sleep helpers
- ✅ **Error handling**: Automatic error catching and cleanup

## Installation

1. Copy the `mta-threads` folder to your MTA server resources
2. Add `<script src="threads.lua" type="shared"/>` to your meta.xml
3. Start using threads in your code!

## Basic Usage

### Creating a Task Manager

```lua
-- Create with defaults (concurrent mode, normal priority)
local tasks = Threads.new();

-- Or specify mode and priority
local tasks = Threads.new('sequential', 'high');
```

### Adding Tasks

```lua
tasks:add(function(self)
    for i = 1, 100 do
        print('Processing item ' .. i);
        coroutine.yield(); -- Yield control cooperatively
    end
end);
```

## Execution Modes

### Concurrent Mode (Default)

Multiple tasks execute **interleaved** - tasks appear to progress simultaneously by switching between them cooperatively (not parallel!).

```lua
local tasks = Threads.new('concurrent', 'normal');

tasks:add(function(self)
    for i = 1, 5 do
        print('[Task A] Step ' .. i);
        sleep(500);
    end
end);

tasks:add(function(self)
    for i = 1, 5 do
        print('[Task B] Step ' .. i);
        sleep(500);
    end
end);

-- Output (interleaved, not parallel):
-- [Task A] Step 1
-- [Task B] Step 1
-- [Task A] Step 2
-- [Task B] Step 2
-- ...
```

### Sequential Mode

Tasks execute **one at a time** (FIFO queue) - each task completes before the next starts.

```lua
local tasks = Threads.new('sequential', 'normal');

tasks:add(function(self)
    for i = 1, 5 do
        print('[Task A] Step ' .. i);
        sleep(500);
    end
end);

tasks:add(function(self)
    for i = 1, 5 do
        print('[Task B] Step ' .. i);
        sleep(500);
    end
end);

-- Output (sequential):
-- [Task A] Step 1
-- [Task A] Step 2
-- [Task A] Step 3
-- [Task A] Step 4
-- [Task A] Step 5
-- [Task B] Step 1
-- [Task B] Step 2
-- ...
```

## Priority System

Priorities control how often tasks are processed and how many yields per tick.

| Priority | Tick Rate | Max Frames/Tick | Best For |
|----------|-----------|-----------------|----------|
| **low** | 250ms | 8 | Background tasks, logs, cleanup |
| **normal** | 100ms | 15 | General processing, queries |
| **high** | 50ms | 25 | UI updates, animations, player interactions |
| **extreme** | 0ms (every frame) | 50 | Client-side rendering, critical real-time tasks |

**Note:** These values are optimized for MTA servers. Use `extreme` with caution as it processes every frame.

```lua
local bgTasks = Threads.new('sequential', 'low');
local mainTasks = Threads.new('concurrent', 'normal');
local uiTasks = Threads.new('concurrent', 'high');
local renderTasks = Threads.new('concurrent', 'extreme'); -- For onClientRender replacement
```

## Real-World Examples

### Example 1: Database Query Processing

```lua
local dbThreads = Threads.new('sequential', 'normal');

-- Process multiple database queries without blocking
dbThreads:add(function(self)
    local players = getElementsByType('player');
    
    for i, player in ipairs(players) do
        local account = getAccountName (getPlayerAccount(player));
        dbExec(db, "UPDATE players SET lastSeen=NOW() WHERE account=?", account);
        coroutine.yield(); -- Don't block server
    end
    
    print('Database update complete!');
end);
```

### Example 2: Map Object Loading

```lua
local mapLoader = Threads.new('sequential', 'low');

mapLoader:add(function(self)
    local objects = {
        {model = 1337, x = 0, y = 0, z = 3},
        {model = 1338, x = 10, y = 10, z = 3},
        -- ... thousands of objects
    };
    
    for i, obj in ipairs(objects) do
        createObject(obj.model, obj.x, obj.y, obj.z);
        
        -- Yield every 10 objects to prevent lag
        if i % 10 == 0 then
            coroutine.yield();
        end
    end
    
    print('Map loaded: ' .. #objects .. ' objects');
end);
```

### Example 3: NPC AI Updates

```lua
local aiThreads = Threads.new('concurrent', 'normal');

-- Each NPC runs in its own thread
for _, npc in ipairs(npcs) do
    aiThreads:add(function(self)
        while isElement(npc) do
            -- Update NPC behavior
            updateNPCPath(npc);
            checkNearbyPlayers(npc);
            
            sleep(1000); -- Update every second
        end
    end);
end
```

### Example 4: Timed Events

```lua
local events = Threads.new('concurrent', 'high');

events:add(function(self)
    for i = 10, 1, -1 do
        outputChatBox('Event starts in ' .. i .. ' seconds!', root, 255, 255, 0);
        sleep(1000);
    end
    
    outputChatBox('Event started!', root, 0, 255, 0);
    startEvent();
end);
```

### Example 5: Resource-Intensive Calculations

```lua
local calcThreads = Threads.new('sequential', 'low');

calcThreads:add(function(self)
    local total = 0;
    
    for i = 1, 1000000 do
        total = total + math.sqrt(i);
        
        -- Yield every 1000 iterations
        if i % 1000 == 0 then
            coroutine.yield();
        end
    end
    
    print('Calculation complete: ' .. total);
end);
```

### Example 6: Animated Sequence

```lua
local animation = Threads.new('sequential', 'high');

animation:add(function(self)
    local ped = createPed(0, 0, 0, 3);
    
    -- Play animation sequence
    setPedAnimation(ped, 'ped', 'WOMAN_walknorm');
    sleep(2000);
    
    setPedAnimation(ped, 'ped', 'WOMAN_run');
    sleep(3000);
    
    setPedAnimation(ped, 'ped', 'WOMAN_idle');
    sleep(1000);
    
    destroyElement(ped);
end);
```

### Example 7: Batch Player Updates

```lua
local playerUpdates = Threads.new('concurrent', 'normal');

playerUpdates:add(function(self)
    while true do
        for _, player in ipairs(getElementsByType('player')) do
            updatePlayerStats(player);
            syncPlayerData(player);
            coroutine.yield();
        end
        
        sleep(5000); -- Repeat every 5 seconds
    end
end);
```

### Example 8: Client-Side Rendering Task (onClientRender)

```lua
-- Client-side: Replace onClientRender with task-based approach
local renderTasks = Threads.new('concurrent', 'extreme');

-- Instead of:
-- addEventHandler('onClientRender', root, function()
--     drawMyHUD();
--     updateAnimations();
-- end);

-- Use tasks for better control:
renderTasks:add(function(self)
    while true do
        -- Draw HUD elements
        dxDrawText('Health: ' .. getElementHealth(localPlayer), 10, 10);
        dxDrawText('Position: ' .. string.format ('%.3f, %.3f, %.3f', getElementPosition(localPlayer)), 10, 30);
        
        sleep (0); -- Yield every frame
    end
end);

renderTasks:add(function(self)
    local alpha = 0;
    local increasing = true;
    
    while true do
        -- Animated fade effect
        dxDrawRectangle(100, 100, 200, 50, tocolor(255, 255, 255, alpha));
        
        if increasing then
            alpha = alpha + 5;
            if alpha >= 255 then
                increasing = false;
            end
        else
            alpha = alpha - 5;
            if alpha <= 0 then
                increasing = true;
            end
        end
        
        sleep (0); -- Yield every frame
    end
end);

-- Benefits:
-- ✓ Can pause/resume individual render tasks
-- ✓ Better organization than one large onClientRender
-- ✓ Each visual element is independent
-- ✓ Easy to add/remove render tasks dynamically
-- ✓ 'extreme' priority processes every frame (0ms delay)
```

## Thread Control

### Pausing and Resuming

```lua
local threadID = threads:add(function(self)
    for i = 1, 100 do
        print('Step ' .. i);
        sleep(100);
    end
end);

-- Pause thread
threads:pause(threadID);

-- Resume later
threads:resume(threadID);
```

### Removing Threads

```lua
local threadID = threads:add(function(self)
    -- Long running task
end);

-- Remove thread if no longer needed
threads:remove(threadID);
```

### Changing Priority at Runtime

```lua
local threads = Threads.new('concurrent', 'normal');

-- Start some threads...

-- Switch to high priority for faster processing
threads:setPriority('high');
```

### Switching Execution Mode

```lua
local threads = Threads.new('concurrent');

-- Switch to sequential mode
threads:setType('sequential');
```

## Sleep Helper

The `sleep(ms)` function pauses execution for a specified time.

```lua
threads:add(function(self)
    print('Starting...');
    sleep(1000); -- Wait 1 second
    print('One second later...');
    sleep(2000); -- Wait 2 seconds
    print('Done!');
end);
```

**Note:** Always use `sleep()` or `coroutine.yield()` inside loops to prevent server lag!

## Best Practices

### ✅ DO

- **Use `coroutine.yield()` or `sleep()` in loops** to prevent blocking
- **Choose appropriate priority** for your use case
- **Use sequential mode** for tasks that must complete in order
- **Use concurrent mode** for independent parallel tasks
- **Yield frequently** in heavy computations

### ❌ DON'T

- **Forget to yield** in long loops (will freeze server!)
- **Use high/extreme priority** for non-critical background tasks
- **Overuse extreme priority** (processes every frame, high CPU usage)
- **Create thousands of threads** simultaneously (use batching)
- **Rely on thread execution order** in concurrent mode

## Performance Tips

1. **Batch operations**: Group related work together
2. **Adjust frame limits**: Lower if causing stutters, higher for faster completion
3. **Profile your threads**: Monitor with frame counters
4. **Clean up properly**: Remove threads when elements are destroyed

## API Reference

### Constructor

#### `Threads.new([type], [priority])`

Creates a new task manager instance.

**Parameters:**
- `type` (string, optional): Execution mode
  - `'concurrent'` - Tasks execute interleaved (default)
  - `'sequential'` - Tasks execute one at a time (queue)
- `priority` (string, optional): Performance profile
  - `'low'` - 250ms ticks, 8 frames/tick
  - `'normal'` - 100ms ticks, 15 frames/tick (default)
  - `'high'` - 50ms ticks, 25 frames/tick
  - `'extreme'` - 0ms ticks (every frame), 50 frames/tick

**Returns:** `Threads` instance

**Example:**
```lua
local tasks = Threads.new('sequential', 'high');
local renderTasks = Threads.new('concurrent', 'extreme'); -- For rendering
```

---

### Task Management

#### `tasks:add(func, ...)`

Adds a new task to the manager.

**Parameters:**
- `func` (function): Task function to execute
  - First parameter is always `self` (the Threads instance)
  - Must call `coroutine.yield()` or `sleep()` to cooperate
- `...` (any): Additional arguments passed to the function

**Returns:** `number` - Unique task ID

**Example:**
```lua
local taskID = tasks:add(function(self, name, value)
    for i = 1, 100 do
        print(name, value, i);
        coroutine.yield();
    end
end, "MyTask", 42);
```

---

#### `tasks:remove(id)`

Removes a task from the manager.

**Parameters:**
- `id` (number): Task ID returned by `add()`

**Returns:** `boolean` - `true` if removed, `false` if not found

**Example:**
```lua
local id = tasks:add(myFunction);
tasks:remove(id); -- Remove task
```

---

### Task Control

#### `tasks:pause(id)`

Pauses a running task.

**Parameters:**
- `id` (number): Task ID to pause

**Returns:** `boolean` - `true` if paused, `false` if not found or already paused

**Example:**
```lua
tasks:pause(taskID);
-- Task stops executing but remains in queue
```

---

#### `tasks:resume(id)`

Resumes a paused task.

**Parameters:**
- `id` (number): Task ID to resume

**Returns:** `boolean` - `true` if resumed, `false` if not found or not paused

**Example:**
```lua
tasks:resume(taskID);
-- Task continues from where it yielded
```

---

### Configuration

#### `tasks:setType(type)`

Changes the execution mode at runtime.

**Parameters:**
- `type` (string): Execution mode
  - `'concurrent'` - Switch to interleaved execution
  - `'sequential'` - Switch to queue-based execution

**Returns:** `boolean` - `true` if changed, `false` if invalid or same as current

**Example:**
```lua
tasks:setType('sequential');
```

---

#### `tasks:getType()`

Gets the current execution mode.

**Returns:** `string` - `'concurrent'` or `'sequential'`

**Example:**
```lua
local mode = tasks:getType();
print('Current mode: ' .. mode);
```

---

#### `tasks:setPriority(priority)`

Changes the priority level at runtime.

**Parameters:**
- `priority` (string): Performance profile
  - `'low'` - Less frequent, fewer frames
  - `'normal'` - Balanced
  - `'high'` - More frequent, more frames
  - `'extreme'` - Every frame, maximum frames

**Returns:** `boolean` - `true` if changed, `false` if invalid or same as current

**Note:** Automatically restarts the internal timer with new settings.

**Example:**
```lua
tasks:setPriority('high');
tasks:setPriority('extreme'); -- For client-side rendering
```

---

#### `tasks:getPriority()`

Gets the current priority level.

**Returns:** `string` - `'low'`, `'normal'`, `'high'`, or `'extreme'`

**Example:**
```lua
local priority = tasks:getPriority();
print('Current priority: ' .. priority);
```

---

#### `tasks:clear()`

Removes all tasks and stops the timer.

**Returns:** `boolean` - `true` if tasks were cleared, `false` if already empty

**Example:**
```lua
tasks:clear(); -- Remove all tasks
```

---

### Global Functions

#### `sleep(milliseconds)`

Pauses task execution for a specified duration or yields immediately.

**Parameters:**
- `milliseconds` (number): Time to sleep in milliseconds
  - If `< 1` or invalid: performs a single `yield()` and returns immediately
  - If `>= 1`: yields repeatedly until the specified time has elapsed

**Returns:** `void`

**Behavior:**
- `sleep(0)` or `sleep()` - Single yield, continues on next tick
- `sleep(100)` - Yields until 100ms have passed
- `sleep(-5)` - Same as `sleep(0)`, single yield
- `sleep("invalid")` - Same as `sleep(0)`, single yield

**Note:** Must be called from within a task function. Uses `getTickCount()` internally.

**Examples:**
```lua
-- Time-based sleep
tasks:add(function(self)
    print('Start');
    sleep(1000); -- Wait 1 second
    print('After 1 second');
    sleep(500);  -- Wait 0.5 seconds
    print('Done');
end);

-- Frame-based yield (for rendering tasks)
tasks:add(function(self)
    while true do
        dxDrawText('FPS: ' .. getFPS(), 10, 10);
        sleep(0); -- Yield every frame (equivalent to coroutine.yield())
    end
end);

-- Processing with periodic yields
tasks:add(function(self)
    for i = 1, 10000 do
        processItem(i);
        if i % 100 == 0 then
            sleep(0); -- Yield every 100 items
        end
    end
end);
```

---

### Internal Methods

#### `tasks:start()`

Starts the internal timer (automatically called by `add()`).

**Returns:** `boolean` - `false` if timer already running

---

#### `tasks:process()`

Internal method that processes tasks (called by timer).

**Do not call manually** - used internally by the timer system.

## License

MIT License - Free to use and modify.

## Credits

Created by dracoN* - Feel free to contribute or report issues!