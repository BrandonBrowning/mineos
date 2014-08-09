-- MineOS
--  by Brandon Browning (https://github.com/BrandonBrowning/mineos)

local usage = [[
mos update
mos add github (program) (user) (repository) (path)
mos add pastebin (program) (id)
mos export pastebin [path]
mos show pastebin]]

function T(t)
  return setmetatable(t, { __index = table })
end

function S(t)
  local result = T{}
  for i, v in pairs(t) do
    result[v] = true
  end

  return result
end

function _keys(iterator)
  local result = T{}

  local i = 1
  for k in pairs(iterator) do
    result[i] = k
    i = i + 1
  end

  return result
end

function table.slice(t, from, to)
  local from = from or 1
  local to = to or #t + 1

  local result = T{}
  local i = 1
  local target = from
  while target < to do
    result[i] = t[target]

    i = i + 1
    target = target + 1
  end

  return result
end

function table.contains(t, element)
  for k, v in pairs(t) do
    if v == element then
      return true
    end
  end

  return false
end

local VERBOSITY_SILENT = 1
local VERBOSITY_ERROR = 2
local VERBOSITY_INFO = 3
local VERBOSITY_VERBOSE = 4

local _config_default = T{}
_config_default.github = T{}
_config_default.pastebin = T{}

_config_default.bootstrap_pbid = "jqN85faF"
_config_default.providers = T{"github", "pastebin"}
_config_default.verbosity = VERBOSITY_INFO

_config_default.github.registration_file = ".mineos/reg-gh"
_config_default.pastebin.registration_file = ".mineos/reg-pb"

local config = _config_default

local github = T{}
github.registration = T{}

function _out(message, verbosity)
  local verbosity = verbosity or config.verbosity
  if verbosity <= config.verbosity then
    print(message)
  end
end

function github.read(user, repo, path, commit)
  local commit = commit or "master"
  local url = string.format("https://raw.github.com/%s/%s/%s/%s", user, repo, commit, path)
  local request = http.get(url)
  local contents = request.readAll()
  request.close()

  return contents
end

function github.register(program, user, repo, path)
  github.registration[program] = {user, repo, path}
end

function github.update()
  for program, settings in pairs(github.registration) do
    local user = settings[1]
    local repo = settings[2]
    local path = settings[3]

    local file = fs.open(program, "w")
    local contents = github.read(user, repo, path)
    file.write(contents)
    file.close()
  end
end

function github.save_registration(to)
  local to = to or config.github.registration_file
  local file = fs.open(to, "w")

  for program, settings in pairs(github.registration) do
    local user = settings[1]
    local repo = settings[2]
    local path = settings[3]

    file.writeLine(string.format("%s %s %s %s", program, user, repo, path))
  end

  file.close()
end

function github.load_registration(from)
  local from = from or config.github.registration_file
  local file = fs.open(from, "r")

  if file then
    local line = file.readLine()
    while line do
      local parts = list(string.gmatch(line, "[^%s]+"))
      local program = parts[1]
      local user = parts[2]
      local repo = parts[3]
      local path = parts[4]

      github.register(program, user, repo, path)

      line = file.readLine()
    end

    file.close()
  end
end

local pastebin = T{}
pastebin.registration = T{}

function pastebin.read(pbid)
  local url = string.format("http://pastebin.com/raw.php?i=%s", pbid)
  local request = http.get(url)
  local contents = request.readAll()
  request.close()

  return contents
end

function pastebin.register(program, pbid)
  if pastebin.registration[program] == pbid then
    _out("Already have this setup", VERBOSITY_INFO)
  else
    pastebin.registration[program] = pbid
  end
end

function pastebin.update()
  for program, pbid in pairs(pastebin.registration) do
    local file = fs.open(program, "w")
    local contents = pastebin.read(pbid)
    file.write(contents)
    file.close()
  end
end

function pastebin.save_registration(to)
  local to = to or config.pastebin.registration_file
  local file = fs.open(to, "w")

  for program, pbid in pairs(pastebin.registration) do
    file.writeLine(string.format("%s %s", program, pbid))
  end

  file.close()
end

function pastebin.load_registration(from)
  local from = from or config.pastebin.registration_file
  local file = fs.open(from, "r")

  if file then
    local line = file.readLine()
    while line do
      local parts = _keys(string.gmatch(line, "[^%s]+"))
      local program = parts[1]
      local pbid = parts[2]

      pastebin.register(program, pbid)

      line = file.readLine()
    end

    file.close()
  end
end

function command_add(provider, program, ...)
  local args = T{...}
  local provider = provider and provider:lower() or nil
  if not provider then
    _out("No command supplied after add", VERBOSITY_ERROR)
  elseif not provider or not config.providers:contains(provider) then
    local provider_csv = config.providers:concat(", ")
    _out(string.format("Provider %s not regonized; found %s", provider, provider_csv), VERBOSITY_ERROR)
  else
    if not program then
      _out("Program name expected", VERBOSITY_ERROR)
    else
      if provider == "github" then
        _out("Github provider not supported yet", VERBOSITY_ERROR)
      else
        local pbid = args[1]
        if not pbid then
          _out("Expected pastebin id after program name", VERBOSITY_ERROR)
        else
          pastebin.register(program, pbid)
          pastebin.save_registration()
        end
      end
    end
  end
end

function command_update()
  github.update()
  pastebin.update()
end

function command_export(provider, path)
  if provider ~= "pastebin" then
    _out(string.format("Provider %s not supported", provider), VERBOSITY_ERROR)
  else
    pastebin.save_registration(path)
  end
end

function command_show(provider)
  local provider = provider and provider:lower() or nil
  if not provider then
    _out("Expected a provider name", VERBOSITY_ERROR)
  elseif provider == "pastebin" then
    for program, pbid in pairs(pastebin.registration) do
      print(string.format("prog=%s id=%s", program, pbid))
    end
  else
    _out("Only support pastebin provider", VERBOSITY_ERROR)
  end
end

function setup()
  github.load_registration()
  pastebin.load_registration()

  pastebin.register("mos", config.bootstrap_pbid)
end

local args = T{...}

if #args == 0 then
  _out(usage, VERBOSITY_ERROR)
else
  local command = args[1]
  local command_map = {
    add = command_add,
    update = command_update,
    export = command_export,
    show = command_show
  }

  local command_handler = command_map[command:lower()]

  if not command_handler then
    local command_csv = _keys(command_map):concat(", ")
    _out(string.format("Command '%s' not recognized; found %s", command, command_csv))
  else
    setup()
    command_handler(unpack(args:slice(2)))
  end
end