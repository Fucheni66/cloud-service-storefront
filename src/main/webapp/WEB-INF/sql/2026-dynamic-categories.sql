-- AJOU 增量脚本：产品动态「可管理分类」+ 精选教程并入产品动态
-- 1) 新建 dynamic_categories（分类可自定义增删改，带配色）
-- 2) 将原 tutorials 内容迁移为 dynamic_posts（category=tutorial），并删除 tutorials 表
-- 全部 IF NOT EXISTS / INSERT IGNORE / DROP IF EXISTS，可重复执行。
-- 执行：
-- /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 < 2026-dynamic-categories.sql

USE ajou_admin;

-- 产品动态分类（可在后台自定义）
CREATE TABLE IF NOT EXISTS dynamic_categories (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  code       VARCHAR(32) NOT NULL UNIQUE COMMENT '分类标识(英数下划线连字符)，对应 dynamic_posts.category 与前台 #hash',
  name       VARCHAR(64) NOT NULL COMMENT '分类显示名',
  color      VARCHAR(20) NOT NULL DEFAULT 'blue' COMMENT '角标配色键 blue/green/orange/red/indigo/slate/emerald/gray',
  sort_order INT         NOT NULL DEFAULT 0 COMMENT '排序权重',
  is_active  TINYINT(1)  NOT NULL DEFAULT 1 COMMENT '是否启用(前台导航与发布可选)',
  created_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品动态分类';

INSERT IGNORE INTO dynamic_categories (code, name, color, sort_order) VALUES
  ('release',     '新品发布', 'blue',    1),
  ('price',       '价格调整', 'orange',  2),
  ('maintenance', '维护公告', 'gray',    3),
  ('solution',    '解决方案', 'indigo',  4),
  ('about',       '关于我们', 'slate',   5),
  ('support',     '帮助支持', 'emerald', 6),
  ('tutorial',    '精选教程', 'green',   7);

-- 精选教程并入产品动态（category=tutorial）。原 tutorials 的 3 条种子内容迁移为文章。
INSERT IGNORE INTO dynamic_posts
  (slug, category, title, summary, content, product_scope, is_published, sort_order, published_at)
VALUES
  ('tutorial-ecs-init',    'tutorial', 'ECS 实例初始化和远程连接', '完成实例购买后，配置登录密钥、安全组和 SSH 连接。',
   '完成实例购买后，配置登录密钥、安全组和 SSH 连接。', '栏目：精选教程', 1, 21, '2026-04-27'),
  ('tutorial-gpu-infer',   'tutorial', 'GPU 实例运行推理服务',   '检查驱动环境、部署模型服务，并监控显存占用。',
   '检查驱动环境、部署模型服务，并监控显存占用。', '栏目：精选教程', 1, 22, '2026-04-26'),
  ('tutorial-billing-cost','tutorial', '按量计费资源的成本查看', '了解小时单价、月预估费用和控制台资源记录。',
   '了解小时单价、月预估费用和控制台资源记录。', '栏目：精选教程', 1, 23, '2026-04-25');

-- 删除独立的精选教程表（内容已并入产品动态）
DROP TABLE IF EXISTS tutorials;
