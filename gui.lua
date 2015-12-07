
love.keyboard.setKeyRepeat( true )

local parse = require "parse"

local gui = {}
local width, height = love.window.getDimensions()
local boxWidth, boxHeight, boxPadding, boxInternalHeight = 0, 0, 5, 0
local input, inputWidth, inputHeight, inputPadding, inputTextHeight, inputHeaderHeight, inputHeaderText = nil, 0, 0, 10, 30, 40, "Please enter a number:"
local speedControlInput
local header = "LMC Simulator v1 - Benedict Allen 2015"
local active_input
local inputs = {}
local buttons = {}
local dimensions, colours, fonts
local log = "Type code in the box to the left, then compile and run to see its effect."
local output = ""
local run
local code = { "" }
local codeScrollX, codeScrollY = 0, 0
local codeCursorX, codeCursorY = 0, 1
local codeCursorblink = 0
local codeActive = false
local codeArea

local vm

local function setCodeCursorPosition( x, y )
	codeCursorblink = 0
	codeCursorX = math.min( x, #code[y] )
	codeCursorY = y

	local cHeight = fonts.code:getHeight() * ( codeCursorY - 1 )
	local cWidth = fonts.code:getWidth( code[codeCursorY]:sub( 1, codeCursorX ) )

	if cHeight > codeScrollY + codeArea.height - 10 - fonts.code:getHeight() then
		codeScrollY = cHeight - codeArea.height + 10 + fonts.code:getHeight()
	elseif cHeight < codeScrollY then
		codeScrollY = cHeight
	end
end

local function countLines( text )
	return select( 2, text:gsub( "\n", "" ) ) + 1
end

local function newInputBox( x, y, width, height, text, font )
	return {
		active = false;
		x = x, y = y;
		width = width, height = height;
		text = text or "";
		cursor = 0;
		scroll = 0;
		cursorblink = 0;
		callback = nil;
		font = font or love.graphics.newFont( height * .8 );
		valid = "0-9a-zA-Z%s";
	}
end

local function addButton( x, y, width, height, text, font )
	local button = {
		x = x, y = y;
		width = width, height = height;
		text = text or "";
		onClick = nil;
		font = font or love.graphics.newFont( height * .8 );
	}
	buttons[#buttons + 1] = button
	return button
end

local function setCursorPosition( input, position )
	input.cursor = position
	input.cursorblink = 0

	local tWidth = input.font:getWidth( input.text:sub( 1, position ) )

	if -tWidth > input.scroll then
		input.scroll = -tWidth
	elseif input.width - 4 - tWidth < input.scroll then
		input.scroll = input.width - 4 - tWidth
	end
end

local function deselectInput()
	if active_input then
		active_input.active = false
		active_input = nil
	end
	codeActive = false
end

local function selectInput( input, cursor )
	deselectInput()
	input.active = true
	active_input = input
	input.cursorblink = 0

	if not cursor then return end

	for i = 1, #input.text do
		local cWidth = input.font:getWidth( input.text:sub( i, i ) ) / 2
		cursor = cursor - cWidth
		if cursor <= 0 then
			setCursorPosition( input, i - 1 )
			return
		end
		cursor = cursor - cWidth
	end

	input.cursor = #input.text
end

local function collisionWithObject( x, y, input )
	return x >= input.x and x < input.x + input.width and y >= input.y and y < input.y + input.height
end

dimensions = {
	header = { width = width, height = height * .1 };
	sidebar = { width = width * .3, height = height * .9 };
	box_area = { width = width * .7, height = height * .7 };
	footer = { width = width * .7, height = height * .2 };
}

boxWidth = ( dimensions.box_area.width - boxPadding ) / 10 - boxPadding
boxHeight = ( dimensions.box_area.height - boxPadding ) / 10 - boxPadding
boxInternalHeight = boxHeight - 2 * boxPadding

colours = {
	background = { 245, 245, 245 };
	header = { 180, 180, 180 };
	header_text = { 0, 0, 0, 200 };
	sidebar = { 230, 230, 230 };
	code = { 255, 255, 255 };
	code_text = { 0, 0, 0, 130 };
	box_area = { 245, 245, 245 };
	box = { 255, 255, 255 };
	box_active = { 230, 230, 50 };
	box_text = { 0, 0, 0, 170 };
	footer = { 180, 180, 180 };
	footer_text = { 0, 0, 0, 200 };
	output = { 245, 245, 245 };
	output_text = { 0, 0, 0, 130 };
	input = { 200, 200, 200 };
	input_header = { 180, 180, 180 };
	input_header_text = { 0, 0, 0, 200 };
	input_box = { 255, 255, 255 };
	input_box_text = { 0, 0, 0, 170 };
	button = { 50, 120, 190 };
	button_text = { 255, 255, 255, 255 };
	log_text = { 0, 0, 0, 200 };
}

fonts = {
	header = love.graphics.newFont( dimensions.header.height * .4 );
	box = love.graphics.newFont( boxHeight * .5 );
	box_lower = love.graphics.newFont( boxPadding * 1.6 );
	footer = love.graphics.newFont( 16 );
	input_header = love.graphics.newFont( inputHeaderHeight * .5 );
	code = love.graphics.newFont( "code-font.ttf", 16 );
	output = love.graphics.newFont( 16 );
	log = love.graphics.newFont( 15 );
}

local function drawInput( input )
	love.graphics.setColor( colours.input_box )
	love.graphics.rectangle( "fill", input.x, input.y, input.width, input.height )

	love.graphics.setScissor( input.x + 1, input.y + 1, input.width - 2, input.height - 2 )
	love.graphics.setColor( colours.input_box_text )
	love.graphics.setFont( input.font )
	love.graphics.print( input.text, input.x + 1 + input.scroll, input.y + input.height / 2 - input.font:getHeight() / 2 )

	if input.active then
		if input.cursorblink % 1 < .5 then
			local x = input.x + 2 + input.font:getWidth( input.text:sub( 1, input.cursor ) ) + input.scroll
			love.graphics.line( x, input.y + 2, x, input.y + input.height - 4 )
		end
	end

	love.graphics.setScissor()
end

local function drawButton( button )
	love.graphics.setColor( colours.button )
	love.graphics.rectangle( "fill", button.x, button.y, button.width, button.height )

	love.graphics.setColor( colours.button_text )
	love.graphics.setFont( button.font )
	love.graphics.print( button.text, button.x + button.width / 2 - button.font:getWidth( button.text ) / 2, button.y + button.height / 2 - button.font:getHeight() / 2 )
end

local function drawBoxes()
	local active = vm:getInstruction()
	for x = 0, 9 do
		for y = 0, 9 do
			local sx = dimensions.sidebar.width + boxPadding + x * ( boxWidth + boxPadding )
			local sy = dimensions.header.height + boxPadding + y * ( boxHeight + boxPadding )

			local index = y * 10 + x
			local value = tostring( vm:getMemory( index ) )

			love.graphics.setColor( active == index and colours.box_active or colours.box )
			love.graphics.rectangle( "fill", sx, sy + boxHeight - boxInternalHeight, boxWidth, boxInternalHeight )

			love.graphics.setColor( colours.box_text )
			love.graphics.setFont( fonts.box_lower )
			love.graphics.print( tostring( y * 10 + x ), sx, sy )

			love.graphics.setColor( colours.box_text )
			love.graphics.setFont( fonts.box )
			love.graphics.print( value, sx + boxWidth / 2 - fonts.box:getWidth( value ) / 2, sy - boxInternalHeight / 2 - fonts.box:getHeight() / 2 + boxHeight )
		end
	end
end

local function drawCode()
	local cX, cY, cWidth, cHeight = codeArea.x, codeArea.y, codeArea.width, codeArea.height
	local tX, tY, tWidth, tHeight = cX + 5, cY + 5, cWidth - 10, cHeight - 10

	love.graphics.setColor( colours.code )
	love.graphics.rectangle( "fill", cX, cY, cWidth, cHeight )
	love.graphics.setScissor( tX, tY, tWidth, tHeight )

	love.graphics.setFont( fonts.code )
	love.graphics.setColor( colours.code_text )
	tX, tY = tX - codeScrollX, tY - codeScrollY

	for i = 1, #code do
		local line = code[i]
		love.graphics.print( line, tX, tY )

		if i == codeCursorY and codeActive and codeCursorblink % 1 < .5 then
			local x = tX + fonts.code:getWidth( line:sub( 1, codeCursorX ) ) + 1
			love.graphics.line( x, tY, x, tY + fonts.code:getHeight() )
		end

		tY = tY + fonts.code:getHeight()
	end

	love.graphics.setScissor()
end

local function drawOutput()
	local oX, oY, oWidth, oHeight = dimensions.sidebar.width + 400, dimensions.header.height + dimensions.box_area.height + 30, dimensions.footer.width - 410, dimensions.footer.height - 35
	local tX, tY, tWidth, tHeight = oX + 5, oY + 5, oWidth - 10, oHeight - 10

	love.graphics.setColor( colours.output )
	love.graphics.rectangle( "fill", oX, oY, oWidth, oHeight )
	love.graphics.setScissor( tX, tY, tWidth, tHeight )

	love.graphics.setFont( fonts.output )
	love.graphics.setColor( colours.output_text )

	local lines = countLines( output )
	local totalHeight = lines * fonts.output:getHeight()
	if totalHeight > tHeight then
		tY = tY + tHeight - totalHeight
	end

	for line in output:gmatch "[^\n]+" do
		love.graphics.print( line, tX, tY )
		tY = tY + fonts.output:getHeight()
	end

	love.graphics.setScissor()
end

local function drawBackground()
	love.graphics.setColor( colours.background )
	love.graphics.clear()
end

local function drawHeader()
	love.graphics.setColor( colours.header )
	love.graphics.rectangle( "fill", 0, 0, dimensions.header.width, dimensions.header.height )
	love.graphics.setColor( colours.header_text )
	love.graphics.setFont( fonts.header )
	love.graphics.print( header, dimensions.header.width / 2 - fonts.header:getWidth( header ) / 2, dimensions.header.height / 2 - fonts.header:getHeight() / 2 )
end

local function drawSidebar()
	love.graphics.setColor( colours.sidebar )
	love.graphics.rectangle( "fill", 0, dimensions.header.height, dimensions.sidebar.width, dimensions.sidebar.height )
	drawCode()
end

local function drawBoxArea()
	love.graphics.setColor( colours.box_area )
	love.graphics.rectangle( "fill", dimensions.sidebar.width, dimensions.header.height, dimensions.box_area.width, dimensions.box_area.height )
	drawBoxes()
end

local function drawFooter()
	love.graphics.setColor( colours.footer )
	love.graphics.rectangle( "fill", dimensions.sidebar.width, dimensions.header.height + dimensions.box_area.height, dimensions.footer.width, dimensions.footer.height )

	love.graphics.setColor( colours.footer_text )
	love.graphics.setFont( fonts.footer )

	love.graphics.print( "Speed", dimensions.sidebar.width + 5, dimensions.header.height + dimensions.box_area.height + 5 )
	love.graphics.print( "PC", dimensions.sidebar.width + 140, dimensions.header.height + dimensions.box_area.height + 5 )
	love.graphics.print( "Acc", dimensions.sidebar.width + 250, dimensions.header.height + dimensions.box_area.height + 5 )
	love.graphics.print( "Output", dimensions.sidebar.width + 400, dimensions.header.height + dimensions.box_area.height + 5 )

	love.graphics.setColor( colours.input_box )
	love.graphics.rectangle( "fill", dimensions.sidebar.width + 165, dimensions.header.height + dimensions.box_area.height + 5, 50, 20 )
	love.graphics.setColor( colours.input_box_text )
	love.graphics.setFont( fonts.footer )
	love.graphics.print( tostring( vm:getInstruction() ), dimensions.sidebar.width + 166, dimensions.header.height + dimensions.box_area.height + 14 - fonts.footer:getHeight() / 2 )

	love.graphics.setColor( colours.input_box )
	love.graphics.rectangle( "fill", dimensions.sidebar.width + 285, dimensions.header.height + dimensions.box_area.height + 5, 50, 20 )
	love.graphics.setColor( colours.input_box_text )
	love.graphics.setFont( fonts.footer )
	love.graphics.print( tostring( vm:getAccumulator() ), dimensions.sidebar.width + 286, dimensions.header.height + dimensions.box_area.height + 14 - fonts.footer:getHeight() / 2 )

	love.graphics.setColor( colours.log_text )
	love.graphics.setFont( fonts.log )
	love.graphics.printf( log, dimensions.sidebar.width + 5, dimensions.header.height + dimensions.box_area.height + 70, 380 )

	drawOutput()
end

local function drawInputBox()
	if not input.active then
		return
	end

	love.graphics.setColor( colours.input )
	love.graphics.rectangle( "fill", width / 2 - inputWidth / 2, height / 2 - inputHeight / 2, inputWidth, inputHeight )
	love.graphics.setColor( colours.input_header )
	love.graphics.rectangle( "fill", width / 2 - inputWidth / 2, height / 2 - inputHeight / 2, inputWidth, inputHeaderHeight )
	love.graphics.setColor( colours.input_header_text )
	love.graphics.setFont( fonts.input_header )
	love.graphics.print( inputHeaderText, width / 2 - fonts.input_header:getWidth( inputHeaderText ) / 2, height / 2 - inputHeight / 2 + inputHeaderHeight / 2 - fonts.input_header:getHeight() / 2 )

	drawInput( input )
end

function gui.draw()
	drawBackground()
	drawHeader()
	drawSidebar()
	drawBoxArea()
	drawFooter()

	for i = 1, #inputs do
		drawInput( inputs[i] )
	end
	for i = 1, #buttons do
		drawButton( buttons[i] )
	end

	drawInputBox()
end

function gui.input( callback )
	input.callback = callback
	input.text = ""
	input.cursor = 0
	input.active = true
	selectInput( input )
end

function gui.output( text )
	output = output .. ( output == "" and "" or "\n" ) .. tostring( text )
end

function gui.log( text )
	log = tostring( text )
end

function gui.mousepressed( x, y, button )
	if button ~= "l" then
		return
	end

	if active_input ~= input then
		deselectInput()
		codeActive = false

		for i = 1, #inputs do
			if collisionWithObject( x, y, inputs[i] ) then
				return selectInput( inputs[i], x - inputs[i].x )
			end
		end

		if collisionWithObject( x, y, codeArea ) then
			local cy = math.max( math.min( #code, math.ceil( ( y - codeArea.y - 5 + codeScrollY ) / fonts.code:getHeight() ) ), 1 )
			local cx = 0

			codeActive = true
			x = x - codeArea.x - 5 + codeScrollX

			for i = 1, #code[cy] do
				local w = fonts.code:getWidth( code[cy]:sub( i, i ) ) / 2
				if x - w <= 0 then
					break
				end
				x = x - w * 2
				cx = cx + 1
			end

			setCodeCursorPosition( cx, cy )
		end
	end

	for i = 1, #buttons do
		if collisionWithObject( x, y, buttons[i] ) then
			if buttons[i].onClick then
				buttons[i]:onClick()
			end
			return
		end
	end

	if collisionWithObject( x, y, input ) then
		return selectInput( input, x - input.x - input.scroll )
	end
end

function gui.keypressed( key )
	if codeActive then
		if key == "left" and codeCursorX > 0 then
			setCodeCursorPosition( codeCursorX - 1, codeCursorY )
		elseif key == "right" and codeCursorX < #code[codeCursorY] then
			setCodeCursorPosition( codeCursorX + 1, codeCursorY )
		elseif key == "left" and codeCursorY > 1 then
			setCodeCursorPosition( #code[codeCursorY - 1], codeCursorY - 1 )
		elseif key == "right" and codeCursorY < #code then
			setCodeCursorPosition( 0, codeCursorY + 1 )
		elseif key == "up" and codeCursorY > 1 then
			setCodeCursorPosition( codeCursorX, codeCursorY - 1 )
		elseif key == "down" and codeCursorY < #code then
			setCodeCursorPosition( codeCursorX, codeCursorY + 1 )
		elseif key == "backspace" and codeCursorX > 0 then
			code[codeCursorY] = code[codeCursorY]:sub( 1, codeCursorX - 1 ) .. code[codeCursorY]:sub( codeCursorX + 1 )
			setCodeCursorPosition( codeCursorX - 1, codeCursorY )
		elseif key == "backspace" and codeCursorY > 1 then
			local pos = #code[codeCursorY - 1]
			code[codeCursorY - 1] = code[codeCursorY - 1] .. code[codeCursorY]
			table.remove( code, codeCursorY )
			setCodeCursorPosition( pos, codeCursorY - 1 )
		elseif key == "delete" and codeCursorX < #code[codeCursorY] then
			code[codeCursorY] = code[codeCursorY]:sub( 1, codeCursorX ) .. code[codeCursorY]:sub( codeCursorX + 2 )
		elseif key == "delete" and codeCursorY < #code then
			code[codeCursorY] = code[codeCursorY] .. code[codeCursorY + 1]
			table.remove( code, codeCursorY + 1 )
		elseif key == "return" then
			table.insert( code, codeCursorY + 1, code[codeCursorY]:sub( codeCursorX + 1 ) )
			code[codeCursorY] = code[codeCursorY]:sub( 1, codeCursorX )
			setCodeCursorPosition( 0, codeCursorY + 1 )
		elseif key == "c" and love.keyboard.isDown "lctrl" then
			gui.log "Copied"
			love.system.setClipboardText( table.concat( code, "\n" ) )
		elseif key == "v" and love.keyboard.isDown "lctrl" then
			gui.log "Pasted"
			code = {}
			codeCursorX = 0
			for line in love.system.getClipboardText():gmatch "[^\n\r]+" do
				code[#code + 1] = line
				codeCursorX = #line
			end
			if #code == 0 then
				code[1] = ""
			end
			codeCursorY = #code
		end
	elseif active_input then
		if key == "left" and active_input.cursor > 0 then
			setCursorPosition( active_input, active_input.cursor - 1 )
		elseif key == "right" and active_input.cursor < #active_input.text then
			setCursorPosition( active_input, active_input.cursor + 1 )
		elseif key == "backspace" and active_input.cursor > 0 then
			active_input.text = active_input.text:sub( 1, active_input.cursor - 1 ) .. active_input.text:sub( active_input.cursor + 1 )
			setCursorPosition( active_input, active_input.cursor - 1 )
		elseif key == "delete" and active_input.cursor < #active_input.text then
			active_input.text = active_input.text:sub( 1, active_input.cursor ) .. active_input.text:sub( active_input.cursor + 2 )
		elseif key == "return" and active_input.callback then
			active_input.text = active_input.callback( active_input.text )
			deselectInput()
		end
	end
end

function gui.textinput( text )
	if codeActive then
		code[codeCursorY] = code[codeCursorY]:sub( 1, codeCursorX ) .. text .. code[codeCursorY]:sub( codeCursorX + 1 )
		setCodeCursorPosition( codeCursorX + #text, codeCursorY )
	elseif active_input then
		active_input.text = active_input.text:sub( 1, active_input.cursor ) .. text:gsub( "[^" .. active_input.valid .. "]", "" ) .. active_input.text:sub( active_input.cursor + 1 )
		setCursorPosition( active_input, active_input.cursor + #text )
	end
end

function gui.update( dt )
	if active_input then
		active_input.cursorblink = active_input.cursorblink + dt
	end
	codeCursorblink = codeCursorblink + dt
	run.text = ( vm:isRunning() or input.active ) and "Stop" or "Run"
end

function gui.load( v )
	vm = v

	inputWidth, inputHeight = width * .6, inputTextHeight + inputHeaderHeight + inputPadding * 2
	input = newInputBox( width / 2 - inputWidth / 2 + inputPadding, height / 2 + inputHeight / 2 - inputPadding - inputTextHeight, inputWidth - inputPadding * 2, inputTextHeight )
	input.valid = "0-9"

	speedControlInput = newInputBox( dimensions.sidebar.width + 60, dimensions.header.height + dimensions.box_area.height + 4, 50, 20, tostring( vm:getSpeed() ) )
	inputs[1] = speedControlInput

	speedControlInput.valid = "0-9%."

	function speedControlInput:callback()
		vm:setSpeed( ( tonumber( self ) or 1 ) )
		speedControlInput.text = tostring( tonumber( self ) or 1 )
		return self
	end

	local compile = addButton( dimensions.sidebar.width + 5, dimensions.header.height + dimensions.box_area.height + 30, 125, 35, "Compile" )
	local clear = addButton( dimensions.sidebar.width + 135, dimensions.header.height + dimensions.box_area.height + 30, 125, 35, "Clear" )
	run = addButton( dimensions.sidebar.width + 265, dimensions.header.height + dimensions.box_area.height + 30, 125, 35, "Run" )
	local clearoutput = addButton( width - 130, dimensions.header.height + dimensions.box_area.height + 5, 125, 20, "Clear Output" )

	function compile:onClick()
		vm:setInstruction( 0 )
		vm:compile( parse.parse( table.concat( code, "\n" ) ) )
	end

	function clear:onClick()
		vm:reset()
	end

	function run:onClick()
		if vm:isRunning() or input.active then
			vm:pause()
			deselectInput()
		else
			vm:setInstruction( 0 )
			vm:setAccumulator( 0 )
			vm:resume()
		end
	end

	function clearoutput:onClick()
		output = ""
	end

	codeArea = { x = 5, y = dimensions.header.height + 5, width = dimensions.sidebar.width - 10, height = dimensions.sidebar.height - 10 }
end

return gui
