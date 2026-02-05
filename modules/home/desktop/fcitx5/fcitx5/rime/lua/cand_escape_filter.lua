--file_name: cand_escape_filter.lua
--author: 叫我最右君<8714446712@qq.com>
--date: 2023-04-01

-- 功能：使词典中的转义字符生效，可以在下面的map中自行添加映射列表，
-- 注意：表键（待转义项）有 两个 反斜杠，且需要用方括号包住，两项之间不要漏掉逗号

--[[
使用方法：
将本文件放至Rime/lua文件夹内，然后在使用的方案引用本filter，推荐将本filter排在最后
引用方式有两种：
① 新版方法，直接在方案里通过 “ - lua_filter@*文件名 ” 来引用
engine:
  ...
  ...
  filters:
    ...
    - lua_filter@*cand_escape_filter

② 旧版方法，通过rime.lua中介引用，更好兼容性（同文等低版本Rime不可用）
首先确保已把本文件放至lua文件夹中，然后在rime.lua文件中加入一行
cand_escape_filter = require("cand_escape_filter")
然后即可在方案中引用（没有星号）
engine:
  ...
  ...
  filters:
    ...
    - lua_filter@cand_escape_filter

]]--

map = {
--    ["\\n"] = "\n", --已知小狼毫不可转义出\n，因为\n被占用
    ["\\n"] = "\r",
    ["\\r"] = "\r",
    ["\\t"] = "\t",
--    ["\\xxxxx"] = "可以自行添加",
}

return function(cands)
    local text, total, count
    for cand in cands:iter() do
        text = cand.text
        total = 0
        for k, v in pairs(map) do
            text, count = string.gsub(text, k, v)
            total = total + count
        end
        if total~=0 then
            yield(Candidate(cand.type, cand._start, cand._end, text, cand.comment))
        else
            yield(cand)
        end
    end
end
