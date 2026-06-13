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
