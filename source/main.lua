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
local xOffset = 0.5
local yOffset = 0.5
local xPosition = 0.0
local yPosition = 0.0

-- Generation variables. Controlled in the options grid
local generationKeys = { "size", "z" } -- , "repeat", "octaves", "persistence"}
local generationVariables = {
    size = 10,
    z = 0,
}

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
    local label = generationKeys[row]
    local value = generationVariables[label]
    gfx.drawTextInRect(
        string.format("%s = %.2f", label, value),
        x + plusWidth + 2*padding,
        y+4,
        width - 2*plusWidth - 4*padding,
        height,
        nil,
        "...",
        kTextAlignment.center
    )
end

-- random = 0, perlin = 1, perlinArray = 2
local generationMethod <const> = 1

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

    -- Show the optionList when we're not modifying it and the user hits 🅰️
    if not isModfiyingVariables and playdate.buttonJustPressed(playdate.kButtonA) then
        isModfiyingVariables = true
    end

    -- If we are showing the option list and they hit 🅱️, dismiss it
    if isModfiyingVariables and playdate.buttonJustPressed(playdate.kButtonB) then
        isModfiyingVariables = false
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
        if playdate.buttonIsPressed(playdate.kButtonB) then
            yOffset -= 0.1
            if yOffset < 0 then
                yOffset += 1
            end
        else
            yPosition -= 1
        end
        regenerateGrid()
        drawEverything()
    end

end

function playdate.downButtonDown()
    if isModfiyingVariables then
        optionList:selectNextRow()
    else
        if playdate.buttonIsPressed(playdate.kButtonB) then
            yOffset += 0.1
            if yOffset >= 1.0 then
                yOffset -= 1
            end
        else
            yPosition += 1
        end
        regenerateGrid()
        drawEverything()
    end
end

function playdate.leftButtonDown()
    if isModfiyingVariables then
    else
        if playdate.buttonIsPressed(playdate.kButtonB) then
            xOffset -= 0.1
            if xOffset < 0 then
                xOffset += 1
            end
        else
            xPosition -= 1
        end
    end
    regenerateGrid()
    drawEverything()
end

function playdate.rightButtonDown()
    if isModfiyingVariables then
    else
        if playdate.buttonIsPressed(playdate.kButtonB) then
            xOffset += 0.1
            if xOffset >= 1.0 then
                xOffset -= 1
            end
        else
            xPosition += 1
        end
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
    gfx.drawText(string.format("x = %.2f", xPosition + xOffset), firstColumnX, 5)
    gfx.drawText(string.format("y = %.2f", yPosition + yOffset), secondColumnX, 5)
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
    local size = generationVariables.size
    for row = 1, size, 1 do
        for col = 1, size, 1 do
            local value = gfx.perlin(
                (col - 1) + xOffset + xPosition,
                (row - 1) + yOffset + yPosition,
                1,
                0
            )
            grid[col][row] = value
        end
    end
end
