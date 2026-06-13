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
