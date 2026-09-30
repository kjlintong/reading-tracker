/**
 * 极简 .env 加载器（避免引入 dotenv 依赖）
 * 已存在的环境变量优先，不会被 .env 覆盖。
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function loadEnv(envPath) {
  const file = envPath ?? path.join(__dirname, '..', '.env');
  if (!fs.existsSync(file)) return {};

  const parsed = {};
  const content = fs.readFileSync(file, 'utf8');
  for (const line of content.split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const eq = t.indexOf('=');
    if (eq < 0) continue;
    const key = t.slice(0, eq).trim();
    let val = t.slice(eq + 1).trim();
    // 去掉成对引号
    if ((val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    parsed[key] = val;
    if (process.env[key] === undefined) process.env[key] = val;
  }
  return parsed;
}

export default loadEnv;
