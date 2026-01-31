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
- ✅ **Priority system**: Low, Normal, High, Extreme manager priorities with configurable performance profiles
- ✅ **Per-thread priority**: Assign individual priorities (1-10) to threads in priority mode
- ✅ **Object-oriented thread control**: Direct thread access via `getThread()` for fine-grained control
- ✅ **Thread methods**: Control threads with `thread:pause()`, `thread:resume()`, `thread:set()`, etc.
- ✅ **Dynamic priority adjustment**: Change thread priorities at runtime via `thread:set(priority)`
- ✅ **Task management**: Add, remove, pause, and resume tasks dynamically
- ✅ **Simple API**: Easy to use with coroutines and sleep helpers
- ✅ **Error handling**: Automatic error catching and cleanup
- ✅ **Backward compatibility**: Legacy `tasks:pause(id)` methods still work

## Installation

1. Copy the `mta-threads` folder to your MTA server resources
2. Add `<script src="threads.lua" type="shared"/>` to your meta.xml
3. Start using threads in your code!

## Basic Usage

### Quick Start

```lua
-- 1. Create a task manager
local tasks = Threads.new('concurrent', 'normal');

-- 2. Add a task
local taskID = tasks:add(function(self)
    for i = 1, 100 do
        print('Processing ' .. i);
        sleep(100); -- Yield control
    end
end, {priority = 5}); -- Optional: only used in 'priority' mode

-- 3. Control the thread
local thread = tasks:getThread(taskID);
if thread then
    thread:pause();     -- Pause execution
    thread:resume();    -- Resume execution
    thread:set(10);     -- Change priority
    print(thread:get()); -- Get priority
end
```

### Creating a Task Manager

```lua
-- Create with defaults (concurrent mode, normal priority)
local tasks = Threads.new();

-- Or specify mode and priority
local tasks = Threads.new('sequential', 'high');
```

### Adding Tasks

```lua
-- Basic task
tasks:add(function(self)
    for i = 1, 100 do
        print('Processing item ' .. i);
        coroutine.yield(); -- Yield control cooperatively
    end
end);

-- Task with priority (ONLY works in 'priority' mode)
tasks:add(function(self)
    print('High priority task');
    sleep(100);
end, {priority = 10}); -- Ignored in 'concurrent' and 'sequential' modes
```

**Important:** The `{priority = N}` option only affects execution order when the manager's type is `'priority'`. In `'concurrent'` and `'sequential'` modes, this value is stored but not used for scheduling.

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

**Important:** Thread priorities (set via `{priority = N}`) are **ONLY used** in this mode. In other modes, all threads are treated equally.

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

### Example 8: Pausable Task

```lua
local tasks = Threads.new('concurrent', 'normal');

local taskID = tasks:add(function(self)
    for i = 1, 100 do
        print('Processing:', i);
        sleep(100);
    end
end);

-- Pause on player command
addCommandHandler('pausetask', function()
    local thread = tasks:getThread(taskID);
    if thread then
        if thread:isPaused() then
            thread:resume();
            outputChatBox('Task resumed!');
        else
            thread:pause();
            outputChatBox('Task paused!');
        end
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

### Getting Thread Object

```lua
local threadID = tasks:add(function(self)
    for i = 1, 100 do
        print('Step ' .. i);
        sleep(100);
    end
end, {priority = 5});

-- Get the thread object
local thread = tasks:getThread(threadID);
```

### Pausing and Resuming

```lua
-- Get thread object
local thread = tasks:getThread(threadID);

if thread then
    -- Pause thread
    thread:pause();
    
    -- Resume later
    thread:resume();
    
    -- Check if paused
    if thread:isPaused() then
        print('Thread is paused');
    end
end

-- Alternative: Use Threads methods (compatibility)
tasks:pause(threadID);
tasks:resume(threadID);
```

### Changing Thread Priority

```lua
local thread = tasks:getThread(threadID);

if thread then
    -- Get current priority
    local currentPriority = thread:get();
    print('Priority:', currentPriority);
    
    -- Change priority
    thread:set(10); -- Set to maximum
end
```

### Removing Threads

```lua
-- Remove thread if no longer needed
tasks:remove(threadID);
```

### Changing Manager Priority

```lua
local threads = Threads.new('concurrent', 'normal');

-- Switch to high priority for faster processing
threads:setPriority('high');
```

### Switching Execution Mode

```lua
local threads = Threads.new('concurrent');

-- Switch to sequential mode
threads:setType('sequential');

-- Switch to priority mode
threads:setType('priority');
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
- **Use thread methods directly** via `getThread()` for cleaner code
- **Choose appropriate priority** for your use case (manager and thread priorities)
- **Use sequential mode** for tasks that must complete in order
- **Use concurrent mode** for independent tasks
- **Use priority mode** when you need fine control over execution order
- **Yield frequently** in heavy computations

### ❌ DON'T

- **Forget to yield** in long loops (will freeze server!)
- **Use high/extreme manager priority** for non-critical background tasks
- **Overuse extreme priority** (processes every frame, high CPU usage)
- **Create thousands of threads** simultaneously (use batching)
- **Rely on thread execution order** in concurrent mode
- **Modify thread properties directly** (use methods instead)

### 💡 Recommended API Usage

```lua
// ✅ Preferred (object-oriented)
local thread = tasks:getThread(taskID);
if thread then
    thread:pause();
    thread:resume();
    local priority = thread:get();
    thread:set(10);
end

// ⚠️ Legacy (still works, but verbose)
tasks:pause(taskID);
tasks:resume(taskID);
local priority = tasks:getThread(taskID):get();
tasks:getThread(taskID):set(10);
```

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
- `options` (table, optional): Configuration options
  - `priority` (number): Thread priority level (1-10, default: 5)
    - Higher values = higher priority
    - **⚠️ ONLY used when manager type is `'priority'`**
    - Ignored in `'concurrent'` and `'sequential'` modes
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

### Task Control (Compatibility Methods)

These methods provide backward compatibility. **Recommended:** Use `thread` methods directly via `getThread(id)`.

#### `tasks:pause(id)`

Pauses a running task (compatibility method).

**Parameters:**
- `id` (number): Task ID to pause

**Returns:** `boolean` - `true` if paused, `false` if not found or already paused

**Recommended Alternative:**
```lua
-- Preferred approach
local thread = tasks:getThread(taskID);
if thread then thread:pause(); end

-- Compatibility approach
tasks:pause(taskID);
```

---

#### `tasks:resume(id)`

Resumes a paused task (compatibility method).

**Parameters:**
- `id` (number): Task ID to resume

**Returns:** `boolean` - `true` if resumed, `false` if not found or not paused

**Recommended Alternative:**
```lua
-- Preferred approach
local thread = tasks:getThread(taskID);
if thread then thread:resume(); end

-- Compatibility approach
tasks:resume(taskID);
```

---

#### `tasks:isPaused(id)`

Checks if a task is paused (compatibility method).

**Parameters:**
- `id` (number): Task ID to check

**Returns:** `boolean` - `true` if paused, `false` otherwise

**Recommended Alternative:**
```lua
-- Preferred approach
local thread = tasks:getThread(taskID);
if thread then
    local paused = thread:isPaused();
end

-- Compatibility approach
local paused = tasks:isPaused(taskID);
```

---

#### `tasks:isStarted(id)`

Checks if a task has started (compatibility method).

**Parameters:**
- `id` (number): Task ID to check

**Returns:** `boolean` - `true` if started, `false` otherwise

**Recommended Alternative:**
```lua
-- Preferred approach
local thread = tasks:getThread(taskID);
if thread then
    local started = thread:isStarted();
end

-- Compatibility approach
local started = tasks:isStarted(taskID);
```

---

### Configuration

#### `tasks:getThread(id)` ⭐

Gets a thread object by its ID, allowing direct access to thread methods.

**Parameters:**
- `id` (number): Task ID returned by `add()`

**Returns:** `Thread | nil` - Thread object or `nil` if not found

**Available Thread Methods:**
- `thread:get()` - Get thread priority (1-10)
- `thread:set(priority)` - Set thread priority (1-10)
- `thread:pause()` - Pause thread execution
- `thread:resume()` - Resume paused thread
- `thread:isPaused()` - Check if thread is paused
- `thread:isStarted()` - Check if thread has started

**Note:** See "Thread Class Reference" section for detailed documentation of each method.

**Example:**
```lua
local taskID = tasks:add(myFunction, {priority = 5});
local thread = tasks:getThread(taskID);

if thread then
    -- Priority management
    print('Priority:', thread:get());
    thread:set(9);
    
    -- State control
    thread:pause();
    print('Paused:', thread:isPaused());
    thread:resume();
else
    print('Thread not found');
end
```

---

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

#### `tasks:setPriority(priority)`

Changes the manager's priority level (execution speed) at runtime.

**Parameters:**
- `priority` (string): Performance profile
  - `'low'` - 250ms ticks, 8 frames/tick
  - `'normal'` - 100ms ticks, 15 frames/tick
  - `'high'` - 50ms ticks, 25 frames/tick
  - `'extreme'` - 0ms ticks (every frame), 50 frames/tick

**Returns:** `boolean` - `true` if changed, `false` if invalid or same as current

**Note:** This affects ALL threads in the manager. Automatically restarts the internal timer.

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

The `Thread` class represents an individual task/coroutine within the thread manager. Thread objects are obtained via `tasks:getThread(id)` and provide methods for priority management and state control.

### Thread Properties

Thread objects contain the following internal properties (read-only, for informational purposes):

| Property | Type | Description |
|----------|------|-------------|
| `routine` | coroutine | The Lua coroutine object |
| `arguments` | table | Arguments passed to the thread function |
| `paused` | boolean | Whether the thread is currently paused |
| `started` | boolean | Whether the thread has begun execution |
| `priority` | number | Thread priority level (1-10, used in 'priority' mode) |

**Note:** These properties should not be modified directly. Use thread methods instead.

---

### Thread Methods

#### `thread:get()`

Gets the priority level of the thread.

**Parameters:** None

**Returns:** `number` - Priority level (1-10)
- Higher values = higher priority
- **⚠️ Only affects execution in `'priority'` mode**
- In other modes, value is stored but not used for scheduling

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

**⚠️ Important:** Priority changes **ONLY affect execution** in `'priority'` mode. In `'concurrent'` and `'sequential'` modes, the value is stored but threads are not scheduled based on priority.

**Example:**
```lua
local thread = tasks:getThread(taskID);

if thread then
    -- Increase priority
    thread:set(10);
    
    -- Check if changed
    local success = thread:set(5);
    if success then
        print('Priority changed to 5');
    end
end
```

---

#### `thread:pause()`

Pauses the thread execution.

**Parameters:** None

**Returns:** `boolean`
- `true` if thread was paused
- `false` if already paused

**Note:** Paused threads remain in the manager but do not execute until resumed.

**Example:**
```lua
local thread = tasks:getThread(taskID);

if thread then
    thread:pause();
    print('Thread paused');
end
```

---

#### `thread:resume()`

Resumes a paused thread.

**Parameters:** None

**Returns:** `boolean`
- `true` if thread was resumed
- `false` if not paused

**Example:**
```lua
local thread = tasks:getThread(taskID);

if thread then
    thread:resume();
    print('Thread resumed');
end
```

---

#### `thread:isPaused()`

Checks if the thread is currently paused.

**Parameters:** None

**Returns:** `boolean` - `true` if paused, `false` otherwise

**Example:**
```lua
local thread = tasks:getThread(taskID);

if thread then
    if thread:isPaused() then
        print('Thread is paused');
    else
        print('Thread is running');
    end
end
```

---

#### `thread:isStarted()`

Checks if the thread has started execution.

**Parameters:** None

**Returns:** `boolean` - `true` if started, `false` if not yet executed

**Note:** A thread is marked as started after its first coroutine resume.

**Example:**
```lua
local thread = tasks:getThread(taskID);

if thread then
    if thread:isStarted() then
        print('Thread has executed at least once');
    else
        print('Thread has not started yet');
    end
end
```

---

### Practical Thread Examples

#### Example: Dynamic Priority Adjustment

```lua
local tasks = Threads.new('priority', 'normal');

-- Create rendering task
local renderID = tasks:add(function(self)
    while true do
        drawCustomUI();
        sleep(16);
    end
end, {priority = 5});

-- Boost priority during combat
addEventHandler('onPlayerDamage', root, function()
    local thread = tasks:getThread(renderID);
    if thread and thread:get() ~= 10 then
        thread:set(10); -- Critical priority
        print('Boosted render priority');
    end
end);

-- Return to normal after combat
addEventHandler('onCombatEnd', root, function()
    local thread = tasks:getThread(renderID);
    if thread and thread:get() ~= 5 then
        thread:set(5); -- Normal priority
        print('Reset render priority');
    end
end);
```

#### Example: Pausable Task with Status Check

```lua
local tasks = Threads.new('concurrent', 'normal');

local processingID = tasks:add(function(self)
    for i = 1, 1000 do
        processData(i);
        sleep(10);
    end
    print('Processing complete!');
end);

-- Command to toggle pause
addCommandHandler('toggle', function()
    local thread = tasks:getThread(processingID);
    
    if not thread then
        outputChatBox('Task not found!');
        return
    end
    
    if thread:isStarted() then
        if thread:isPaused() then
            thread:resume();
            outputChatBox('Task resumed');
        else
            thread:pause();
            outputChatBox('Task paused');
        end
    else
        outputChatBox('Task has not started yet');
    end
end);
```

#### Example: Priority Manager

```lua
local tasks = Threads.new('priority', 'normal');

-- Create multiple tasks with different priorities
local tasks = {
    low = tasks:add(backgroundWork, {priority = 2}),
    med = tasks:add(gameLogic, {priority = 5}),
    high = tasks:add(criticalSystem, {priority = 10}),
};

-- Function to adjust all priorities
function adjustPriorities(factor)
    for name, id in pairs(taskIDs) do
        local thread = tasks:getThread(id);
        if thread then
            local current = thread:get();
            local newPriority = math.min(10, math.max(1, current * factor));
            thread:set(newPriority);
            print(name .. ' priority: ' .. current .. ' -> ' .. newPriority);
        end
    end
end

-- Boost all priorities during high load
adjustPriorities(1.5);
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