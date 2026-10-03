local M = {}

local ACCEPTED = 1
local NOOP = 2
local command = "/jc"

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

    local file = io.open(rime_api.get_user_data_dir() .. "/keytao-custom-phrase.txt", "a")
    if file then
      file:write(env.text .. "\t" .. env.code .. "\t1000000\n")
      file:close()
    end
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
