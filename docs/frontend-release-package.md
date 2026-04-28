# 前端源码发布包说明

## 文件命名

前端源码发布包建议命名为：

```text
cloud-service-storefront-frontend-v1.0.0.zip
```

命名包含项目名、模块名和版本号，方便在 GitHub Releases 中区分前端包和后端包。

## 包含内容

- 根目录前端 HTML 页面
- `assets/` 静态资源目录
- `templates/` 公共头部和底部模板
- `README.md` 项目说明
- `.nojekyll` GitHub Pages 配置文件

## 不包含内容

- `backend/` 后端代码目录
- `reports/` 报告目录
- `releases/` 本地发布包目录
- 旧的 zip 文件和本地打包目录
- `.DS_Store` 系统隐藏文件

## 使用说明

下载并解压前端源码包后，可以直接通过静态服务器访问页面。

如果需要访问支付、登录、购买记录等功能，需要同时配置后端接口地址。
