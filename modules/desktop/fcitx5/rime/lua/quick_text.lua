-- 日常快捷文本：日期、时间、时间戳、UUID、邮箱。
--
-- 用法：
--   /rq       当前日期：2026-11-08
--   /rqcn     中文日期：2026年11月8日
--   /sj       当前时间：01:32
--   /ts       日期时间：2026-11-08 01:32:45
--   /unix     Unix 时间戳
--   /uuid     随机 UUID
--   /email    从 keytao-email.txt 读取的邮箱
--
-- 邮箱文件放在 Rime 用户目录，每行一个邮箱：
--   ~/.local/share/fcitx5/rime/keytao-email.txt

local M = {}

local function candidate(seg, text, comment)
  local c = Candidate("quick_text", seg.start, seg._end, text, comment or "")
  c.quality = 100000
  yield(c)
end

local function read_emails()
  local result = {}
  local path = rime_api.get_user_data_dir() .. "/keytao-email.txt"
  local file = io.open(path, "r")
  if not file then
    return result
  end
  for line in file:lines() do
    local email = line:match("^%s*(.-)%s*$")
    if email and email ~= "" and not email:match("^#") then
      result[#result + 1] = email
    end
  end
  file:close()
  return result
end

local function uuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  math.randomseed(os.time() + math.floor(os.clock() * 1000000))
  return template:gsub("[xy]", function(ch)
    local r = math.random(0, 15)
    if ch == "y" then
      r = 8 + (r % 4)
    end
    return string.format("%x", r)
  end)
end

function M.func(input, seg)
  if input == "/rq" then
    candidate(seg, os.date("%Y-%m-%d"), "日期")
  elseif input == "/rqcn" then
    candidate(seg, os.date("%Y年") .. tonumber(os.date("%m")) .. "月" .. tonumber(os.date("%d")) .. "日", "中文日期")
  elseif input == "/sj" then
    candidate(seg, os.date("%H:%M"), "时间")
  elseif input == "/ts" then
    candidate(seg, os.date("%Y-%m-%d %H:%M:%S"), "日期时间")
  elseif input == "/unix" then
    candidate(seg, tostring(os.time()), "Unix 时间戳")
  elseif input == "/uuid" then
    candidate(seg, uuid(), "UUID")
  elseif input == "/email" then
    for _, email in ipairs(read_emails()) do
      candidate(seg, email, "邮箱")
    end
  end
end

return M
