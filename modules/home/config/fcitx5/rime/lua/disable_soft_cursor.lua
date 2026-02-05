-- file_name: disable_soft_cursor.lua
-- author: 叫我最右君<QQ:871446712>
-- date: 2024-04-12

--[[

功能：通过set_option设置soft_cursor选项来关闭桌面端的光标
源码：https://github.com/rime/librime/blob/master/src/rime/context.cc#L37-L41

=====================================================

# 使用方式：
 1. 将本文件放在 Rime/lua 下，命名为 disable_soft_cursor.lua
 2. 在你需要使用的方案文件中，processors里加入此插件的调用，尽量放在最前，如下所示：
engine:
  processors:
    - lua_processor@*disable_soft_cursor
    - ascii_composer
    ···
    ···
=====================================================

]]--






local lw
lw = function(...) end
--lw = log.warning -- 打印日志


local kNoop = 2


function init(env)
	env.engine.context:set_option("soft_cursor", false)
end

function func(_, env)
	local context = env.engine.context
	if context:get_option("soft_cursor") then
		context:set_option("soft_cursor", false)
	end
	return kNoop
end


return {
	init = init,
	func = func,
}