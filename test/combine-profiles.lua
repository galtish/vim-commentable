#! /usr/bin/env lua

local utils = require("utils")

-- Constants relating to vim's profile output
local COUNT_INDICATION = 5
local TOTAL_START = 9
local TOTAL_END = 16
local SELF_START = 20
local SELF_END = 27
local REAL_LINE_START = 29

--[========================================================================]--
--[ parseargs (args) {{{                                                   ]--
--[========================================================================]--
local function parseargs (args)
	local parsed = {}

	local function addarg (name, elem, uniq)
		if parsed[name] == nil then
			if uniq then
				parsed[name] = elem
			else
				parsed[name] = {elem}
			end
		else
			if uniq then
				error("Multiple instances of unique argument --" .. name)
			else
				local l = parsed[name]
				l[#l+1] = elem
			end
		end
	end

	local STATE_LOCK   = -1
	local STATE_NORM   = 0
	local STATE_OUTPUT = 1
	local state        = STATE_NORM

	local lastarg = nil

	for _, arg in ipairs(args) do
		lastarg = arg
		if state == STATE_LOCK then
			addarg('profiles', arg)
		elseif state == STATE_NORM then
			if arg == '--' then
				state = STATE_LOCK
			elseif arg == '-o' or arg == '--output' then
				state = STATE_OUTPUT
			else
				addarg('profiles', arg)
			end
		elseif state == STATE_OUTPUT then
			addarg('output', arg, true)
			state = STATE_NORM
		else
			error("Programming error in parseargs()")
		end
	end

	if state ~= STATE_NORM and state ~= STATE_LOCK then
		error("Missing mandatory argument to arg: " .. lastarg)
	end

	if not parsed.profiles then
		parsed.profiles = {}
	end

	return parsed
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ printprofile (profile, tofile) {{{                                     ]--
--[========================================================================]--
local function printprofile (profile, tofile)
	local out
	if tofile then
		out = io.open(tofile, 'w')
	else
		out = io.output()
	end

	for k, v in pairs(profile.scripts) do
		for m, n in ipairs(v.lines) do
			out:write(string.format(
				"%+e\t%+e\t%+e\t%s\n",
				(n.callcount or -1),
				(n.total or -1),
				(n.self or -1),
				n.text))
		end
	end

	if tofile then
		out:close()
	end
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ readprofile (profilefile) {{{                                          ]--
--[========================================================================]--
local function readprofile (profilefile)
	local STATE_NONE           = 0
	local STATE_SCRIPTHEADER   = 1
	local STATE_SCRIPTBODY     = 2
	local STATE_FUNCTIONHEADER = 3
	local STATE_FUNCTIONBODY   = 4
	local STATE_TOTALFUNCTIONS = 5
	local STATE_SELFFUNCTIONS  = 6
	local state = STATE_NONE

	local scripts = {}
	local funcs = {}

	local function newthing (name, thingtype) -- {{{

		local function thingaddline (this, line) -- {{{
			local callcount = 0
			local total = 0.0
			local self = 0.0

			if line:sub(COUNT_INDICATION, COUNT_INDICATION) ~= " " then
				-- there is a call count
				local cc = line:match('^%s*(%d+)')
				callcount = tonumber(cc)
			end

			if line:sub(TOTAL_START, TOTAL_START) ~= " " then
				local cc = line:sub(TOTAL_START, TOTAL_END)
				total = tonumber(cc)
			end

			if line:sub(SELF_START, SELF_START) ~= " " then
				local cc = line:sub(SELF_START, SELF_END)
				self = tonumber(cc)
			end

			local baseline = line:sub(REAL_LINE_START)
			if baseline:match("^%s*$") or baseline:match("^%s*\".*$") or
		   	baseline:match("^%s*end") then
				-- line is a comment
				this.lines[#this.lines+1] = {
					["callcount"] = nil,
					["total"] = nil,
					["self"] = nil,
					["text"] = baseline,
				}
			else
				local joinmatch = baseline:match("^%s*\\(.*)$")
				if joinmatch then
					-- Have to combine line joins
					local prevline = this.lines[#this.lines]
					local newline = {
						["callcount"] = prevline.callcount,
						["total"] = prevline.total,
						["self"] = prevline.self,
						["text"] = prevline.text .. joinmatch,
					}
					this.lines[#this.lines] = newline
				else
					this.lines[#this.lines+1] = {
						["callcount"] = callcount,
						["total"] = total,
						["self"] = self,
						["text"] = baseline,
					}
				end
			end
		end -- }}}

		local function thingclose (this) -- {{{
			if thingtype == 'script' then
				scripts[name] = this
			elseif thingtype == 'func' then
				funcs[name] = this
			end
		end -- }}}

		return {
			["name"] = name,
			["lines"] = {},
			["addline"] = thingaddline,
			["close"] = thingclose,
		}
	end -- }}}

	local function statechange (to) -- {{{
		state = to
	end -- }}}

	-- A 'thing' is either a script or a function that we're currently
	-- processing.
	local thing = newthing('fake', 'nothing')

	for line in io.lines(profilefile) do
		if state == STATE_NONE then
			local scriptname = line:match("^SCRIPT%s+(.*)$")
			if scriptname then
				statechange(STATE_SCRIPTHEADER)
				thing:close()
				thing = newthing(scriptname, 'script')
			elseif line:match("^%s*$") then
				-- blank line, skip
			else
				error("Unexpected line :" .. line)
			end
		elseif state == STATE_SCRIPTHEADER then
			-- STATE: SCRIPTHEADER
			if line == "count  total (s)   self (s)" then
				statechange(STATE_SCRIPTBODY)
			end
		elseif state == STATE_SCRIPTBODY then
			-- STATE: SCRIPTBODY
			local scriptname = line:match("^SCRIPT%s+(.*)$")
			local funcname = line:match("^FUNCTION%s+(.*)$")
			if scriptname then
				statechange(STATE_SCRIPTHEADER)
				thing:close()
				thing = newthing(scriptname, 'script')
			elseif funcname then
				statechange(STATE_FUNCTIONHEADER)
				thing:close()
				thing = newthing(funcname, 'func')
			elseif line == "FUNCTIONS SORTED ON TOTAL TIME" then
				statechange(STATE_TOTALFUNCTIONS)
				thing:close()
			else
				thing:addline(line)
			end
		elseif state == STATE_FUNCTIONHEADER then
			-- STATE: FUNCTIONHEADER
			if line == "count  total (s)   self (s)" then
				statechange(STATE_FUNCTIONBODY)
			end
		elseif state == STATE_FUNCTIONBODY then
			-- STATE: FUNCTIONBODY
			local funcname = line:match("^FUNCTION%s+(.*)$")
			if funcname then
				statechange(STATE_FUNCTIONHEADER)
				thing:close()
				thing = newthing(funcname, 'func')
			elseif line == "FUNCTIONS SORTED ON TOTAL TIME" then
				statechange(STATE_TOTALFUNCTIONS)
				thing:close()
			else
				thing:addline(line)
			end
		elseif state == STATE_TOTALFUNCTIONS then
			-- STATE: TOTALFUNCTIONS
			if line == "FUNCTIONS SORTED ON SELF TIME" then
				-- TODO use total functions
				statechange(STATE_SELFFUNCTIONS)
			end
		elseif state == STATE_SELFFUNCTIONS then
			-- STATE: SELFFUNCTIONS
			-- TODO use self functions
		else
			error("Programming error, state: " .. state)
		end
	end

	return {
		["scripts"] = scripts,
		["funcs"] = funcs,
	}
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ mungefunctions (profile) {{{                                           ]--
--[========================================================================]--
local function mungefunctions (profile)
	return profile
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ consprofile (profiles, newprofile) {{{                                 ]--
--[========================================================================]--
local function consprofile (profiles, newprofile)

	local newscripts = newprofile.scripts or {}
	local newfuncs = newprofile.funcs or {}

	local k, v

	for k, v in pairs(newscripts) do
		if profiles.scripts[k] then
			-- Sum the callcounts throughout the script
			local olines = v.lines
			local lines = profiles.scripts[k].lines
			local count = #olines
			for lnum = 1, count do
				local line = lines[lnum]
				local oline = olines[lnum]
				if line.callcount then
					line.callcount = oline.callcount + line.callcount
				else
					line.callcount = oline.callcount
				end

				if line.total then
					line.total = line.total + oline.total
				end

				if line.self then
					line.self = line.self + oline.self
				end
			end
		else
			profiles.scripts[k] = v
		end
	end

	for k, v in pairs(newfuncs) do
	end

	return profiles
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ main (args) {{{                                                        ]--
--[========================================================================]--
local function main (args)
	local args = parseargs(args)
	local profiles = {["scripts"] = {}, ["funcs"] = {}}

	for _, prof in ipairs(args.profiles) do
		if not utils.isfile(prof) then
			error("Cannot read profile " .. prof)
		else
			profiles = consprofile(profiles, mungefunctions(readprofile(prof)))
		end
	end

	printprofile(profiles, args.output)

	return 0
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

local success, rc = pcall(main, arg)
if success then
	os.exit(rc)
else
	print("Error: " .. rc)
	os.exit(1)
end