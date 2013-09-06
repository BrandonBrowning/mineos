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

function list(iterator)
	local result = {}

	for item in iterator do
		table.insert(result, item)
	end

	return result
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

		file.writeLine(string.format("%s %s %s %s", programName, user, repo, path))
	end

	file.close()
end

function github.load_registration(from)
	local from = from or config.github._registration_file
	local file = fs.open(from, "r")

	if file then
		local line = file.readLine()
		while line do
			local parts = list(string.gmatch(line, "[^%s]+"))
			local programName = parts[1]
			local user = parts[2]
			local repo = parts[3]
			local path = parts[4]

			github.register(user, repo, {[programName] = path})

			line = file.readLine()
		end

		file.close()
	end
end

function _setup()
	github.load_registration(config.github._registration_file)
end

_setup()