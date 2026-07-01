local M = {}

function M.init(env)
  M.size = env.engine.schema.config:get_int("menu/page_size") or 5
end

local function isEmoji(cand)
  if cand:get_dynamic_type() ~= "Shadow" then return false end
  local t = cand.text
  return not (t:find("[\228-\233][\128-\191]") and t:find("[%a]"))
end

function M.func(input, env)
  local size = M.size
  if size < 3 then
    for cand in input:iter() do yield(cand) end
    return
  end

  local emoji = {}
  local i = 0
  local last_text = ""
  for cand in input:iter() do
    i = i + 1
    if i <= size then
      if isEmoji(cand) then
        cand = ShadowCandidate(cand, cand.type, cand.text, last_text)
        table.insert(emoji, cand)
      else
        last_text = cand.text
        yield(cand)
      end
    else
      table.insert(emoji, cand)
    end
  end

  for _, cand in ipairs(emoji) do
    yield(cand)
  end
end

return M
