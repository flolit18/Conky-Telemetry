------------------------------------------------------------
-- CPU AVERAGE CLOCK GRAPH
------------------------------------------------------------

local CPU_MAX_FREQ = nil


local function read_number(path)

    local file = io.open(path, "r")

    if not file then
        return nil
    end

    local value = tonumber(file:read("*l"))

    file:close()

    return value
end


local function get_cpu_max_freq()

    local max_freq = 0

    for cpu = 0, 255 do

        local path =
            "/sys/devices/system/cpu/cpu" ..
            cpu ..
            "/cpufreq/cpuinfo_max_freq"

        local value = read_number(path)

        if value and value > max_freq then
            max_freq = value
        end
    end

    -- fallback Core Ultra 7 265K
    if max_freq <= 0 then
        max_freq = 5500000
    end

    return max_freq
end


function conky_cpu_clock_avg_pct()

    if CPU_MAX_FREQ == nil then
        CPU_MAX_FREQ = get_cpu_max_freq()
    end

    local sum = 0
    local count = 0

    for cpu = 0, 255 do

        local path =
            "/sys/devices/system/cpu/cpu" ..
            cpu ..
            "/cpufreq/scaling_cur_freq"

        local value = read_number(path)

        if value then
            sum = sum + value
            count = count + 1
        end
    end

    if count == 0 then
        return 0
    end

    local average = sum / count

    local pct =
        average / CPU_MAX_FREQ * 100

    if pct < 0 then
        pct = 0
    elseif pct > 100 then
        pct = 100
    end

    return pct
end