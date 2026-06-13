// 登录认证配置，用于邮箱登录注册、邮箱验证码登录、找回密码和 Google OAuth 登录。
window.AUTH_CONFIG = {
  apiBaseUrl: '',

  loginSuccessPage: 'console.jsp',
  email: {
    codePath: '/auth_code.php',
    registerPath: '/auth_register.php',
    loginPath: '/auth_login.php',
    codeLoginPath: '/auth_login_code.php',
    resetPath: '/auth_reset.php',
  },
  purchasesPath: '/purchases.php',
  google: {
    clientId: '203242566561-jp41htf16rca7cr5l5kusio7tubdoton.apps.googleusercontent.com',

    loginPath: '/google_login.php',

    authorizedOrigins: [
      'http://127.0.0.1:8887',
      'http://localhost:8887',
      'http://localhost:8080',
      'http://127.0.0.1:8080',
      'https://fucheni66.github.io',
      'https://ajou.userapi.cn'
    ]
  }
};
