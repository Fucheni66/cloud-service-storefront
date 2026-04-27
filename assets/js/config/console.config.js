// 控制台页面配置。
// 真实购买成功的数据由后端 /purchases 按登录用户返回。
window.CONSOLE_PAGE_CONFIG = {
  // 后端 PHP 服务地址，服务器已把 API 作为运行目录，不需要再拼接 /api。
  apiBaseUrl: 'http://ajou.userapi.cn/',
  purchasesPath: '/purchases',
  services: []
};
