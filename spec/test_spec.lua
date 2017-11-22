require 'busted.runner'()
local yaml = require('yaml')

function scandir(directory)
  local i, t, popen = 0, {}, io.popen
  local pfile = popen('ls -a "'..directory..'"')
  for filename in pfile:lines() do
    local match = {filename:match('^(.+)%.lua$')}
    if #match > 0 then
      i = i + 1
      t[i] = match[1]
    end
  end
  pfile:close()
  return t
end

function readAll(file)
  local f = io.open(file, "rb")
  local content = f:read("*all")
  f:close()
  return content
end

describe('Parsing in', function()

  local files = scandir("samples/")
  for k, file in pairs(files) do
    it(file, function()
      local data = yaml.eval(readAll("samples/"..file..".yaml"))
      local answer = require("samples."..file)
      assert.are.same(answer, data)
    end)
  end
end)
