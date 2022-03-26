-- Common CoreLibs imports.
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

-- Use common shorthands for playdate code
local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

-- variables
local grid = {}
local gridTotalWidth <const> = playdate.display.getWidth() / 2
local start <const> = { x = 5, y = 30 }
local isModfiyingVariables = false

-- Motion variables. Controlled with ⬆️⬇️⬅️➡️
local xPosition = 0.5
local yPosition = 0.5

-- Generation variables. Controlled in the options grid
local generationKeys = { "size", "z", "repeatValue", "octaves", "persistence", "isArray"}
local generationVariables = {
    size = 10,
    z = 0,
    repeatValue = 0,
    octaves = 1,
    persistence = 1.0,
    isArray = false
}

function variableDisplay(index)
    local label = generationKeys[index]
    local value = generationVariables[label]
    local result = "???"
    if label == "size" or label == "octaves" then
        result = string.format("%s = %d", label, value)
    elseif label == "z" then
        result = string.format("z = %.1f", value)
    elseif label == "persistence" then
        result = string.format("persist = %.2f", value)
    elseif label == "repeatValue" then
        -- This is special, because `repeat` is a Lua keyword
        result = string.format("repeat = %d", value)
    elseif label == "isArray" then
        if generationVariables.isArray then
            result = ".perlinArray(...)"
        else
            result = ".perlin(...)"
        end
    end
    return result
end


-- Options list view
local optionList = playdate.ui.gridview.new(0, 25)
optionList:setNumberOfRows(#generationKeys)
optionList:setCellPadding(0, 0, 5, 5)
optionList:setContentInset(12, 12, 20, 20)

-- Add a background to the optionList, with a vertical line to the left
local backgroundImage = gfx.image.new(
    playdate.display.getWidth() / 2,
    playdate.display.getHeight(),
    gfx.kColorBlack
)
gfx.lockFocus(backgroundImage)
gfx.setColor(gfx.kColorWhite)
gfx.drawLine(0, 0, 0, playdate.display.getHeight())
gfx.unlockFocus()
optionList.backgroundImage = backgroundImage

function optionList:drawCell(section, row, column, selected, x, y, width, height)
    local plusWidth, plusHeight = gfx.getTextSize("*+*")
    local padding = 6
    local textY = y + (height - plusHeight) / 2
    gfx.setColor(gfx.kColorWhite)
    if selected then
        gfx.fillRoundRect(x, y, width, height, 4)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.drawText("*+*", x + width - plusWidth - padding, textY)
        gfx.drawText("*-*", x + padding, textY)
    else
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end
    gfx.drawTextInRect(
        variableDisplay(row),
        x + plusWidth + 2*padding,
        y+4,
        width - 2*plusWidth - 4*padding,
        height,
        nil,
        "...",
        kTextAlignment.center
    )
end

function optionList:increaseSelectedValue()
    local key = generationKeys[self:getSelectedRow()]
    if key == "size" or key == "octaves" or key == "repeatValue" then
        generationVariables[key] += 1
    elseif key == "z" then
        local amount = 1.0
        if playdate.buttonIsPressed(playdate.kButtonB) then
            amount = 0.1
        end
        generationVariables[key] += amount
    elseif key == "persistence" then
        local amount = 0.1
        if playdate.buttonIsPressed(playdate.kButtonB) then
            amount = 0.01
        end
        generationVariables[key] += amount
    elseif key == "isArray" then
        generationVariables[key] = not generationVariables[key]
    end
end

function optionList:decreaseSelectedValue()
    local key = generationKeys[self:getSelectedRow()]
    if key == "size" or key == "octaves" then
        local newValue = math.max(1, generationVariables[key] - 1)
        generationVariables[key] = newValue
    elseif key == "repeatValue" then
        generationVariables[key] -= 1
    elseif key == "z" then
        local amount = 1.0
        if playdate.buttonIsPressed(playdate.kButtonB) then
            amount = 0.1
        end
        generationVariables[key] -= amount
    elseif key == "persistence" then
        local amount = 0.1
        if playdate.buttonIsPressed(playdate.kButtonB) then
            amount = 0.01
        end
        generationVariables[key] -= amount
    elseif key == "isArray" then
        generationVariables[key] = not generationVariables[key]
    end
end

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
    if #grid < generationVariables.size then
        for i=1, generationVariables.size, 1 do
            grid[i] = {}
        end

        regenerateGrid()
        drawEverything()
    end

    if isModfiyingVariables then
        optionList:drawInRect(220, 0, 180, 240)
    end

    -- Toggle the optionList when the user hits 🅰️
    if playdate.buttonJustPressed(playdate.kButtonA) then
        isModfiyingVariables = not isModfiyingVariables
        drawEverything()
    end

    -- Update and draw all sprites. Calling this method in playdate.update
    -- is generally what you want, if you're using sprites.
    -- See https://sdk.play.date/1.9.3/#f-graphics.sprite.update for more info
    gfx.sprite.update()

    -- Update all timers once per frame. This is required if you're using
    -- timers in your game.
    -- See https://sdk.play.date/1.9.3/#f-timer.updateTimers for more info
    playdate.timer.updateTimers()
end

function playdate.upButtonDown()
    if isModfiyingVariables then
        optionList:selectPreviousRow()
    else
        local amount = 1
        if playdate.buttonIsPressed(playdate.kButtonB) then
            amount = 0.1
        end
        yPosition -= amount
        regenerateGrid()
        drawEverything()
    end

end

function playdate.downButtonDown()
    if isModfiyingVariables then
        optionList:selectNextRow()
    else
        local amount = 1
        if playdate.buttonIsPressed(playdate.kButtonB) then
            amount = 0.1
        end
        yPosition += amount
        regenerateGrid()
        drawEverything()
    end
end

function playdate.leftButtonDown()
    if isModfiyingVariables then
        optionList:decreaseSelectedValue()
    else
        local amount = 1
        if playdate.buttonIsPressed(playdate.kButtonB) then
            amount = 0.1
        end
        xPosition -= amount
    end
    regenerateGrid()
    drawEverything()
end

function playdate.rightButtonDown()
    if isModfiyingVariables then
        optionList:increaseSelectedValue()
    else
        local amount = 1
        if playdate.buttonIsPressed(playdate.kButtonB) then
            amount = 0.1
        end
        xPosition += amount
    end
    regenerateGrid()
    drawEverything()
end

function drawEverything()
    gfx.clear()

    drawTitle()
    drawDetailColumn()
    drawGrid()
end

function drawTitle()
    gfx.pushContext()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("Perlin Noise explorer", 5, 5)
    gfx.popContext()
end

function drawDetailColumn()
    local firstColumnX = 240
    local secondColumnX = firstColumnX + (400 - 240) / 2
    gfx.pushContext()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(string.format("x = %.1f", xPosition), firstColumnX, 5)
    gfx.drawText(string.format("y = %.1f", yPosition), secondColumnX, 5)
    gfx.popContext()
end

function drawGrid()
    local size = generationVariables.size
    local dx = gridTotalWidth / size

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
            gfx.setColor(gfx.kColorWhite)
            gfx.setDitherPattern(value)
            gfx.fillRect(rect)
            gfx.popContext()
        end
    end
    gfx.pushContext()
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(start.x, start.y, gridTotalWidth, gridTotalWidth)
    gfx.popContext()
end

-- Grid generation
function regenerateGrid()
    if generationVariables.isArray then
        regenerateGridByArray()
    else
        regenerateGridBySingleValue()
    end
end

function regenerateGridBySingleValue()
    local size = generationVariables.size
    local z = generationVariables.z
    local repeatValue = generationVariables.repeatValue
    local octaves = generationVariables.octaves
    local persistence = generationVariables.persistence
    for row = 1, size, 1 do
        for col = 1, size, 1 do
            local value = gfx.perlin(
                (col - 1) + xPosition,
                (row - 1) + yPosition,
                z,
                repeatValue,
                octaves,
                persistence
            )
            grid[col] = grid[col] or {}
            grid[col][row] = value
        end
    end
end

function regenerateGridByArray()
    local size = generationVariables.size
    local z = generationVariables.z
    local repeatValue = generationVariables.repeatValue
    local octaves = generationVariables.octaves
    local persistence = generationVariables.persistence
    for col = 1, size, 1 do
        local column = gfx.perlinArray(
            size,
            xPosition + col - 1, -- x
            0, -- dx
            yPosition, -- y
            1, -- dy
            z, -- z
            0, -- dz
            repeatValue,
            octaves,
            persistence
        )
        grid[col] = column
    end
end

