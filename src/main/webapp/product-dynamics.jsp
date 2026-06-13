<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>产品动态 - AJOU</title>
  <script src="assets/js/vendor/tailwindcss-cdn.js?v=local-precompiled"></script>
  <script src="assets/js/tailwind-config.js?v=20260428-3"></script>
  <script src="assets/js/vendor/jquery-3.7.1.min.js?v=20260428-1"></script>
  <script src="assets/js/layout.js?v=20260612-4"></script>
  <link href="/assets/vendor/fontawesome/css/all.min.css" rel="stylesheet">
  <link rel="stylesheet" href="assets/css/styles.css?v=20260428-5">
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased min-h-screen flex flex-col">
  <div id="site-header"></div>

  <main class="flex-grow bg-bg-gray pb-16">
    <section class="bg-white border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div class="text-sm text-gray-500 mb-3">
          <a href="index.jsp" class="hover:text-primary">首页</a>
          <span class="mx-2">/</span>
          <span class="text-gray-900">产品动态</span>
        </div>
        <h1 class="text-3xl font-bold text-gray-900 mb-3">产品动态</h1>
        <p class="text-gray-500">查看云服务器、GPU 实例、网络与存储服务的最新发布、价格调整、维护公告和解决方案。</p>
      </div>
    </section>

    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="grid grid-cols-1 lg:grid-cols-[240px_1fr] gap-6">
        <aside class="bg-white border border-gray-200 rounded-lg p-5 h-fit">
          <h2 class="text-sm font-bold text-gray-900 mb-4">动态分类</h2>
          <%-- 分类导航由 /api/dynamics 的 categories 渲染，后台「动态分类」管理 --%>
          <div id="dynamics-categories" class="space-y-2 text-sm">
            <div class="px-3 py-2 text-gray-400">加载中…</div>
          </div>
        </aside>

        <%-- 动态列表由 /api/dynamics 渲染，后台「产品动态」管理 --%>
        <div id="dynamics-list" class="space-y-5">
          <div class="bg-white border border-gray-200 rounded-lg p-6 text-gray-400 text-sm">加载中…</div>
        </div>
      </div>
    </section>
  </main>

  <div id="site-footer"></div>
  <script src="assets/js/dynamics.js?v=20260612-13"></script>
  <script src="assets/js/ai-guide.js?v=20260613-1"></script>
  <script src="assets/js/nav-auth.js?v=20260428-3"></script>
</body>
</html>
