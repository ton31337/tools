#include "redismodule.h"
#include <string.h>

void h5g_flushdbCommandFilter(RedisModuleCommandFilterCtx *filter)
{
	size_t cmd_len;

	if (RedisModule_CommandFilterArgsCount(filter) > 1)
		return;

	RedisModuleString *cmd = RedisModule_CommandFilterArgGet(filter, 0);
	const char *cmd_str = RedisModule_StringPtrLen(cmd, &cmd_len);

	if (cmd_len == 7 && !strncasecmp(cmd_str, "flushdb", cmd_len)) {
		RedisModule_CommandFilterArgReplace(filter, 0,
						    RedisModule_CreateString(NULL,
									     "FCALL",
									     5));
		RedisModule_CommandFilterArgInsert(filter, 1,
						   RedisModule_CreateString(NULL,
									    "h5g_flushdb",
									    11));
		RedisModule_CommandFilterArgInsert(filter, 2,
						   RedisModule_CreateString(NULL,
									    "0",
									    1));
	}
}

int RedisModule_OnLoad(RedisModuleCtx *ctx)
{
	if (RedisModule_Init(ctx, "h5g", 1, REDISMODULE_APIVER_1) ==
	    REDISMODULE_ERR)
		return REDISMODULE_ERR;

	if (RedisModule_RegisterCommandFilter(ctx, h5g_flushdbCommandFilter,
					      0) == NULL)
		return REDISMODULE_ERR;

	return REDISMODULE_OK;
}
