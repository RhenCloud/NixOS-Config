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

  local moved = {}
  local n = 0
  for cand in input:iter() do
    n = n + 1
    if n <= size and isEmoji(cand) then
      moved[#moved + 1] = cand
    else
      yield(cand)
    end
  end
  for i = 1, #moved do
    yield(moved[i])
  end
end

return M
