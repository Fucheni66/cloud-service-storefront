// 支付接口配置。
window.PAYMENT_API_CONFIG = {
  // 后端 PHP 服务地址，服务器已把 api 目录作为运行目录，接口直接访问 .php 文件。
  baseUrl: 'https://ajou.userapi.cn/',
  createPayment: '/alipay_create.php',
  queryPayment: '/alipay_query.php',
  createQrCode: '/qrcode.php',
  purchases: '/purchases.php',
  successPage: 'payment-success.html',
};
