import http from 'k6/http';
import { sleep, check } from 'k6';
import { Counter } from 'k6/metrics';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';
import redis from 'k6/experimental/redis';

export const requests = new Counter('http_reqs');
export const options = {
  stages: [
    { target: 100, duration: '1m' },
    { target: 200, duration: '1m' },
    { target: 300, duration: '1m' },
  ],
};

const redis_addrs = '127.0.0.1:6379';
const redis_password = '';
const redisClient = new redis.Client({
  addrs: redis_addrs.split(','),
  password: redis_password,
});

export default async function () {
  const randomPostfixLen = randomIntBetween(1, 3);
  const postfix = randomString(randomPostfixLen, '1234567890abcdef')
  const domain = 'dainius' + postfix + '.lt';
  const exists = await redisClient.exists('vhost:' + domain);

  if (exists == true) {
    const params = { headers: { 'Host': domain } };
    const res = http.get('http://127.0.0.1', params);
    sleep(1);
    const checkRes = check(res, {
      'status is 200': (r) => r.status === 200,
    });
  }
}
