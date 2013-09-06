-- MineOS
--  by Brandon Browning
--  at https://github.com/BrandonBrowning/mineos

_config_default = {}
_config_default.verbosity = 2 -- 0=silent 1=important 2=helpful 3=all

_config_default.github = {}
_config_default.github._registration_file = ".mineos/github/registration"

config = _config_default

function out(message, verbosity)
	local verbosity = verbosity or _config_default.verbosity
	if verbosity <= config.verbosity then
		print(message)
	end
end

github = {}
github.registration = {}

function github.read(user, repo, path)
	local url = string.format("https://raw.github.com/%s/%s/master/%s", user, repo, path)
	local request = http.get(url)
	local contents = request.readAll()
	request.close()

	return contents
end

function github.register(user, repo, programNameToPathMap)
	for programName, path in pairs(programNameToPathMap) do
		github.registration[programName] = {user, repo, path}
	end
end

function github.update()
	for programName, settings in pairs(github.registration) do
		local user = settings[1]
		local repo = settings[2]
		local path = settings[3]

		local file = fs.open(programName, "w")
		local contents = github.read(user, repo, path)
		file.write(contents)
		file.close()
	end
end

function github.save_registration(to)
	local file = fs.open(to, "w")

	for programName, settings in pairs(github.registration) do
		local user = settings[1]
		local repo = settings[2]
		local path = settings[3]

		file.writeLine(string.format("%s,%s,%s", user, repo, path))
	end

	file.close()
end

function github.load_registration(from)
	local file = fs.open(from, "r")

	local line = file.readLine()
	while line do
		
	end
end

function github._setup()
	local register_folder = config.github._register_folder

	if not fs.exists(register_folder) then
		fs.makeDir(register_folder)
	elseif not fs.isDir(register_folder) then
		fs.delete(register_folder)
		fs.makeDir(register_folder)
	end
end

function _setup()
	github._setup()
end

_setup()