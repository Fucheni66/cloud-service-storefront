-- 开发者社区「技术支持」卡片增量脚本：app_configs site 分组新增工单时间/故障响应/回复时效
-- 前台 developer-community.jsp 右侧「技术支持」卡片读取，后台「系统设置·站点」维护。
-- 与 schema.sql 同步，可重复执行（INSERT IGNORE）。
-- 应用：
--   /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 \
--     ajou_admin < src/main/webapp/WEB-INF/sql/2026-community-support.sql

INSERT IGNORE INTO app_configs (config_key, config_group, config_value, label, is_secret, sort_order) VALUES
  ('site.support_ticket_hours', 'site', '09:00-22:00', '社区-在线工单时间', 0, 6),
  ('site.support_fault',        'site', '优先响应',     '社区-实例故障响应', 0, 7),
  ('site.support_reply',        'site', '工作日',       '社区-社区回复时效', 0, 8);
