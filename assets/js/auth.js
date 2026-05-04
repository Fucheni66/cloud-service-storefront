// 登录页认证逻辑：邮箱登录注册、Google 登录、统一保存浏览器登录态。
(function () {
  const config = window.AUTH_CONFIG;

  const storageKeys = {
    loginInfo: 'ajou_login_info',
    authUser: 'ajou_auth_user',
    authToken: 'ajou_auth_token',
  };

  if (!config) {
    return;
  }

  window.addEventListener('load', function () {
    bindEmailAuth();

    if (config.google) {
      waitForGoogleSdk(0);
    }
  });

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

    google.accounts.id.initialize({
      client_id: config.google.clientId,
      callback: handleGoogleCredential,
    });

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

  async function handleGoogleCredential(response) {
    if (!response || !response.credential) {
      showAuthMessage('没有获取到 Google 登录凭证。', 'error');
      return;
    }

    showAuthMessage('正在验证 Google 登录信息...', 'info');

    try {
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

  function saveLoginInfo(data) {
    localStorage.setItem(storageKeys.loginInfo, JSON.stringify(data));

    if (data.user) {
      localStorage.setItem(storageKeys.authUser, JSON.stringify(data.user));
    }

    if (data.token) {
      localStorage.setItem(storageKeys.authToken, data.token);
    }
  }

  function redirectAfterLogin() {
    window.setTimeout(function () {
      window.location.href =
        getLoginRedirectUrl() || config.loginSuccessPage || 'console.html';
    }, 500);
  }

  function getLoginRedirectUrl() {
    const redirect = new URLSearchParams(window.location.search).get(
      'redirect',
    );
    const lowerRedirect = (redirect || '').toLowerCase();

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
