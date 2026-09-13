require("cairo")

------------------------------------------------------------
-- Conky 1.10+ moved the Xlib helpers (cairo_xlib_surface_create)
-- out of the "cairo" binding and into a separate module.
-- Older builds expose them directly, so this require is optional.
------------------------------------------------------------

pcall(require, "cairo_xlib")

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local DATA_FILE = "/tmp/conky-spectrum.dat"

local NUM_BARS = 32

local MARGIN_X = 0
local BAR_GAP = 3

-- Height of the tallest bar, in pixels. Must stay in step with the
-- ${voffset} band reserved in conky-spectrum.conf: raise both by the
-- same amount to enlarge the analyser.
local GRAPH_HEIGHT = 140

-- Distance from the bottom of the Conky window up to the baseline the
-- bars stand on. It measures everything printed under the band in
-- conky-spectrum.conf (the 30 HZ / 20 KHZ line and the rule below it),
-- so it changes only when those lines change.
local BOTTOM_OFFSET = 40

-- Smoothing, applied once per Conky update.
--
-- These are per-frame factors, so they depend on the update_interval
-- of the Conky instance loading this script. Tuned for 60 fps
-- (conky-spectrum.conf, update_interval = 0.0167).
--
-- Equivalent settings for the same rise and decay times:
--   60 fps -> ATTACK 0.23, RELEASE 0.064
--   20 fps -> ATTACK 0.55, RELEASE 0.18
--   10 fps -> ATTACK 0.80, RELEASE 0.33
local ATTACK = 0.23
local RELEASE = 0.064

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local smooth_values = {}

for i = 1, NUM_BARS do
    smooth_values[i] = 0
end

local warned = false

------------------------------------------------------------
-- READ DATA
------------------------------------------------------------

local function read_spectrum()

    local file = io.open(DATA_FILE, "r")

    if not file then
        return nil
    end

    local line = file:read("*l")
    file:close()

    if not line then
        return nil
    end

    local values = {}

    for value in string.gmatch(line, "%S+") do

        local number = tonumber(value)

        if number then

            if number < 0 then
                number = 0
            elseif number > 100 then
                number = 100
            end

            table.insert(values, number)
        end
    end

    if #values ~= NUM_BARS then
        return nil
    end

    return values
end

------------------------------------------------------------
-- SMOOTHING
------------------------------------------------------------

local function update_smoothing(values)

    for i = 1, NUM_BARS do

        local target = values[i]
        local current = smooth_values[i]

        local factor

        if target > current then
            factor = ATTACK
        else
            factor = RELEASE
        end

        smooth_values[i] =
            current + (target - current) * factor
    end
end

------------------------------------------------------------
-- DRAW
------------------------------------------------------------

function conky_draw_spectrum()

    --------------------------------------------------------
    -- Conky window is not ready during the first updates
    --------------------------------------------------------

    if conky_window == nil then
        return
    end

    if cairo_xlib_surface_create == nil then

        if not warned then
            print("spectrum.lua: cairo_xlib bindings missing. " ..
                  "Install conky-all (Lua + Cairo support).")
            warned = true
        end

        return
    end

    --------------------------------------------------------
    -- Build a Cairo surface on the Conky window
    --------------------------------------------------------

    local surface = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )

    local cr = cairo_create(surface)

    --------------------------------------------------------
    -- Read spectrum
    --------------------------------------------------------

    local values = read_spectrum()

    if values then
        update_smoothing(values)
    end

    --------------------------------------------------------
    -- Geometry
    --------------------------------------------------------

    local window_width = conky_window.width
    local window_height = conky_window.height

    local graph_width =
        window_width - 2 * MARGIN_X

    local total_gap =
        (NUM_BARS - 1) * BAR_GAP

    local bar_width =
        (graph_width - total_gap) / NUM_BARS

    --------------------------------------------------------
    -- Spectrum position
    --
    -- Spectrum is located near bottom of Conky,
    -- just above frequency labels / uptime.
    --------------------------------------------------------

    local graph_bottom =
        window_height - BOTTOM_OFFSET

    --------------------------------------------------------
    -- Bars
    --------------------------------------------------------

    cairo_set_source_rgba(
        cr,
        1.0,
        1.0,
        1.0,
        0.95
    )

    for i = 1, NUM_BARS do

        local normalized =
            smooth_values[i] / 100.0

        local height =
            normalized * GRAPH_HEIGHT

        local x =
            MARGIN_X +
            (i - 1) * (bar_width + BAR_GAP)

        local y =
            graph_bottom - height

        cairo_rectangle(
            cr,
            x,
            y,
            bar_width,
            height
        )

        cairo_fill(cr)
    end

    --------------------------------------------------------
    -- Baseline
    --------------------------------------------------------

    cairo_set_source_rgba(
        cr,
        1.0,
        1.0,
        1.0,
        0.30
    )

    cairo_set_line_width(cr, 1)

    cairo_move_to(
        cr,
        MARGIN_X,
        graph_bottom
    )

    cairo_line_to(
        cr,
        MARGIN_X + graph_width,
        graph_bottom
    )

    cairo_stroke(cr)

    --------------------------------------------------------
    -- Cleanup
    --
    -- Both the context and the surface must be released
    -- every frame, otherwise Conky leaks memory.
    --------------------------------------------------------

    cairo_destroy(cr)
    cairo_surface_destroy(surface)
end
