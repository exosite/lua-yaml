local yaml = require('yaml')

local function readAll(file)
  local f = io.open(file, "rb")
  local content = f:read("*all")
  f:close()
  return content
end

if not arg[2] then
  error("file name parameter required")
end

local content = readAll(arg[2])

-- ENABLE WHEN DEBUGGING PARSER ERRORS
--~ local tokens = yaml.tokenize(content)
--~ local i = 1
--~ while tokens[i] do
--~   print(i, tokens[i][1], "'" .. (tokens[i].raw or '') .. "'")
--~   i = i + 1
--~ end

yaml.dump(yaml.eval(content))
