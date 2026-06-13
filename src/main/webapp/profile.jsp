<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>个人中心 - AJOU</title>
  <script src="assets/js/vendor/tailwindcss-cdn.js?v=local-precompiled"></script>
  <script src="assets/js/tailwind-config.js?v=20260428-3"></script>
  <script src="assets/js/vendor/jquery-3.7.1.min.js?v=20260428-1"></script>
  <script src="assets/js/layout.js?v=20260612-4"></script>
  <link href="/assets/vendor/fontawesome/css/all.min.css" rel="stylesheet">
  <link rel="stylesheet" href="assets/css/styles.css?v=20260428-5">
  <script src="assets/js/require-auth.js?v=20260428-3"></script>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased min-h-screen flex flex-col">
  <div id="site-header"></div>

  <main class="flex-grow bg-bg-gray pb-16">
    <section class="bg-white border-b border-gray-200">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div class="text-sm text-gray-500 mb-3">
          <a href="index.jsp" class="hover:text-primary">首页</a>
          <span class="mx-2">/</span>
          <a href="console.jsp" class="hover:text-primary">控制台</a>
          <span class="mx-2">/</span>
          <span class="text-gray-900">个人中心</span>
        </div>
        <h1 class="text-3xl font-bold text-gray-900 mb-3">个人中心</h1>
        <p class="text-gray-500">管理你的登录密码与关联登录方式。</p>
      </div>
    </section>

    <section class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      <div id="profile-message" class="hidden rounded border px-4 py-2.5 text-sm"></div>

      <!-- 账号概览 -->
      <div class="bg-white border border-gray-200 rounded-xl shadow-sm p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-4">账号信息</h2>
        <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3 text-sm">
          <div><dt class="text-gray-500">邮箱</dt><dd id="pf-email" class="text-gray-900 mt-0.5">—</dd></div>
          <div><dt class="text-gray-500">注册来源</dt><dd id="pf-provider" class="text-gray-900 mt-0.5">—</dd></div>
        </dl>
      </div>

      <!-- 修改密码 -->
      <div class="bg-white border border-gray-200 rounded-xl shadow-sm p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">修改密码</h2>
        <p id="pf-password-hint" class="text-sm text-gray-500 mb-4">修改后请使用新密码登录。</p>
        <form id="password-form" class="space-y-4 max-w-md">
          <div id="old-password-wrap">
            <label for="pf-old-password" class="block text-sm font-medium text-gray-700 mb-2">原密码</label>
            <input id="pf-old-password" type="password" autocomplete="current-password"
                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                   placeholder="请输入原密码">
          </div>
          <div>
            <label for="pf-new-password" class="block text-sm font-medium text-gray-700 mb-2">新密码</label>
            <input id="pf-new-password" type="password" autocomplete="new-password" minlength="6" required
                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                   placeholder="至少 6 位新密码">
          </div>
          <div>
            <label for="pf-confirm-password" class="block text-sm font-medium text-gray-700 mb-2">确认新密码</label>
            <input id="pf-confirm-password" type="password" autocomplete="new-password" minlength="6" required
                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                   placeholder="再次输入新密码">
          </div>
          <button type="submit"
                  class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
            保存密码
          </button>
        </form>
      </div>

      <!-- 关联登录 -->
      <div class="bg-white border border-gray-200 rounded-xl shadow-sm p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-1">关联登录</h2>
        <p class="text-sm text-gray-500 mb-4">绑定 Google 账号后，下次可直接用 Google 一键快速登录。</p>
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border border-gray-100 rounded-lg p-4">
          <div class="flex items-center gap-3">
            <span class="w-10 h-10 rounded-full bg-gray-50 border border-gray-200 flex items-center justify-center">
              <i class="fa-brands fa-google text-lg text-[#4285F4]"></i>
            </span>
            <div>
              <div class="text-sm font-medium text-gray-900">Google 账号</div>
              <div id="pf-google-status" class="text-xs text-gray-500 mt-0.5">未绑定</div>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <div id="pf-google-bind-button" class="hidden"></div>
            <button id="pf-google-unbind" type="button"
                    class="hidden border border-red-200 bg-white text-red-500 rounded px-4 py-2 text-sm hover:bg-red-50 transition">
              解除绑定
            </button>
          </div>
        </div>
      </div>
    </section>
  </main>

  <div id="site-footer"></div>

  <script src="assets/js/config/auth.config.js?v=20260612-feat"></script>
  <script src="https://accounts.google.com/gsi/client" async defer></script>
  <script src="assets/js/profile.js?v=20260612-feat"></script>
  <script src="assets/js/ai-guide.js?v=20260613-1"></script>
  <script src="assets/js/nav-auth.js?v=20260612-feat"></script>
</body>
</html>
