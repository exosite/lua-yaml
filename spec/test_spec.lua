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

function compare(data, answer)
  if type(data) == 'table' then
    for kk, vv in pairs(data) do
      compare(vv, answer[kk])
    end
  else
    it(tostring(data) .. ' should be ' .. tostring(answer), function()
      assert.are.equal(data, answer)
    end)
  end
end

describe('Parse mix type in object', function()

  local files = scandir("samples/")
-- Lua implementation of PHP scandir function

  for k, file in pairs(files) do
    print(file)
    local data = yaml.eval(readAll("samples/"..file..".yaml"))
    local answer = require("samples."..file)
    
    compare(data, answer)
  end
end)