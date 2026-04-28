# 《Web 前端开发》期中项目汇报报告

项目名称：云服务商算力前端演示平台  
项目类型：云服务 / 服务器租赁类平台网站  
技术栈：HTML + CSS + JavaScript + jQuery + Tailwind CSS 本地脚本  
部署方式：GitHub Pages 前端托管  
小组成员：董衍波、施博格、蒋宝锐、张壹政  
托管网址：[https://fucheni66.github.io/cloud-service-storefront/](https://fucheni66.github.io/cloud-service-storefront/)  
GitHub：[https://github.com/Fucheni66/cloud-service-storefront](https://github.com/Fucheni66/cloud-service-storefront)

## 目录

1. [一、项目整体介绍](#section-1)
2. [二、项目页面结构](#section-2)
3. [三、核心功能与技术点](#section-3)
4. [四、登录方案说明](#section-4)
5. [五、支付方案说明](#section-5)
6. [六、网页设计说明](#section-6)
7. [七、网站托管与运行方式](#section-7)
8. [八、创新点说明](#section-8)
9. [九、前端交互功能清单](#section-9)
10. [十、汇报提纲](#section-10)
11. [十一、汇报说明](#section-11)

---

<a id="section-1"></a>

## 一、项目整体介绍

本项目是一个面向云服务器购买与管理场景的平台类网站，整体参考云服务厂商的产品购买流程进行设计。网站围绕“浏览云服务产品、选择实例配置、完成支付、查看已购资源、管理云服务”这一主线展开。

项目主要由以下几个方面组成：

1. 首页展示模块：展示平台定位、搜索栏、热门产品、系统架构与核心特性。
2. 产品列表模块：展示 CPU 云服务器和 GPU 云服务器，支持通过配置文件动态渲染产品数据。
3. 自定义购买模块：支持用户选择实例规格、地域、操作系统、系统盘、计费方式和购买时长。
4. 支付与订单模块：用户确认配置后生成订单，调用后端支付接口生成支付宝二维码。
5. 登录认证模块：支持邮箱登录注册和 Google 登录，并将登录状态保存到浏览器本地。
6. 控制台模块：登录后展示用户已购买的云服务，并提供云服务管理页面。
7. 社区与产品动态模块：提供产品动态、API 文档、帮助支持、社区问答和发帖页面。

项目不是单一静态页面，而是一个多页面、有流程、有状态、有数据交互的平台型网站。

---

<a id="section-2"></a>

## 二、项目页面结构

本项目包含 4 个以上页面，实际包含 12 个主要页面。

| 页面 | 文件 | 作用 |
|---|---|---|
| 首页 | `index.html` | 展示平台介绍、搜索栏、热门产品和系统架构 |
| 产品列表页 | `products.html` | 展示 CPU / GPU 云服务器列表 |
| 购买配置页 | `purchase.html` | 选择服务器配置、计算费用、生成支付二维码 |
| 登录注册页 | `auth.html` | 邮箱登录注册、Google 登录 |
| 控制台页 | `console.html` | 展示用户已购买的云服务 |
| 云服务管理页 | `console-manage.html` | 展示单个云服务的监控、网络、账单和操作信息 |
| 产品动态页 | `product-dynamics.html` | 展示产品发布、价格、维护、解决方案等栏目 |
| 产品动态详情页 | `product-dynamics-detail.html` | 根据参数展示不同动态详情 |
| 开发者社区页 | `developer-community.html` | 展示社区问题、文档入口和支持入口 |
| 社区问题详情页 | `community-question-detail.html` | 展示问答详情并支持评论 |
| 发帖页 | `community-publish.html` | 发布问题或经验分享 |
| 支付成功页 | `payment-success.html` | 支付成功后展示订单结果并引导进入控制台 |

页面之间形成完整流程：

```text
首页 -> 产品列表 -> 购买配置 -> 支付确认 -> 支付成功 -> 控制台 -> 云服务管理
```

登录保护流程：

```text
访问控制台 -> 判断是否登录 -> 未登录跳转 auth.html -> 登录成功返回控制台
```

### 项目目录结构

前端项目目录结构如下，只列出前端页面、静态资源、公共模板和项目说明文件，不包含后端目录和报告目录。

```text
.
├── .gitignore                         # Git 忽略配置，排除后端目录、临时文件等不需要提交的内容
├── .nojekyll                          # GitHub Pages 配置文件，避免静态资源被 Jekyll 处理
├── README.md                          # 项目说明文档
├── index.html                         # 首页，展示搜索栏、热门产品和平台介绍
├── products.html                      # 产品购买列表页，展示云服务器和 GPU 实例
├── purchase.html                      # 自定义配置购买页，选择规格、地域、系统盘和计费方式
├── console.html                       # 用户控制台页面，展示已购买云服务列表
├── console-manage.html                # 云服务管理页面，展示监控、网络、费用和操作入口
├── auth.html                          # 登录 / 注册页面，支持邮箱登录注册和 Google 登录
├── developer-community.html           # 开发者社区首页，展示教程、问答和发布入口
├── community-publish.html             # 社区发表页面，用于发布内容
├── community-question-detail.html     # 社区问答详情页面，展示问题和评论区回复
├── product-dynamics.html              # 产品动态页面，包含新品、价格、维护、解决方案等分类
├── product-dynamics-detail.html       # 产品动态详情页，按参数展示不同文章内容
├── payment-success.html               # 支付成功页面，提示资源分配中或分配完成
├── assets                             # 前端静态资源目录
│   ├── css                            # 样式文件目录
│   │   └── styles.css                 # 全站公共样式、头部占位高度、公共导航和组件样式
│   └── js                             # JavaScript 脚本目录
│       ├── app.js                     # 购买配置页逻辑，包含价格计算、支付弹窗和支付轮询
│       ├── auth.js                    # 登录注册逻辑，处理邮箱登录注册和 Google 登录回调
│       ├── console.js                 # 控制台列表渲染逻辑，读取并展示用户购买内容
│       ├── console-manage.js          # 云服务管理页渲染逻辑
│       ├── home.js                    # 首页热门产品渲染逻辑
│       ├── layout.js                  # 使用 jQuery 加载公共头部和底部 HTML 模板
│       ├── nav-auth.js                # 使用 jQuery 渲染导航栏登录态和退出登录逻辑
│       ├── products.js                # 产品列表页渲染和分类切换逻辑
│       ├── require-auth.js            # 页面登录保护逻辑，未登录时跳转登录页
│       ├── tailwind-config.js         # Tailwind 本地脚本主题配置
│       ├── vendor                     # 前端第三方本地脚本目录
│       │   ├── jquery-3.7.1.min.js    # 本地化后的 jQuery 脚本
│       │   └── tailwindcss-cdn.js     # 本地化后的 Tailwind CSS 运行脚本
│       └── config                     # 页面配置文件目录
│           ├── auth.config.js         # 登录接口和 Google 登录参数配置
│           ├── console.config.js      # 控制台接口和默认配置
│           ├── payment.config.js      # 支付、二维码和购买记录接口配置
│           ├── products.config.js     # 产品列表和商品卡片配置
│           └── purchase.config.js     # 购买页规格、价格、折扣和展示名称配置
└── templates                          # 公共 HTML 模板目录
│   ├── header.html                    # 公共页面头部导航模板
│   └── footer.html                    # 公共页面底部信息模板
```

### 主要文件信息

| 文件 | 类型 | 说明 |
|---|---|---|
| `templates/header.html` | HTML 模板 | 公共头部导航栏，包含 Logo、产品购买、解决方案、开发者社区、产品动态、控制台和登录入口 |
| `templates/footer.html` | HTML 模板 | 公共底部区域，包含关于我们、产品服务、帮助支持和联系方式 |
| `assets/js/layout.js` | JavaScript | 使用 jQuery `.load()` 把 `header.html` 和 `footer.html` 加载到每个页面的占位容器中 |
| `assets/js/nav-auth.js` | JavaScript | 读取 `localStorage` 登录态，登录后把“登录 / 注册”替换成头像和用户菜单 |
| `assets/css/styles.css` | CSS | 存放全站公共样式，并为 `#site-header` 预设 64px 高度，减少公共头部加载闪动 |
| `assets/js/vendor/jquery-3.7.1.min.js` | 本地第三方脚本 | 本地化后的 jQuery，用于页面渲染和公共模板加载 |
| `assets/js/vendor/tailwindcss-cdn.js` | 本地第三方脚本 | 本地化后的 Tailwind CSS 运行脚本，避免页面直接请求 Tailwind CDN |
| `assets/js/config/*.js` | 配置文件 | 存放产品数据、购买价格、支付接口、登录接口和控制台接口配置 |

---

<a id="section-3"></a>

## 三、核心功能与技术点

### 1. 本地存储 localStorage

项目使用浏览器 `localStorage` 保存登录状态和购买记录。

主要保存内容包括：

```text
ajou_login_info      登录接口返回的完整信息
ajou_auth_user       当前用户信息
ajou_auth_token      后端生成的登录 token
ajou_purchased_services  本地购买记录缓存
```

本地存储的作用：

1. 登录后导航栏可以显示用户头像和 name。
2. 控制台页面可以判断用户是否已经登录。
3. 支付成功后可以先保存购买记录，即使后端同步失败，也能保留本地记录。
4. 页面刷新后仍能恢复用户状态。

### 2. 前后端交互

项目虽然前端以 HTML、CSS、JS 为主，但也实现了和后端接口的交互。

前端通过 `fetch` 请求后端 PHP 接口。`POST` 请求主要使用 JSON 请求体提交参数，`GET` 请求主要通过 URL 查询参数传递参数。用户购买记录接口还会在请求头中携带 `Authorization: Bearer token`，用于识别当前登录用户。

| 接口 | 请求方式 | 请求参数 | 作用 |
|---|---|---|---|
| <small>`https://ajou.userapi.cn/google_login.php`</small> | `POST` | `credential`：Google 返回的 ID Token | Google 登录验证，后端校验 token 后返回 `user` 和 `token` |
| <small>`https://ajou.userapi.cn/auth_code.php`</small> | `POST` | `email`：注册邮箱 | 获取邮箱验证码 |
| <small>`https://ajou.userapi.cn/auth_register.php`</small> | `POST` | `email`：邮箱<br>`password`：密码<br>`code`：验证码 | 邮箱注册，注册成功后返回登录态 |
| <small>`https://ajou.userapi.cn/auth_login.php`</small> | `POST` | `email`：邮箱<br>`password`：密码 | 邮箱登录，登录成功后返回 `user` 和 `token` |
| <small>`https://ajou.userapi.cn/alipay_create.php`</small> | `POST` | `order_id`：订单号<br>`amount`：支付金额<br>`subject`：订单标题 | 创建支付宝支付订单并返回二维码链接 |
| <small>`https://ajou.userapi.cn/alipay_query.php`</small> | `GET` | `order_id`：订单号 | 查询订单支付状态，前端根据返回结果判断是否支付成功 |
| <small>`https://ajou.userapi.cn/qrcode.php`</small> | `GET` | `url`：需要生成二维码的链接<br>`size`：二维码尺寸 | 根据支付链接生成二维码图片 |
| <small>`https://ajou.userapi.cn/purchases.php`</small> | `POST` | 请求头：`Authorization: Bearer token`<br>请求体：`order_id`<br>`amount`<br>`subject`<br>`service` | 支付成功后保存当前用户购买的商品和实例配置 |
| <small>`https://ajou.userapi.cn/purchases.php`</small> | `GET` | 请求头：`Authorization: Bearer token` | 返回当前登录用户已购买的云服务列表，供控制台页面渲染 |

例如创建支付订单时，前端使用 `POST` 请求：

```json
{
  "order_id": "pay_2c4g_1777309206155",
  "amount": "0.11",
  "subject": "Server 2C 4G"
}
```

查询支付状态时，前端使用 `GET` 请求：

```text
https://ajou.userapi.cn/alipay_query.php?order_id=pay_2c4g_1777309206155
```

### 3. 配置化数据管理

项目将页面数据拆分到 `assets/js/config/` 目录中，避免把所有数据都写死在 HTML 页面里。

主要配置文件：

| 文件 | 作用 |
|---|---|
| `products.config.js` | 产品列表页的 CPU / GPU 分类和产品数据 |
| `purchase.config.js` | 购买页默认状态、价格、折扣和展示名称 |
| `payment.config.js` | 支付接口地址配置 |
| `auth.config.js` | 登录接口和 Google Client ID 配置 |
| `console.config.js` | 控制台接口配置 |

这样做的好处是：如果后期要新增服务器规格、修改价格、调整接口地址，不需要大面积修改 HTML，只需要调整配置文件。

### 4. 公共页面模板实现逻辑

为了减少每个 HTML 页面中重复书写头部和底部代码，项目将公共头部和底部拆分成独立 HTML 模板：

```text
templates/header.html
templates/footer.html
```

每个页面的主体中只保留两个占位容器：

```html
<div id="site-header"></div>

页面主体内容

<div id="site-footer"></div>
```

每个页面头部统一引入本地 jQuery 和公共布局脚本：

```html
<script src="assets/js/vendor/jquery-3.7.1.min.js?v=20260428-1"></script>
<script src="assets/js/layout.js?v=20260428-1"></script>
```

`layout.js` 的核心逻辑是使用 jQuery 的 `.load()` 方法加载模板：

```js
$('#site-header').load('templates/header.html', function () {
  setActiveNav();

  if (window.renderAuthNav) {
    window.renderAuthNav();
  }
});

$('#site-footer').load('templates/footer.html');
```

实现流程如下：

```text
页面加载
        ↓
layout.js 找到 #site-header 和 #site-footer
        ↓
使用 jQuery load() 加载 header.html 和 footer.html
        ↓
头部加载完成后执行 setActiveNav()
        ↓
根据当前页面地址高亮导航栏
        ↓
如果用户已登录，再调用 window.renderAuthNav()
        ↓
nav-auth.js 把“登录 / 注册”替换成用户头像和下拉菜单
```

为了避免公共头部异步加载时页面高度突然变化，`styles.css` 对头部占位容器提前设置了和导航栏一致的高度：

```css
#site-header {
  height: 64px;
  min-height: 64px;
}
```

同时，公共头部模板使用 `.site-main-nav`、`.site-nav-inner`、`.site-nav-link` 等普通 CSS 类控制布局，不再依赖 Tailwind 动态生成导航布局样式，这样可以减少头部加载时的闪动。

这个实现没有使用额外插件，只使用了本地 jQuery 和普通 HTML 模板，逻辑比较简单，后期修改导航或底部时只需要修改模板文件。

### 5. 产品动态页面的数据存放和渲染方式

产品动态页面没有再单独增加 JS 配置文件，数据直接存放在对应页面的 HTML DOM 结构中，再通过页面底部的 JavaScript 根据 URL 参数控制显示和隐藏。

#### 产品动态列表页：`product-dynamics.html#price`

列表页地址示例：

```text
https://fucheni66.github.io/cloud-service-storefront/product-dynamics.html#price
```

其中 `#price` 是浏览器 URL 的 Hash 值，用来表示当前要显示“价格调整”分类。页面左侧分类和右侧文章卡片通过 `data-dynamics-tab`、`data-dynamics-panel` 关联。

数据存放位置：

```html
<a href="product-dynamics.html#price" data-dynamics-tab="price">价格调整</a>

<article data-dynamics-panel="price">
  <h2>通用型 CPU 实例按月价格优化</h2>
  <p>2C4G、4C8G 和 8C16G 实例完成价格配置更新...</p>
  <a href="product-dynamics-detail.html?id=price-cpu">查看详情</a>
</article>
```

渲染逻辑：

```text
读取 window.location.hash
        ↓
得到 price
        ↓
查找 data-dynamics-panel="price" 的文章卡片
        ↓
显示价格调整内容，隐藏其它分类内容
        ↓
同步高亮 data-dynamics-tab="price" 的左侧分类
```

也就是说，`#price` 本身不是接口参数，而是前端页面内部的分类状态。页面数据就写在 `product-dynamics.html` 的对应 `article` 标签中，JS 只负责根据 Hash 控制 DOM 显示隐藏。

#### 产品动态详情页：`product-dynamics-detail.html?id=price-cpu`

详情页地址示例：

```text
https://fucheni66.github.io/cloud-service-storefront/product-dynamics-detail.html?id=price-cpu
```

其中 `id=price-cpu` 是 URL 查询参数，用来表示当前要显示哪一篇详情文章。详情页的每篇文章数据存放在 `product-dynamics-detail.html` 的 `data-dynamics-detail` 节点中。

数据存放位置：

```html
<article data-dynamics-detail="price-cpu">
  <h2>通用型 CPU 实例按月价格优化</h2>
  <p>通用型 CPU 实例完成价格配置更新...</p>
</article>
```

渲染逻辑：

```text
读取 URLSearchParams(window.location.search)
        ↓
得到 id=price-cpu
        ↓
查找 data-dynamics-detail="price-cpu" 的详情文章
        ↓
显示对应详情，隐藏其它详情
        ↓
如果没有匹配到 id，则默认显示第一篇详情
```

因此，`?id=price-cpu` 控制详情页显示哪一篇文章，文章内容本身存放在 `product-dynamics-detail.html` 内部，不需要请求后端接口。

---

<a id="section-4"></a>

## 四、登录方案说明

本项目登录采用两种方式：

### 1. 邮箱登录 / 注册

用户可以通过邮箱注册账号，注册时需要获取验证码。验证码接口由后端提供，前端负责表单输入、按钮状态、验证码倒计时和登录状态保存。

流程如下：

```text
填写邮箱和密码
        ↓
获取验证码
        ↓
提交注册
        ↓
后端返回 user + token
        ↓
前端保存到 localStorage
        ↓
跳转控制台
```

### 2. Google 登录

Google 登录采用 Google Identity Services。前端点击 Google 登录按钮后，Google 返回 `credential / ID Token`，前端把这个 token 提交给后端验证。

流程如下：

```text
用户点击 Google 登录
        ↓
Google 返回 credential / ID Token
        ↓
前端 auth.js POST 到 google_login.php
        ↓
后端验证 Google ID Token
        ↓
验证成功后返回 user + token
        ↓
前端保存到 localStorage
        ↓
跳转 console.html
        ↓
导航栏显示头像和 name
```

Google 登录的特点：

1. 前端不直接信任 Google 返回信息。
2. 后端会验证 ID Token 的合法性。
3. 登录后导航栏会自动替换“登录 / 注册”为用户头像和姓名。
4. 用户点击头像后可以展开下拉菜单，查看主页或退出登录。

### 3. 前端权限判断和页面跳转

项目中的权限判断主要在前端完成，用于保护控制台、云服务管理页和购买页等需要登录后访问的页面。相关逻辑集中在 `assets/js/require-auth.js`、`assets/js/auth.js` 和 `assets/js/nav-auth.js`。

#### 登录态保存

用户邮箱登录、注册或 Google 登录成功后，后端会返回 `user` 和 `token`。前端会把这些信息保存到浏览器 `localStorage`：

```text
ajou_login_info      保存完整登录返回值
ajou_auth_user       保存当前用户信息
ajou_auth_token      保存后端返回的登录 token
```

#### 权限判断条件

需要登录保护的页面会先加载 `require-auth.js`。该脚本会读取本地登录态，并判断是否同时满足以下条件：

```text
存在 token
        ↓
存在 user 信息
        ↓
user 中有 name 或 email
        ↓
允许继续访问当前页面
```

如果不满足条件，就认为用户未登录。

#### 未登录跳转逻辑

未登录时，`require-auth.js` 会获取当前页面地址，并跳转到登录页：

```text
当前页面：console.html?id=xxx
        ↓
拼接 redirect 参数
        ↓
跳转到 auth.html?redirect=console.html%3Fid%3Dxxx
```

这样可以记录用户原本要访问的页面。

#### 登录成功后的返回逻辑

登录成功后，`auth.js` 会读取 URL 中的 `redirect` 参数：

```text
读取 redirect
        ↓
判断 redirect 是否安全
        ↓
如果不是 http://、https:// 或 // 开头
        ↓
跳回 redirect 指定页面
        ↓
如果没有 redirect，则默认进入 console.html
```

这里做了外部链接拦截，避免登录后被跳转到第三方网站。

#### 导航栏权限状态

`nav-auth.js` 会读取 `ajou_auth_user` 或 `ajou_login_info.user`。如果存在用户信息，就把导航栏中的“登录 / 注册”按钮替换成用户头像和姓名下拉菜单。

退出登录时，前端会清理本地登录态：

```text
remove ajou_login_info
remove ajou_auth_user
remove ajou_auth_token
        ↓
跳转回 index.html
```

整体流程如下：

```text
用户访问受保护页面
        ↓
require-auth.js 检查 localStorage
        ↓
未登录：跳转 auth.html?redirect=原页面
        ↓
用户登录成功
        ↓
auth.js 保存 user + token
        ↓
读取 redirect 并跳回原页面
        ↓
nav-auth.js 更新导航栏用户状态
```

---

<a id="section-5"></a>

## 五、支付方案说明

期中项目的支付采用支付宝当面付二维码支付流程。

前端点击“立即购买”后，会将订单号、金额和商品名称提交到后端接口：

```text
POST https://ajou.userapi.cn/alipay_create.php
```

请求示例：

```json
{
  "order_id": "pay_2c4g_1777309206155",
  "amount": "0.11",
  "subject": "Server 2C 4G"
}
```

后端返回支付宝二维码地址后，前端再通过二维码接口生成二维码图片。

支付流程如下：

```text
选择服务器配置
        ↓
实时计算价格
        ↓
点击立即购买
        ↓
创建订单
        ↓
后端生成支付宝二维码
        ↓
前端展示二维码
        ↓
轮询查询支付状态
        ↓
支付成功后写入购买记录
        ↓
跳转支付成功页 / 控制台
```

这个设计让购买流程更接近真实云平台，而不是简单的静态按钮跳转。

---

<a id="section-6"></a>

## 六、网页设计说明

### 1. 整体风格

网站整体采用科技风、云服务平台风格，主色调为蓝色，搭配白色背景、浅灰模块和橙色价格强调色。

主要视觉特点：

1. 蓝色科技风主色。
2. 大面积留白提升平台感。
3. 卡片式产品展示。
4. 渐变标题和动态背景光晕。
5. 悬浮阴影和 hover 反馈增强交互感。

### 2. 首页设计

首页使用动态光晕背景和渐变文字突出 AI 云平台定位。顶部搜索栏模拟真实云平台搜索体验，下面展示热门产品和系统架构说明。

首页设计重点：

1. Hero 区域突出平台定位。
2. 动态背景增强科技感。
3. 搜索栏和热搜产品提高真实平台体验。
4. 热门产品卡片让用户快速进入购买流程。
5. 系统架构模块体现项目的学习和技术说明性质。

### 3. 购买页设计

购买页采用云服务厂商常见的配置表单布局，左侧是配置项，右侧是可选参数。底部固定结算栏实时显示配置摘要和价格。

购买页设计重点：

1. 配置项分区清晰。
2. 被选中项有蓝色边框和角标反馈。
3. 磁盘容量支持滑块和输入框双向联动。
4. 底部固定结算栏方便用户随时确认价格。
5. 弹窗中展示订单信息和支付二维码。

### 4. 控制台设计

控制台用于展示用户已购买的云服务。每个云服务以卡片方式展示规格、地域、系统盘、公网地址、到期时间等信息。

云服务管理页进一步展示：

1. 监控概览。
2. 网络与连接信息。
3. 操作日志。
4. 启动、停止、重启、重装系统等操作按钮。
5. 账单信息和支持入口。

---

<a id="section-7"></a>

## 七、网站托管与运行方式

前端代码托管在 GitHub 仓库，并通过 GitHub Pages 发布。

前端访问地址：

```text
https://fucheni66.github.io/cloud-service-storefront/
```

后端接口部署在独立服务器域名：

```text
https://ajou.userapi.cn/
```

整体部署结构：

```text
GitHub Pages：托管 HTML / CSS / JS 静态页面
独立服务器：运行 PHP 后端接口
浏览器：通过 fetch 请求后端接口
```

这种方式把前端展示和后端接口分开，符合前后端分离的基本思想。

---

<a id="section-8"></a>

## 八、创新点说明

### 创新点一：科技风动态首页视觉设计

首页不是普通静态介绍页，而是使用了动态光晕背景、渐变文字、悬浮卡片和云服务平台风格的搜索栏。

具体体现：

1. 使用 CSS `@keyframes` 实现背景光晕缓慢移动。
2. 标题使用蓝色到紫色的渐变文字，强化 AI 云平台感觉。
3. 产品卡片采用悬浮阴影和 hover 反馈。
4. 首页结构模拟真实云平台首页，包含搜索、热搜、热门产品和系统架构。

### 创新点二：云服务器动态配置与价格联动

购买页不是固定价格展示，而是根据用户选择动态计算价格。

联动内容包括：

1. 实例规格影响基础价格。
2. 系统盘类型和容量影响磁盘价格。
3. 包年包月和按量计费采用不同计算方式。
4. 购买时长影响折扣。
5. 修改任意配置后，底部价格和配置摘要实时更新。

这使页面具备较强的真实业务交互感。

### 创新点三：配置化产品渲染和购买流程联动

产品列表页通过 `products.config.js` 配置 CPU / GPU 产品数据，再由 jQuery 动态渲染页面。

优点：

1. 产品数据和页面结构分离。
2. 新增产品时不需要直接修改 HTML。
3. 产品卡片点击后会把实例参数带到购买页。
4. 购买页根据 URL 参数自动选中对应实例。

这个设计让“产品列表 -> 购买配置”之间形成了明确的数据关联。

### 创新点四：登录状态驱动的导航栏和控制台保护

登录后，导航栏会自动从“登录 / 注册”切换为用户头像和 name，并支持下拉菜单。

控制台页面也会检查登录状态，未登录会自动跳转到登录页，并携带 `redirect` 参数，登录成功后回到原页面。

这让网站具备更完整的平台账号体系体验。

---

<a id="section-9"></a>

## 九、前端交互功能清单

以下列出项目中的主要前端交互：

1. 首页搜索表单跳转到产品页。
2. 首页热搜产品点击跳转。
3. 产品列表页通过 jQuery 动态渲染 CPU / GPU 产品卡片。
4. 产品卡片点击“立即配置”跳转购买页，并携带实例参数。
5. 购买页根据 URL 参数自动选中实例。
6. CPU / GPU 实例分类 Tab 切换。
7. 配置选项点击后切换选中状态。
8. 计费模式切换后显示或隐藏购买时长。
9. 磁盘容量滑块和数字输入框双向联动。
10. 实例、磁盘、计费方式和时长变化后实时计算价格。
11. 底部固定结算栏实时显示配置摘要。
12. 点击“立即购买”弹出订单支付弹窗。
13. 支付弹窗可关闭。
14. 后端生成支付宝二维码并在页面展示。
15. 前端轮询查询支付状态。
16. 支付成功后保存购买记录到本地存储。
17. 控制台动态渲染已购买服务列表。
18. 云服务管理页根据订单 ID 渲染详情。
19. 邮箱登录表单提交和错误提示。
20. 邮箱注册验证码倒计时。
21. Google 登录按钮渲染和授权回调。
22. 登录状态保存到 localStorage。
23. 导航栏登录后显示头像和 name。
24. 用户头像下拉菜单支持查看主页和退出登录。
25. 控制台未登录自动跳转登录页。
26. 产品动态页支持 Hash Tab 切换。
27. 产品动态详情页根据 URL 参数展示不同内容。
28. 社区评论表单提交后动态插入评论。
29. 发帖页面提交后显示成功提示并平滑滚动到顶部。
30. 多页面之间通过 `a href` 形成完整业务流程跳转。

---

<a id="section-10"></a>

## 十、汇报提纲

1. 项目背景：说明云服务器购买平台的业务场景和项目目标。
2. 页面结构：展示首页、产品列表页、购买页、控制台、产品动态和社区页面。
3. 数据配置：说明产品数据、接口地址、购买配置存放在 `assets/js/config` 目录中。
4. 核心交互：展示实例选择、价格计算、支付弹窗、二维码生成和状态查询流程。
5. 登录权限：说明登录状态保存、未登录跳转和控制台访问控制。
6. 公共模板：说明头部和底部通过 `templates` 目录与 `layout.js` 统一引入。
7. 项目总结：说明多页面流程、前后端交互和项目维护结构。

---

<a id="section-11"></a>

## 十一、汇报说明

我们小组本次期中项目的主题是“云服务商算力前端演示平台”。这个项目属于平台类网站，主要模拟云服务器租赁和购买流程。

我们的项目整体由首页、产品列表页、购买配置页、登录注册页、控制台页、云服务管理页、产品动态页和社区页面组成。用户可以从首页进入产品列表，选择 CPU 或 GPU 云服务器，然后进入购买页配置实例规格、地域、系统盘、操作系统和计费方式。确认配置后，系统会实时计算价格，并生成订单支付二维码。支付完成后，用户可以进入控制台查看自己购买的云服务。

在技术实现上，项目全部使用 HTML、CSS 和 JavaScript 完成，部分页面使用 jQuery 进行动态渲染。我们将产品数据、购买参数、接口地址等内容拆分到了 `assets/js/config` 目录中，避免所有数据写死在 HTML 页面里，提升了代码结构清晰度和后续维护性。

项目的一个核心点是本地存储。登录成功后，前端会把用户信息和 token 保存到 localStorage 中。导航栏会根据本地登录状态显示用户头像和姓名，控制台页面也会根据登录状态判断是否允许访问。如果用户没有登录，会自动跳转到登录页面。

另一个核心点是前后端交互。前端通过 fetch 请求后端 PHP 接口，实现 Google 登录验证、邮箱登录注册、支付宝支付二维码生成、支付状态查询和购买记录保存。前端托管在 GitHub Pages，后端接口部署在独立服务器域名上，实现了前后端分离。

本项目的支付采用支付宝当面付二维码支付。用户点击立即购买后，前端会把订单号、金额和商品名称发送给后端，后端生成支付宝二维码地址，前端再展示二维码，并定时查询支付状态。这个流程让项目更接近真实云平台的购买体验。

登录方面，我们实现了邮箱登录注册和 Google 登录。Google 登录使用 Google Identity Services，前端获取 credential 后提交给后端验证，验证成功后保存用户信息，并在导航栏展示头像和 name。

网页设计方面，我们采用科技风云平台设计。首页使用动态光晕背景、渐变标题、搜索栏、热门产品卡片和系统架构模块。购买页采用真实云服务厂商常见的配置面板布局，底部固定结算栏实时展示费用，整体风格统一。

本项目的创新点主要有两个。第一是科技风动态首页视觉设计，通过动态光晕、渐变文字和悬浮卡片提升页面视觉效果。第二是云服务器动态配置与价格联动，用户每修改一个配置项，价格和摘要都会实时变化。此外，我们还实现了配置化产品渲染和登录状态驱动导航，这些都增强了平台类网站的完整性。

在交互功能方面，项目实现了搜索跳转、产品动态渲染、实例参数跳转、CPU/GPU Tab 切换、配置选中、磁盘滑块联动、价格实时计算、订单弹窗、二维码生成、支付状态轮询、登录注册、验证码倒计时、Google 登录、头像下拉菜单、控制台登录保护、评论动态插入等功能。

最后，项目代码结构清晰，页面数量超过 4 个，多页面之间形成了完整的浏览、选择、购买、支付和管理流程。以上就是我们小组项目的主要内容，谢谢大家。
