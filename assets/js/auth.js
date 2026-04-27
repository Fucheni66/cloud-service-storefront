// 登录页 Google 登录对接逻辑：获取 Google credential，调用后端 API，并写入浏览器 localStorage。
(function () {
  // ----------- 基础配置 ----------------
  const config = window.AUTH_CONFIG;

  // 这三个 key 是前端登录态的统一存储位置，导航栏和控制台保护都会读取。
  const storageKeys = {
    loginInfo: "ajou_login_info",
    authUser: "ajou_auth_user",
    authToken: "ajou_auth_token",
  };

  if (!config || !config.google) {
    return;
  }

  // ----------- 页面启动入口 ----------------
  window.addEventListener("load", function () {
    // Google SDK 是异步加载的，页面 load 后仍可能还没挂载到 window.google。
    waitForGoogleSdk(0);
  });

  // ----------- 等待并初始化 Google SDK ----------------
  function waitForGoogleSdk(attempt) {
    if (!window.google || !google.accounts || !google.accounts.id) {
      if (attempt < 20) {
        window.setTimeout(function () {
          waitForGoogleSdk(attempt + 1);
        }, 200);
        return;
      }

      showAuthMessage("Google 登录组件加载失败，请检查网络。", "error");
      return;
    }

    // 初始化 Google Identity Services，登录成功后 Google 会回调 handleGoogleCredential。
    google.accounts.id.initialize({
      client_id: config.google.clientId,
      callback: handleGoogleCredential,
    });

    // 把 Google 官方登录按钮渲染到 auth.html 的 #google-login-button 容器里。
    google.accounts.id.renderButton(
      document.getElementById("google-login-button"),
      {
        theme: "outline",
        size: "large",
        width: 380,
        text: "signin_with",
        locale: "zh_CN",
      },
    );
  }

  // ----------- 接收 Google 授权结果 ----------------
  function handleGoogleCredential(response) {
    // response.credential 是 Google 返回的 ID Token，不能只在前端信任，必须交给后端验证。
    if (!response || !response.credential) {
      showAuthMessage("没有获取到 Google 登录凭证。", "error");
      return;
    }

    showAuthMessage("正在验证 Google 登录信息...", "info");

    // ----------- 提交后端验证 ----------------
    // 把 Google ID Token 提交给 PHP 后端，由后端校验 aud/iss/exp/email/sub。
    fetch(config.apiBaseUrl + config.google.loginPath, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        credential: response.credential,
      }),
    })
      .then(function (res) {
        return res.json().then(function (data) {
          if (!res.ok) {
            throw new Error(data.message || data.error || "Google 登录失败");
          }

          return data;
        });
      })
      .then(function (data) {
        // 后端返回本地 user + token 后，前端保存登录态供导航栏和控制台保护读取。
        saveLoginInfo(data);
        showAuthMessage("Google 登录成功，正在进入控制台。", "success");

        window.setTimeout(function () {
          //自动跳转
          window.location.href =
            getLoginRedirectUrl() || config.loginSuccessPage || "console.html";
        }, 500);
      })
      .catch(function (error) {
        showAuthMessage(
          error.message || "Google 登录失败，请稍后重试。",
          "error",
        );
      });
  }

  // ----------- 保存浏览器登录态 ----------------
  function saveLoginInfo(data) {
    // 保存完整返回值，便于调试和后续扩展。
    localStorage.setItem(storageKeys.loginInfo, JSON.stringify(data));

    if (data.user) {
      // 保存纯用户信息，nav-auth.js 用它显示头像和 name。
      localStorage.setItem(storageKeys.authUser, JSON.stringify(data.user));
    }

    if (data.token) {
      // 保存后端生成的本地 token，require-auth.js 用它判断是否已登录。
      localStorage.setItem(storageKeys.authToken, data.token);
    }
  }

  // ----------- 登录成功后跳转地址 ----------------
  function getLoginRedirectUrl() {
    // 用户从控制台被拦截到登录页时，redirect 用来登录后回到原页面。
    const redirect = new URLSearchParams(window.location.search).get(
      "redirect",
    );
    const lowerRedirect = (redirect || "").toLowerCase();

    // 禁止跳转到外部 URL，避免登录后被重定向到第三方地址。
    if (
      !redirect ||
      lowerRedirect.startsWith("http://") ||
      lowerRedirect.startsWith("https://") ||
      redirect.startsWith("//")
    ) {
      return "";
    }

    return redirect;
  }

  // ----------- 页面提示信息 ----------------
  function showAuthMessage(text, type) {
    const message = document.getElementById("auth-message");

    if (!message) {
      return;
    }

    message.textContent = text;
    message.className =
      "mb-4 rounded border px-3 py-2 text-sm " +
      (type === "success"
        ? "bg-green-50 border-green-100 text-green-700"
        : type === "error"
          ? "bg-red-50 border-red-100 text-red-700"
          : "bg-blue-50 border-blue-100 text-primary");
  }
})();
