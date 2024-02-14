// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright (C) 2024 Donatas Abraitis <donatas@hostinger.com>
 */

#include "redismodule.h"
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#define NUM_REDIS_DATABASES 32768
const char *flushdb_str = "flushdb";
const char *hproxy_flushdb_str = "hproxy.flushdb";

uint32_t crc32(const char *key)
{
	uint32_t crc = 0xffffffff;
	for (int i = 0; key[i] != '\0'; ++i) {
		crc ^= (uint8_t)key[i];
		for (int j = 0; j < 8; ++j) {
			crc = (crc >> 1) ^ (0xEDB88320 & (-(crc & 1)));
		}
	}
	return ~crc;
}

int HProxyFlushDB(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{
	uint16_t db_id;
	RedisModuleCallReply *reply;
	RedisModuleString *new_argv[2];
	int new_argc;

	if (argc != 2)
		return RedisModule_WrongArity(ctx);

	const char *cmd = RedisModule_StringPtrLen(argv[0], NULL);
	const char *account =
		RedisModule_StringPtrLen(RedisModule_GetCurrentUserName(ctx),
					 NULL);

	if (!strncasecmp(cmd, hproxy_flushdb_str, strlen(hproxy_flushdb_str))) {
		db_id = crc32(account) % NUM_REDIS_DATABASES;
		RedisModule_SelectDb(ctx, db_id);
	}

	new_argv[0] = RedisModule_CreateString(NULL, flushdb_str,
					       strlen(flushdb_str));
	new_argv[1] = NULL;

	reply = RedisModule_Call(ctx, flushdb_str, "v", new_argv, 0);
	if (reply) {
		RedisModule_ReplyWithCallReply(ctx, reply);
		RedisModule_FreeCallReply(reply);
	} else
		RedisModule_ReplyWithLongLong(ctx, 0);

	return REDISMODULE_OK;
}

void ProxyCommandFilter(RedisModuleCommandFilterCtx *filter)
{
	size_t cmd_len;

	RedisModuleString *cmd = RedisModule_CommandFilterArgGet(filter, 0);
	const char *cmd_str = RedisModule_StringPtrLen(cmd, &cmd_len);

	if (!strncasecmp(cmd_str, flushdb_str, strlen(flushdb_str))) {
		RedisModule_CommandFilterArgReplace(
			filter, 0,
			RedisModule_CreateString(NULL, hproxy_flushdb_str,
						 strlen(hproxy_flushdb_str)));
		RedisModule_CommandFilterArgInsert(filter, 1, cmd);
	}
}

int RedisModule_OnLoad(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{
	if (RedisModule_Init(ctx, "h5g", 1, REDISMODULE_APIVER_1) ==
	    REDISMODULE_ERR)
		return REDISMODULE_ERR;

	if (RedisModule_CreateCommand(ctx, hproxy_flushdb_str, HProxyFlushDB,
				      "", 1, 1, 1) == REDISMODULE_ERR)
		return REDISMODULE_ERR;

	if (RedisModule_RegisterCommandFilter(ctx, ProxyCommandFilter,
					      REDISMODULE_CMDFILTER_NOSELF) ==
	    NULL)
		return REDISMODULE_ERR;

	return REDISMODULE_OK;
}
