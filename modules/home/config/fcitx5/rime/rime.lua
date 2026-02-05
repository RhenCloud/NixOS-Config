-- select_character_processor: 以词定字
-- 详见 `lua/select_character.lua`
select_character = require("select_character")

-- emoji降低排序位置
reduce_emoji_filter = require("reduce_emoji_filter")

-- 错音错字提示
-- 关闭此 Lua 时，同时需要关闭 translator/spelling_hints，否则 comment 里都是拼音
corrector = require("corrector")

-- c = require("c")

-- pin_cand_filter = require("pin_cand_filter")

-- long_phrase_first: 最长词组和单字在先
-- 详见 `lua/candidate_sorting/long_phrase_first.lua`
long_phrase_first = require("candidate_sorting.long_phrase_first")

-- single_char_first: 单字在先
-- 详见 `lua/candidate_sorting/single_char_first.lua`
-- single_char_first = require("candidate_sorting.single_char_first")

-- single_char_only: 只显示单字
-- 详见 `lua/candidate_sorting/single_char_only.lua`
-- single_char_only = require("candidate_sorting.single_char_only")

-- 词条隐藏、降频
-- 在 engine/processors 增加 - lua_processor@cold_word_drop_processor
-- 在 engine/filters 增加 - lua_filter@cold_word_drop_filter
-- 在 key_binder 增加快捷键：
-- turn_down_cand: "Control+j"  # 匹配当前输入码后隐藏指定的候选字词 或候选词条放到第四候选位置
-- drop_cand: "Control+d"       # 强制删词, 无视输入的编码
-- get_record_filername() 函数中仅支持了 Windows、macOS、Linux
cold_word_drop_processor = require("cold_word_drop.processor")
cold_word_drop_filter = require("cold_word_drop.filter")