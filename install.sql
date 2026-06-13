-- ============================================================
-- AJOU 云服务 v2 —— 数据库一键初始化脚本 
-- 包含：建库建表 + 种子数据 + 全部增量 + 后台管理员账号
-- 字符集：导入务必使用 utf8mb4，否则中文乱码
--   mysql --default-character-set=utf8mb4 -u用户 -p < install.sql
-- 导入本文件（库的排序规则选 utf8mb4_unicode_ci）
-- 生成时间：手动合并，全部语句幂等(可重复导入)
-- ============================================================

-- ========== [1/9] schema.sql 主结构与基础种子 ==========
-- AJOU 管理后台数据库建表脚本
-- 执行（务必加 --default-character-set=utf8mb4，否则种子中文会乱码）：
-- /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 < schema.sql

CREATE DATABASE IF NOT EXISTS ajou_admin
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ajou_admin;

-- 管理员表
CREATE TABLE IF NOT EXISTS admins (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(64)  NOT NULL UNIQUE COMMENT '登录用户名',
  password_hash VARCHAR(100) NOT NULL COMMENT 'BCrypt 哈希(60 字符, 留余量)',
  display_name  VARCHAR(64)  NOT NULL COMMENT '显示名',
  role          VARCHAR(32)  NOT NULL DEFAULT 'admin' COMMENT '角色',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  last_login_at TIMESTAMP    NULL DEFAULT NULL COMMENT '最近登录时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='后台管理员';

-- 云产品规格（SKU）—— 数据来源：前端 products.config.js / purchase.config.js
CREATE TABLE IF NOT EXISTS product_specs (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  instance_code VARCHAR(32)  NOT NULL UNIQUE COMMENT '规格标识，如 2c4g/gpu_t4',
  title         VARCHAR(64)  NOT NULL COMMENT '展示名称',
  description   VARCHAR(255) NULL COMMENT '副标题/适用说明',
  category      VARCHAR(16)  NOT NULL DEFAULT 'cpu' COMMENT '分组：cpu/gpu',
  vcpu          INT          NOT NULL DEFAULT 0 COMMENT 'vCPU 核数',
  memory_gb     INT          NOT NULL DEFAULT 0 COMMENT '内存 GB',
  feature_spec  VARCHAR(64)  NULL COMMENT '第三条规格(CPU:带宽 / GPU:算力)',
  gpu_info      VARCHAR(128) NULL COMMENT 'GPU 卡型/显存(CPU 型为空)',
  price_monthly DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '月付价(元)',
  unit          VARCHAR(16)  NOT NULL DEFAULT '/月起' COMMENT '价格单位文案',
  badge_text    VARCHAR(32)  NULL COMMENT '徽章文案，如 畅销',
  is_active     TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否上架',
  sort_order    INT          NOT NULL DEFAULT 0 COMMENT '排序权重',
  home_weight   INT          NOT NULL DEFAULT 0 COMMENT '首页热门权重,>0进首页热门产品区,按权重降序',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='云产品规格(SKU)';

-- 初始种子数据（来自 products.config.js，重复执行安全）。home_weight 前 4 进首页热门浮层
INSERT IGNORE INTO product_specs
  (instance_code, title, description, category, vcpu, memory_gb, feature_spec, gpu_info, price_monthly, badge_text, sort_order, home_weight)
VALUES
  ('2c4g',     '入门型 2c4g',   '通用型 g7 | 适合个人开发者建站、测试',     'cpu', 2,  4,  '最高 5Gbps 内网带宽',  NULL,                   60.00,  '畅销', 1, 100),
  ('4c8g',     '企业型 4c8g',   '通用型 g7 | 适合中小企业应用、数据库',     'cpu', 4,  8,  '最高 10Gbps 内网带宽', NULL,                   120.00, NULL,   2, 90),
  ('8c16g',    '高计算型 8c16g','计算型 c7 | 高并发Web、大型游戏服',        'cpu', 8,  16, '最高 15Gbps 内网带宽', NULL,                   250.00, NULL,   3, 80),
  ('gpu_t4',   'AI 推理型 T4',  '含 1 * NVIDIA T4 | 轻量级AI推理、云游戏', 'gpu', 4,  16, '130 TOPS INT8 算力',   '1 * NVIDIA T4 16GB',   1200.00,NULL,   4, 70),
  ('gpu_a100', 'AI 训练型 A100','含 1 * NVIDIA A100 | 深度学习、大模型训练','gpu',12, 96, '624 TFLOPS 算力',      '1 * NVIDIA A100 40/80GB',8500.00,NULL,  5, 0);

-- 顾客端用户（合并 PHP email_users / google_users，用 provider 区分）
CREATE TABLE IF NOT EXISTS users (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  ext_id         VARCHAR(64)  NOT NULL UNIQUE COMMENT '来源ID(email_user_/google_user_)',
  provider       VARCHAR(20)  NOT NULL DEFAULT 'email' COMMENT 'email/google',
  email          VARCHAR(255) NOT NULL COMMENT '邮箱',
  display_name   VARCHAR(255) NULL COMMENT '显示名',
  picture        VARCHAR(512) NULL COMMENT '头像URL',
  google_sub     VARCHAR(100) NULL COMMENT 'Google 唯一ID',
  email_verified TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '邮箱是否已验证',
  login_count    INT          NOT NULL DEFAULT 0 COMMENT '累计登录次数',
  password_hash  VARCHAR(100) NULL COMMENT 'BCrypt 哈希(邮箱注册用户)',
  status         VARCHAR(20)  NOT NULL DEFAULT 'active' COMMENT 'active/disabled',
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_at  TIMESTAMP    NULL DEFAULT NULL,
  INDEX idx_provider (provider),
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='顾客端用户';

-- 用户种子（示例 + 1 条来自 PHP google_users.json 的真实迁移记录）
INSERT IGNORE INTO users
  (ext_id, provider, email, display_name, google_sub, email_verified, login_count, status, last_login_at)
VALUES
  ('email_user_seed01', 'email',  'alice@example.com', 'Alice', NULL, 1, 3, 'active',   '2026-04-28 09:10:00'),
  ('email_user_seed02', 'email',  'bob@example.com',   'Bob',   NULL, 1, 1, 'active',   '2026-04-29 14:20:00'),
  ('email_user_seed03', 'email',  'carol@example.com', 'Carol', NULL, 1, 0, 'disabled', NULL),
  ('google_user_demo01', 'google', 'admin@example.com', 'Admin', '100000000000000000000', 1, 5, 'active', '2026-04-28 01:47:43'),
  ('google_user_seed02', 'google', 'dave@example.com',  'Dave',  '110000000000000000002', 1, 2, 'active', '2026-05-01 11:00:00');

-- 云实例订单（替代 PHP purchases）—— 订单视角与云实例视角共用此表
CREATE TABLE IF NOT EXISTS cloud_orders (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  order_no      VARCHAR(64)  NOT NULL UNIQUE COMMENT '订单号',
  user_id       INT          NULL COMMENT '关联 users.id',
  user_email    VARCHAR(255) NULL COMMENT '下单用户邮箱(冗余)',
  instance_code VARCHAR(32)  NOT NULL COMMENT '规格 2c4g/gpu_t4',
  instance_name VARCHAR(64)  NULL COMMENT '实例名称',
  region        VARCHAR(32)  NOT NULL DEFAULT 'beijing' COMMENT '地域 code',
  os            VARCHAR(32)  NULL COMMENT '操作系统',
  disk          VARCHAR(64)  NULL COMMENT '磁盘',
  public_ip     VARCHAR(50)  NULL COMMENT '公网IP',
  billing       VARCHAR(20)  NOT NULL DEFAULT 'monthly' COMMENT 'monthly/hourly',
  amount        DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '金额',
  status        VARCHAR(20)  NOT NULL DEFAULT 'pending' COMMENT 'running/expired/pending/released',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '下单时间',
  paid_at       DATETIME     NULL COMMENT '支付时间',
  expire_at     DATE         NULL COMMENT '到期时间',
  INDEX idx_status (status),
  INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='云实例订单';

-- 云实例订单种子（覆盖 运行中/待支付/已到期，金额对应产品价格）
INSERT IGNORE INTO cloud_orders
  (order_no, user_id, user_email, instance_code, instance_name, region, os, disk, public_ip, billing, amount, status, paid_at, expire_at)
VALUES
  ('ecs-20260601001', 4, 'admin@example.com', '2c4g',     '个人建站',   'beijing',   'ubuntu', '40GB SSD',   '39.105.18.26',  'monthly', 60.00,   'running', '2026-06-01 09:12:00', '2026-07-01'),
  ('ecs-20260603002', 1, 'alice@example.com',     '4c8g',     '企业应用',   'shanghai',  'centos', '100GB SSD',  '47.100.20.31',  'monthly', 120.00,  'running', '2026-06-03 14:05:00', '2026-06-15'),
  ('ecs-20260605003', 2, 'bob@example.com',       'gpu_t4',   'AI推理节点', 'guangzhou', 'ubuntu', '200GB ESSD', '120.78.55.12',  'monthly', 1200.00, 'running', '2026-06-05 10:00:00', '2026-09-05'),
  ('ecs-20260510004', 4, 'admin@example.com', '2c4g',     '测试机',     'beijing',   'debian', '40GB SSD',   '39.105.18.99',  'monthly', 60.00,   'expired', '2026-05-10 08:30:00', '2026-06-10'),
  ('ecs-20260611005', 1, 'alice@example.com',     '8c16g',    '高性能Web',  'singapore', 'ubuntu', '100GB SSD',  NULL,            'monthly', 250.00,  'pending', NULL,                  NULL),
  ('ecs-20260606006', 5, 'dave@example.com',        'gpu_a100', '大模型训练', 'beijing',   'ubuntu', '500GB ESSD', '39.105.18.200', 'monthly', 8500.00, 'running', '2026-06-06 16:40:00', '2026-12-06');

-- 系统配置（key-value + 分组），来源：PHP config/app.php 的 google_oauth / alipay_face_pay
CREATE TABLE IF NOT EXISTS app_configs (
  config_key   VARCHAR(64)  PRIMARY KEY COMMENT '配置键 group.name',
  config_group VARCHAR(32)  NOT NULL COMMENT '分组 google/alipay/wechat/site',
  config_value TEXT         NULL COMMENT '配置值',
  label        VARCHAR(128) NOT NULL COMMENT '显示名',
  is_secret    TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '是否敏感(不回显)',
  sort_order   INT          NOT NULL DEFAULT 0,
  updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_group (config_group)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置';

INSERT IGNORE INTO app_configs (config_key, config_group, config_value, label, is_secret, sort_order) VALUES
  ('google.client_id',           'google', '203242566561-jp41htf16rca7cr5l5kusio7tubdoton.apps.googleusercontent.com', 'Client ID', 0, 1),
  ('google.tokeninfo_url',       'google', 'https://oauth2.googleapis.com/tokeninfo', 'Tokeninfo 校验地址', 0, 2),
  ('google.authorized_origins',  'google', 'https://ajou.userapi.cn,https://fucheni66.github.io', '授权来源(逗号分隔)', 0, 3),
  ('alipay.app_id',              'alipay', '', '应用 App ID', 0, 1),
  ('alipay.merchant_private_key','alipay', '', '商户私钥', 1, 2),
  ('alipay.public_key',          'alipay', '', '支付宝公钥', 1, 3),
  ('alipay.gateway_url',         'alipay', 'https://openapi.alipay.com/gateway.do', '网关地址', 0, 4),
  ('alipay.sign_type',           'alipay', 'RSA2', '签名算法', 0, 5),
  ('wechat.app_id',              'wechat', '', '公众号/小程序 AppID', 0, 1),
  ('wechat.mch_id',              'wechat', '', '商户号 MchID', 0, 2),
  ('wechat.app_secret',          'wechat', '', 'AppSecret', 1, 3),
  ('wechat.api_v3_key',          'wechat', '', 'APIv3 密钥', 1, 4),
  ('wechat.notify_url',          'wechat', '', '支付回调地址', 0, 5),
  ('site.name',                  'site',   'AJOU 云服务', '站点名称', 0, 1),
  ('site.api_base_url',          'site',   'https://ajou.userapi.cn/', 'API 基地址', 0, 2),
  ('site.icp',                   'site',   '', '备案号', 0, 3),
  ('site.contact_phone',         'site',   '400-888-8888', '联系电话', 0, 4),
  ('site.contact_email',         'site',   'admin@example.com', '联系邮箱', 0, 5),
  ('site.support_ticket_hours',  'site',   '09:00-22:00', '社区-在线工单时间', 0, 6),
  ('site.support_fault',         'site',   '优先响应', '社区-实例故障响应', 0, 7),
  ('site.support_reply',         'site',   '工作日', '社区-社区回复时效', 0, 8),
  ('ai.enabled',                 'ai',     '1', '启用 AI 导购（1开/0关）', 0, 1),
  ('ai.api_base_url',            'ai',     'https://api.deepseek.com', '接口地址（OpenAI 兼容）', 0, 2),
  ('ai.model',                   'ai',     'deepseek-chat', '模型名称', 0, 3),
  ('ai.api_key',                 'ai',     '', 'API Key', 1, 4),
  ('ai.system_prompt',           'ai',     '', '附加系统提示词（可选）', 0, 5),
  ('home.dynamic_category',      'home',   '', '首页产品动态-展示分类(空=不限,取最新)', 0, 1),
  ('home.dynamic_slug',          'home',   '', '首页产品动态-指定文章(空=该分类最新一条)', 0, 2);

-- 前台登录 token（登录/注册签发，purchases 等接口校验）
CREATE TABLE IF NOT EXISTS auth_tokens (
  token      VARCHAR(64)  PRIMARY KEY COMMENT '本地签发 token',
  user_id    INT          NOT NULL COMMENT '关联 users.id',
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='前台登录令牌';

-- 邮箱验证码（注册校验）
CREATE TABLE IF NOT EXISTS email_codes (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  email      VARCHAR(255) NOT NULL,
  code       CHAR(6)      NOT NULL,
  used       TINYINT(1)   NOT NULL DEFAULT 0,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME     NOT NULL,
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='邮箱验证码';

-- ============================================================
-- 内容运营：产品动态 / 开发者社区问答 / 精选教程
-- 反推自前台 product-dynamics / developer-community / community-* 页面。
-- 详见独立增量脚本 sql/2026-content-community.sql（含完整种子）。
-- ============================================================

-- 产品动态文章（CMS），来源：product-dynamics.jsp / -detail.jsp
CREATE TABLE IF NOT EXISTS dynamic_posts (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  slug          VARCHAR(64)  NOT NULL UNIQUE COMMENT 'URL 标识，对应前台 ?id=',
  category      VARCHAR(20)  NOT NULL DEFAULT 'release' COMMENT 'release/price/maintenance/solution/about/support',
  title         VARCHAR(128) NOT NULL COMMENT '标题',
  summary       VARCHAR(512) NULL COMMENT '列表摘要',
  content       TEXT         NULL COMMENT '详情正文（段落以空行分隔）',
  product_scope VARCHAR(128) NULL COMMENT '适用产品/影响地域/栏目',
  badge_text    VARCHAR(32)  NULL COMMENT '角标文案（留空用分类名）',
  is_published  TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否发布',
  sort_order    INT          NOT NULL DEFAULT 0 COMMENT '排序权重',
  view_count    INT          NOT NULL DEFAULT 0 COMMENT '浏览次数',
  published_at  DATE         NULL COMMENT '发布日期',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_category (category),
  INDEX idx_published (is_published)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品动态文章';

-- 开发者社区问答，来源：developer-community.jsp / community-question-detail.jsp
CREATE TABLE IF NOT EXISTS community_questions (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  slug           VARCHAR(64)  NOT NULL UNIQUE COMMENT 'URL 标识，对应前台 ?question=',
  tag            VARCHAR(32)  NULL COMMENT '角标，如 连接/计费',
  category       VARCHAR(64)  NOT NULL DEFAULT '云服务器 ECS' COMMENT '分类',
  type           VARCHAR(32)  NOT NULL DEFAULT '问题求助' COMMENT '问题求助/经验分享/教程文章',
  title          VARCHAR(255) NOT NULL COMMENT '标题',
  summary        VARCHAR(512) NULL COMMENT '列表摘要',
  content        TEXT         NULL COMMENT '正文',
  recommendation TEXT         NULL COMMENT '推荐处理（高亮块）',
  contact        VARCHAR(128) NULL COMMENT '联系方式（仅后台可见）',
  author_name    VARCHAR(64)  NOT NULL DEFAULT '社区用户' COMMENT '发表人',
  status         VARCHAR(20)  NOT NULL DEFAULT 'published' COMMENT 'pending/published/closed',
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='开发者社区问答';

-- 社区问答回复
CREATE TABLE IF NOT EXISTS community_replies (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  question_id INT          NOT NULL COMMENT '关联 community_questions.id',
  author_name VARCHAR(64)  NOT NULL DEFAULT '社区用户' COMMENT '回复人',
  is_official TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '是否官方回复',
  content     TEXT         NOT NULL COMMENT '回复正文',
  like_count  INT          NOT NULL DEFAULT 0 COMMENT '点赞数',
  status      VARCHAR(20)  NOT NULL DEFAULT 'published' COMMENT 'published/hidden',
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_question (question_id),
  UNIQUE KEY uk_question_time (question_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='社区问答回复';

-- 产品动态分类（可自定义），来源：后台「动态分类」。精选教程为其中 tutorial 分类。
-- 分类种子与精选教程内容迁移见 sql/2026-dynamic-categories.sql。
CREATE TABLE IF NOT EXISTS dynamic_categories (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  code       VARCHAR(32) NOT NULL UNIQUE COMMENT '分类标识，对应 dynamic_posts.category 与前台 #hash',
  name       VARCHAR(64) NOT NULL COMMENT '分类显示名',
  color      VARCHAR(20) NOT NULL DEFAULT 'blue' COMMENT '角标配色键',
  sort_order INT         NOT NULL DEFAULT 0 COMMENT '排序权重',
  is_active  TINYINT(1)  NOT NULL DEFAULT 1 COMMENT '是否启用',
  created_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品动态分类';

-- 首页「热门产品推荐」卡片（三标签可管理），来源：后台「首页推荐」。卡片种子见 sql/2026-home-settings.sql。
CREATE TABLE IF NOT EXISTS home_recommends (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  tab           VARCHAR(20)  NOT NULL DEFAULT 'basic' COMMENT '标签:basic通用服务器/business业务部署/gpu GPU算力',
  title         VARCHAR(64)  NOT NULL COMMENT '卡片标题',
  description   VARCHAR(255) NULL COMMENT '卡片描述',
  icon          VARCHAR(64)  NOT NULL DEFAULT 'fa-solid fa-server' COMMENT 'FontAwesome 图标 class',
  spec_text     VARCHAR(64)  NULL COMMENT '推荐配置文案',
  price         VARCHAR(32)  NULL COMMENT '展示价格',
  unit          VARCHAR(16)  NOT NULL DEFAULT '/月起' COMMENT '价格单位文案',
  instance_code VARCHAR(32)  NULL COMMENT '购买跳转规格标识',
  is_active     TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否展示',
  sort_order    INT          NOT NULL DEFAULT 0 COMMENT '同标签内排序',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_tab (tab)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='首页热门产品推荐卡片';

-- ============================================================
-- 后续阶段表设计草案（本次不建，仅记录方向）
-- ------------------------------------------------------------
-- regions / disk_types / os_images / billing_rules  购买配置
-- ============================================================

-- ========== [2/9] 2026-content-community.sql 动态/社区表与种子 ==========
-- AJOU 内容运营增量脚本：产品动态 / 开发者社区问答 / 精选教程
-- 反推自前台页面 product-dynamics(.jsp/-detail.jsp)、developer-community.jsp、
-- community-question-detail.jsp、community-publish.jsp。
-- 全部 IF NOT EXISTS / INSERT IGNORE，可重复执行。
-- 执行（务必加 --default-character-set=utf8mb4，否则种子中文乱码）：
-- /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 < 2026-content-community.sql

USE ajou_admin;

-- ============================================================
-- 产品动态文章（CMS）—— 数据来源：product-dynamics.jsp / product-dynamics-detail.jsp
-- category 对应前台左侧动态分类：release/price/maintenance/solution/about/support
-- ============================================================
CREATE TABLE IF NOT EXISTS dynamic_posts (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  slug          VARCHAR(64)  NOT NULL UNIQUE COMMENT 'URL 标识，对应前台 ?id=（如 release-a100）',
  category      VARCHAR(20)  NOT NULL DEFAULT 'release' COMMENT '分类 release/price/maintenance/solution/about/support',
  title         VARCHAR(128) NOT NULL COMMENT '标题',
  summary       VARCHAR(512) NULL COMMENT '列表摘要',
  content       TEXT         NULL COMMENT '详情正文（段落以空行分隔）',
  product_scope VARCHAR(128) NULL COMMENT '适用产品/影响地域/栏目，详情页副信息',
  badge_text    VARCHAR(32)  NULL COMMENT '角标文案（留空则用分类默认名）',
  is_published  TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否发布（前台可见）',
  sort_order    INT          NOT NULL DEFAULT 0 COMMENT '排序权重',
  view_count    INT          NOT NULL DEFAULT 0 COMMENT '浏览次数',
  published_at  DATE         NULL COMMENT '发布日期（前台展示）',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_category (category),
  INDEX idx_published (is_published)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品动态文章';

INSERT IGNORE INTO dynamic_posts
  (slug, category, title, summary, content, product_scope, sort_order, published_at)
VALUES
  ('release-a100', 'release', 'GPU A100 训练实例上线',
   '新增面向深度学习和大模型训练的 A100 实例规格，支持更高显存容量和更稳定的长周期训练任务。',
   'AJOU 新增 A100 训练实例规格，面向深度学习训练、模型微调和大规模推理测试场景。\n\n该规格提供更高显存容量和更稳定的长周期计算能力，适合需要持续运行训练任务的团队使用。\n\n本次更新：新增 A100 40GB GPU 实例规格；支持深度学习训练、模型微调和推理验证；实例购买页可查看可用规格和价格。',
   '适用产品：GPU 云服务器', 1, '2026-04-27'),
  ('price-cpu', 'price', '通用型 CPU 实例按月价格优化',
   '2C4G、4C8G 和 8C16G 实例完成价格配置更新，首页热门产品和产品购买页已统一从商品配置读取。',
   '通用型 CPU 实例完成价格配置更新，覆盖 2C4G、4C8G 和 8C16G 等常用规格。\n\n首页热门产品、产品购买页和下单页已统一读取商品配置，确保用户看到的价格保持一致。\n\n影响范围：涉及通用型 CPU 实例的月付和按量展示价格；已同步到首页热门产品和产品购买页；已购买资源不受本次展示配置变更影响。',
   '适用产品：云服务器 ECS', 2, '2026-04-26'),
  ('maintenance-network', 'maintenance', '华北2地域网络维护窗口',
   '华北2地域将在低峰时段进行网络设备维护。维护期间实例运行不受影响，少量新购资源可能出现短暂分配延迟。',
   '华北2地域将在低峰时段进行网络设备维护，维护期间已运行实例不受影响。\n\n少量新购资源可能出现短暂分配延迟。如资源长时间未开通，可在控制台查看订单状态或提交工单。\n\n用户建议：避免在维护窗口内集中创建大量实例；已经运行的实例无需手动操作；如新购资源延迟，优先查看控制台资源状态。',
   '影响地域：华北2(北京)', 3, '2026-04-25'),
  ('solution-business-cloud', 'solution', '中小型业务上云部署方案',
   '推荐使用云服务器 ECS、通用型 SSD 和基础安全组规则，适合企业官网、后台管理系统和轻量业务服务快速上线。',
   '该方案面向中小型业务系统，推荐以云服务器 ECS 为核心，搭配通用型 SSD 和基础安全组规则完成快速上线。\n\n方案适合企业官网、后台管理系统、轻量 API 服务和测试环境，重点关注成本、可维护性和基础安全。\n\n计算：2C4G 或 4C8G ECS 实例；存储：40GB 通用型 SSD 起步；网络：开放必要端口并限制管理入口。',
   '适用场景：官网、后台、轻量业务系统', 4, '2026-04-27'),
  ('about-company', 'about', '公司简介',
   '了解 AJOU 的云服务器、GPU 算力和基础设施服务能力。',
   'AJOU 专注于云服务器、GPU 算力和基础云资源服务，为个人开发者、中小企业和实验团队提供稳定易用的计算环境。\n\n平台围绕实例购买、资源开通、费用展示和控制台管理构建核心流程，帮助用户快速完成业务部署和资源管理。',
   '栏目：关于我们', 5, '2026-04-28'),
  ('about-news', 'about', '新闻动态',
   '查看平台更新、产品发布和服务公告。',
   '新闻动态用于集中展示 AJOU 的平台更新、产品发布、价格调整、维护公告和解决方案内容。\n\n用户可通过产品动态页面按分类查看最新文章，也可以从页脚直接进入指定文章详情。',
   '栏目：关于我们', 6, '2026-04-28'),
  ('about-contact', 'about', '联系我们',
   '获取售前咨询、技术支持和商务合作联系方式。',
   '如需了解云服务器选型、GPU 实例配置、购买流程或资源开通状态，可以通过以下方式联系 AJOU。\n\n服务热线：400-888-8888；支持邮箱：admin@example.com。',
   '栏目：关于我们', 7, '2026-04-28'),
  ('support-help', 'support', '帮助中心',
   '查找购买、支付、资源开通、控制台查看和实例连接相关说明。',
   '帮助中心整理购买、支付、资源开通、控制台查看和常见实例连接问题。\n\n如果购买成功后资源暂未显示，可以先刷新控制台页面，再根据订单号检查支付和开通状态。',
   '栏目：帮助支持', 8, '2026-04-28'),
  ('support-api', 'support', 'API 文档',
   '查看支付创建、支付查询、二维码生成和用户购买记录接口说明。',
   'API 文档用于说明前端购买页、支付创建、支付查询和二维码接口的调用关系。\n\n正式对接时，订单金额和商品信息应由后端确认后返回，前端只负责展示和发起支付流程。\n\n当前接口：生成支付 POST /alipay_create.php；查询支付 GET /alipay_query.php；二维码 GET /qrcode.php?url=。',
   '栏目：帮助支持', 9, '2026-04-28'),
  ('support-ticket', 'support', '提交工单',
   '遇到支付异常、资源开通延迟、实例无法连接等问题时提交支持请求。',
   '当遇到支付异常、资源长时间未开通、实例状态异常或无法连接时，可以提交工单。\n\n提交时建议附上订单号、实例规格、地域和问题截图，便于支持人员快速定位。',
   '栏目：帮助支持', 10, '2026-04-28');

-- ============================================================
-- 开发者社区问答 —— 数据来源：developer-community.jsp / community-question-detail.jsp
-- status：pending(待审核，前台不可见) / published(已发布) / closed(已关闭)
-- 用户从 community-publish.jsp 发表的内容落为 pending，由后台审核发布。
-- ============================================================
CREATE TABLE IF NOT EXISTS community_questions (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  slug           VARCHAR(64)  NOT NULL UNIQUE COMMENT 'URL 标识，对应前台 ?question=（如 public-ip）',
  tag            VARCHAR(32)  NULL COMMENT '角标，如 连接/计费',
  category       VARCHAR(64)  NOT NULL DEFAULT '云服务器 ECS' COMMENT '分类',
  type           VARCHAR(32)  NOT NULL DEFAULT '问题求助' COMMENT '类型 问题求助/经验分享/教程文章',
  title          VARCHAR(255) NOT NULL COMMENT '标题',
  summary        VARCHAR(512) NULL COMMENT '列表摘要',
  content        TEXT         NULL COMMENT '正文（段落以空行分隔）',
  recommendation TEXT         NULL COMMENT '推荐处理（高亮块，可空）',
  contact        VARCHAR(128) NULL COMMENT '联系方式（发表表单提交，仅后台可见）',
  author_name    VARCHAR(64)  NOT NULL DEFAULT '社区用户' COMMENT '发表人',
  status         VARCHAR(20)  NOT NULL DEFAULT 'published' COMMENT 'pending/published/closed',
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='开发者社区问答';

INSERT IGNORE INTO community_questions
  (slug, tag, category, type, title, summary, content, recommendation, author_name, status, created_at)
VALUES
  ('public-ip', '连接', '云服务器 ECS', '问题求助',
   '实例购买成功后，为什么控制台暂时没有公网地址？',
   '资源分配完成后会写入控制台，本地预览环境会从浏览器存储读取购买记录。',
   '购买成功后页面已经提示资源分配中，但进入控制台时公网地址仍为空，实例状态也没有立即显示为运行中。\n\n这种情况通常是实例记录已经写入浏览器本地存储，但公网地址、系统镜像和资源状态还处在模拟分配阶段。正式环境里需要等待后端资源编排完成后再回写控制台。',
   '先刷新控制台页面确认本地购买记录是否存在。如果是正式资源，应通过订单号查询开通状态；如果超过预计时间仍未完成，可以提交工单并附上订单编号。',
   '社区用户', 'published', '2026-04-27 09:30:00'),
  ('billing-precision', '计费', '费用中心', '问题求助',
   '按量计费为什么只显示两位小数？',
   '购买页展示按小时费用，金额统一保留两位小数，方便用户确认订单。',
   '购买页里按量计费显示为每小时费用，但实际计算时可能有更多小数位。页面现在只展示两位小数，是为了让用户在下单前更容易确认金额。\n\n如果后续接入真实计费系统，前端展示金额和后端结算金额应统一由后端返回，避免前端自行计算造成误差。',
   '展示层保留两位小数即可。支付请求中的金额必须使用后端确认后的金额，不能只依赖浏览器页面计算。',
   '社区用户', 'published', '2026-04-26 14:10:00');

-- 社区回复。以 (question_id, created_at) 作为种子幂等键。
CREATE TABLE IF NOT EXISTS community_replies (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  question_id INT          NOT NULL COMMENT '关联 community_questions.id',
  author_name VARCHAR(64)  NOT NULL DEFAULT '社区用户' COMMENT '回复人',
  is_official TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '是否官方回复',
  content     TEXT         NOT NULL COMMENT '回复正文',
  like_count  INT          NOT NULL DEFAULT 0 COMMENT '点赞数',
  status      VARCHAR(20)  NOT NULL DEFAULT 'published' COMMENT 'published/hidden',
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_question (question_id),
  UNIQUE KEY uk_question_time (question_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='社区问答回复';

INSERT IGNORE INTO community_replies
  (question_id, author_name, is_official, content, like_count, created_at)
VALUES
  ((SELECT id FROM community_questions WHERE slug = 'public-ip'), '云极技术支持', 1,
   '本地预览环境不会真实分配公网 IP，购买成功后只会在控制台显示模拟资源信息。', 12, '2026-04-27 10:20:00'),
  ((SELECT id FROM community_questions WHERE slug = 'public-ip'), '社区用户', 0,
   '可以先确认浏览器没有开启隐私模式，否则本地存储可能不会保留购买记录。', 5, '2026-04-27 11:05:00'),
  ((SELECT id FROM community_questions WHERE slug = 'billing-precision'), '云极技术支持', 1,
   '当前演示页面按小时费用统一保留两位小数，正式账单可以在费用中心查看明细。', 8, '2026-04-26 16:30:00');

-- ============================================================
-- 精选教程：已并入产品动态（dynamic_posts 的 tutorial 分类），不再单独建表。
-- 分类表与教程内容的迁移见 sql/2026-dynamic-categories.sql。
-- ============================================================

-- ========== [3/9] 2026-dynamic-categories.sql 动态分类 ==========
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

-- ========== [4/9] 2026-solution-community-data.sql 社区/方案数据 ==========
-- 内容增量脚本：扩充「解决方案」文章 + 开发者社区问答（含官方回复）
-- 目的：为后续「AI 检索数据库 → 定位解决方案/问答页 → 对话框给跳转按钮」提供基础数据。
-- 解决方案对应前台 product-dynamics.jsp#solution（详情 product-dynamics-detail.jsp?id=<slug>）
-- 社区问答对应前台 developer-community.jsp（详情 community-question-detail.jsp?question=<slug>）
-- 与 schema.sql / 2026-content-community.sql 同源，INSERT IGNORE 可重复执行。
-- 应用：
--   /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 \
--     ajou_admin < src/main/webapp/WEB-INF/sql/2026-solution-community-data.sql

-- ============ 1) 解决方案文章（category = solution） ============
INSERT IGNORE INTO dynamic_posts
  (slug, category, title, summary, content, product_scope, badge_text, is_published, sort_order, published_at)
VALUES
  ('solution-high-availability', 'solution', '高并发网站高可用架构方案',
   '通过负载均衡 + 多台云服务器 + 数据库分离，支撑活动期高并发访问，避免单点故障。',
   '当网站面临活动促销或突发流量时，单台服务器容易成为瓶颈甚至宕机。推荐采用「负载均衡 + 多实例 + 独立数据库」的高可用架构。\n\n前端用 2 台及以上 8核16G 计算型实例承载 Web 服务，通过负载均衡分发流量；数据库与缓存独立部署到单独实例，避免与应用争抢资源；静态资源放对象存储或 CDN 加速。\n\n这样任意一台 Web 实例故障都不影响整体可用性；扩容时只需增加实例并挂到负载均衡即可，按量计费可在活动结束后释放多余实例控制成本。',
   '适用：8核16G 计算型 / 多实例', NULL, 1, 2, '2026-05-20'),

  ('solution-ai-training', 'solution', 'GPU 深度学习训练环境搭建方案',
   '基于 A100 / T4 GPU 实例，快速搭建可用于大模型训练与推理的深度学习环境。',
   '深度学习训练对显存与算力要求高，推荐使用 GPU 云服务器。模型推理、图像识别等轻量场景选择 NVIDIA T4（16G 显存）；大模型训练、长时间任务选择 NVIDIA A100（40G 显存，624 TFLOPS 算力）。\n\n建议系统选 Ubuntu 22.04，安装对应版本的 NVIDIA 驱动与 CUDA、cuDNN，再用 conda 创建独立的 PyTorch / TensorFlow 环境；训练数据挂载极速型 ESSD 云盘提升 IO。\n\n训练任务通常是阶段性的，采用按量计费在任务结束后释放实例可显著降低成本；需要长期使用可转包年包月获得更低单价。',
   '适用：GPU T4 / GPU A100', NULL, 1, 3, '2026-05-18'),

  ('solution-database-deploy', 'solution', '数据库与缓存中间件部署方案',
   '将 MySQL、Redis 等中间件独立部署到专用实例，保障业务系统的数据层稳定。',
   '业务系统的数据库、缓存如果和应用挤在同一台服务器，容易相互抢占内存和 IO，导致性能波动。推荐把数据层独立部署。\n\n选择 4核8G 通用型实例部署 MySQL，系统盘使用极速型 ESSD 提升随机读写；Redis 缓存可与数据库同机或单独部署。数据库端口仅对内网或指定安全组放行，不直接暴露公网。\n\n定期对数据盘做快照备份，重要数据建议主从复制；随业务增长可纵向升配更大内存，或横向拆分读写实例。',
   '适用：4核8G 通用型 / ESSD 云盘', NULL, 1, 4, '2026-05-15'),

  ('solution-static-website', 'solution', '个人建站与开发测试环境方案',
   '用入门级云服务器低成本搭建个人博客、作品集或开发测试环境。',
   '个人博客、作品集、课程项目和开发测试这类轻量场景，对配置要求不高，推荐入门型 2核4G 实例，系统盘 40GB 通用型 SSD 即可起步。\n\n系统选 Ubuntu 22.04，可通过宝塔面板或 Docker 快速部署 WordPress、Nginx、Node 等常见环境。开发测试环境建议开放 22 / 80 / 443 端口，并用安全组限制来源。\n\n这类用途流量平稳，包年包月单价更划算；如只是短期演示，可用按量计费随用随开随释放。',
   '适用：2核4G 入门型', NULL, 1, 5, '2026-05-12'),

  ('solution-security-network', 'solution', '网络安全与访问控制方案',
   '通过安全组、最小端口开放和跳板机，构建云服务器的基础安全防护。',
   '云服务器暴露在公网会面临扫描和爆破风险，做好网络与访问控制是上云第一步。\n\n核心原则是最小开放：安全组只放行业务必需端口（Web 的 80 / 443、Linux 远程的 22、Windows 的 3389），并限制来源 IP；管理入口建议通过单独的跳板机统一登录，内网实例不直接开放公网。\n\n配合定期更新系统补丁、关闭弱口令、开启登录告警，可大幅降低被入侵风险；重要数据务必开启快照与备份。',
   '适用：全部规格 / 安全组', NULL, 1, 6, '2026-05-10'),

  ('solution-cost-optimize', 'solution', '成本优化与弹性伸缩方案',
   '结合包年包月与按量计费，按业务峰谷弹性增减实例，平衡性能与成本。',
   '云资源成本优化的关键是按需付费与峰谷弹性。长期稳定运行的基础服务用包年包月锁定低单价；活动、训练、测试等阶段性负载用按量计费，用完即释放。\n\n面对可预期的流量高峰（如促销），可临时增开多台实例挂到负载均衡，高峰过后释放；GPU 训练任务结束后第一时间释放实例，避免空跑计费。\n\n再配合系统盘容量按需选择、关闭闲置实例，可在不影响业务的前提下显著降低月度支出。',
   '适用：全部规格 / 计费策略', NULL, 1, 7, '2026-05-08');

-- ============ 2) 开发者社区问答（均为已发布） ============
INSERT IGNORE INTO community_questions
  (slug, tag, category, type, title, summary, content, recommendation, author_name, status, created_at)
VALUES
  ('ssh-connect-fail', '连接', '云服务器 ECS', '问题求助',
   '云服务器无法 SSH 远程连接怎么排查？',
   '新购实例 SSH 连不上，多数与安全组端口、公网 IP 或登录凭证有关。',
   '购买实例后用 SSH 连接一直超时或被拒绝，确认密码没输错，但就是连不上，应该从哪些方面排查？\n\n实例状态显示运行中，公网 IP 也已分配，本地用 ssh root@公网IP 连接时提示连接超时。',
   '依次检查：安全组是否放行 22 端口且来源包含你的 IP；公网 IP 与登录用户是否正确（Linux 默认 root）；系统防火墙是否拦截。可参考「网络安全与访问控制方案」。',
   '社区用户', 'published', '2026-05-21 10:12:00'),

  ('gpu-cuda-install', '教程', 'GPU 云服务器', '问题求助',
   'GPU 实例如何安装 NVIDIA 驱动和 CUDA？',
   '新开的 GPU 实例默认没有驱动，需要按显卡型号安装匹配的驱动与 CUDA。',
   '刚开了一台带 T4 的 GPU 实例，跑 nvidia-smi 提示找不到命令，是不是要自己装驱动？应该装哪个版本？\n\n系统是 Ubuntu 22.04，主要想跑 PyTorch 做模型推理。',
   '先按显卡型号安装对应的 NVIDIA 驱动，再装与框架匹配的 CUDA、cuDNN，最后用 conda 创建独立环境装 PyTorch。完整步骤见「GPU 深度学习训练环境搭建方案」。',
   '社区用户', 'published', '2026-05-19 15:40:00'),

  ('web-high-concurrency', '网络', '云服务器 ECS', '问题求助',
   '网站访问量上来后变慢，应该如何扩容？',
   '单台服务器扛不住流量高峰时，可通过升配或多实例 + 负载均衡横向扩展。',
   '一台 4核8G 的服务器平时够用，但搞活动时访问量一大就很卡甚至打不开，加配置能解决吗？还是要加机器？',
   '短期可纵向升配到 8核16G；流量波动大或要高可用，建议多实例 + 负载均衡横向扩展，数据库独立部署。详见「高并发网站高可用架构方案」。',
   '社区用户', 'published', '2026-05-17 11:05:00'),

  ('db-deploy-advice', '网络', '云服务器 ECS', '问题求助',
   '数据库要不要和应用部署在同一台服务器？',
   '小规模可同机，业务增长后建议数据库独立部署，避免与应用争抢资源。',
   '现在 MySQL 和后端应用装在同一台 2核4G 上，最近偶尔出现响应变慢，是不是数据库和应用放一起不太好？',
   '访问量小可以同机起步；一旦出现资源争抢，建议把数据库迁到独立的 4核8G 实例并用 ESSD 云盘。参考「数据库与缓存中间件部署方案」。',
   '社区用户', 'published', '2026-05-16 09:25:00'),

  ('disk-snapshot-backup', '网络', '云服务器 ECS', '问题求助',
   '云服务器的数据如何做备份和快照？',
   '重要数据建议定期对系统盘 / 数据盘做快照，关键库再加主从复制。',
   '服务器上有比较重要的数据，担心误删或故障，平台有没有备份机制？快照和备份是一回事吗？',
   '定期对系统盘和数据盘创建快照即可快速回滚；数据库等关键数据再配主从复制做容灾。安全实践见「网络安全与访问控制方案」。',
   '社区用户', 'published', '2026-05-14 16:50:00'),

  ('billing-choose', '计费', '费用中心', '问题求助',
   '按量计费和包年包月该怎么选？',
   '长期稳定负载选包年包月更省，短期或弹性负载选按量计费用完即释放。',
   '第一次买云服务器，按量计费和包年包月差别大吗？我的项目可能要长期跑，但前期还在测试阶段。',
   '测试阶段用按量计费随用随释放；确定长期运行后转包年包月锁定低单价。成本策略详见「成本优化与弹性伸缩方案」。',
   '社区用户', 'published', '2026-05-13 14:30:00');

-- ============ 3) 社区问答回复（每题含 1 条官方回复 is_official=1） ============
INSERT IGNORE INTO community_replies
  (question_id, author_name, is_official, content, like_count, created_at)
VALUES
  ((SELECT id FROM community_questions WHERE slug = 'ssh-connect-fail'), 'AJOU 官方支持', 1,
   '排查顺序：1) 安全组放行 22 端口且来源包含你的公网 IP；2) 确认公网 IP 与登录用户（Linux 默认 root，Windows 为 Administrator）；3) 检查实例内系统防火墙。本地预览环境为模拟资源，不提供真实 SSH 登录。', 21, '2026-05-21 11:00:00'),
  ((SELECT id FROM community_questions WHERE slug = 'ssh-connect-fail'), '社区用户', 0,
   '我之前也是安全组没放行 22，加上来源 IP 后就好了。', 6, '2026-05-21 13:20:00'),

  ((SELECT id FROM community_questions WHERE slug = 'gpu-cuda-install'), 'AJOU 官方支持', 1,
   'Ubuntu 22.04 上先 apt 安装匹配 T4 的 NVIDIA 驱动并重启，nvidia-smi 正常后再装 CUDA 与 cuDNN，最后用 conda 建环境装对应 CUDA 版本的 PyTorch。完整流程可参考「GPU 深度学习训练环境搭建方案」。', 18, '2026-05-19 16:30:00'),

  ((SELECT id FROM community_questions WHERE slug = 'web-high-concurrency'), 'AJOU 官方支持', 1,
   '建议先评估瓶颈在 CPU 还是带宽：短期可升配到 8核16G；长期高并发用「负载均衡 + 多实例」横向扩展，并把数据库独立出来。方案见「高并发网站高可用架构方案」。', 15, '2026-05-17 12:10:00'),

  ((SELECT id FROM community_questions WHERE slug = 'db-deploy-advice'), 'AJOU 官方支持', 1,
   '出现资源争抢就该拆分了。推荐数据库迁到独立 4核8G 实例并使用极速型 ESSD，端口只对内网放行。详见「数据库与缓存中间件部署方案」。', 13, '2026-05-16 10:40:00'),

  ((SELECT id FROM community_questions WHERE slug = 'disk-snapshot-backup'), 'AJOU 官方支持', 1,
   '快照是某一时刻磁盘的完整镜像，可用于快速回滚；建议对系统盘和数据盘定期做快照，关键数据库再加主从复制做容灾。', 11, '2026-05-14 17:30:00'),

  ((SELECT id FROM community_questions WHERE slug = 'billing-choose'), 'AJOU 官方支持', 1,
   '测试阶段用按量计费，用完即释放最省；确定长期运行后转包年包月可享更低单价，并可按 3 / 6 / 12 个月获得折扣。成本策略见「成本优化与弹性伸缩方案」。', 9, '2026-05-13 15:20:00');

-- ========== [5/9] 2026-community-support.sql 社区相关配置 ==========
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

-- ========== [6/9] 2026-home-settings.sql 首页权重/推荐卡片/动态展示 ==========
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

-- ========== [7/9] 2026-site-contact.sql 站点联系配置 ==========
-- 站点联系方式增量脚本：app_configs site 分组新增联系电话/邮箱（前台页脚展示，后台「系统设置·站点」维护）
-- 与 schema.sql 同步，可重复执行（INSERT IGNORE）。
-- 应用：
--   /Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -uroot -proot -P8889 -h127.0.0.1 \
--     ajou_admin < src/main/webapp/WEB-INF/sql/2026-site-contact.sql

INSERT IGNORE INTO app_configs (config_key, config_group, config_value, label, is_secret, sort_order) VALUES
  ('site.contact_phone', 'site', '400-888-8888',          '联系电话', 0, 4),
  ('site.contact_email', 'site', 'admin@example.com', '联系邮箱', 0, 5);

-- ========== [8/9] 2026-ai-guide.sql AI 大模型配置 ==========
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

-- ========== [9/9] 2026-smtp-and-auth.sql SMTP 配置 + email_codes.scene 列 ==========
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

-- ========== [附加] 后台管理员账号 ==========
-- 用户名 admin / 密码 admin123 （BCrypt 工作因子12，登录后请尽快修改）
USE ajou_admin;
INSERT IGNORE INTO admins (username, password_hash, display_name, role) VALUES
  ('admin', '$2a$12$nE9Kj/CdaDdrMWraa1kZFeZz3CHrC52RujcS3lLX0uLzeHlPv3gZq', '超级管理员', 'admin');
