# MTA Async

A powerful asynchronous iteration library for Multi Theft Auto (MTA) San Andreas that provides non-blocking loop operations to prevent server freezing during heavy computations.

## ⚠️ Important Notice

**This resource requires the `threads.lua` file from the `main` branch to work properly.** Make sure to include it in your resource before using the Async library.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Requirements](#requirements)
- [Usage](#usage)
  - [Creating an Async Instance](#creating-an-async-instance)
  - [Iterate Method](#iterate-method)
  - [Foreach Method](#foreach-method)
  - [Map Method](#map-method)
  - [Interval Configuration](#interval-configuration)
- [API Reference](#api-reference)
- [Examples](#examples)
- [Performance Considerations](#performance-considerations)
- [License](#license)

## 🔍 Overview

The MTA Async library provides a way to perform iterative operations without blocking the main server thread. This is particularly useful when you need to process large datasets, perform bulk operations, or execute time-consuming loops that would otherwise cause server lag or timeouts.

## ✨ Features

- **Non-blocking iterations**: Execute loops without freezing the server
- **Customizable intervals**: Control the execution speed between iterations
- **Callback support**: Get notified when operations complete
- **Elapsed time tracking**: Monitor how long operations take
- **Type annotations**: Full LuaLS/EmmyLua support for better IDE integration
- **Easy to use**: Simple and intuitive API

## 📦 Installation

1. Download or clone this repository
2. **Important**: Download the `threads.lua` file from the `main` branch
3. Place both files in your MTA resource folder
4. Add the following to your `meta.xml`:

```xml
<script src="threads.lua" type="shared" cache="false"/>
<script src="async.lua" type="shared" cache="false"/>
```

## 📋 Requirements

- **Multi Theft Auto: San Andreas** (Server/Client)
- **threads.lua** from the `main` branch (required dependency)
- MTA version 1.5.0 or higher recommended

## 🚀 Usage

### Creating an Async Instance

First, create a new Async instance with your desired interval (in milliseconds):

```lua
-- Create an async instance with 100ms interval between iterations
local async = Async.new(100)

-- Create an async instance with 50ms interval for faster processing
local fastAsync = Async.new(50)
```

### Iterate Method

The `iterate` method allows you to perform numeric loops asynchronously:

```lua
async:iterate(from, to, increment, func, callback)
```

**Parameters:**
- `from` (number): Starting value
- `to` (number): Ending value
- `increment` (number): Step value
- `func` (function): Function to execute on each iteration (receives current index)
- `callback` (function, optional): Function called when iteration completes (receives elapsed time in ms)

**Example:**

```lua
local async = Async.new(100)

-- Process numbers from 1 to 1000
async:iterate(1, 1000, 1, 
    function(i)
        -- This runs for each number
        outputDebugString("Processing: " .. i)
    end,
    function(elapsed)
        -- This runs when complete
        outputDebugString("Completed in " .. elapsed .. "ms")
    end
)
```

### Foreach Method

The `foreach` method allows you to iterate over tables asynchronously:

```lua
async:foreach(object, func, callback)
```

**Parameters:**
- `object` (table): The table to iterate over
- `func` (function): Function to execute for each element (receives value and key)
- `callback` (function, optional): Function called when iteration completes (receives elapsed time in ms)

**Example:**

```lua
local async = Async.new(100)

local players = {
    {name = "John", score = 100},
    {name = "Jane", score = 200},
    {name = "Bob", score = 150}
}

-- Process each player
async:foreach(players,
    function(player, index)
        -- This runs for each player
        outputDebugString(player.name .. " has " .. player.score .. " points")
    end,
    function(elapsed)
        -- This runs when complete
        outputDebugString("All players processed in " .. elapsed .. "ms")
    end
)
```

### Map Method

The `map` method allows you to iterate over arrays asynchronously, similar to `foreach` but specifically designed for indexed arrays (using `ipairs`):

```lua
async:map(array, func, callback)
```

**Parameters:**
- `array` (table): The array to iterate over (indexed table)
- `func` (function): Function to execute for each element (receives value and index)
- `callback` (function, optional): Function called when iteration completes (receives elapsed time in ms)

**Example:**

```lua
local async = Async.new(100)

local numbers = {10, 20, 30, 40, 50}

-- Process each number in the array
async:map(numbers,
    function(value, index)
        -- This runs for each array element
        outputDebugString("Index " .. index .. ": " .. value)
    end,
    function(elapsed)
        -- This runs when complete
        outputDebugString("Array processed in " .. elapsed .. "ms")
    end
)
```

### Interval Configuration

You can get or set the interval between iterations:

```lua
-- Get current interval
local currentInterval = async:getInterval()
outputDebugString("Current interval: " .. currentInterval .. "ms")

-- Set new interval (must be >= 1ms)
local success = async:setInterval(50)
if success then
    outputDebugString("Interval updated to 50ms")
end
```

## 📚 API Reference

### `Async.new(interval)`

Creates a new Async instance.

- **Parameters:**
  - `interval` (number): Interval in milliseconds between iterations (default: 100)
- **Returns:** Async instance

---

### `async:iterate(from, to, increment, func, callback)`

Performs an asynchronous numeric loop.

- **Parameters:**
  - `from` (number): Starting value
  - `to` (number): Ending value
  - `increment` (number): Step value (can be negative for countdown)
  - `func` (function): Function called for each iteration `func(i)`
  - `callback` (function, optional): Completion callback `callback(elapsed)`
- **Returns:** Task reference

---

### `async:foreach(object, func, callback)`

Performs an asynchronous table iteration.

- **Parameters:**
  - `object` (table): Table to iterate
  - `func` (function): Function called for each element `func(value, key)`
  - `callback` (function, optional): Completion callback `callback(elapsed)`
- **Returns:** Task reference

---

### `async:map(array, func, callback)`

Performs an asynchronous array iteration using `ipairs`.

- **Parameters:**
  - `array` (table): Array to iterate (indexed table)
  - `func` (function): Function called for each element `func(value, index)`
  - `callback` (function, optional): Completion callback `callback(elapsed)`
- **Returns:** Task reference

---

### `async:getInterval()`

Gets the current interval between iterations.

- **Returns:** (number) Current interval in milliseconds

---

### `async:setInterval(interval)`

Sets a new interval between iterations.

- **Parameters:**
  - `interval` (number): New interval in milliseconds (must be >= 1)
- **Returns:** (boolean) true if successful, false otherwise

## 💡 Examples

### Example 1: Spawning Multiple Vehicles Asynchronously

```lua
local async = Async.new(100)

local vehicleModels = {411, 451, 506, 541, 415}
local spawnPositions = {
    {x = 0, y = 0, z = 3},
    {x = 10, y = 0, z = 3},
    {x = 20, y = 0, z = 3},
    {x = 30, y = 0, z = 3},
    {x = 40, y = 0, z = 3}
}

async:iterate(1, #vehicleModels, 1,
    function(i)
        local model = vehicleModels[i]
        local pos = spawnPositions[i]
        createVehicle(model, pos.x, pos.y, pos.z)
    end,
    function(elapsed)
        outputDebugString("Spawned " .. #vehicleModels .. " vehicles in " .. elapsed .. "ms")
    end
)
```

### Example 2: Processing Player Database

```lua
local async = Async.new(50)

-- Simulate a player database
local playerDatabase = {
    {id = 1, name = "Player1", banned = false},
    {id = 2, name = "Hacker123", banned = true},
    {id = 3, name = "Player3", banned = false},
    -- ... many more players
}

async:foreach(playerDatabase,
    function(playerData, index)
        if playerData.banned then
            outputDebugString("Player " .. playerData.name .. " is banned")
            -- Perform ban operations
        else
            -- Update player stats
            outputDebugString("Processing player: " .. playerData.name)
        end
    end,
    function(elapsed)
        outputDebugString("Database processing completed in " .. elapsed .. "ms")
    end
)
```

### Example 3: Countdown Timer

```lua
local async = Async.new(1000) -- 1 second interval

async:iterate(10, 1, -1,
    function(i)
        outputChatBox("Countdown: " .. i, root, 255, 255, 0)
    end,
    function(elapsed)
        outputChatBox("GO!", root, 0, 255, 0)
    end
)
```

### Example 4: Large Area Object Creation

```lua
local async = Async.new(100)

-- Create objects in a grid pattern
local gridSize = 50

async:iterate(1, gridSize * gridSize, 1,
    function(i)
        local x = (i % gridSize) * 5
        local y = math.floor(i / gridSize) * 5
        createObject(1337, x, y, 0) -- Create object at grid position
    end,
    function(elapsed)
        outputDebugString("Created " .. (gridSize * gridSize) .. " objects in " .. elapsed .. "ms")
    end
)
```

## ⚡ Performance Considerations

1. **Interval Selection:**
   - Lower intervals (10-50ms) = Faster processing but higher CPU usage
   - Higher intervals (100-500ms) = Slower processing but lower CPU usage
   - Balance based on your server's needs and load

2. **Use Cases:**
   - ✅ **Good for:** Large loops, bulk operations, database processing, mass object creation
   - ❌ **Not needed for:** Simple operations, small loops (< 100 iterations), real-time critical code

3. **Best Practices:**
   - Use async operations for loops with 100+ iterations
   - Adjust intervals based on operation complexity
   - Use callbacks to chain multiple async operations
   - Monitor elapsed time to optimize performance

## 📄 License

This resource is provided as-is for use with Multi Theft Auto: San Andreas.

---

**Author:** dracoN*  
**Version:** 1.0.0  
**Type:** Shared (Server/Client)

---

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📞 Support

For issues or questions, please open an issue on the repository or contact the author.

---

**Remember:** Always include `threads.lua` from the `main` branch in your resource for this library to function correctly!