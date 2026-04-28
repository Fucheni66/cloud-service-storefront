# 后端源码发布包说明

## 文件命名

后端源码发布包建议命名为：

```text
ajou-server-backend-v1.0.0.zip
```

命名包含后端项目名和版本号，适合作为 GitHub Releases 的附件文件。

## 包含内容

- `backend/api/` 接口文件
- `backend/classes/` 后端业务类文件
- `backend/public/` 入口文件
- `backend/extend/` 第三方 SDK 和扩展类库
- `backend/html/` 后端接口调用 demo
- `backend/config/app.example.php` 示例配置文件

## 不包含内容

- `backend/config/app.php` 真实配置文件
- `backend/data/*.json` 本地运行数据
- 支付宝 SDK 日志文件
- `.DS_Store` 系统隐藏文件

## 配置说明

后端包只提供 `app.example.php` 示例配置。

部署时需要复制为：

```text
backend/config/app.php
```

然后填写自己的 Google 登录配置和支付宝当面付配置。

真实配置文件不要上传到公开仓库，也不要放进 GitHub Releases 附件。
