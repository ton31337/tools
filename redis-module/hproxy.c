// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright (C) 2024 Donatas Abraitis <donatas@hostinger.com>
 */

#include "redismodule.h"
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#define NUM_REDIS_DATABASES 8192
#define SCAN		    "scan"
#define FLUSHDB		    "flushdb"

void strsplit(const char *string, const char *delimiter, char ***result,
	      int *argc)
{
	if (!string)
		return;

	unsigned int sz = 4, idx = 0;
	char *copy, *copystart;
	const char *tok = NULL;

	*result = calloc(sizeof(char *) * sz, 1);
	copystart = copy = strdup(string);
	*argc = 0;

	while (copy) {
		tok = strsep(&copy, delimiter);
		(*result)[idx] = strdup(tok);
		if (++idx == sz)
			*result = realloc(*result, (sz *= 2) * sizeof(char *));
		(*argc)++;
	}

	free(copystart);
}

const char *cmd_real_get(const char *cmd)
{
	int num_splits;
	char **splits;
	static char command[BUFSIZ] = {};

	strsplit(cmd, ".", &splits, &num_splits);

	if (num_splits < 2)
		return cmd;

	strncpy(command, splits[1], sizeof(command));

	for (unsigned int i = 0; i < num_splits; i++)
		free(splits[i]);

	free(splits);

	return command;
}

const char *cmd_proxy_get(const char *cmd)
{
	static char command[BUFSIZ] = {};

	snprintf(command, sizeof(command), "hproxy.%s", cmd);

	return command;
}

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

int HProxyCommand(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{
	RedisModuleCallReply *reply;

	if (argc < 1)
		return RedisModule_WrongArity(ctx);

	const char *cmd = cmd_real_get(RedisModule_StringPtrLen(argv[0], NULL));
	const char *account =
		RedisModule_StringPtrLen(RedisModule_GetCurrentUserName(ctx),
					 NULL);

	/* If the account is default (= admin), don't force DB */
	if (strncmp(account, "default", strlen("default")))
		RedisModule_SelectDb(ctx, crc32(account) % NUM_REDIS_DATABASES);

	if (!strncmp(cmd, SCAN, strlen(SCAN))) {
		unsigned long long arg1;

		if (RedisModule_StringToULongLong(argv[1], &arg1) !=
		    REDISMODULE_OK)
			RedisModule_ReplyWithSimpleString(ctx, "ERR");

		reply = RedisModule_Call(ctx, cmd, "l", arg1);
	} else if (cmd, FLUSHDB, strlen(FLUSHDB)) {
		reply = RedisModule_Call(ctx, cmd, "v", argv, 0);
	}

	if (reply) {
		RedisModule_ReplyWithCallReply(ctx, reply);
		RedisModule_FreeCallReply(reply);
	} else
		RedisModule_ReplyWithLongLong(ctx, 0);

	return REDISMODULE_OK;
}

void HProxyCommandFilter(RedisModuleCommandFilterCtx *filter)
{
	size_t cmd_len;

	const char *cmd_real =
		RedisModule_StringPtrLen(RedisModule_CommandFilterArgGet(filter,
									 0),
					 &cmd_len);

	if (strncmp(cmd_real, SCAN, strlen(SCAN)) &&
	    strncmp(cmd_real, FLUSHDB, strlen(FLUSHDB)))
		return;

	const char *cmd_proxy = cmd_proxy_get(cmd_real);

	RedisModule_CommandFilterArgReplace(
		filter, 0,
		RedisModule_CreateString(NULL, cmd_proxy, strlen(cmd_proxy)));
}

int RedisModule_OnLoad(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{
	if (RedisModule_Init(ctx, "h5g", 1, REDISMODULE_APIVER_1) ==
	    REDISMODULE_ERR)
		return REDISMODULE_ERR;

	if (RedisModule_CreateCommand(ctx, cmd_proxy_get(SCAN), HProxyCommand,
				      "", 1, 1, 1) == REDISMODULE_ERR)
		return REDISMODULE_ERR;

	if (RedisModule_CreateCommand(ctx, cmd_proxy_get(FLUSHDB), HProxyCommand,
				      "", 1, 1, 1) == REDISMODULE_ERR)
		return REDISMODULE_ERR;

	if (RedisModule_RegisterCommandFilter(ctx, HProxyCommandFilter,
					      REDISMODULE_CMDFILTER_NOSELF) ==
	    NULL)
		return REDISMODULE_ERR;

	return REDISMODULE_OK;
}
