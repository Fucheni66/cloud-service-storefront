// 支付接口配置。
window.PAYMENT_API_CONFIG = {
  baseUrl: 'http://localhost:8000',
  createPayment: '/alipay/create',
  queryPayment: '/alipay/query',
  createQrCode: '/qrcode',
  successPage: 'payment-success.html',
};
