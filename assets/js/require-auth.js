// 控制台访问保护：未登录时跳转到登录页，并携带登录成功后的返回地址。
(function () {
  // 这个脚本放在需要登录的页面头部，页面主体渲染前就先做权限判断。

  // 控制台页面在渲染前先检查登录态，避免未登录用户看到控制台内容。
  if (hasLoginInfo()) {
    return;
  }

  // 未登录时记录当前页面地址，登录成功后可以跳回原页面。
  const currentPage = getCurrentPage();
  // 带上 redirect，登录成功后 auth.js 会跳回当前控制台页面。
  window.location.replace('auth.html?redirect=' + encodeURIComponent(currentPage));

  function hasLoginInfo() {
    // 必须同时有用户信息和后端 token，才认为是有效登录态。
    // ajou_auth_user 是精简用户信息，ajou_login_info 是完整登录返回结果。
    const directUser = readJson('ajou_auth_user');
    const loginInfo = readJson('ajou_login_info');
    // token 可能单独存储，也可能保存在完整登录信息中。
    const token = localStorage.getItem('ajou_auth_token') || (loginInfo && loginInfo.token);
    const user = directUser || (loginInfo && loginInfo.user);

    // 有 token，且用户信息里至少有 name 或 email，才允许继续访问页面。
    return Boolean(token && user && (user.name || user.email));
  }

  function readJson(key) {
    // localStorage 内容可能被手动修改，解析失败时按未登录处理。
    try {
      return JSON.parse(localStorage.getItem(key) || 'null');
    } catch (error) {
      return null;
    }
  }

  function getCurrentPage() {
    // 保留当前页面的 query 和 hash，保证登录后能回到同一个管理资源或购买页面。
    const page = window.location.pathname.split('/').pop() || 'console.html';
    return page + window.location.search + window.location.hash;
  }
})();
