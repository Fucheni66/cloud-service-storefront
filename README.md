# 云服务商算力前端演示

项目主要使用 HTML、CSS 和 JavaScript 编写，页面风格参考云服务厂商的产品购买、控制台和登录流程。

## 内容


- `index.html`：首页，展示平台介绍、搜索栏、热门产品和系统架构说明。
- `products.html`：产品购买页，使用 jQuery 根据配置动态渲染 CPU/GPU 云服务器列表。
- `purchase.html`：自定义配置购买页，支持实例、地域、系统盘、计费模式和购买时长选择。
- `console.html`：控制台页面，展示用户已购买的云服务。
- `console-manage.html`：云服务管理页面。
- `auth.html`：登录 / 注册页面，已经接入 Google 登录按钮。
- `developer-community.html`：开发者社区页面。
- `product-dynamics.html`：产品动态页面。
- `payment-success.html`：支付成功展示页面。

## 技术栈


- HTML
- CSS
- JavaScript
- jQuery
- Tailwind CDN
- Font Awesome
- Google Identity Services
- localStorage

## 目录结构

```text
.
├── *.html
├── assets
│   ├── css
│   │   └── styles.css
│   └── js
│       ├── app.js
│       ├── auth.js
│       ├── console.js
│       ├── console-manage.js
│       ├── home.js
│       ├── nav-auth.js
│       ├── products.js
│       ├── require-auth.js
│       └── config
│           ├── auth.config.js
│           ├── console.config.js
│           ├── payment.config.js
│           ├── products.config.js
│           └── purchase.config.js
└── README.md
```

## 页面数据配置

产品、购买参数、控制台数据和认证  `assets/js/config/` 目录。

例如：

- `products.config.js`：产品列表页的分类和产品卡片数据。
- `purchase.config.js`：购买配置页的默认值、价格、折扣和展示名称。
- `console.config.js`：控制台默认云服务数据。
- `auth.config.js`：Google 登录前端配置和后端 API 地址。
- `payment.config.js`：支付接口地址配置。

## Google 登录流程

前端接入了 Google Identity Services。

前端流程是：

```text
用户点击 Google 登录
        ↓
Google 返回 credential / ID Token
        ↓
auth.js 把 credential POST 到后端 /auth/google
        ↓
后端验证成功后返回 user + token
        ↓
前端保存到 localStorage
        ↓
跳转到 console.html
        ↓
nav-auth.js 显示头像和 name
        ↓
require-auth.js 保护控制台页面
```

浏览器本地会保存：

```text
ajou_login_info
ajou_auth_user
ajou_auth_token
```

## 本地运行

直接用静态服务器运行前端。

```bash
cd /Users/apple/Sites/localhost/ajou_server
python3 -m http.server 8887
```

然后访问：

```text
http://127.0.0.1:8887/index.html
```

如果要测试 Google 登录的完整流程，还需要单独启动后端服务：

```bash
cd /Users/apple/Sites/localhost/ajou_server/backend/public
php -S localhost:8000
```


