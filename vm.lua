
local gui = require "gui"

local opcodes = {
	add = 100;
	sub = 200;
	lda = 300;
	sta = 500;
	bra = 600;
	brz = 700;
	brp = 800;
	inp = 901;
	out = 902;
	hlt = 000;
	dat = ___; -- no opcode as not instruction
}

local memory = {}
local accumulator = 0
local counter = 0
local vm = {}
local temp = {}
local running = false
local time = 0
local speed = 1/10

local function blank_memory()
	for i = 0, 99 do
		memory[i] = 0
	end
end

local function fetch()
	local m = memory[counter]
	counter = counter + 1
	return m
end

local function decode( i )
	if i == 901 then
		return "inp", 0
	elseif i == 902 then
		return "out", 0
	elseif i < 100 then
		return i == 0 and "hlt" or "dat", i
	else
		local n = i - i % 100
		return opcodes[n] or "hlt", i - n
	end
end

local function execute( i, d )
	vm[i]( d )
end

for k, v in pairs( opcodes ) do
	temp[#temp + 1] = k
end
for i = 1, #temp do
	opcodes[opcodes[temp[i]]] = temp[i]
end

function vm:add()
	gui.log( "Adding address #" .. self .. " (" .. memory[self] .. ") to accumulator (" .. accumulator .. ")\nAccumulator is now " .. accumulator + memory[self] )
	accumulator = accumulator + memory[self]
end

function vm:sub()
	gui.log( "Subtracting address #" .. self .. " (" .. memory[self] .. ") from accumulator (" .. accumulator .. ")\nAccumulator is now " .. accumulator - memory[self] )
	accumulator = accumulator - memory[self]
end

function vm:lda()
	gui.log( "Loading address #" .. self .. " (" .. memory[self] .. ") into accumulator\nAccumulator is now " .. memory[self] )
	accumulator = memory[self]
end

function vm:sta()
	gui.log( "Setting address #" .. self .. " to accumulator (" .. accumulator .. ")" )
	memory[self] = accumulator
end

function vm:bra()
	gui.log( "Jumping to address #" .. self )
	counter = self
end

function vm:brz()
	if accumulator == 0 then
		gui.log( "Jumping to address #" .. self )
		counter = self
	else
		gui.log( "Not jumping to address #" .. self )
	end
end

function vm:brp()
	if accumulator >= 0 then
		gui.log( "Jumping to address #" .. self )
		counter = self
	else
		gui.log( "Not jumping to address #" .. self )
	end
end

function vm:inp()
	gui.log "Waiting for input"
	vm:pause()
	gui.input( function( text )
		vm:resume()
		accumulator = tonumber( text ) or 0
		gui.log( "Input retrieved, setting accumulator to " .. accumulator )
		return ""
	end )
end

function vm:out()
	gui.log( "Outputting accumulator (" .. accumulator .. ")" )
	gui.output( accumulator )
end

function vm:hlt()
	gui.log "Stopping"
	running = false
end

vm.dat = vm.hlt

function vm:compile( instructions, p )
	if #instructions == 0 then return end
	for i = 0, #instructions do
		if instructions[i].data == true then
			memory[i] = instructions[i].instruction
			print( i, decode( instructions[i].instruction ) )
		elseif instructions[i].instruction == "dat" then
			memory[i] = ( instructions[i].data or 0 )
			print( i, "dat", instructions[i].data )
		elseif instructions[i].data then
			memory[i] = opcodes[instructions[i].instruction] + instructions[i].data
			print( i, instructions[i].instruction, instructions[i].data )
		else
			memory[i] = opcodes[instructions[i].instruction]
			print( i, instructions[i].instruction )
		end
	end
end

function vm:reset()
	accumulator = 0
	counter = 0
	blank_memory()
end

function vm:isRunning()
	return running
end

function vm:pause()
	running = false
end

function vm:resume()
	running = true
end

function vm:step( dt )
	time = time + dt
	if time >= speed then
		time = time - speed
		local i = fetch()
		local n, d = decode( i )
		execute( n, d )
	end
end

function vm:getInstruction()
	return counter
end

function vm:getMemory( i )
	return memory[i]
end

function vm:getAccumulator()
	return accumulator
end

function vm:getSpeed()
	return 1/speed
end

function vm:setInstruction( i )
	counter = i
end

function vm:setMemory( i, v )
	memory[i] = v
end

function vm:setAccumulator( v )
	accumulator = v
end

function vm:setSpeed( s )
	speed = 1/s
end

return vm
