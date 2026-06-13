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
