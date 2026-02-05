local function make_hight_quality_candidate(inputText, startSeg, endSeg, text, comment)
	-- Candidate(type, start, end, text, comment)
	local candidate = Candidate(inputText, startSeg, endSeg, text, comment)
	candidate.quality = 125
	-- 调整优先级
	return candidate
end

function comment_func(input, seg)
    for cand in input:iter() do
        local c = cand.comment
        if c == "ni hao" then
            make_hight_quality_candidate("nihao", seg.start, seg._end, "Test", "nihao")
            -- 返回候选词
            yield(cand)
        end
    end
end

return comment_func