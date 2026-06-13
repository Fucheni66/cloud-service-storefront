<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>登录 / 注册 - AJOU</title>
    <script src="assets/js/vendor/tailwindcss-cdn.js?v=local-precompiled"></script>
    <script src="assets/js/tailwind-config.js?v=20260428-3"></script>
    <script src="assets/js/vendor/jquery-3.7.1.min.js?v=20260428-1"></script>
    <script src="assets/js/layout.js?v=20260612-4"></script>
    <link
      href="/assets/vendor/fontawesome/css/all.min.css"
      rel="stylesheet"
    />
    <link rel="stylesheet" href="assets/css/styles.css?v=20260428-5" />
  </head>
  <body
    class="bg-bg-gray text-gray-800 font-sans antialiased min-h-screen flex flex-col"
  >
    <div id="site-header"></div>

    <main class="flex-grow flex items-center justify-center px-4 py-12">
      <section
        class="w-full max-w-md bg-white border border-gray-200 rounded-xl shadow-sm p-6"
      >
        <div class="mb-6">
          <h1 id="auth-title" class="text-2xl font-bold text-gray-900">
            登录账号
          </h1>
          <p id="auth-subtitle" class="text-sm text-gray-500 mt-2">
            进入控制台管理你的云服务。
          </p>
        </div>

        <div
          id="auth-top-tabs"
          class="grid grid-cols-2 gap-2 bg-gray-100 rounded p-1 mb-5"
        >
          <button
            type="button"
            data-auth-tab="login"
            class="auth-tab bg-white text-primary shadow-sm rounded py-2 text-sm font-medium transition"
          >
            登录
          </button>
          <button
            type="button"
            data-auth-tab="register"
            class="auth-tab text-gray-600 rounded py-2 text-sm font-medium transition"
          >
            注册
          </button>
        </div>

        <div
          id="auth-message"
          class="hidden mb-4 rounded border px-3 py-2 text-sm"
        ></div>

        <!-- ============ 登录视图（密码 / 验证码） ============ -->
        <div data-auth-view="login">
          <div class="flex gap-4 mb-4 text-sm border-b border-gray-100">
            <button
              type="button"
              data-login-mode="password"
              class="login-mode-tab pb-2 border-b-2 border-primary text-primary font-medium"
            >
              密码登录
            </button>
            <button
              type="button"
              data-login-mode="code"
              class="login-mode-tab pb-2 border-b-2 border-transparent text-gray-500 hover:text-primary"
            >
              验证码登录
            </button>
          </div>

          <!-- 密码登录 -->
          <form id="login-form" data-login-pane="password" class="space-y-4">
            <div>
              <label for="login-email" class="block text-sm font-medium text-gray-700 mb-2">邮箱</label>
              <input
                id="login-email"
                name="email"
                type="email"
                autocomplete="email"
                required
                class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                placeholder="name@example.com"
              />
            </div>
            <div>
              <label for="login-password" class="block text-sm font-medium text-gray-700 mb-2">密码</label>
              <input
                id="login-password"
                name="password"
                type="password"
                autocomplete="current-password"
                required
                class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                placeholder="请输入密码"
              />
            </div>
            <button
              type="submit"
              class="w-full bg-primary hover:bg-primary-hover text-white rounded py-2.5 text-sm font-medium transition"
            >
              登录
            </button>
            <div id="google-login-button" class="w-full min-h-[44px] flex justify-center"></div>
          </form>

          <!-- 验证码登录 -->
          <form id="login-code-form" data-login-pane="code" class="hidden space-y-4">
            <div>
              <label for="login-code-email" class="block text-sm font-medium text-gray-700 mb-2">邮箱</label>
              <input
                id="login-code-email"
                name="email"
                type="email"
                autocomplete="email"
                required
                class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                placeholder="name@example.com"
              />
            </div>
            <div>
              <label for="login-code-input" class="block text-sm font-medium text-gray-700 mb-2">验证码</label>
              <div class="flex gap-2">
                <input
                  id="login-code-input"
                  name="code"
                  type="text"
                  inputmode="numeric"
                  required
                  class="flex-1 min-w-0 border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                  placeholder="请输入验证码"
                />
                <button
                  type="button"
                  data-send-code
                  data-scene="login"
                  data-email-input="login-code-email"
                  class="w-28 border border-gray-300 bg-white hover:bg-gray-50 text-gray-700 rounded px-3 py-2.5 text-sm font-medium transition"
                >
                  获取验证码
                </button>
              </div>
            </div>
            <button
              type="submit"
              class="w-full bg-primary hover:bg-primary-hover text-white rounded py-2.5 text-sm font-medium transition"
            >
              登录
            </button>
          </form>

          <div class="mt-4 text-right">
            <button type="button" id="forgot-link" class="text-sm text-gray-500 hover:text-primary">
              忘记密码？
            </button>
          </div>
        </div>

        <!-- ============ 注册视图 ============ -->
        <form id="register-form" data-auth-view="register" class="hidden space-y-4">
          <div>
            <label for="register-email" class="block text-sm font-medium text-gray-700 mb-2">邮箱</label>
            <input
              id="register-email"
              name="email"
              type="email"
              autocomplete="email"
              required
              class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
              placeholder="name@example.com"
            />
          </div>
          <div>
            <label for="register-password" class="block text-sm font-medium text-gray-700 mb-2">密码</label>
            <input
              id="register-password"
              name="password"
              type="password"
              autocomplete="new-password"
              required
              minlength="6"
              class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
              placeholder="至少 6 位密码"
            />
          </div>
          <div>
            <label for="register-code" class="block text-sm font-medium text-gray-700 mb-2">验证码</label>
            <div class="flex gap-2">
              <input
                id="register-code"
                name="code"
                type="text"
                inputmode="numeric"
                required
                class="flex-1 min-w-0 border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                placeholder="请输入邮箱验证码"
              />
              <button
                type="button"
                data-send-code
                data-scene="register"
                data-email-input="register-email"
                class="w-28 border border-gray-300 bg-white hover:bg-gray-50 text-gray-700 rounded px-3 py-2.5 text-sm font-medium transition"
              >
                获取验证码
              </button>
            </div>
          </div>
          <button
            type="submit"
            class="w-full bg-primary hover:bg-primary-hover text-white rounded py-2.5 text-sm font-medium transition"
          >
            注册
          </button>
        </form>

        <!-- ============ 找回密码视图 ============ -->
        <form id="forgot-form" data-auth-view="forgot" class="hidden space-y-4">
          <div>
            <label for="forgot-email" class="block text-sm font-medium text-gray-700 mb-2">邮箱</label>
            <input
              id="forgot-email"
              name="email"
              type="email"
              autocomplete="email"
              required
              class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
              placeholder="name@example.com"
            />
          </div>
          <div>
            <label for="forgot-code" class="block text-sm font-medium text-gray-700 mb-2">验证码</label>
            <div class="flex gap-2">
              <input
                id="forgot-code"
                name="code"
                type="text"
                inputmode="numeric"
                required
                class="flex-1 min-w-0 border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                placeholder="请输入邮箱验证码"
              />
              <button
                type="button"
                data-send-code
                data-scene="reset"
                data-email-input="forgot-email"
                class="w-28 border border-gray-300 bg-white hover:bg-gray-50 text-gray-700 rounded px-3 py-2.5 text-sm font-medium transition"
              >
                获取验证码
              </button>
            </div>
          </div>
          <div>
            <label for="forgot-password" class="block text-sm font-medium text-gray-700 mb-2">新密码</label>
            <input
              id="forgot-password"
              name="password"
              type="password"
              autocomplete="new-password"
              required
              minlength="6"
              class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
              placeholder="至少 6 位新密码"
            />
          </div>
          <button
            type="submit"
            class="w-full bg-primary hover:bg-primary-hover text-white rounded py-2.5 text-sm font-medium transition"
          >
            重置密码
          </button>
          <div class="text-center">
            <button type="button" id="back-to-login" class="text-sm text-gray-500 hover:text-primary">
              返回登录
            </button>
          </div>
        </form>

        <div id="auth-switch-row" class="mt-5 text-center text-sm text-gray-500">
          <span id="auth-switch-text">还没有账号？</span>
          <button
            type="button"
            id="auth-switch-button"
            class="text-primary hover:text-primary-hover font-medium"
          >
            立即注册
          </button>
        </div>
      </section>
    </main>

    <script>
      (function () {
        const tabs = document.querySelectorAll("[data-auth-tab]");
        const views = document.querySelectorAll("[data-auth-view]");
        const loginModeTabs = document.querySelectorAll("[data-login-mode]");
        const loginPanes = document.querySelectorAll("[data-login-pane]");
        const title = document.getElementById("auth-title");
        const subtitle = document.getElementById("auth-subtitle");
        const message = document.getElementById("auth-message");
        const switchRow = document.getElementById("auth-switch-row");
        const switchText = document.getElementById("auth-switch-text");
        const switchButton = document.getElementById("auth-switch-button");
        const topTabs = document.getElementById("auth-top-tabs");
        let currentView = "login";

        function switchView(view) {
          currentView = ["login", "register", "forgot"].includes(view) ? view : "login";
          message.classList.add("hidden");

          if (currentView !== "forgot") {
            window.location.hash = currentView;
          }

          views.forEach(function (panel) {
            panel.classList.toggle("hidden", panel.dataset.authView !== currentView);
          });

          // 顶部「登录/注册」tab 高亮（找回密码视图不高亮任何 tab）
          tabs.forEach(function (tab) {
            const isActive = tab.dataset.authTab === currentView;
            tab.classList.toggle("bg-white", isActive);
            tab.classList.toggle("text-primary", isActive);
            tab.classList.toggle("shadow-sm", isActive);
            tab.classList.toggle("text-gray-600", !isActive);
          });

          // 顶部 tab 与底部切换行：登录/注册时显示，找回密码时隐藏
          const isForgot = currentView === "forgot";
          topTabs.classList.toggle("hidden", isForgot);
          switchRow.classList.toggle("hidden", isForgot);

          if (currentView === "register") {
            title.textContent = "注册账号";
            subtitle.textContent = "创建账号后即可购买和管理云服务。";
            switchText.textContent = "已有账号？";
            switchButton.textContent = "立即登录";
          } else if (currentView === "forgot") {
            title.textContent = "找回密码";
            subtitle.textContent = "通过邮箱验证码重置你的登录密码。";
          } else {
            title.textContent = "登录账号";
            subtitle.textContent = "进入控制台管理你的云服务。";
            switchText.textContent = "还没有账号？";
            switchButton.textContent = "立即注册";
          }
        }

        function switchLoginMode(mode) {
          const target = mode === "code" ? "code" : "password";
          loginModeTabs.forEach(function (tab) {
            const isActive = tab.dataset.loginMode === target;
            tab.classList.toggle("border-primary", isActive);
            tab.classList.toggle("text-primary", isActive);
            tab.classList.toggle("font-medium", isActive);
            tab.classList.toggle("border-transparent", !isActive);
            tab.classList.toggle("text-gray-500", !isActive);
          });
          loginPanes.forEach(function (pane) {
            pane.classList.toggle("hidden", pane.dataset.loginPane !== target);
          });
        }

        window.switchAuthView = switchView;

        tabs.forEach(function (tab) {
          tab.addEventListener("click", function () {
            switchView(tab.dataset.authTab);
          });
        });

        loginModeTabs.forEach(function (tab) {
          tab.addEventListener("click", function () {
            switchLoginMode(tab.dataset.loginMode);
          });
        });

        switchButton.addEventListener("click", function () {
          switchView(currentView === "login" ? "register" : "login");
        });

        document.getElementById("forgot-link").addEventListener("click", function () {
          switchView("forgot");
        });
        document.getElementById("back-to-login").addEventListener("click", function () {
          switchView("login");
        });

        switchView(window.location.hash.replace("#", "") === "register" ? "register" : "login");
        switchLoginMode("password");

        window.addEventListener("hashchange", function () {
          const hash = window.location.hash.replace("#", "");
          if (hash === "register" || hash === "login") {
            switchView(hash);
          }
        });
      })();
    </script>
<script src="assets/js/config/auth.config.js?v=20260612-feat"></script>
<script src="https://accounts.google.com/gsi/client" async defer></script>
<script src="assets/js/auth.js?v=20260612-feat"></script>
<script src="assets/js/ai-guide.js?v=20260613-1"></script>
<script src="assets/js/nav-auth.js?v=20260612-feat"></script>
  </body>
</html>
