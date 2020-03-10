package = "lua-yaml"
version = "1.2-2"
source = {
   url = "git://github.com/exosite/lua-yaml.git"
}
description = {
   summary = "YAML parser in raw LUA",
   homepage = "http://github.com/exosite/lua-yaml",
   license = "MIT",
   maintainer = "Dominic Letz <dominicletz@exosite.com>"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      yaml = "yaml.lua"
   }
}
