#!lua name=h5g

redis.register_function(
	'h5g_flushdb',
	function()
		local cur = 0
		local deleted = 0
		local user = redis.call("ACL", "WHOAMI")
		local match = user .. ":*"

		repeat
			local res = redis.call("SCAN", cur, "MATCH", match)
			cur = tonumber(res[1])
			local keys = res[2]

			for _, key in ipairs(keys) do
				redis.call("DEL", key)
				deleted = deleted + 1
			end
		until cur == 0

		return deleted
	end
)
