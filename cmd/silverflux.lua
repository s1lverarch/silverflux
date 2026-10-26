#!/usr/bin/env lua
-- silverflux — SilverArch sync: pacman + AUR + mirrors
-- Author: Silvercore (s1lverarch) <s1lv3rcore@proton.me>
-- Website: https://s1lverarch.github.io/linuxdistro/
-- License: GPL-v3.0

local VERSION     = "0.1.0"
local HOME        = os.getenv("HOME") or "/root"
local CONFIG_DIR  = HOME .. "/.config/silverflux"
local CONFIG_FILE = CONFIG_DIR .. "/config.lua"
local MIRRORLIST  = "/etc/pacman.d/mirrorlist"

-- ── Colors (truecolor) ────────────────────────────────────────────────────────
local R = "\27[0m"
local B = "\27[1m"
local function rgb(r, g, b) return string.format("\27[38;2;%d;%d;%dm", r, g, b) end
local COL = {
	silver = rgb(192, 192, 192),
	cyan   = rgb(0, 255, 208),
	blue   = rgb(0, 191, 255),
	green  = rgb(0, 255, 127),
	yellow = rgb(255, 215, 0),
	red    = rgb(255, 68, 102),
	dim    = rgb(102, 102, 102),
}

local function out(tag, color, msg)
	print(string.format(" %s%s%s %s", color, B, tag, R .. msg))
end
local function info(m) out("::", COL.blue, m) end
local function ok(m)   out("✓", COL.green, m) end
local function warn(m) out("!", COL.yellow, m) end
local function die(m)  out("✘", COL.red, m); os.exit(1) end

-- ── Shell helpers ─────────────────────────────────────────────────────────────
local function shq(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

local function run(cmd)
	local a, _, code = os.execute(cmd)
	if type(a) == "number" then return a == 0 end -- Lua 5.1/5.2
	return code == 0                              -- Lua 5.3+
end

local function capture(cmd)
	local p = io.popen(cmd)
	if not p then return "" end
	local s = p:read("*a") or ""
	p:close()
	return (s:gsub("%s+$", ""))
end

local function has(bin)
	return capture("command -v " .. bin .. " 2>/dev/null") ~= ""
end

local function is_root()
	return capture("id -u") == "0"
end

-- ── Config ────────────────────────────────────────────────────────────────────
local config = {
	aur_helper    = "auto",      -- auto | paru | yay | none
	mirror_method = "reflector", -- reflector | rate-mirrors | none
	mirror_count  = 20,          -- how many fastest mirrors to keep
	keep_versions = 3,           -- rollback: keep N old versions (0 = off)
	notify        = true,        -- desktop notifications (notify-send)
	hooks         = true,        -- run pre/post-sync scripts
}

local function load_config()
	local f = io.open(CONFIG_FILE, "r")
	if not f then return end
	f:close()
	local ok_, user = pcall(dofile, CONFIG_FILE)
	if ok_ and type(user) == "table" then
		for k, v in pairs(user) do config[k] = v end
	else
		warn("config error in " .. CONFIG_FILE .. " — using defaults")
	end
end

-- ── Features ──────────────────────────────────────────────────────────────────
local function notify(title, body)
	if config.notify and has("notify-send") then
		run("notify-send " .. shq(title) .. " " .. shq(body))
	end
end

local function hook(name)
	if not config.hooks then return end
	local path = CONFIG_DIR .. "/hooks/" .. name
	local f = io.open(path, "r")
	if f then
		f:close()
		info("running hook: " .. name)
		run(shq(path))
	end
end

local function aur_bin()
	if config.aur_helper == "none" then return nil end
	if config.aur_helper ~= "auto" then return config.aur_helper end
	if has("paru") then return "paru" end
	if has("yay") then return "yay" end
	return nil
end

-- AUR helpers must never run as root: drop to the invoking user via sudo
local function run_aur(args)
	local bin = aur_bin()
	if not bin then
		warn("no AUR helper found (install paru or yay) — skipping AUR")
		return true
	end
	local cmd = bin .. " " .. args
	if is_root() then
		local user = os.getenv("SUDO_USER")
		if not user or user == "root" then
			die("run silverflux with sudo so AUR builds run as your user")
		end
		cmd = "sudo -u " .. shq(user) .. " " .. cmd
	end
	return run(cmd)
end

local function update_mirrors()
	local m = config.mirror_method
	if m == "none" then return end
	if not is_root() then die("mirror update needs root") end

	if m == "reflector" then
		if not has("reflector") then
			warn("reflector not installed (sudo pacman -S reflector)")
			return
		end
		info("ranking top " .. config.mirror_count .. " mirrors (reflector)")
		run(string.format("cp %s %s.bak", MIRRORLIST, MIRRORLIST))
		local cmd = string.format(
			"reflector --latest %d --protocol https --sort rate --save %s",
			config.mirror_count, MIRRORLIST)
		if run(cmd) then
			ok("mirrors ranked")
		else
			warn("reflector failed — restoring previous mirrorlist")
			run(string.format("cp %s.bak %s", MIRRORLIST, MIRRORLIST))
		end

	elseif m == "rate-mirrors" then
		if not has("rate-mirrors") then
			warn("rate-mirrors not installed")
			return
		end
		info("ranking mirrors (rate-mirrors)")
		run("rate-mirrors --save=" .. MIRRORLIST .. " arch")
		ok("mirrors ranked")
	end
end

-- ── Commands ──────────────────────────────────────────────────────────────────
local function cmd_sync()
	if not is_root() then die("sync needs root: sudo silverflux") end
	notify("silverflux", "system update started")
	hook("pre-sync.sh")

	update_mirrors()

	info("syncing repos and upgrading (pacman -Syu)")
	if not run("pacman -Syu") then die("pacman -Syu failed") end

	info("upgrading AUR packages")
	run_aur("-Sua")

	if config.keep_versions > 0 and has("paccache") then
		info("keeping last " .. config.keep_versions .. " versions (rollback)")
		run("paccache -rk" .. config.keep_versions)
	end

	hook("post-sync.sh")
	ok("system up to date")
	notify("silverflux", "system update complete")
end

local function cmd_mirrors()
	update_mirrors()
end

local function cmd_aur()
	info("upgrading AUR packages")
	run_aur("-Sua")
end

local function cmd_status()
	local repo = capture("pacman -Qu 2>/dev/null | wc -l")
	print(string.format(" %s%spacman%s  %s pending", COL.cyan, B, R, repo))
	local bin = aur_bin()
	if bin and not is_root() then
		local aur = capture(bin .. " -Qua 2>/dev/null | wc -l")
		print(string.format(" %s%sAUR   %s  %s pending", COL.cyan, B, R, aur))
	end
end

local function usage()
	print(string.format([[
 %s%ssilverflux%s v%s — pacman + AUR sync + mirrors

 %susage%s
   sudo silverflux              full sync (mirrors + pacman + AUR + cleanup)
   sudo silverflux mirrors      rank mirrors only
   sudo silverflux aur          update AUR packages only
        silverflux status       show pending updates
        silverflux --version

 %sconfig%s  ~/.config/silverflux/config.lua
 %shooks%s   ~/.config/silverflux/hooks/pre-sync.sh  post-sync.sh
]], COL.cyan, B, R, VERSION, COL.silver, R, COL.dim, R))
end

-- ── Main ──────────────────────────────────────────────────────────────────────
load_config()
local cmd = arg[1] or "sync"

if cmd == "sync" or cmd == "-Syu" then cmd_sync()
elseif cmd == "mirrors" then cmd_mirrors()
elseif cmd == "aur" then cmd_aur()
elseif cmd == "status" then cmd_status()
elseif cmd == "--version" or cmd == "-v" then print("silverflux v" .. VERSION)
elseif cmd == "--help" or cmd == "-h" then usage()
else
	warn("unknown command: " .. cmd)
	usage()
	os.exit(1)
end
