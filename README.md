# 云服务商算力前端演示

项目主要使用 HTML、CSS 和 JavaScript 编写，页面风格参考云服务厂商的产品购买、控制台和登录流程。

## 项目内容

静态页面拆分为多个独立页面，页面数据和交互逻辑拆分到 JS 配置和脚本文件中，方便后续维护。

当前前端包含这些页面：

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

前端主要使用：

- HTML
- CSS
- JavaScript
- jQuery
- Tailwind CSS 本地脚本
- Font Awesome
- Google Identity Services
- localStorage

## 目录结构

```text
.
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
│   │   └── styles.css                 # 全站公共样式和组件样式
│   └── js                             # JavaScript 脚本目录
│       ├── app.js                     # 购买配置页逻辑，包含价格计算、支付弹窗和支付轮询
│       ├── auth.js                    # 登录注册逻辑，处理邮箱登录注册和 Google 登录回调
│       ├── console.js                 # 控制台列表渲染逻辑，读取并展示用户购买内容
│       ├── console-manage.js          # 云服务管理页渲染逻辑
│       ├── home.js                    # 首页热门产品渲染逻辑
│       ├── layout.js                  # 使用 jQuery 加载公共头部和底部模板
│       ├── nav-auth.js                # 导航栏登录态渲染和退出登录逻辑
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
├── templates                          # 公共 HTML 模板目录
│   ├── header.html                    # 公共页面头部导航模板
│   └── footer.html                    # 公共页面底部信息模板
├── reports                            # 项目报告和说明页面目录
│   └── web_frontend_midterm_report.html # 前端项目报告页面
└── README.md                          # 项目说明文档
```

## 页面数据配置

页面上的产品、购买参数、控制台数据和认证参数统一放在 `assets/js/config/` 目录。

例如：

- `products.config.js`：产品列表页的分类和产品卡片数据。
- `purchase.config.js`：购买配置页的默认值、价格、折扣和展示名称。
- `console.config.js`：控制台默认云服务数据。
- `auth.config.js`：Google 登录前端配置和后端 API 地址。
- `payment.config.js`：支付接口地址配置。

## Google 登录流程

前端已接入 Google Identity Services。

前端流程是：

```text
用户点击 Google 登录
        ↓
Google 返回 credential / ID Token
        ↓
auth.js 把 credential POST 到后端 google_login.php
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
