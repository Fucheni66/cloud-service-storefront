// 通用导航登录状态渲染：登录后显示头像/name 下拉菜单，并支持查看主页和退出登录。
(function () {
  document.addEventListener('DOMContentLoaded', renderAuthNav);
  document.addEventListener('click', handleDocumentClick);
  window.addEventListener('storage', renderAuthNav);

  function renderAuthNav() {
    const user = getStoredUser();

    if (!user) {
      return;
    }

    // 所有页面导航栏里的登录入口保持 href="auth.html"，登录后统一替换成用户菜单。
    document.querySelectorAll('a[href="auth.html"]').forEach(function (link) {
      if (!link.textContent.includes('登录')) {
        return;
      }

      link.replaceWith(renderUserMenu(user));
    });
  }

  function renderUserMenu(user) {
    // 用户菜单替代原来的“登录 / 注册”按钮，点击后展开下拉菜单。
    const wrapper = document.createElement('div');
    wrapper.className = 'relative nav-auth-menu';

    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'inline-flex items-center gap-2 max-w-[180px] rounded-full bg-white border border-gray-200 px-3 py-1.5 text-sm font-medium text-gray-700 hover:border-primary hover:text-primary transition shadow-sm';
    button.title = user.email || user.name || '已登录用户';
    button.setAttribute('aria-haspopup', 'true');
    button.setAttribute('aria-expanded', 'false');
    button.appendChild(renderAvatar(user));
    button.appendChild(renderName(user));
    button.appendChild(renderChevron());
    button.addEventListener('click', function (event) {
      event.stopPropagation();
      toggleMenu(wrapper, button);
    });

    const menu = document.createElement('div');
    menu.className = 'hidden absolute right-0 mt-2 w-48 bg-white border border-gray-200 rounded-xl shadow-lg py-2 z-[80]';
    menu.setAttribute('data-nav-auth-dropdown', 'true');
    // 下拉菜单顶部显示当前登录用户，下面提供控制台入口和退出登录。
    menu.appendChild(renderUserSummary(user));
    menu.appendChild(renderMenuLink('查看主页', 'console.html', 'fa-solid fa-house'));
    menu.appendChild(renderLogoutButton());

    wrapper.appendChild(button);
    wrapper.appendChild(menu);
    return wrapper;
  }

  function toggleMenu(wrapper, button) {
    closeOtherMenus(wrapper);

    const menu = wrapper.querySelector('[data-nav-auth-dropdown]');
    const isOpen = !menu.classList.contains('hidden');
    menu.classList.toggle('hidden', isOpen);
    button.setAttribute('aria-expanded', String(!isOpen));
  }

  function closeOtherMenus(currentWrapper) {
    document.querySelectorAll('.nav-auth-menu').forEach(function (wrapper) {
      if (wrapper === currentWrapper) {
        return;
      }

      const menu = wrapper.querySelector('[data-nav-auth-dropdown]');
      const button = wrapper.querySelector('button');

      if (menu) {
        menu.classList.add('hidden');
      }

      if (button) {
        button.setAttribute('aria-expanded', 'false');
      }
    });
  }

  function handleDocumentClick(event) {
    if (event.target.closest('.nav-auth-menu')) {
      return;
    }

    closeOtherMenus(null);
  }

  function renderUserSummary(user) {
    const summary = document.createElement('div');
    summary.className = 'px-4 pb-2 mb-2 border-b border-gray-100';

    const name = document.createElement('div');
    name.className = 'text-sm font-semibold text-gray-900 truncate';
    name.textContent = user.name || '已登录用户';

    const email = document.createElement('div');
    email.className = 'text-xs text-gray-500 truncate mt-0.5';
    email.textContent = user.email || '';

    summary.appendChild(name);
    summary.appendChild(email);
    return summary;
  }

  function renderMenuLink(text, href, icon) {
    const link = document.createElement('a');
    link.href = href;
    link.className = 'flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-blue-50 hover:text-primary transition';

    const iconNode = document.createElement('i');
    iconNode.className = icon + ' w-4 text-gray-400';

    const label = document.createElement('span');
    label.textContent = text;

    link.appendChild(iconNode);
    link.appendChild(label);
    return link;
  }

  function renderLogoutButton() {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition text-left';

    const icon = document.createElement('i');
    icon.className = 'fa-solid fa-right-from-bracket w-4 text-red-400';

    const label = document.createElement('span');
    label.textContent = '退出登录';

    button.appendChild(icon);
    button.appendChild(label);
    button.addEventListener('click', function () {
      logout();
    });

    return button;
  }

  function logout() {
    // 退出登录只清理浏览器登录态；后端 JSON 登录记录保留作为历史记录。
    localStorage.removeItem('ajou_login_info');
    localStorage.removeItem('ajou_auth_user');
    localStorage.removeItem('ajou_auth_token');
    window.location.href = 'index.html';
  }

  function getStoredUser() {
    // 优先读取精简用户信息；不存在时从完整登录返回值里取 user。
    const directUser = readJson('ajou_auth_user');

    if (directUser && (directUser.name || directUser.email)) {
      return directUser;
    }

    const loginInfo = readJson('ajou_login_info');
    return loginInfo && loginInfo.user ? loginInfo.user : null;
  }

  function readJson(key) {
    try {
      return JSON.parse(localStorage.getItem(key) || 'null');
    } catch (error) {
      return null;
    }
  }

  function renderAvatar(user) {
    // Google 用户通常带 picture 字段，优先显示真实头像。
    if (user.picture) {
      const img = document.createElement('img');
      img.src = user.picture;
      img.alt = user.name || user.email || 'user';
      img.referrerPolicy = 'no-referrer';
      img.className = 'w-7 h-7 rounded-full object-cover flex-shrink-0';
      return img;
    }

    const avatar = document.createElement('span');
    avatar.className = 'w-7 h-7 rounded-full bg-primary text-white flex items-center justify-center text-xs font-bold flex-shrink-0';
    avatar.textContent = getInitial(user);
    return avatar;
  }

  function renderName(user) {
    const name = document.createElement('span');
    name.className = 'truncate';
    name.textContent = user.name || user.email || '已登录';
    return name;
  }

  function renderChevron() {
    const icon = document.createElement('i');
    icon.className = 'fa-solid fa-angle-down text-xs text-gray-400 flex-shrink-0';
    return icon;
  }

  function getInitial(user) {
    const value = (user.name || user.email || 'U').trim();
    return value ? value.charAt(0).toUpperCase() : 'U';
  }
})();
