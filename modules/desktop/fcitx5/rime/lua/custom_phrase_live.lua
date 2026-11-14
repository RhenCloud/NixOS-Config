local M = {}

local function file_stamp(path)
  local pipe = io.popen("stat -c %Y " .. string.format("%q", path) .. " 2>/dev/null")
  if not pipe then
    return "missing"
  end
  local stamp = pipe:read("*l") or "missing"
  pipe:close()
  return stamp
end

local function load(path)
  local index = {}
  local file = io.open(path, "r")
  if not file then
    return index
  end

  for line in file:lines() do
    local text, code, weight = line:match("^([^\t]+)\t([^\t]+)\t(%d+)$")
    if text and code and weight then
      local bucket = index[code]
      if not bucket then
        bucket = {}
        index[code] = bucket
      end
      bucket[#bucket + 1] = {
        text = text,
        weight = tonumber(weight),
      }
    end
  end
  file:close()
  return index
end

function M.init(env)
  env.path = rime_api.get_user_data_dir() .. "/keytao-custom-phrase.txt"
  env.stamp = ""
  env.index = {}
end

function M.func(input, seg, env)
  local stamp = file_stamp(env.path)
  if stamp ~= env.stamp then
    env.index = load(env.path)
    env.stamp = stamp
  end

  for _, entry in ipairs(env.index[input] or {}) do
    local candidate = Candidate("custom_phrase", seg.start, seg._end, entry.text, "")
    candidate.quality = entry.weight
    yield(candidate)
  end
end

return M
