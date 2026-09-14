------------------------------------------------------------
-- CPU LOAD GRAPH
------------------------------------------------------------

local previous_total = 0
local previous_busy = 0
local primed = false


------------------------------------------------------------
-- Aggregate "cpu" line of /proc/stat:
--
--   cpu  user nice system idle iowait irq softirq steal ...
--
-- All counters are cumulative ticks since boot.
------------------------------------------------------------

local function read_cpu()

    local file = io.open("/proc/stat", "r")

    if not file then
        return nil
    end

    local line = file:read("*l")

    file:close()

    if not line then
        return nil
    end

    local values = {}

    for value in string.gmatch(line, "%d+") do
        table.insert(values, tonumber(value))
    end

    if #values < 8 then
        return nil
    end

    local total = 0

    for i = 1, 8 do
        total = total + values[i]
    end

    -- values[4] = idle, values[5] = iowait
    local busy = total - values[4] - values[5]

    return total, busy
end


function conky_cpu_load_pct()

    local total, busy = read_cpu()

    if not total then
        return 0
    end

    local delta_total = total - previous_total
    local delta_busy = busy - previous_busy

    previous_total = total
    previous_busy = busy

    -- First call after Conky starts: comparing against zero would
    -- report the average since boot instead of the load right now.
    if not primed then
        primed = true
        return 0
    end

    if delta_total <= 0 then
        return 0
    end

    local pct = delta_busy * 100.0 / delta_total

    if pct < 0 then
        pct = 0
    elseif pct > 100 then
        pct = 100
    end

    return pct
end
