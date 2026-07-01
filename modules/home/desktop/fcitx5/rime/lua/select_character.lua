local M = {}

function M.init(env)
  local config = env.engine.schema.config
  M.first_key = config:get_string('key_binder/select_first_character') or 'bracketleft'
  M.last_key = config:get_string('key_binder/select_last_character') or 'bracketright'
end

local function first_char(s)
  local i = utf8.offset(s, 1)
  local j = utf8.offset(s, 2)
  if i and j then return s:sub(i, j - 1)
  elseif i then return s:sub(i)
  else return "" end
end

local function last_char(s)
  local n = utf8.len(s)
  if not n or n == 0 then return "" end
  local i = utf8.offset(s, n)
  return i and s:sub(i) or ""
end

function M.func(key, env)
  local kr = key:repr()
  if kr ~= M.first_key and kr ~= M.last_key then return 2 end

  local context = env.engine.context
  local ct = context:get_commit_text()
  if ct == "" then return 2 end

  local text = context:get_selected_candidate().text
  local c = kr == M.first_key and first_char(text) or last_char(text)
  context:clear_previous_segment()
  local t = context:get_commit_text()
  context:clear()
  env.engine:commit_text(t .. c)
  return 1
end

return M
