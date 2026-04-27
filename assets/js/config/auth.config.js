// 登录认证配置，目前用于保存 Google OAuth 客户端参数。
window.AUTH_CONFIG = {
  // 后端 PHP 服务地址，auth.js 会把 Google credential POST 到这里。
  apiBaseUrl: 'http://localhost:8000',
  // 没有 redirect 参数时，登录成功默认进入控制台。
  loginSuccessPage: 'console.html',
  google: {
    // Google Cloud 创建的 OAuth Web Client ID，前端初始化 Google 按钮必须使用。
    clientId: '203242566561-jp41htf16rca7cr5l5kusio7tubdoton.apps.googleusercontent.com',
    // 后端 Google 登录 API 路径，后端会验证 ID Token 后返回本地登录信息。
    loginPath: '/auth/google',
    // Google Cloud 控制台里配置的本地开发来源，方便对照排查授权来源错误。
    authorizedOrigins: [
      'http://127.0.0.1:8887',
      'http://localhost:8887'
    ]
  }
};
