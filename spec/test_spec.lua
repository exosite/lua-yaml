require 'busted.runner'()
local yaml = require('yaml')

describe('Parse mix type in object', function()
  local sample = [[
---
text: Text
text_with_space: Text text
text_with_single_quote: 'Text'
text_with_double_quote: "Text"
text_number: '1'
number: 1
true: true
false: false
object:
  key: value
array:
  - a
  - b
  - c
]]
  local data = yaml.eval(sample)
  local answer = {
    text = 'Text',
    text_with_space = 'Text text',
    text_with_single_quote = 'Text',
    text_with_double_quote = 'Text',
    text_number = '1',
    number = 1,
    ['true'] = true,
    ['false'] = false,
    object = {
      key = 'value',
    },
    array = { 'a', 'b', 'c' },
  }

  for k, v in pairs(answer) do
    if type(v) == 'table' then
      for kk, vv in pairs(v) do
        it(k .. '[' .. kk .. '] should be ' .. tostring(vv), function()
          assert.are.equal(vv, data[k][kk])
        end)
      end
    else
      it(k .. ' should be ' .. tostring(v), function()
        assert.are.equal(v, data[k])
      end)
    end
  end
end)
