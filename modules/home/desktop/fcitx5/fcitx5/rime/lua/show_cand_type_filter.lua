-- file_name: show_cand_type_filter.lua
-- author: 叫我最右君<QQ:871446712>
-- date: 2024-03-06
-- date: 2024-03-28
-- 功能：显示候选项的类型，并可以自定义显示内容，未定义的显示原本的类型
-- 注意事项：在engine/filters排序时应把本filter排在reverse_lookup_filter之前，否则会覆盖反查的comment；或者自行在schema里设置作用的tag


local comment_map = {
--	[""] = false, --如果type为空字符串，则不修改cand_comment
	["reverse_lookup"] = false, --如果为reverse_translator产生的cand，则不修改cand_comment
	["table"] = "table",
	["user_table"] = "user",
--	["可自行添加类型"] = "想要显示的类型提示",
}


function show_cand_type_filter(cands, env)
	for cand in cands:iter() do
		local display_comment = comment_map[cand.type]
		if display_comment==false then
			goto continue
		end
		if display_comment then
			cand.comment = display_comment
		else
			cand.comment = cand.type
		end
		::continue::
		yield(cand)
	end
end


return show_cand_type_filter
