local Parser,tokens,context;

function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    for key, value in pairs (tt) do
      io.write(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        io.write(string.format("[%s] => table\n", tostring (key)));
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write("(\n");
        table_print (value, indent + 7, done)
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write(")\n");
      else
        io.write(string.format("[%s] => %s\n",
            tostring (key), tostring(value)))
      end
    end
  else
    io.write(type(tt) .. ": " .. tostring(tt) .. "\n")
  end
  io.flush()
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
  self.tokens = tokens;
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
  {[0]="string",    "^\"(.-)\""},
  {[0]="string",    "^'(.-)'"},
  {[0]="timestamp", "^(%d%d%d%d)-(%d%d?)-(%d%d?)%s+(%d%d?):(%d%d):(%d%d)"},
  {[0]="timestamp", "^(%d%d%d%d)-(%d%d?)-(%d%d?)%s+(%d%d?):(%d%d)"},
  {[0]="timestamp", "^(%d%d%d%d)-(%d%d?)-(%d%d?)%s+(%d%d?)"},
  {[0]="timestamp", "^(%d%d%d%d)-(%d%d?)-(%d%d?)"},
  {[0]="float",     "^(%d+%.%d+)"},
  {[0]="int",       "^(%d+)"},
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
        token = {[0] = tokens[i][0], captures}
        str = str:gsub(tokens[i][1], "", 1)
        
        if token[0] == "{" or token[0] == "[" then
          inline = true
        elseif token[0] == "id" then
          -- Since id pattern contains last semi-colon we're re-adding it
          str = token[1][2] .. str
        elseif token[0] == "string" then
          -- Joining strings
          local prev = last(stack)
          if prev[0] == "string" then
            prev[1][1] = prev[1][1] .. token[1][1]
            ignore = true
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
  local indent = self:accept("indent")
  local token = self:peek()
  
  if token[0] == "doc" then
    result = self:parseDoc()
  elseif token[0] == "-" then
    result = self:parseList()
  elseif token[0] == "{" then
    result = self:parseInlineHash()
  elseif token[0] == "[" then
    result = self:parseInlineList()
  elseif token[0] == "id" then
    result = self:parseHash()
  elseif token[0] == "string" then
    result = self:advanceValue()
  elseif token[0] == "timestamp" then
    result = self:parseTimestamp()
  elseif token[0] == "float" then
    result = tonumber(self:advanceValue())
  elseif token[0] == "int" then
    result = tonumber(self:advanceValue())
  elseif token[0] == "true" then
    self:advanceValue();
    result = true
  elseif token[0] == "false" then
    self:advanceValue();
    result = false
  elseif token[0] == "null" then
    self:advanceValue();
    result = nil
  end
  
  if indent then
    if not self:peekType("dedent") and token[0] == "-" then
      -- This corner case around list indention could need some review. (see edge_cases/list.yaml)
    elseif self:peek() ~= nil then
      self:expect("dedent", "last term "..token[0]..": '"..token[1][1].."' is not properly dedented")
    end
  end
  return result
end

Parser.parseDoc = function (self)
  self:accept("doc")
  return self:parse()
end

Parser.parseHash = function (self, hash)
  if hash == nil then
    hash = {}
  end
  while self:peekType("id") do
    local id = self:advanceValue()
    self:expect(":","expected semi-colon after id")
    self:ignoreSpace()
    hash[id] = self:parse()

    -- self:ignoreWhitespace();
    self:ignoreSpace();
  end
  
  if self:accept("indent") then
    self:parseHash(hash)
    self:expect("dedent","expected dedent after hash")
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
  local list;
  list = {}
  while self:accept("-") do
    self:ignoreSpace();
    push(list, self:parse())

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
    push(list, self:parse())
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