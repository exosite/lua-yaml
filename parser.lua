local yaml = require('yaml')

local function readAll(file)
  local f = io.open(file, "rb")
  local content = f:read("*all")
  f:close()
  return content
end

local debug = false
if arg[2] == "-d" then
  debug = true
  arg[2] = arg[3]
elseif arg[3] == "-d" then
  debug = true
end

if not arg[2] then
  error("file name parameter required")
end

local content = readAll(arg[2])

-- ENABLE WHEN DEBUGGING PARSER ERRORS
if debug then
  local tokens = yaml.tokenize(content)
  local i = 1
  while tokens[i] do
    print(i, tokens[i][1], "'" .. (tokens[i].raw or '') .. "'")
    i = i + 1
  end
end

yaml.dump(yaml.eval(content))
