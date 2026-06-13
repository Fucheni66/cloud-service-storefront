-- 站点联系方式增量脚本：app_configs site 分组新增联系电话/邮箱（前台页脚展示，后台「系统设置·站点」维护）
-- 与 schema.sql 同步，可重复执行（INSERT IGNORE）。
-- 应用：
--   /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 \
--     ajou_admin < src/main/webapp/WEB-INF/sql/2026-site-contact.sql

INSERT IGNORE INTO app_configs (config_key, config_group, config_value, label, is_secret, sort_order) VALUES
  ('site.contact_phone', 'site', '400-888-8888',          '联系电话', 0, 4),
  ('site.contact_email', 'site', 'admin@example.com', '联系邮箱', 0, 5);
