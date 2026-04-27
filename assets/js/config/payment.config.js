// 支付接口配置。
window.PAYMENT_API_CONFIG = {
  // 后端 PHP 服务地址，服务器已把 API 作为运行目录，不需要再拼接 /api。
  baseUrl: 'http://ajou.userapi.cn/',
  createPayment: '/alipay/create',
  queryPayment: '/alipay/query',
  createQrCode: '/qrcode',
  purchases: '/purchases',
  successPage: 'payment-success.html',
};
