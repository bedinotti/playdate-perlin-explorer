-- Common CoreLibs imports.
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"


-- Use common shorthands for playdate code
local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

-- variables
local size = 10
local gridTotalWidth = 150
local grid = {}

local xDivisor = 1.0
local yDivisor = 1.0

-- random = 0, perlin = 1, perlinArray = 2
local generationMethod = 0

--- By convention, most games need to perform some initial setup when they're
--- initially launched. Perform that setup here.
---
--- Note: This will be called exactly once. If you're looking to do something
--- whenever the game is resumed from the background, see playdate.gameWillResume
--- in lifecycle.lua
local function gameDidLaunch()
    print(playdate.metadata.name .. " launched!")

    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 240)
end
gameDidLaunch()

--- This update method is called once per frame.
function playdate.update()
    if #grid < size then
        for i=1, size, 1 do
            grid[i] = {}
        end

        if isUsingPerlin then
            generatePerlinGrid()
        else
            generateMathRandomGrid()
        end

        drawLabel()
        drawGrid()
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        generationMethod += 1
        generationMethod = generationMethod % 3

        if generationMethod == 0 then
            generateMathRandomGrid()
        elseif generationMethod == 1 then
            generatePerlinGrid()
        else
            generatePerlinArrayGrid()
        end
        gfx.clear()

        drawLabel()
        drawGrid()
    end

    playdate.drawFPS(0,220)

    -- Update and draw all sprites. Calling this method in playdate.update
    -- is generally what you want, if you're using sprites.
    -- See https://sdk.play.date/1.9.3/#f-graphics.sprite.update for more info
    gfx.sprite.update()

    -- Update all timers once per frame. This is required if you're using
    -- timers in your game.
    -- See https://sdk.play.date/1.9.3/#f-timer.updateTimers for more info
    playdate.timer.updateTimers()
end

function drawLabel()
    gfx.pushContext()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    if generationMethod == 0 then
        gfx.drawText("Math.random", 0, 0)
    elseif generationMethod == 1 then
        gfx.drawText("Perlin single values", 0, 0)
        gfx.drawText(string.format("x / %.2f", xDivisor), 240, 0)
        gfx.drawText(string.format("y / %.2f", yDivisor), 240, 40)
    else
        gfx.drawText("Perlin array", 0, 0)
        gfx.drawText(string.format("x / %.2f", xDivisor), 240, 0)
        gfx.drawText(string.format("y / %.2f", yDivisor), 240, 40)
    end
    gfx.popContext()
end

function drawGrid()
    local dx = gridTotalWidth / size
    local start = { x = 20, y = 40 }

    for row = 1, size, 1 do
        for col = 1, size, 1 do
            local value = grid[col][row]
            local rect = geo.rect.new(
                start.x + (col - 1) * dx,
                start.y + (row - 1) * dx,
                dx,
                dx
            )
            gfx.pushContext()
            -- if value > 0.5 then
                gfx.setColor(gfx.kColorWhite)
                gfx.setDitherPattern(value)
                gfx.fillRect(rect)

                gfx.setDitherPattern(0)
                if value > 0.5 then
                    gfx.setColor(gfx.kColorBlack)
                end
                gfx.drawRect(rect)
            gfx.popContext()
        end
    end
end

function generateMathRandomGrid()
    for row = 1, size, 1 do
        for col = 1, size, 1 do
            local value = math.random()
            grid[col][row] = value
        end
    end
end

function generatePerlinGrid()
    for row = 1, size, 1 do
        for col = 1, size, 1 do
            local value = gfx.perlin(col / xDivisor, row / yDivisor, 1, 0)
            grid[col][row] = value
        end
    end
end

function generatePerlinArrayGrid()
    for col = 1, size, 1 do
        local colValues = gfx.perlinArray(size, col / xDivisor, 0, 1, 1 / yDivisor)
        grid[col] = colValues
    end
end
