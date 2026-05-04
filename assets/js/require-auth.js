// 控制台访问保护：未登录时跳转到登录页，并携带登录成功后的返回地址。
(function () {
  if (hasLoginInfo()) {
    return;
  }

  const currentPage = getCurrentPage();

  window.location.replace('auth.html?redirect=' + encodeURIComponent(currentPage));

  function hasLoginInfo() {
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
