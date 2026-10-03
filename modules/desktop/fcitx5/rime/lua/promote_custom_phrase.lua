local M = {}

function M.func(input)
  for candidate in input:iter() do
    if candidate.type == "custom_phrase" then
      candidate.quality = candidate.quality + 1000000
    end
    yield(candidate)
  end
end

return M
