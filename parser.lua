local yaml = require('yaml')

function readAll(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end

if not arg[2] then
  error("file name parameter required")
end

content = readAll(arg[2])
local tokens = yaml.tokenize(content)

-- ENABLE WHEN DEBUGGING PARSER ERRORS
--~ i = 0
--~ while tokens[i] do
--~   print(i, tokens[i][0], "'" .. tokens[i][1][1] .. "'")
--~   i = i + 1
--~ end

yaml.dump(yaml.eval(content))
