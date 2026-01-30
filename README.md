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

```lua
local bgTasks = Threads.new('sequential', 'low');
local mainTasks = Threads.new('concurrent', 'normal');
local uiTasks = Threads.new('concurrent', 'high');
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
- **Use high priority** for non-critical background tasks
- **Create thousands of threads** simultaneously (use batching)
- **Rely on thread execution order** in concurrent mode

## Performance Tips

1. **Batch operations**: Group related work together
2. **Adjust frame limits**: Lower if causing stutters, higher for faster completion
3. **Profile your threads**: Monitor with frame counters
4. **Clean up properly**: Remove threads when elements are destroyed

## API Reference

### Threads.new(type, priority)
Creates a new thread manager.
- **type**: `'concurrent'` or `'sequential'` (default: `'concurrent'`)
- **priority**: `'low'`, `'normal'`, or `'high'` (default: `'normal'`)

### threads:add(func, ...)
Adds a new thread. Returns thread ID.
- **func**: Function to execute (receives `self` as first parameter)
- **...**: Additional arguments passed to function

### threads:remove(id)
Removes a thread by ID.

### threads:pause(id)
Pauses a thread.

### threads:resume(id)
Resumes a paused thread.

### threads:setType(type)
Changes execution mode (`'concurrent'` or `'sequential'`).

### threads:setPriority(priority)
Changes priority (`'low'`, `'normal'`, or `'high'`).

### sleep(milliseconds)
Pauses thread execution for specified time (global function).

## License

MIT License - Free to use and modify.

## Credits

Created by dracoN* - Feel free to contribute or report issues!