-- ============================================================
-- 2026 增量：SMTP 邮件配置 + 邮箱验证码场景隔离
-- 支撑功能：后台 SMTP 配置、注册/登录/找回密码三类邮箱验证码、个人中心
-- 执行（务必加 --default-character-set=utf8mb4）：
-- /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 \
--   ajou_admin < src/main/webapp/WEB-INF/sql/2026-smtp-and-auth.sql
-- ============================================================

USE ajou_admin;

-- 邮箱验证码增加「场景」列：register 注册 / login 验证码登录 / reset 找回密码
-- 避免一个场景的验证码被另一场景误用。
SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ajou_admin' AND TABLE_NAME = 'email_codes' AND COLUMN_NAME = 'scene'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE email_codes ADD COLUMN scene VARCHAR(20) NOT NULL DEFAULT ''register'' COMMENT ''register/login/reset'' AFTER code',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- SMTP 邮件发送配置（key-value，沿用系统设置分组机制）。
-- 注意：smtp.password 为敏感项（is_secret=1），不在此脚本写入真实授权码，
-- 部署后请在「后台 > 系统设置 > SMTP 邮件」中填写，或单独执行一条 UPDATE 设置。
INSERT IGNORE INTO app_configs (config_key, config_group, config_value, label, is_secret, sort_order) VALUES
  ('smtp.host',      'smtp', 'smtp.qq.com',      'SMTP 服务器地址',          0, 1),
  ('smtp.port',      'smtp', '465',              '端口（SSL 用 465，STARTTLS 用 587）', 0, 2),
  ('smtp.ssl',       'smtp', '1',                '启用 SSL（1=SSL/465，0=STARTTLS/587）', 0, 3),
  ('smtp.username',  'smtp', 'noreply@example.com',  '用户名/帐户',              0, 4),
  ('smtp.password',  'smtp', '',                 '密码/授权码',              1, 5),
  ('smtp.from',      'smtp', 'noreply@example.com',  '发件地址（通常同用户名）', 0, 6),
  ('smtp.from_name', 'smtp', 'AJOU 云服务',       '发件人显示名',             0, 7);
