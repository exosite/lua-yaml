local Parser,tokens,context;

function table_print(tt)
  print('return '..table_print_value(tt))
end

function table_print_value(value, indent, done)
  indent = indent or 0
  done = done or {}
  if type(value) == "table" and not done [value] then
    done [value] = true
    
    local rep = "{\n"
    local last
    for key in pairs (value) do
      last = key
    end
    
    local comma
    for key, value2 in pairs (value) do
      if key == last then
        comma = ''
      else
        comma = ','
      end
      local keyRep
      if type(key) == "number" then 
        keyRep = key 
      else 
        keyRep = string.format("%q", tostring(key)) 
      end
      rep = rep .. string.format(
        "%s[%s] = %s%s\n", 
        string.rep(" ", indent + 7),
        keyRep,
        table_print_value(value2, indent + 7, done),
        comma
      )
    end
    
    rep = rep .. string.rep (" ", indent+4) -- indent it
    rep = rep .. "}"
    return rep
  elseif type(value) == "string" then
    return string.format("%q", value)
  else 
    return tostring(value)
  end
end

function first(stack)
  return stack[0]
end

function last(stack)
  return stack[size(stack)-1]
end

function size(stack)
  if stack[0] then
    return #stack+1
  else
    return 0
  end
end

function push(stack, item)
  stack[size(stack)] = item
end

function pop(stack)
  local item = stack[size(stack) - 1]
  stack[size(stack) - 1] = nil
  return item
end

function shift(stack)
  local item = stack[0]
  local i = 0
  while stack[i] ~= nil do
    stack[i] = stack[i+1]
    i = i + 1
  end
  return item
end

context = function (env, str)
  if type(str) ~= "string" then
    return ""
  end

  str = str:sub(0,25):gsub("\n","\\n"):gsub("\"","\\\"");
  return ", near \"" .. str .. "\""
end

Parser = {}
function Parser.new (self, tokens)
  self.tokens = tokens
  self.parse_stack = {}
  return self
end

exports = {}
exports.version = "0.2.3";

word = function(w) return "^"..w.."[%s$%c]" end 

tokens = {
  [0] = 
  {[0]="comment",   "^#[^\n]*"},
  {[0]="indent",    "^\n( *)"},
  {[0]="space",     "^ +",""},
  {[0]="true",      word("enabled")},
  {[0]="true",      word("true")},
  {[0]="true",      word("yes")},
  {[0]="true",      word("on")},
  {[0]="false",     word("disabled")},
  {[0]="false",     word("false")},
  {[0]="false",     word("no")},
  {[0]="false",     word("off")},
  {[0]="null",      word("null")},
  {[0]="null",      word("Null")},
  {[0]="null",      word("NULL")},
  {[0]="null",      word("~")},
  {[0]="string",    "^\"(.-)\"", force_text = true},
  {[0]="string",    "^'(.-)'", force_text = true},
  {[0]="timestamp", "^(%d%d%d%d)-(%d%d?)-(%d%d?)%s+(%d%d?):(%d%d):(%d%d)"},
  {[0]="timestamp", "^(%d%d%d%d)-(%d%d?)-(%d%d?)%s+(%d%d?):(%d%d)"},
  {[0]="timestamp", "^(%d%d%d%d)-(%d%d?)-(%d%d?)%s+(%d%d?)"},
  {[0]="timestamp", "^(%d%d%d%d)-(%d%d?)-(%d%d?)"},
  {[0]="doc",       "^%-%-%-"},
  {[0]=",",         "^,"},
  {[0]="string",    "^%b{} *[^,%c]+", noinline = true},
  {[0]="{",         "^{"},
  {[0]="}",         "^}"},
  {[0]="string",    "^%b[] *[^,%c]+", noinline = true},
  {[0]="[",         "^%["},
  {[0]="]",         "^%]"},
  {[0]="-",         "^%-"},
  {[0]=":",         "^:"},
  {[0]="id",        "^([%w][%w %-_]*)(:[%s%c])"},
  {[0]="string",    "^[^%c]+", noinline = true},
  {[0]="string",    "^[^,%c ]+"}
};
exports.tokenize = function (str)
  local token;
  local ignore
  local indents = 0
  local lastIndents = 0
  local stack = {}
  local indentAmount = 0
  local inline = false
  str = str:gsub("\r\n","\010")
  
  while #str > 0 do
    local i = 0
    local len = size(tokens)
    while i < len do
      --print(i, tokens[i][0], inline)
      local captures
      if not inline or tokens[i].noinline == nil then
        captures = {str:match(tokens[i][1])}
      else
        captures = {}
      end
      
      if #captures > 0 then
        captures.input = str:sub(0, 25)
        token = {[0] = tokens[i][0], captures, force_text = tokens[i].force_text}
        str = str:gsub(tokens[i][1], "", 1)
        
        if token[0] == "{" or token[0] == "[" then
          inline = true
        elseif token[0] == "id" then
          -- Since id pattern contains last semi-colon we're re-adding it
          str = token[1][2] .. str
        elseif token[0] == "string" then
          -- Finding numbers
          local snip = token[1][1]
          if not token.force_text then
            if snip:match("^(%d+%.%d+)$") then
              token[0] = "float"
            elseif snip:match("^(%d+)$") then
              token[0] = "int"
            end
          end
          
        elseif token[0] == "comment" then
          ignore = true;
        elseif token[0] == "indent" then
          inline = false
          lastIndents = indents
          if indentAmount == 0 then
            indentAmount = #token[1][1]
          end

          if indentAmount ~= 0 then
            indents = (#token[1][1] / indentAmount);
          else
            indents = 0
          end
          
          if indents == lastIndents then
            ignore = true;
          elseif indents > lastIndents + 1 then
            error("SyntaxError: invalid indentation, got " .. tostring(indents) .. " instead of " .. tostring(lastIndents))
          elseif indents < lastIndents then
            local input = token[1].input
            token = {[0]="dedent", {"", input = ""}}
            token.input = input
            while lastIndents > indents + 1 do
              lastIndents = lastIndents - 1
              push(stack, token)
            end
          end
        end -- if token[0] == XXX
        break
      end -- if #captures > 0

      i = i + 1
    end

    if not ignore then
      if token then
        push(stack, token)
        token = nil
      else
        error("SyntaxError " .. context(_ENV,str))
      end

    end

    ignore = false;
  end

  return stack
end

Parser.peek = function (self)
  return self.tokens[0]
end

Parser.advance = function (self)
  return shift(self.tokens)
end

Parser.advanceValue = function (self)
  return self:advance()[1][1]
end

Parser.accept = function (self, type)
  if self:peekType(type) then
    return self:advance()
  end
end

Parser.expect = function (self, type, msg)
  if self:accept(type) then
    return
  end

  error(msg .. context(_ENV,self:peek()[1].input))
end

Parser.peekType = function (self, val)
  local _lev = self.tokens[0]
  if _lev then 
    return self.tokens[0][0] == val
  else 
    return _lev
  end 
end

Parser.ignore = function (self, items)
  local advanced
  repeat
    advanced = false
    for k,v in pairs(items) do
      if self:peekType(v) then
        self:advance()
        advanced = true
      end
    end
  until advanced == false
end 

Parser.ignoreSpace = function (self)
  self:ignore{"space"}
end

Parser.ignoreWhitespace = function (self)
  self:ignore{"space", "indent", "dedent"}
end

Parser.parse = function (self)
  local result 
  local c = {
    indent = self:accept("indent") and 1 or 0,
    token = self:peek()
  }
  push(self.parse_stack, c)

  if c.token[0] == "doc" then
    result = self:parseDoc()
  elseif c.token[0] == "-" then
    result = self:parseList()
  elseif c.token[0] == "{" then
    result = self:parseInlineHash()
  elseif c.token[0] == "[" then
    result = self:parseInlineList()
  elseif c.token[0] == "id" then
    result = self:parseHash()
  elseif c.token[0] == "string" then
    result = self:advanceValue()
  elseif c.token[0] == "timestamp" then
    result = self:parseTimestamp()
  elseif c.token[0] == "float" then
    result = tonumber(self:advanceValue())
  elseif c.token[0] == "int" then
    result = tonumber(self:advanceValue())
  elseif c.token[0] == "true" then
    self:advanceValue();
    result = true
  elseif c.token[0] == "false" then
    self:advanceValue();
    result = false
  elseif c.token[0] == "null" then
    self:advanceValue();
    result = nil
  end
  
  local c = pop(self.parse_stack)
  while c.indent > 0 do
    c.indent = c.indent - 1
    if self:peek() ~= nil then
      local term = "term "..c.token[0]..": '"..c.token[1][1].."'"
      self:expect("dedent", "last ".. term .." is not properly dedented")
    end
  end
  
  return result
end

Parser.parseDoc = function (self)
  self:accept("doc")
  return self:parse()
end

Parser.parseHash = function (self, hash)
  hash = hash or {}
  local indents = 0
  local parent = self.parse_stack[size(self.parse_stack)-2]
  
  if parent ~= nil and parent.token[0] == "-" then
    local id = self:advanceValue()
    self:expect(":","expected semi-colon after id")
    self:ignoreSpace()
    if self:accept("indent") then
      indents = indents + 1
      hash[id] = self:parse()
    else
      hash[id] = self:parse()
      if self:accept("indent") then
        indents = indents + 1
      end
    end
    self:ignoreSpace();
  end
    
  while self:peekType("id") do
    local id = self:advanceValue()
    self:expect(":","expected semi-colon after id")
    self:ignoreSpace()
    hash[id] = self:parse()
    self:ignoreSpace();
  end
  
  while indents > 0 do
    self:expect("dedent", "expected dedent")
    indents = indents - 1
  end
  
  return hash
end

Parser.parseInlineHash = function (self)
  local id
  local hash = {}
  local i = 0
  
  self:accept("{")
  while not self:accept("}") do
    self:ignoreSpace()
    if i > 0 then
      self:expect(",","expected comma")
    end

    self:ignoreWhitespace()
    if self:peekType("id") then
      id = self:advanceValue() 
      if id then
        self:expect(":","expected semi-colon after id")
        self:ignoreSpace()
        hash[id] = self:parse()
        self:ignoreWhitespace()
      end
    end

    i = i + 1
  end
  return hash
end

Parser.parseList = function (self)
  local list = {}
  while self:accept("-") do
    self:ignoreSpace()
    list[#list + 1] = self:parse()

    self:ignoreSpace()
  end
  return list
end

Parser.parseInlineList = function (self)
  local list = {}
  local i = 0
  self:accept("[")
  while not self:accept("]") do
    self:ignoreSpace()
    if i > 0 then
      self:expect(",","expected comma")
    end

    self:ignoreSpace()
    list[#list + 1] = self:parse()
    self:ignoreSpace()
    i = i + 1
  end

  return list
end
  
Parser.parseTimestamp = function (self)
  token = self:advance()[1]
  
  return os.time{
    year  = token[1], 
    month = token[2], 
    day   = token[3],
    hour  = token[4] or 0,
    min   = token[5] or 0,
    sec   = token[6] or 0
  }
end

exports.eval = function (str)
  return Parser:new(exports.tokenize(str)):parse()
end

exports.dump = table_print

return exports