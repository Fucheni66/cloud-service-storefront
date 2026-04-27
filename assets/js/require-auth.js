// 控制台访问保护：未登录时跳转到登录页，并携带登录成功后的返回地址。
(function () {
  // 控制台页面在渲染前先检查登录态，避免未登录用户看到控制台内容。
  if (hasLoginInfo()) {
    return;
  }

  const currentPage = getCurrentPage();
  // 带上 redirect，登录成功后 auth.js 会跳回当前控制台页面。
  window.location.replace('auth.html?redirect=' + encodeURIComponent(currentPage));

  function hasLoginInfo() {
    // 必须同时有用户信息和后端 token，才认为是有效登录态。
    const directUser = readJson('ajou_auth_user');
    const loginInfo = readJson('ajou_login_info');
    const token = localStorage.getItem('ajou_auth_token') || (loginInfo && loginInfo.token);
    const user = directUser || (loginInfo && loginInfo.user);

    return Boolean(token && user && (user.name || user.email));
  }

  function readJson(key) {
    try {
      return JSON.parse(localStorage.getItem(key) || 'null');
    } catch (error) {
      return null;
    }
  }

  function getCurrentPage() {
    const page = window.location.pathname.split('/').pop() || 'console.html';
    return page + window.location.search + window.location.hash;
  }
})();
