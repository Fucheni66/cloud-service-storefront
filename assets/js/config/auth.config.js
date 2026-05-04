// 登录认证配置，用于邮箱登录注册和 Google OAuth 登录。
window.AUTH_CONFIG = {
  apiBaseUrl: 'https://ajou.userapi.cn/',

  loginSuccessPage: 'console.html',
  email: {
    codePath: '/auth_code.php',
    registerPath: '/auth_register.php',
    loginPath: '/auth_login.php',
  },
  purchasesPath: '/purchases.php',
  google: {
    clientId: '203242566561-jp41htf16rca7cr5l5kusio7tubdoton.apps.googleusercontent.com',

    loginPath: '/google_login.php',

    authorizedOrigins: [
      'http://127.0.0.1:8887',
      'http://localhost:8887',
      'https://fucheni66.github.io',
      'https://ajou.userapi.cn'
    ]
  }
};
