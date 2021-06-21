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

describe('dump', function()
  local expected = {
    total = 3,
    title = "very good!",
    list = {
      {item = "good", id = 3},
      {item = "item2", id = 4, sub = {
        no = 34,
        te = "haha",
        it = {
          "this is false",
          "aother",
          {some=1, at=4}
        }
      }}
    }
  }
  local str = yaml.dump(expected)
  local data = yaml.eval(str)
  assert.are.same(expected, data)
end)
