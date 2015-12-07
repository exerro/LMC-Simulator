
local vm = require "vm"
local gui = require "gui"
local parse = require "parse"

local plain = love.graphics.getFont()

vm:reset()

function love.load()
	gui.load( vm )
end

function love.mousepressed( x, y, button )
	gui.mousepressed( x, y, button )
end

function love.keypressed( key )
	gui.keypressed( key )
end

function love.textinput( text )
	gui.textinput( text )
end

function love.update( dt )
	gui.update( dt )
	if vm:isRunning() then
		vm:step( dt )
	end
end

function love.draw()
	gui.draw( vm )
	love.graphics.setFont( plain )
	love.graphics.setColor( 255, 255, 255 )
	love.graphics.print( love.timer.getFPS(), 0, 0 )
end
