// 个人中心：修改密码 + 关联登录（绑定/解绑 Google）。
(function () {
  const authConfig = window.AUTH_CONFIG || {};
  const apiBase = (authConfig.apiBaseUrl || '').replace(/\/+$/, '');

  const endpoints = {
    profile: '/api/profile',
    password: '/api/profile/password',
    bindGoogle: '/api/profile/google/bind',
    unbindGoogle: '/api/profile/google/unbind',
  };

  let state = { hasPassword: false, googleBound: false };

  window.addEventListener('load', function () {
    if (!getAuthToken()) {
      return;
    }
    loadProfile();
    bindPasswordForm();
    bindUnbind();
  });

  async function loadProfile() {
    try {
      const data = await apiFetch(endpoints.profile, { method: 'GET' });
      applyProfile(data.user || {});
    } catch (error) {
      showMessage(error.message || '读取个人信息失败', 'error');
    }
  }

  function applyProfile(user) {
    state.hasPassword = Boolean(user.hasPassword);
    state.googleBound = Boolean(user.googleBound);

    setText('pf-email', user.email || '—');
    setText('pf-provider', user.provider === 'google' ? 'Google 登录' : '邮箱注册');

    // 原密码框：从未设置密码（如纯 Google 用户）时隐藏，并提示这是「设置密码」
    const oldWrap = document.getElementById('old-password-wrap');
    const hint = document.getElementById('pf-password-hint');
    if (state.hasPassword) {
      oldWrap.classList.remove('hidden');
      hint.textContent = '修改后请使用新密码登录。';
    } else {
      oldWrap.classList.add('hidden');
      hint.textContent = '你还未设置登录密码，设置后即可使用邮箱 + 密码登录。';
    }

    renderGoogleSection();
  }

  function renderGoogleSection() {
    const status = document.getElementById('pf-google-status');
    const bindBtn = document.getElementById('pf-google-bind-button');
    const unbindBtn = document.getElementById('pf-google-unbind');

    if (state.googleBound) {
      status.textContent = '已绑定 · 可使用 Google 快速登录';
      status.className = 'text-xs text-green-600 mt-0.5';
      bindBtn.classList.add('hidden');
      unbindBtn.classList.remove('hidden');
    } else {
      status.textContent = '未绑定';
      status.className = 'text-xs text-gray-500 mt-0.5';
      unbindBtn.classList.add('hidden');
      bindBtn.classList.remove('hidden');
      renderGoogleButton();
    }
  }

  function renderGoogleButton() {
    const clientId = authConfig.google && authConfig.google.clientId;
    const container = document.getElementById('pf-google-bind-button');
    if (!clientId || !container) {
      return;
    }
    container.innerHTML = '';
    waitForGoogle(0, function () {
      google.accounts.id.initialize({
        client_id: clientId,
        callback: handleBindCredential,
      });
      google.accounts.id.renderButton(container, {
        theme: 'outline',
        size: 'large',
        text: 'continue_with',
        locale: 'zh_CN',
      });
    });
  }

  function waitForGoogle(attempt, ready) {
    if (window.google && google.accounts && google.accounts.id) {
      ready();
      return;
    }
    if (attempt < 25) {
      window.setTimeout(function () {
        waitForGoogle(attempt + 1, ready);
      }, 200);
    }
  }

  async function handleBindCredential(response) {
    if (!response || !response.credential) {
      showMessage('没有获取到 Google 凭证', 'error');
      return;
    }
    try {
      const data = await apiFetch(endpoints.bindGoogle, {
        method: 'POST',
        body: { credential: response.credential },
      });
      showMessage(data.message || '已绑定 Google', 'success');
      applyProfile(data.user || {});
    } catch (error) {
      showMessage(error.message || '绑定失败', 'error');
    }
  }

  function bindUnbind() {
    const btn = document.getElementById('pf-google-unbind');
    if (!btn) {
      return;
    }
    btn.addEventListener('click', async function () {
      if (!window.confirm('确定解除 Google 绑定？')) {
        return;
      }
      try {
        const data = await apiFetch(endpoints.unbindGoogle, { method: 'POST', body: {} });
        showMessage(data.message || '已解绑', 'success');
        applyProfile(data.user || {});
      } catch (error) {
        showMessage(error.message || '解绑失败', 'error');
      }
    });
  }

  function bindPasswordForm() {
    const form = document.getElementById('password-form');
    if (!form) {
      return;
    }
    form.addEventListener('submit', async function (event) {
      event.preventDefault();
      const oldPassword = value('pf-old-password');
      const newPassword = value('pf-new-password');
      const confirmPassword = value('pf-confirm-password');

      if (newPassword.length < 6) {
        showMessage('新密码长度至少 6 位', 'error');
        return;
      }
      if (newPassword !== confirmPassword) {
        showMessage('两次输入的新密码不一致', 'error');
        return;
      }

      const submit = form.querySelector('button[type="submit"]');
      submit.disabled = true;
      submit.classList.add('opacity-70');
      try {
        const data = await apiFetch(endpoints.password, {
          method: 'POST',
          body: { oldPassword, newPassword },
        });
        showMessage(data.message || '密码已修改', 'success');
        form.reset();
        // 重新拉取状态（可能从「未设置密码」变为「已设置」）
        loadProfile();
      } catch (error) {
        showMessage(error.message || '修改失败', 'error');
      } finally {
        submit.disabled = false;
        submit.classList.remove('opacity-70');
      }
    });
  }

  async function apiFetch(path, options) {
    const opts = options || {};
    const headers = { Authorization: `Bearer ${getAuthToken()}` };
    if (opts.body !== undefined) {
      headers['Content-Type'] = 'application/json';
    }
    const response = await fetch(apiBase + path, {
      method: opts.method || 'GET',
      headers,
      body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
    });
    const data = await response.json().catch(function () {
      return {};
    });
    if (!response.ok || !data.success) {
      throw new Error(data.message || data.error || '请求失败');
    }
    return data;
  }

  function getAuthToken() {
    const loginInfo = readJson('ajou_login_info');
    return localStorage.getItem('ajou_auth_token') || (loginInfo && loginInfo.token) || '';
  }

  function readJson(key) {
    try {
      return JSON.parse(localStorage.getItem(key) || 'null');
    } catch (error) {
      return null;
    }
  }

  function showMessage(text, type) {
    const box = document.getElementById('profile-message');
    if (!box) {
      return;
    }
    box.textContent = text;
    box.className =
      'rounded border px-4 py-2.5 text-sm ' +
      (type === 'success'
        ? 'bg-green-50 border-green-200 text-green-700'
        : type === 'error'
          ? 'bg-red-50 border-red-200 text-red-600'
          : 'bg-blue-50 border-blue-100 text-primary');
    box.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  function setText(id, text) {
    const el = document.getElementById(id);
    if (el) {
      el.textContent = text;
    }
  }

  function value(id) {
    const el = document.getElementById(id);
    return el ? el.value.trim() : '';
  }
})();
