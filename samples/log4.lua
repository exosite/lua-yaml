return {
  ["Date"] = os.time{year=2001, month=11, day=23, hour=10, min=3, sec=17, isdst=false},
  ["Fatal"] = "Unknown variable \"bar\"",
  ["Stack"] = {
    [1] = {
      ["file"] = "TopClass.py\
line: 23\
code: |\
x = MoreObject(\"345\\n\")\
"
    },
    [2] = {
      ["code"] = "foo = bar",
      ["file"] = "MoreClass.py",
      ["line"] = 58
    }
  },
  ["User"] = "ed"
}
