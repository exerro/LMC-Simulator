
local operand_counts = {
	add = 1, sub = 1;
	lda = 1, sta = 1;
	bra = 1, brz = 1, brp = 1;
	inp = 0, out = 0;
	hlt = 0;
	dat = 0;
}

local parse = {}

function parse.parse( str )
	str = str:gsub( "%s*//.-\n", "\n" )
			 :gsub( "%s*//.-$", "" )
			 :gsub( "(%s)[^%S\n]+", "%1" )
			 :gsub( "%s+\n", "\n" )
			 :gsub( "\n+", "\n" )

	local instructions = {}
	local labels = {}
	local i = 0

	for line in str:gmatch "[^\n]+" do
		local ins = line:match "^%w+" or "hlt"
		local label, data

		line = line:gsub( "^%w+%s?", "" )

		if not tonumber( ins ) and not operand_counts[ins:lower()] then
			label = ins
			ins = line:match ("^%w+" or "hlt") :lower()
			line = line:gsub( "^%w+%s?", "" )

			if not operand_counts[ins] then
				ins = "hlt"
			end
		end

		if label then
			labels[label] = i
		end

		if tonumber( ins ) then
			instructions[i] = {
				instruction = tonumber( ins );
				data = true;
			}
			i = i + 1
		else
			ins = ins:lower()

			if operand_counts[ins] == 1 or (#line > 0 and ins == "dat") then
				data = tonumber( line ) or line
			end

			instructions[i] = {
				instruction = ins;
				data = data;
			}

			i = i + 1
		end
	end

	if #instructions == 0 then return {} end

	for i = 0, #instructions do
		if type( instructions[i].data ) == "string" then
			instructions[i].data = labels[instructions[i].data]

			if not instructions[i].data then
				instructions[i].instruction = "hlt"
			end
		end
	end

	return instructions
end

return parse
