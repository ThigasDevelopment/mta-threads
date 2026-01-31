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

- ✅ **Three execution modes**: Concurrent (interleaved), Sequential (queue-based), and Priority-based
- ✅ **Priority system**: Low, Normal, High, Extreme with configurable performance profiles
- ✅ **Per-thread priority**: Assign individual priorities (1-10) to threads in priority mode
- ✅ **Dynamic priority adjustment**: Change thread priorities at runtime via `thread:set()`
- ✅ **Direct thread access**: Get thread objects with `getThread()` for fine-grained control
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

### Priority Mode ⭐ NEW

Tasks execute based on **individual priority levels** (1-10) - higher priority threads execute first.

```lua
local tasks = Threads.new('priority', 'normal');

-- Low priority: Background tasks (priority 2)
tasks:add(function(self)
    for i = 1, 5 do
        print('[Background] Processing ' .. i);
        sleep(100);
    end
end, {priority = 2});

-- Medium priority: Game logic (priority 5)
tasks:add(function(self)
    for i = 1, 5 do
        print('[Logic] Update ' .. i);
        sleep(100);
    end
end, {priority = 5});

-- High priority: Combat/Critical systems (priority 10)
tasks:add(function(self)
    for i = 1, 5 do
        print('[Critical] Health update ' .. i);
        sleep(100);
    end
end, {priority = 10});

-- Output (priority-based execution):
-- [Critical] Health update 1
-- [Critical] Health update 2
-- [Critical] Health update 3
-- [Critical] Health update 4
-- [Critical] Health update 5
-- [Logic] Update 1
-- [Logic] Update 2
-- ...
-- [Background] Processing 1
-- ...
```

**When to use Priority Mode:**
- ✅ Critical systems (player health, combat) need faster execution
- ✅ Mix of important and background tasks
- ✅ Want fine control over execution order
- ✅ Performance-sensitive applications

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

### Example 9: Priority-Based Combat System ⭐

```lua
local gameThreads = Threads.new('priority', 'normal');

-- CRITICAL: Player health updates (priority 10)
gameThreads:add(function(self)
    while true do
        for _, player in ipairs(getElementsByType('player')) do
            updatePlayerHealth(player);
            checkPlayerStatus(player);
        end
        sleep(50); -- Update every 50ms
    end
end, {priority = 10});

-- HIGH: Combat calculations (priority 8)
gameThreads:add(function(self)
    while true do
        processCombatActions();
        calculateDamage();
        sleep(100);
    end
end, {priority = 8});

-- MEDIUM: NPC AI updates (priority 5)
gameThreads:add(function(self)
    while true do
        for _, npc in ipairs(npcs) do
            updateNPCBehavior(npc);
            coroutine.yield();
        end
        sleep(200);
    end
end, {priority = 5});

-- LOW: Visual effects and particles (priority 2)
gameThreads:add(function(self)
    while true do
        updateParticleEffects();
        cleanupOldEffects();
        sleep(500);
    end
end, {priority = 2});

-- Benefits:
-- ✓ Critical systems (health) always execute first
-- ✓ Combat has higher priority than AI
-- ✓ Visual effects don't interfere with gameplay
-- ✓ Predictable execution order
```

### Example 10: Dynamic Priority Adjustment

```lua
local tasks = Threads.new('priority', 'normal');

-- Start with normal priority
local renderTaskID = tasks:add(function(self)
    while true do
        renderUI();
        sleep(16); -- ~60 FPS
    end
end, {priority = 5});

-- Increase priority during combat
addEventHandler('onPlayerDamage', root, function()
    local thread = tasks:getThread(renderTaskID);
    if thread then
        thread:set(9); -- Boost to high priority
    end
end);

-- Return to normal after combat ends
addEventHandler('onCombatEnd', root, function()
    local thread = tasks:getThread(renderTaskID);
    if thread then
        thread:set(5); -- Back to medium
    end
end);
```

### Example 11: Client-Side Rendering Task (onClientRender)

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
  - `'priority'` - Tasks execute based on individual priority levels
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
local gameLogic = Threads.new('priority', 'normal'); -- For priority-based execution
```

---

### Task Management

#### `tasks:add(func, [options], ...)`

Adds a new task to the manager.

**Parameters:**
- `func` (function): Task function to execute
  - First parameter is always `self` (the Threads instance)
  - Must call `coroutine.yield()` or `sleep()` to cooperate
- `options` (table, optional): Configuration options (only for 'priority' mode)
  - `priority` (number): Thread priority level (1-10, default: 5)
    - Higher values = higher priority
    - Only applies when execution mode is `'priority'`
- `...` (any): Additional arguments passed to the function

**Returns:** `number` - Unique task ID

**Examples:**
```lua
-- Basic usage (concurrent/sequential modes)
local taskID = tasks:add(function(self, name, value)
    for i = 1, 100 do
        print(name, value, i);
        coroutine.yield();
    end
end, "MyTask", 42);

-- With priority (priority mode only)
local criticalTask = tasks:add(function(self)
    -- Critical game logic
    updatePlayerHealth();
    sleep(50);
end, {priority = 10}); -- Highest priority

local backgroundTask = tasks:add(function(self)
    -- Background processing
    cleanupOldData();
    sleep(1000);
end, {priority = 2}); -- Low priority

-- With priority AND arguments
local taskID = tasks:add(function(self, playerName, data)
    print("Processing:", playerName, data);
    sleep(100);
end, {priority = 7}, "John", {score = 100});
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
  - `'priority'` - Switch to priority-based execution

**Returns:** `boolean` - `true` if changed, `false` if invalid or same as current

**Example:**
```lua
tasks:setType('sequential');
tasks:setType('priority'); -- Switch to priority mode
```

---

#### `tasks:getType()`

Gets the current execution mode.

**Returns:** `string` - `'concurrent'`, `'sequential'`, or `'priority'`

**Example:**
```lua
local mode = tasks:getType();
print('Current mode: ' .. mode);
```

---

#### `tasks:getThread(id)` ⭐

Gets a thread object by its ID, allowing direct access to thread methods.

**Parameters:**
- `id` (number): Task ID returned by `add()`

**Returns:** `Thread | nil` - Thread object or `nil` if not found

**Thread Methods:**
- `thread:get()` - Get thread priority (1-10)
- `thread:set(priority)` - Set thread priority (1-10)

**Note:** Thread methods are primarily useful in `'priority'` mode.

**Examples:**
```lua
local taskID = tasks:add(myFunction, {priority = 5});

-- Get the thread object
local thread = tasks:getThread(taskID);

if thread then
    -- Get current priority
    local currentPriority = thread:get();
    print('Current priority:', currentPriority); -- 5
    
    -- Change priority
    thread:set(9); -- Increase to high priority
    print('New priority:', thread:get()); -- 9
    
    -- Lower priority
    thread:set(2);
else
    print('Thread not found');
end
```

**Practical Usage:**
```lua
-- Dynamic priority adjustment
local renderTask = tasks:add(renderFunction, {priority = 5});

addEventHandler('onPlayerDamage', root, function()
    -- Boost render priority during combat
    local thread = tasks:getThread(renderTask);
    if thread then thread:set(10); end
end);

addEventHandler('onCombatEnd', root, function()
    -- Return to normal priority
    local thread = tasks:getThread(renderTask);
    if thread then thread:set(5); end
end);
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

## Thread Class Reference

The `Thread` class represents an individual task/coroutine within the thread manager. Thread objects are obtained via `tasks:getThread(id)` and provide methods for priority management.

### Thread Properties

Thread objects contain the following internal properties (read-only, for informational purposes):

| Property | Type | Description |
|----------|------|-------------|
| `routine` | coroutine | The Lua coroutine object |
| `arguments` | table | Arguments passed to the thread function |
| `paused` | boolean | Whether the thread is currently paused |
| `started` | boolean | Whether the thread has begun execution |
| `priority` | number | Thread priority level (1-10, used in 'priority' mode) |

**Note:** These properties should not be accessed directly. Use thread methods instead.

---

### Thread Methods

#### `thread:get()`

Gets the priority level of the thread.

**Parameters:** None

**Returns:** `number` - Priority level (1-10)
- Higher values = higher priority
- Only meaningful in `'priority'` execution mode

**Example:**
```lua
local taskID = tasks:add(myFunction, {priority = 7});
local thread = tasks:getThread(taskID);

if thread then
    local priority = thread:get();
    print('Thread priority:', priority); -- 7
end
```

---

#### `thread:set(priority)`

Sets the priority level of the thread at runtime.

**Parameters:**
- `priority` (number): New priority level (1-10)
  - 1 = Lowest priority (background tasks)
  - 5 = Medium priority (default)
  - 10 = Highest priority (critical systems)

**Returns:** `boolean` 
- `true` if priority was changed
- `false` if invalid priority or unchanged

**Note:** Priority changes take effect immediately in `'priority'` mode. In other modes, priority is stored but not used.

**Examples:**
```lua
local taskID = tasks:add(updateFunction, {priority = 5});
local thread = tasks:getThread(taskID);

-- Increase priority during critical moment
if thread then
    thread:set(10); -- Boost to maximum
end

-- Later, return to normal
if thread then
    local success = thread:set(5);
    if success then
        print('Priority changed to 5');
    end
end
```

**Practical Example - Dynamic Priority:**
```lua
-- Create a rendering task with medium priority
local renderID = tasks:add(function(self)
    while true do
        drawCustomUI();
        sleep(16);
    end
end, {priority = 5});

-- Boost priority during combat
addEventHandler('onClientRender', root, function()
    if isPlayerInCombat() then
        local thread = tasks:getThread(renderID);
        if thread and thread:get() ~= 10 then
            thread:set(10); -- Critical priority
        end
    else
        local thread = tasks:getThread(renderID);
        if thread and thread:get() ~= 5 then
            thread:set(5); -- Normal priority
        end
    end
end);
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