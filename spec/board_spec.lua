-- NOTE: board.create() uses GENERATE_UID global
_G.GENERATE_UID = function()
    _G.uid_counter = (_G.uid_counter or 0) + 1
    return _G.uid_counter
end

local board = require("board")

-- Minimal conf without gaps — easy to reason about
local conf_simple = {
    size = 3,
    gap_ratio = { top = 0, bottom = 0, left = 0, right = 0 },
    max_size = { width = 3000, height = 3000 },
    cell_gap_ratio = 0,
    multipliers = { { 1, 1, 1 }, { 1, 1, 1 }, { 1, 1, 1 } }
}

-- Conf with gaps to test gap calculations
local conf_with_gaps = {
    size = 3,
    gap_ratio = { top = 1, bottom = 1, left = 1, right = 1 },
    max_size = { width = 3000, height = 3000 },
    cell_gap_ratio = 0.5,
    multipliers = { { 1, 1, 1 }, { 1, 1, 1 }, { 1, 1, 1 } }
}

local function make_state(overrides)
    local s = {
        transform     = { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
        base_transform = { x = 0, y = 0, width = 0, height = 0, z_index = 0 },
        layout        = { cellSize = 0, cellGap = 0, fieldGaps = { top = 0, bottom = 0, left = 0, right = 0 } },
        offset        = { x = 0, y = 0 },
        zoom          = 1,
        cells         = {},
        cell_uids     = {},
        elem_uids     = {}
    }
    if overrides then
        for k, v in pairs(overrides) do s[k] = v end
    end
    return s
end

-- ─────────────────────────────────────────────
describe("board.recalculate", function()
    it("sets base_transform centered on given point", function()
        local state = make_state()
        board.recalculate(state, conf_simple, 300, 300, 150, 150)

        -- With no gaps, board_width = cell_size * 3
        -- cell_size = 300/3 = 100 → board = 300×300 → starts at (0, 0)
        assert.are.equal(0, state.base_transform.x)
        assert.are.equal(0, state.base_transform.y)
        assert.are.equal(300, state.base_transform.width)
        assert.are.equal(300, state.base_transform.height)
    end)

    it("calculates correct cell_size without gaps", function()
        local state = make_state()
        board.recalculate(state, conf_simple, 300, 300, 0, 0)

        assert.are.equal(100, state.layout.cellSize)
        assert.are.equal(0, state.layout.cellGap)
    end)

    it("cell_size is constrained by the smaller dimension", function()
        local state = make_state()
        -- width=600, height=300 — height is the constraint
        board.recalculate(state, conf_simple, 600, 300, 0, 0)

        assert.are.equal(100, state.layout.cellSize) -- 300/3
    end)

    it("respects max_size constraint", function()
        local conf_small_max = {
            size = 3,
            gap_ratio = { top = 0, bottom = 0, left = 0, right = 0 },
            max_size = { width = 150, height = 150 },
            cell_gap_ratio = 0,
            multipliers = { { 1, 1, 1 }, { 1, 1, 1 }, { 1, 1, 1 } }
        }
        local state = make_state()
        board.recalculate(state, conf_small_max, 3000, 3000, 0, 0)

        -- max_size clamps to 150×150 → cell_size = 150/3 = 50
        assert.are.equal(50, state.layout.cellSize)
    end)

    it("calculates field_gaps correctly", function()
        local state = make_state()
        -- With gap_ratio all=1 and cell_gap_ratio=0.5, size=3:
        -- denominator = 3 + 2*0.5 + 1 + 1 = 6 → cell_size = 300/6 = 50
        -- field_gaps.top = 50 * 1 = 50
        -- cell_gap = 50 * 0.5 = 25
        board.recalculate(state, conf_with_gaps, 300, 300, 0, 0)

        assert.are.equal(50, state.layout.cellSize)
        assert.are.equal(25, state.layout.cellGap)
        assert.are.equal(50, state.layout.fieldGaps.top)
        assert.are.equal(50, state.layout.fieldGaps.left)
    end)
end)

-- ─────────────────────────────────────────────
describe("board.get_layout", function()
    it("returns layout multiplied by zoom=1", function()
        local state = make_state({
            zoom = 1,
            layout = {
                cellSize = 100,
                cellGap = 10,
                fieldGaps = { top = 5, bottom = 5, left = 5, right = 5 }
            }
        })
        local layout = board.get_layout(state, conf_simple)

        assert.are.equal(100, layout.cellSize)
        assert.are.equal(10, layout.cellGap)
        assert.are.equal(5, layout.fieldGaps.top)
    end)

    it("scales all values by zoom", function()
        local state = make_state({
            zoom = 2,
            layout = {
                cellSize = 100,
                cellGap = 10,
                fieldGaps = { top = 5, bottom = 6, left = 7, right = 8 }
            }
        })
        local layout = board.get_layout(state, conf_simple)

        assert.are.equal(200, layout.cellSize)
        assert.are.equal(20, layout.cellGap)
        assert.are.equal(10, layout.fieldGaps.top)
        assert.are.equal(12, layout.fieldGaps.bottom)
        assert.are.equal(14, layout.fieldGaps.left)
        assert.are.equal(16, layout.fieldGaps.right)
    end)
end)

-- ─────────────────────────────────────────────
describe("board.get_space_transform", function()
    -- Simple state: transform at (0,0), cell_size=100, no gaps, zoom=1
    local function make_simple_state(zoom)
        return make_state({
            transform = { x = 0, y = 0, width = 300, height = 300, z_index = 0 },
            zoom = zoom or 1,
            layout = {
                cellSize = 100,
                cellGap = 0,
                fieldGaps = { top = 0, bottom = 0, left = 0, right = 0 }
            }
        })
    end

    it("cell (1,1) starts at board origin", function()
        local t = board.get_space_transform(make_simple_state(), conf_simple, 1, 1)

        assert.are.equal(0, t.x)
        assert.are.equal(0, t.y)
        assert.are.equal(100, t.width)
        assert.are.equal(100, t.height)
    end)

    it("cell (2,1) is offset by one cell horizontally", function()
        local t = board.get_space_transform(make_simple_state(), conf_simple, 2, 1)

        assert.are.equal(100, t.x)
        assert.are.equal(0, t.y)
    end)

    it("cell (1,2) is offset by one cell vertically", function()
        local t = board.get_space_transform(make_simple_state(), conf_simple, 1, 2)

        assert.are.equal(0, t.x)
        assert.are.equal(100, t.y)
    end)

    it("cell (3,3) is at the last position", function()
        local t = board.get_space_transform(make_simple_state(), conf_simple, 3, 3)

        assert.are.equal(200, t.x)
        assert.are.equal(200, t.y)
    end)

    it("scales cell size by zoom", function()
        local t = board.get_space_transform(make_simple_state(2), conf_simple, 1, 1)

        assert.are.equal(200, t.width)
        assert.are.equal(200, t.height)
    end)

    it("scales cell position by zoom", function()
        local t = board.get_space_transform(make_simple_state(2), conf_simple, 2, 1)

        -- zoom=2: field_gap=0, (2-1) * (100+0) * 2 = 200
        assert.are.equal(200, t.x)
    end)

    it("accounts for board transform offset", function()
        local state = make_state({
            transform = { x = 50, y = 30, width = 300, height = 300, z_index = 0 },
            zoom = 1,
            layout = {
                cellSize = 100,
                cellGap = 0,
                fieldGaps = { top = 0, bottom = 0, left = 0, right = 0 }
            }
        })
        local t = board.get_space_transform(state, conf_simple, 1, 1)

        assert.are.equal(50, t.x)
        assert.are.equal(30, t.y)
    end)

    it("accounts for field gaps", function()
        local state = make_state({
            transform = { x = 0, y = 0, width = 300, height = 300, z_index = 0 },
            zoom = 1,
            layout = {
                cellSize = 100,
                cellGap = 0,
                fieldGaps = { top = 20, bottom = 0, left = 15, right = 0 }
            }
        })
        local t = board.get_space_transform(state, conf_simple, 1, 1)

        assert.are.equal(15, t.x)
        assert.are.equal(20, t.y)
    end)
end)

-- ─────────────────────────────────────────────
describe("board element management", function()
    before_each(function()
        _G.uid_counter = 0
    end)

    it("add_element stores uid at correct position", function()
        local state = board.create(conf_simple)
        board.add_element(state, 2, 3, 42)

        assert.are.equal(42, board.get_elem_uid(state, 2, 3))
    end)

    it("get_elem_uid returns nil for empty cell", function()
        local state = board.create(conf_simple)

        assert.is_nil(board.get_elem_uid(state, 1, 1))
    end)

    it("remove_element clears the cell", function()
        local state = board.create(conf_simple)
        board.add_element(state, 1, 1, 99)
        board.remove_element(state, 1, 1)

        assert.is_nil(board.get_elem_uid(state, 1, 1))
    end)

    it("remove_element on empty cell does nothing", function()
        local state = board.create(conf_simple)
        assert.has_no.errors(function()
            board.remove_element(state, 2, 2)
        end)
    end)

    it("get_cell returns correct multiplier", function()
        local conf = {
            size = 2,
            gap_ratio = { top = 0, bottom = 0, left = 0, right = 0 },
            max_size = { width = 3000, height = 3000 },
            cell_gap_ratio = 0,
            multipliers = { { 1, 2 }, { 3, 1 } }
        }
        local state = board.create(conf)

        assert.are.equal(2, board.get_cell(state, 2, 1).multiplier) -- x=2, y=1
        assert.are.equal(3, board.get_cell(state, 1, 2).multiplier) -- x=1, y=2
    end)
end)
