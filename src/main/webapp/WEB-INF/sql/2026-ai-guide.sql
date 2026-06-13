-- AI 导购增量脚本：app_configs 新增 ai 分组（大模型配置，DeepSeek 兼容 OpenAI 格式）
-- 前台 AI 导购悬浮球经 /api/ai/chat 后端代理调用，密钥仅存数据库（is_secret 不回显），不入代码库。
-- 与 schema.sql 同步，可重复执行（INSERT IGNORE）。
-- 应用：
--   /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 \
--     ajou_admin < src/main/webapp/WEB-INF/sql/2026-ai-guide.sql

INSERT IGNORE INTO app_configs (config_key, config_group, config_value, label, is_secret, sort_order) VALUES
  ('ai.enabled',       'ai', '1',                        '启用 AI 导购（1开/0关）', 0, 1),
  ('ai.api_base_url',  'ai', 'https://api.deepseek.com', '接口地址（OpenAI 兼容）', 0, 2),
  ('ai.model',         'ai', 'deepseek-chat',            '模型名称', 0, 3),
  ('ai.api_key',       'ai', '',                         'API Key', 1, 4),
  ('ai.system_prompt', 'ai', '',                         '附加系统提示词（可选）', 0, 5);
