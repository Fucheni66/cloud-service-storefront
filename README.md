# AJOU 管理后台（JSP / Servlet / JDBC + MySQL）

AJOU 云服务商城的 Java 后端，前台（storefront）与后台（admin）一体，采用 JSP / Servlet / JDBC + MySQL。后台用于管理用户、订单、产品、产品动态与社区问答，并提供首页配置、AI 导购、邮箱验证码、支付宝当面付等功能。

## 技术栈

- Java 17（编译目标），Maven 打 WAR
- Jakarta EE 11：Servlet 6.1 / JSP 4.0 / JSTL 3.0
- Tomcat 11.0.5
- MySQL（MAMP，端口 8889）+ JDBC（Connector/J 9.3）
- BCrypt 密码哈希（jBCrypt）
- 架构：MVC（Servlet 控制器 + JSP 视图 + JavaBean + JDBC DAO）

## 目录结构

```
src/main/
├─ java/com/ajou/
│  ├─ common/            DbUtil(JDBC) / PasswordUtil(BCrypt) / CharsetFilter(UTF-8)
│  └─ admin/             model · dao · web(Servlet) · filter(鉴权)
├─ resources/db.properties     JDBC 连接配置
└─ webapp/
   ├─ index.jsp          前台占位首页
   └─ WEB-INF/
      ├─ web.xml
      ├─ sql/schema.sql   建库建表脚本
      └─ views/admin/     login / register / dashboard + fragments
```

## 数据库连接

`src/main/resources/db.properties`：

```
jdbc:mysql://127.0.0.1:8889/ajou_admin?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai&characterEncoding=UTF-8
用户名 / 密码：本地 MAMP 自行设置；部署到生产时改为真实账号密码，切勿提交真实密码到仓库
```

## 构建与运行

```bash
# 1) 建库建表（确保 MAMP MySQL 已启动；必须加 --default-character-set=utf8mb4 否则种子中文乱码）
#    -u/-p 换成你本地数据库的账号密码
/Applications/MAMP/Library/bin/mysql --default-character-set=utf8mb4 -u你的账号 -p -P8889 -h127.0.0.1 \
  < src/main/webapp/WEB-INF/sql/schema.sql

# 2) 打包
mvn clean package

# 3) 部署到 Tomcat 11（重新部署前先删旧解压目录）
rm -rf /opt/homebrew/Cellar/tomcat/11.0.5/libexec/webapps/ajou-admin
cp target/ajou-admin.war /opt/homebrew/Cellar/tomcat/11.0.5/libexec/webapps/

# 4) 启动 / 停止
catalina start      # 日志：.../libexec/logs/catalina.out
catalina stop
```

## 访问地址

| 页面 | URL |
|---|---|
| 前台首页 | http://localhost:8080/ajou-admin/ |
| 前台产品页 | http://localhost:8080/ajou-admin/products.jsp |
| 管理员登录 | http://localhost:8080/ajou-admin/admin/login |
| 后台仪表盘 | http://localhost:8080/ajou-admin/admin/dashboard（需登录） |

## 路由

| URL | 方法 | 说明 |
|---|---|---|
| `/admin/login` | GET/POST | 登录（校验+写 session+更新 last_login）→ 跳仪表盘。**管理员注册入口已移除**，账号由 DB 维护 |
| `/admin/dashboard` | GET | 统计概览：用户数/本月营收/运行中实例/即将到期（全真实） |
| `/admin/products` | GET/POST | 云产品规格(SKU) CRUD + 上下架 |
| `/admin/users` | GET/POST | 用户管理：列表/筛选/搜索/详情(含该用户购买列表+批量删除)/启用禁用/删除 |
| `/admin/instances` | GET/POST | 云实例管理：列表(按型号/状态/用户筛选)/详情/续费/释放 |
| `/admin/orders` | GET/POST | 订单管理：列表/筛选/详情/标记开通/删除 |
| `/admin/settings` | GET/POST | 系统设置：Google/支付宝/微信/站点/AI 大模型/**SMTP 邮件** 配置（敏感项不回显）；SMTP 分组支持发送测试邮件 |
| `/admin/dynamics` | GET/POST | 产品动态 CMS：列表(分类/关键词筛选+分页)/发布/编辑/删除/上下线 |
| `/admin/dynamic-categories` | GET/POST | 动态分类：自定义增删改/配色/启停（精选教程为 tutorial 分类） |
| `/admin/home` | GET/POST | 首页配置：产品动态展示(分类+指定文章) + 热门产品权重批量调整 |
| `/admin/home-recommends` | GET/POST | 首页推荐：三标签(通用服务器/业务部署/GPU算力)卡片增删改/排序/启停 |
| `/admin/community` | GET/POST | 社区问答：列表/审核(发布·关闭)/编辑/删除 + 回复管理 |
| `/admin/logout` | GET | 退出 |
| `/api/products` | GET | 前台产品 JSON API（在售规格，公开访问） |
| `/api/dynamics` | GET | 产品动态：列表(+分类清单) / `?category=` 按分类 / `?slug=` 单篇详情 |
| `/api/home` | GET | 首页数据：热门产品(按权重) + 推荐卡片(三标签) + 一条产品动态 |
| `/api/site` | GET | 站点信息：名称 / 联系电话 / 联系邮箱 / 备案号 / 技术支持时效（页脚 + 社区技术支持卡片读取） |
| `/api/ai/chat` | POST | AI 导购对话代理：后端携密钥调 DeepSeek（OpenAI 兼容），注入在售产品目录，返回回复 + 选购指令 action |
| `/api/community/questions` | GET | 社区问答列表（仅已发布） |
| `/api/community/question?slug=` | GET | 问答详情 + 回复 |
| `/api/community/publish` | POST | 前台发表问答（落 pending 待审核） |
| `/api/community/reply` | POST | 前台发表回复（直接发布） |
| `/`、`/products.jsp` | GET | 前台首页、产品页（JSP 骨架；首页调 /api/home，产品页调 /api/products 渲染） |
| `*-dynamics*.jsp`、`developer-community*.jsp`、`community-*.jsp` | GET | 前台 JSP 骨架 + 调 /api/dynamics、/api/community/* 渲染 |

### 前台 API（兼容原 PHP 路径，前台 JS 零改动，仅 config baseUrl 改本地）

| URL | 方法 | 说明 |
|---|---|---|
| `/auth_code.php` | POST | 发送邮箱验证码（**真实 SMTP 发送**，`scene` 区分 register/login/reset，60s 限频，不再明文返回 code） |
| `/auth_register.php` | POST | 邮箱注册（校验 register 验证码）→ 落 users(provider=email) + 签发 token |
| `/auth_login.php` | POST | 邮箱密码登录 → 校验 BCrypt + 签发 token |
| `/auth_login_code.php` | POST | 邮箱验证码登录（校验 login 验证码）→ 签发 token |
| `/auth_reset.php` | POST | 忘记密码：校验 reset 验证码 → 重置 BCrypt 密码 |
| `/google_login.php` | POST | Google 登录（解析 ID Token，落/匹配 provider=google 或已绑定 google_sub 的邮箱用户） |
| `/api/profile` | GET | 个人中心：当前用户信息（Bearer token） |
| `/api/profile/password` | POST | 个人中心：修改/设置密码（Bearer token） |
| `/api/profile/google/bind`、`/unbind` | POST | 个人中心-关联登录：绑定/解绑 Google（Bearer token） |
| `/api/system-monitor` | GET | 本机真实系统监控 CPU/内存/磁盘/带宽（跨 mac/linux，Bearer token），控制台监控概览数据源 |
| `/purchases.php` | GET | 我的服务/实例（Bearer token，按用户返回 cloud_orders；后台删除后实时不再返回） |
| `/purchases.php` | POST | 支付成功写订单（Bearer token）→ cloud_orders |
| `/alipay_create.php` | POST | 支付宝当面付下单（纯 Java `AlipayClient` + JDK RSA2 签名调真实 alipay.trade.precreate，返回被扫 qr_code，未配置则报错） |
| `/alipay_query.php` | GET | 查询支付状态（真实 alipay.trade.query，仅 TRADE_SUCCESS/TRADE_FINISHED 才 paid=true） |
| `/qrcode.php` | GET | 二维码图片（ZXing 把 qr_code 链接编码成**真实可扫** PNG，支付宝 App 可识别） |

> 登录态：token 存 `auth_tokens` 表，前台经 `Authorization: Bearer <token>` 调用受保护接口。前台用户与订单与后台管理**共享同一数据库**（后台用户管理/订单管理可见前台产生的数据）。

> 受 `AdminAuthFilter` 保护：除 login/logout 外，所有 `/admin/*` 均需登录。

> SMTP 邮件：配置存 `app_configs` 的 `smtp.*` 分组（见 `sql/2026-smtp-and-auth.sql`）。授权码（`smtp.password`，敏感项）不写入 SQL 种子，部署后在「后台 > 系统设置 > SMTP 邮件」填写。

> 支付宝当面付：商户参数存 `app_configs` 的 `alipay.*` 分组。商户私钥/支付宝公钥（敏感项）不写入 SQL 种子，部署后在「后台 > 系统设置 > 支付宝当面付」填写 App ID 与商户私钥（PKCS8 Base64，单行无 PEM 头）。当面付全部由 v2 Java 实现（`AlipayClient` + ZXing），不依赖任何 PHP。

## 前端样式（Tailwind 预编译）

前台/后台样式为**预编译静态 CSS** `assets/css/tailwind.css`（约 50KB，浏览器缓存、无运行时编译），不再使用 Tailwind Play CDN 的运行时 JIT。

- 前台：`vendor/tailwindcss-cdn.js` 为轻量加载器（注入静态 CSS），页面 HTML 无需改动。
- 后台：`fragments/head.jspf` 直接 `<link>` 该静态 CSS。

> 该文件为预先生成的静态产物；如需调整样式，可自行用 Tailwind CLI 扫描 `.jsp/.jspf/.js/templates` 重新构建后覆盖此文件。

## 数据表

| 表 | 说明 |
|---|---|
| `admins` | 后台管理员 |
| `product_specs` | 云产品规格(SKU)，含 5 个种子；`home_weight` 驱动首页热门产品 |
| `users` | 顾客端用户（合并邮箱/Google，provider 区分） |
| `cloud_orders` | 云实例订单（订单视角 + 云实例视角共用） |
| `app_configs` | 系统配置 key-value（google/alipay/wechat/site） |
| `auth_tokens` | 前台登录令牌（token → user） |
| `email_codes` | 邮箱验证码 |
| `dynamic_posts` | 产品动态文章（CMS），含 10 个种子 + 3 篇 tutorial 教程 |
| `dynamic_categories` | 产品动态分类（可自定义增删改/配色），含 7 个种子 |
| `home_recommends` | 首页热门产品推荐卡片（三标签可管理），含 9 个种子 |
| `community_questions` | 开发者社区问答，含 2 个种子 |
| `community_replies` | 社区问答回复，含 3 个种子 |

> 首页产品动态展示配置存 `app_configs` 的 `home` 分组（`home.dynamic_category` / `home.dynamic_slug`），由后台「首页配置」维护。

> 前台公共页脚（`layout.js`）联系电话/邮箱、开发者社区「技术支持」卡片（在线工单/实例故障/社区回复时效）均读取 `/api/site`，对应 `app_configs` 的 `site.contact_phone` / `site.contact_email` / `site.support_*`，由后台「系统设置·站点」维护。

> 内容运营增量脚本：`WEB-INF/sql/2026-content-community.sql`（动态/问答/回复）+ `2026-dynamic-categories.sql`（分类表 + 精选教程并入产品动态、删除旧 tutorials 表）+ `2026-home-settings.sql`（product_specs.home_weight + home_recommends 表 + 首页动态配置）+ `2026-site-contact.sql`（站点联系电话/邮箱）+ `2026-community-support.sql`（社区技术支持时效）+ `2026-ai-guide.sql`（AI 大模型配置 ai 分组）+ `2026-solution-community-data.sql`（扩充解决方案文章 + 社区问答含官方回复，为 AI 问题解决检索打底）。均与 `schema.sql` 同步，可重复执行。

> **支付宝当面付（真实对接）**：`AlipayClient`（JDK 自带 RSA2 签名，无需 SDK）调 `alipay.trade.precreate` 下单、`alipay.trade.query` 查状态，商户参数取自 `app_configs` 的 `alipay` 分组（后台「系统设置·支付宝当面付」填 App ID / 商户私钥 / 网关 / 签名算法）。**只有支付宝返回 TRADE_SUCCESS 才判定已付并跳转**，未配置或未付一律 `paid=false`，不会再出现「没支付就跳转」。
> - 上线前置：① 后台填真实支付宝商户参数；② `/qrcode.php` 当前是伪二维码（不可扫），需替换为真实 QR（引入 zxing 或前端 QR 库对 precreate 返回的 qr_code 编码）。

> **AI 自动导购 + 问题解决**：前台全站悬浮球（`assets/js/ai-guide.js`），对话经 `/api/ai/chat` 后端代理调 DeepSeek（密钥存 `app_configs` 的 `ai.api_key`，is_secret 不回显、不入代码库）。
> - 选购：模型按协议输出 `<<ACTION>>` 选购指令，前端用「假鼠标」跨页自动完成 导航→逐项选配置→点「立即购买」弹出支付弹窗（不自动支付）；会话与执行计划存 sessionStorage，刷新自动续跑（无 iframe）。
> - 问题解决：后端把「解决方案文章 + 社区问答(含官方回复)」注入提示词作知识库，模型匹配后输出 `<<LINK>>` 指令（type=solution/question + slug），前端在该条回复下渲染「查看解决方案 / 查看官方回复」按钮，点击跳转到 `product-dynamics-detail.jsp?id=` 或 `community-question-detail.jsp?question=` 对应页面。
>
> **精选教程不再是独立体系**：内容即产品动态中 `tutorial` 分类的文章，在「产品动态」后台统一维护，前台社区页右侧读取 `/api/dynamics?category=tutorial`。
