
local table = table

-- Nice Fisher-Yates implementation, from Wikipedia
local rand = math.random
function table.Shuffle(t)
  local n = #t

  while n > 2 do
    -- n is now the last pertinent index
    local k = rand(n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end

  return t
end