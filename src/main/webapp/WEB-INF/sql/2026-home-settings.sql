-- 首页运营增量脚本：热门产品权重 + 热门产品推荐卡片 + 首页产品动态展示配置
-- 与 schema.sql 同步，可重复执行（ALTER 用 information_schema 守卫，CREATE/INSERT 幂等）。
-- 应用：
--   /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 \
--     ajou_admin < src/main/webapp/WEB-INF/sql/2026-home-settings.sql

-- ============ 1) product_specs 增加首页热门权重列（幂等） ============
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'product_specs' AND COLUMN_NAME = 'home_weight');
SET @sql := IF(@col = 0,
  'ALTER TABLE product_specs ADD COLUMN home_weight INT NOT NULL DEFAULT 0 COMMENT ''首页热门权重,>0进首页热门产品区,按权重降序'' AFTER sort_order',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 给现有种子规格设权重：前 4 个进首页热门浮层（gpu_a100 默认 0 不进）
UPDATE product_specs SET home_weight = 100 WHERE instance_code = '2c4g'   AND home_weight = 0;
UPDATE product_specs SET home_weight = 90  WHERE instance_code = '4c8g'   AND home_weight = 0;
UPDATE product_specs SET home_weight = 80  WHERE instance_code = '8c16g'  AND home_weight = 0;
UPDATE product_specs SET home_weight = 70  WHERE instance_code = 'gpu_t4' AND home_weight = 0;

-- ============ 2) 首页热门产品推荐卡片（三标签可管理） ============
CREATE TABLE IF NOT EXISTS home_recommends (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  tab           VARCHAR(20)  NOT NULL DEFAULT 'basic' COMMENT '标签:basic通用服务器/business业务部署/gpu GPU算力',
  title         VARCHAR(64)  NOT NULL COMMENT '卡片标题',
  description   VARCHAR(255) NULL COMMENT '卡片描述',
  icon          VARCHAR(64)  NOT NULL DEFAULT 'fa-solid fa-server' COMMENT 'FontAwesome 图标 class',
  spec_text     VARCHAR(64)  NULL COMMENT '推荐配置文案，如 2核 4G / 40GB SSD',
  price         VARCHAR(32)  NULL COMMENT '展示价格，如 60',
  unit          VARCHAR(16)  NOT NULL DEFAULT '/月起' COMMENT '价格单位文案',
  instance_code VARCHAR(32)  NULL COMMENT '购买跳转 purchase.jsp?instance= 的规格标识',
  is_active     TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否展示',
  sort_order    INT          NOT NULL DEFAULT 0 COMMENT '同标签内排序',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_tab (tab)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='首页热门产品推荐卡片';

-- 种子：搬运 index.jsp 原 9 张硬编码卡片（重复执行安全，靠 title+tab 不重复）
INSERT INTO home_recommends (tab, title, description, icon, spec_text, price, unit, instance_code, sort_order)
SELECT * FROM (
  SELECT 'basic'    AS tab, '个人网站服务器'  AS title, '适合个人博客、作品集、课程项目和企业官网，配置轻量，成本可控。' AS description, 'fa-solid fa-globe'         AS icon, '2核 4G / 40GB SSD'  AS spec_text, '60'   AS price, '/月起' AS unit, '2c4g'     AS instance_code, 1 AS sort_order UNION ALL
  SELECT 'basic',    '开发测试环境',   '适合接口调试、后台管理系统测试、数据库联调和临时演示环境。',     'fa-solid fa-code',          '4核 8G / 80GB SSD',  '120',  '/月起', '4c8g',     2 UNION ALL
  SELECT 'basic',    '企业应用服务器', '适合中小企业业务系统、CRM、ERP、管理后台和小程序后端服务。',     'fa-solid fa-building',      '8核 16G / 100GB SSD','250',  '/月起', '8c16g',    3 UNION ALL
  SELECT 'business', '高并发 Web 服务','支撑活动页、门户站点和业务接口，适合搭配负载均衡和缓存使用。',   'fa-solid fa-bolt',          '8核 16G / 高带宽',   '250',  '/月起', '8c16g',    1 UNION ALL
  SELECT 'business', '数据库与缓存节点','适合部署 MySQL、Redis、队列服务和业务中间件，保障应用基础能力。','fa-solid fa-database',      '4核 8G / 100GB SSD', '120',  '/月起', '4c8g',     2 UNION ALL
  SELECT 'business', '安全运维跳板机', '适合作为 SSH 登录入口、运维控制节点和内网管理入口，便于权限管理。','fa-solid fa-shield-halved', '2核 4G / 安全组',    '60',   '/月起', '2c4g',     3 UNION ALL
  SELECT 'gpu',      '轻量推理服务器', '适合轻量模型推理、图像识别、实验 API 服务和小型 GPU 任务。',     'fa-solid fa-robot',         'NVIDIA T4',          '1200', '/月起', 'gpu_t4',   1 UNION ALL
  SELECT 'gpu',      '图形渲染工作站', '适合云端渲染、视频处理、图形任务和需要 GPU 加速的桌面环境。',     'fa-solid fa-gauge-high',    'GPU T4 / 16G 显存',  '1200', '/月起', 'gpu_t4',   2 UNION ALL
  SELECT 'gpu',      '训练实验服务器', '适合深度学习实验、数据处理任务和需要更高显存的训练环境。',       'fa-solid fa-brain',         'NVIDIA A100',        '8500', '/月起', 'gpu_a100', 3
) AS seed
WHERE NOT EXISTS (SELECT 1 FROM home_recommends LIMIT 1);

-- ============ 3) 首页产品动态展示配置（app_configs home 分组） ============
INSERT IGNORE INTO app_configs (config_key, config_group, config_value, label, is_secret, sort_order) VALUES
  ('home.dynamic_category', 'home', '', '首页产品动态-展示分类(空=不限,取最新)', 0, 1),
  ('home.dynamic_slug',     'home', '', '首页产品动态-指定文章(空=该分类最新一条)', 0, 2);
