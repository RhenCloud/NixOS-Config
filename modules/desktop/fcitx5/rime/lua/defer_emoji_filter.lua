-- 把首屏的表情候选推迟到后面，避免常用字被同码表情挤走。
--
-- keytao 的 emoji_cn 开关（simplifier@emoji_cn，opencc append 模式）会把
-- 每个字对应的表情拆成独立候选插在该字之后，例如 `不` 会变成：
--   不 / 🙂‍↔️ / 🙅🏻 / 🫨 / 吧
-- 于是输入 b 时常用字「吧」掉到第 5 位。
--
-- 本过滤器缓存首屏范围内的表情候选，等凑够 page_size 个普通候选后再一起
-- 输出，效果是第一页保持纯中文，表情集中出现在第二页开头。

local M = {}

function M.init(env)
  M.size = env.engine.schema.config:get_int("menu/page_size") or 6
end

-- 含 CJK 部首/汉字区字符即视为普通候选，否则视为表情/符号
local function is_emoji(text)
  return text:find("[\228-\233][\128-\191]") == nil
end

function M.func(input, env)
  local size = M.size
  local deferred = {}
  local yielded = 0

  for cand in input:iter() do
    if yielded < size and is_emoji(cand.text) then
      deferred[#deferred + 1] = cand
    else
      yield(cand)
      yielded = yielded + 1
      if yielded == size then
        for _, c in ipairs(deferred) do
          yield(c)
        end
        deferred = {}
      end
    end
  end

  for _, c in ipairs(deferred) do
    yield(c)
  end
end

return M
