local M = {}

local function entries(path, code)
  local file = io.open(path, "r")
  if not file then
    return {}
  end

  local result = {}
  for line in file:lines() do
    local text, entry_code, weight = line:match("^([^\t]+)\t([^\t]+)\t(%d+)$")
    if entry_code == code then
      table.insert(result, { text = text, weight = tonumber(weight) })
    end
  end
  file:close()
  return result
end

function M.func(input, seg)
  for _, entry in ipairs(entries(rime_api.get_user_data_dir() .. "/keytao-custom-phrase.txt", input)) do
    local candidate = Candidate("custom_phrase", seg.start, seg._end, entry.text, "")
    candidate.quality = entry.weight
    yield(candidate)
  end
end

return M
