local M = {}

local ACCEPTED = 1
local NOOP = 2
local command = "/jc"
local weight = 1000000

local function save_entry(text, code)
  local path = rime_api.get_user_data_dir() .. "/keytao-custom-phrase.txt"
  local entries = {}
  local found = false
  local file = io.open(path, "r")

  if file then
    for line in file:lines() do
      local old_text, old_code, old_weight = line:match("^([^\t]+)\t([^\t]+)\t(%d+)$")
      if old_text and old_code then
        if old_text == text and old_code == code then
          if not found then
            entries[#entries + 1] = text .. "\t" .. code .. "\t" .. weight
            found = true
          end
        else
          entries[#entries + 1] = old_text .. "\t" .. old_code .. "\t" .. old_weight
        end
      end
    end
    file:close()
  end

  if not found then
    entries[#entries + 1] = text .. "\t" .. code .. "\t" .. weight
  end

  local temp_path = path .. ".tmp"
  local output = io.open(temp_path, "w")
  if not output then
    return
  end
  output:write(table.concat(entries, "\n"), "\n")
  output:close()
  os.rename(temp_path, path)
end

function M.init(env)
  env.armed = false
  env.code = ""
  env.text = ""
  env._select_conn = env.engine.context.select_notifier:connect(function(context)
    if not env.armed then
      return
    end

    local candidate = context:get_selected_candidate()
    if not candidate or context.input == "" then
      return
    end

    env.code = context.input
    env.text = candidate.text
  end)
  env._commit_conn = env.engine.context.commit_notifier:connect(function()
    if not env.armed or env.code == "" or env.text == "" then
      return
    end

    save_entry(env.text, env.code)
    env.armed = false
    env.code = ""
    env.text = ""
  end)
end

function M.fini(env)
  if env._select_conn then
    env._select_conn:disconnect()
  end
  if env._commit_conn then
    env._commit_conn:disconnect()
  end
end

function M.func(key, env)
  if key:release() or key:ctrl() or key:alt() then
    return NOOP
  end

  local context = env.engine.context
  local key_repr = key:repr()
  if context.input == command then
    env.armed = true
    env.code = ""
    env.text = ""
    context:clear()
    return ACCEPTED
  end

  if env.armed and key_repr == "Escape" then
    env.armed = false
    env.code = ""
    env.text = ""
    context:clear()
    return ACCEPTED
  end

  return NOOP
end

return M
