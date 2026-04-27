// 登录页认证逻辑：邮箱登录注册、Google 登录、统一保存浏览器登录态。
(function () {
  // ----------- 基础配置 ----------------
  const config = window.AUTH_CONFIG;

  // 这三个 key 是前端登录态的统一存储位置，导航栏和控制台保护都会读取。
  const storageKeys = {
    loginInfo: 'ajou_login_info',
    authUser: 'ajou_auth_user',
    authToken: 'ajou_auth_token',
  };

  if (!config) {
    return;
  }

  // ----------- 页面启动入口 ----------------
  window.addEventListener('load', function () {
    bindEmailAuth();

    if (config.google) {
      // Google SDK 是异步加载的，页面 load 后仍可能还没挂载到 window.google。
      waitForGoogleSdk(0);
    }
  });

  // ----------- 邮箱登录注册 ----------------
  function bindEmailAuth() {
    const loginForm = document.getElementById('login-form');
    const registerForm = document.getElementById('register-form');
    const sendCodeButton = document.getElementById('send-code-button');

    if (loginForm) {
      loginForm.addEventListener('submit', handleEmailLogin);
    }

    if (registerForm) {
      registerForm.addEventListener('submit', handleEmailRegister);
    }

    if (sendCodeButton) {
      sendCodeButton.addEventListener('click', handleSendCode);
    }
  }

  /**
   * 邮箱登录表单提交。
   */
  async function handleEmailLogin(event) {
    event.preventDefault();

    const form = event.currentTarget;
    const submitButton = form.querySelector('button[type="submit"]');
    setButtonLoading(submitButton, true, '登录中...');
    showAuthMessage('正在登录...', 'info');

    try {
      const data = await postAuthJson(config.email.loginPath, {
        email: getInputValue('login-email'),
        password: getInputValue('login-password'),
      });

      saveLoginInfo(data);
      showAuthMessage('登录成功，正在进入控制台。', 'success');
      redirectAfterLogin();
    } catch (error) {
      showAuthMessage(error.message || '登录失败，请检查邮箱和密码。', 'error');
    } finally {
      setButtonLoading(submitButton, false, '登录');
    }
  }

  /**
   * 获取邮箱验证码。
   */
  async function handleSendCode() {
    const button = document.getElementById('send-code-button');
    const email = getInputValue('register-email');

    if (!email) {
      showAuthMessage('请先填写邮箱。', 'error');
      return;
    }

    setButtonLoading(button, true, '发送中...');

    try {
      const data = await postAuthJson(config.email.codePath, { email });
      const codeInput = document.getElementById('register-code');

      if (codeInput && data.code) {
        codeInput.value = data.code;
      }

      showAuthMessage(`验证码已发送，演示验证码：${data.code || ''}`, 'success');
      startCodeCountdown(button);
    } catch (error) {
      setButtonLoading(button, false, '获取验证码');
      showAuthMessage(error.message || '验证码发送失败。', 'error');
    }
  }

  /**
   * 邮箱注册表单提交。
   */
  async function handleEmailRegister(event) {
    event.preventDefault();

    const form = event.currentTarget;
    const submitButton = form.querySelector('button[type="submit"]');
    setButtonLoading(submitButton, true, '注册中...');
    showAuthMessage('正在注册...', 'info');

    try {
      const data = await postAuthJson(config.email.registerPath, {
        email: getInputValue('register-email'),
        password: getInputValue('register-password'),
        code: getInputValue('register-code'),
      });

      saveLoginInfo(data);
      showAuthMessage('注册成功，正在进入控制台。', 'success');
      redirectAfterLogin();
    } catch (error) {
      showAuthMessage(error.message || '注册失败，请检查填写内容。', 'error');
    } finally {
      setButtonLoading(submitButton, false, '注册');
    }
  }

  // ----------- 等待并初始化 Google SDK ----------------
  function waitForGoogleSdk(attempt) {
    if (!window.google || !google.accounts || !google.accounts.id) {
      if (attempt < 20) {
        window.setTimeout(function () {
          waitForGoogleSdk(attempt + 1);
        }, 200);
        return;
      }

      showAuthMessage('Google 登录组件加载失败，请检查网络。', 'error');
      return;
    }

    // 初始化 Google Identity Services，登录成功后 Google 会回调 handleGoogleCredential。
    google.accounts.id.initialize({
      client_id: config.google.clientId,
      callback: handleGoogleCredential,
    });

    // 把 Google 官方登录按钮渲染到 auth.html 的 #google-login-button 容器里。
    google.accounts.id.renderButton(
      document.getElementById('google-login-button'),
      {
        theme: 'outline',
        size: 'large',
        width: 380,
        text: 'signin_with',
        locale: 'zh_CN',
      },
    );
  }

  // ----------- 接收 Google 授权结果 ----------------
  async function handleGoogleCredential(response) {
    // response.credential 是 Google 返回的 ID Token，不能只在前端信任，必须交给后端验证。
    if (!response || !response.credential) {
      showAuthMessage('没有获取到 Google 登录凭证。', 'error');
      return;
    }

    showAuthMessage('正在验证 Google 登录信息...', 'info');

    try {
      // 把 Google ID Token 提交给 PHP 后端，由后端校验 aud/iss/exp/email/sub。
      const data = await postAuthJson(config.google.loginPath, {
        credential: response.credential,
      });

      saveLoginInfo(data);
      showAuthMessage('Google 登录成功，正在进入控制台。', 'success');
      redirectAfterLogin();
    } catch (error) {
      showAuthMessage(error.message || 'Google 登录失败，请稍后重试。', 'error');
    }
  }

  // ----------- 请求后端认证接口 ----------------
  async function postAuthJson(path, payload) {
    const response = await fetch(buildApiUrl(path), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });
    const data = await response.json();

    if (!response.ok || !data.success) {
      throw new Error(data.message || data.error || '请求失败');
    }

    return data;
  }

  function buildApiUrl(path) {
    const baseUrl = (config.apiBaseUrl || '').replace(/\/+$/, '');
    return `${baseUrl}${path || ''}`;
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
  function redirectAfterLogin() {
    window.setTimeout(function () {
      // 自动跳转
      window.location.href =
        getLoginRedirectUrl() || config.loginSuccessPage || 'console.html';
    }, 500);
  }

  function getLoginRedirectUrl() {
    // 用户从控制台被拦截到登录页时，redirect 用来登录后回到原页面。
    const redirect = new URLSearchParams(window.location.search).get(
      'redirect',
    );
    const lowerRedirect = (redirect || '').toLowerCase();

    // 禁止跳转到外部 URL，避免登录后被重定向到第三方地址。
    if (
      !redirect ||
      lowerRedirect.startsWith('http://') ||
      lowerRedirect.startsWith('https://') ||
      redirect.startsWith('//')
    ) {
      return '';
    }

    return redirect;
  }

  // ----------- 页面提示信息 ----------------
  function showAuthMessage(text, type) {
    const message = document.getElementById('auth-message');

    if (!message) {
      return;
    }

    message.textContent = text;
    message.className =
      'mb-4 rounded border px-3 py-2 text-sm ' +
      (type === 'success'
        ? 'bg-green-50 border-green-100 text-green-700'
        : type === 'error'
          ? 'bg-red-50 border-red-100 text-red-700'
          : 'bg-blue-50 border-blue-100 text-primary');
  }

  function setButtonLoading(button, isLoading, text) {
    if (!button) {
      return;
    }

    button.disabled = isLoading;
    button.textContent = text;
    button.classList.toggle('opacity-70', isLoading);
    button.classList.toggle('cursor-not-allowed', isLoading);
  }

  function startCodeCountdown(button) {
    let seconds = 60;
    button.disabled = true;
    button.classList.add('text-gray-400', 'cursor-not-allowed');
    button.textContent = `${seconds}s`;

    const timer = window.setInterval(function () {
      seconds -= 1;
      button.textContent = `${seconds}s`;

      if (seconds <= 0) {
        window.clearInterval(timer);
        button.disabled = false;
        button.textContent = '获取验证码';
        button.classList.remove('text-gray-400', 'cursor-not-allowed', 'opacity-70');
      }
    }, 1000);
  }

  function getInputValue(id) {
    const input = document.getElementById(id);
    return input ? input.value.trim() : '';
  }
})();
