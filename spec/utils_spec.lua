local utils = require("utils")

describe("utils.clamp", function()
    it("returns value when within range", function()
        assert.are.equal(5, utils.clamp(5, 0, 10))
    end)

    it("clamps to min", function()
        assert.are.equal(0, utils.clamp(-5, 0, 10))
    end)

    it("clamps to max", function()
        assert.are.equal(10, utils.clamp(15, 0, 10))
    end)

    it("returns min when value equals min", function()
        assert.are.equal(0, utils.clamp(0, 0, 10))
    end)

    it("returns max when value equals max", function()
        assert.are.equal(10, utils.clamp(10, 0, 10))
    end)
end)

describe("utils.lerp", function()
    it("returns a at t=0", function()
        assert.are.equal(0, utils.lerp(0, 100, 0))
    end)

    it("returns b at t=1", function()
        assert.are.equal(100, utils.lerp(0, 100, 1))
    end)

    it("returns midpoint at t=0.5", function()
        assert.are.equal(50, utils.lerp(0, 100, 0.5))
    end)

    it("works with negative values", function()
        assert.are.equal(-50, utils.lerp(-100, 0, 0.5))
    end)
end)

describe("utils.get_distance", function()
    it("returns 0 for same point", function()
        assert.are.equal(0, utils.get_distance({ x = 5, y = 5 }, { x = 5, y = 5 }))
    end)

    it("returns correct horizontal distance", function()
        assert.are.equal(3, utils.get_distance({ x = 0, y = 0 }, { x = 3, y = 0 }))
    end)

    it("returns correct vertical distance", function()
        assert.are.equal(4, utils.get_distance({ x = 0, y = 0 }, { x = 0, y = 4 }))
    end)

    it("returns correct diagonal distance (3-4-5 triangle)", function()
        assert.are.equal(5, utils.get_distance({ x = 0, y = 0 }, { x = 3, y = 4 }))
    end)
end)

describe("utils.is_point_in_transform_bounds", function()
    local transform = { x = 10, y = 20, width = 100, height = 50 }

    it("returns true for point inside", function()
        assert.is_true(utils.is_point_in_transform_bounds(transform, { x = 50, y = 40 }))
    end)

    it("returns true for point on top-left corner", function()
        assert.is_true(utils.is_point_in_transform_bounds(transform, { x = 10, y = 20 }))
    end)

    it("returns true for point on bottom-right corner", function()
        assert.is_true(utils.is_point_in_transform_bounds(transform, { x = 110, y = 70 }))
    end)

    it("returns false for point to the left", function()
        assert.is_false(utils.is_point_in_transform_bounds(transform, { x = 9, y = 40 }))
    end)

    it("returns false for point above", function()
        assert.is_false(utils.is_point_in_transform_bounds(transform, { x = 50, y = 19 }))
    end)

    it("returns false for point to the right", function()
        assert.is_false(utils.is_point_in_transform_bounds(transform, { x = 111, y = 40 }))
    end)

    it("returns false for point below", function()
        assert.is_false(utils.is_point_in_transform_bounds(transform, { x = 50, y = 71 }))
    end)
end)

describe("utils.get_percent_size", function()
    it("uses height when width > height", function()
        -- width=1000 > height=500 → height * 0.8 * percent
        assert.are.equal(500 * 0.8 * 0.5, utils.get_percent_size(1000, 500, 0.5))
    end)

    it("uses width when width <= height", function()
        -- width=400 <= height=500 → width * percent
        assert.are.equal(400 * 0.5, utils.get_percent_size(400, 500, 0.5))
    end)

    it("uses width when width equals height", function()
        assert.are.equal(500 * 0.5, utils.get_percent_size(500, 500, 0.5))
    end)
end)
