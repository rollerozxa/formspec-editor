---------------------------------
---------Formspec Editor---------
---------------------------------
-----------By ExeVirus-----------

--Fix builtin
minetest.register_alias("mapgen_stone", "air")
minetest.register_alias("mapgen_water_source", "air")

--Variables
local modpath = minetest.get_modpath("formspec_edit")

local insecure_env = minetest.request_insecure_environment()
if not insecure_env then
	error("[formspec_editor] Cannot access insecure environment!\n"..
	      "Please add 'formspec_edit' to your list of trusted mods in your settings")
end

local io = insecure_env.io
local update_time = 0.2

--Load provided file if present
local dirpath = minetest.settings:get("formspec_editor.directory")
if not dirpath or dirpath == "" then
	dirpath = modpath
end

--Crash if not singleplayer
--TODO: hide the 'Host server' checkbox in main menu then possible
if not minetest.is_singleplayer() then
	error("[formspec_editor] This game doesn't work in multiplayer!")
end

local error_formspec = [[
formspec_version[4]
size[8,2]
label[0.375,0.5;Error:formspec.spec is either ]
label[0.375,1;non-existent,or empty]
]]

--function definitions

-----------------------------------
--file_get_contents()
-----------------------------------
local function file_get_contents(filename)
	local file = io.open(filename, "rb")
	if file == nil then
		return -1
	else
		local content = file:read("*all")
		file:close()
		if content == nil then
			return -1
		else
			return content
		end
	end
end

-----------------------------------
--load_formspec()
-----------------------------------
local function load_formspec()
	local formspec = file_get_contents(dirpath.."/formspec_editor.formspec")
	local variablesjson = file_get_contents(dirpath.."/formspec_variables.json")

	if formspec == -1 then
		return error_formspec
	else
		if variablesjson == -1 then
			return formspec
		else
			variables = minetest.parse_json(variablesjson)
			for k,v in pairs(variables) do
				formspec = formspec:gsub("${"..k.."}", v)
			end

			return formspec
		end
	end
end

-----------------------------------
--update_formspec()
-----------------------------------
local function update_formspec(player_name)
	minetest.after(0.1, function(name)
		minetest.show_formspec(name, "fs", load_formspec())
	end, player_name)
end

-----------------------------------
--turn_off_hud()
-----------------------------------
local function turn_off_hud(player_ref)
	player_ref:hud_set_flags({
		hotbar = false,
		healthbar = false,
		crosshair = false,
		wielditem = false,
		breathbar = false,
		minimap = false,
		minimap_radar = false,
	})
end

-----------------------------------
--set_sky()
-----------------------------------
local function set_sky(player_ref)
	player_ref:set_sky({
		base_color = "#303030",
		type = "plain",
		clouds = false,
	})
	player_ref:set_stars({visible = false})
	player_ref:set_sun({visible = false, sunrise_visible = false})
	player_ref:set_moon({visible = false})
	player_ref:override_day_night_ratio(0)
end

--Registrations

--label[1.7,2;... dust ...]

-----------------------------------
--on_joinplayer()
-----------------------------------
minetest.register_on_joinplayer(function(player_ref,_)
	turn_off_hud(player_ref)
	set_sky(player_ref)
end)
-----------------------------------
--on_player_receive_fields()
-----------------------------------
minetest.register_on_player_receive_fields(function(player_ref, _, fields)
	if fields.quit then
		minetest.request_shutdown()
	end
	update_formspec(player_ref:get_player_name())
end)

local time = 0
minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time >= update_time then
		local player = minetest.get_connected_players()[1] --The game isn't supposed to work in multiplayer
		if player then
			update_formspec(player:get_player_name())
		end
		time = 0
	end
end)
