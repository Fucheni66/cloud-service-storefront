<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>产品动态详情 - AJOU</title>
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
          <a href="product-dynamics.jsp" class="hover:text-primary">产品动态</a>
          <span class="mx-2">/</span>
          <span class="text-gray-900">详情</span>
        </div>
        <h1 class="text-3xl font-bold text-gray-900 mb-3">产品动态详情</h1>
        <p class="text-gray-500">查看产品发布、价格调整、维护公告和解决方案的完整说明。</p>
      </div>
    </section>

    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6">
        <%-- 详情正文由 /api/dynamics?slug= 渲染 --%>
        <div id="dynamics-detail" class="space-y-6">
          <div class="bg-white border border-gray-200 rounded-lg p-6 text-gray-400 text-sm">加载中…</div>
        </div>

        <aside class="space-y-6">
          <section class="bg-white border border-gray-200 rounded-lg p-6">
            <h2 class="text-lg font-bold text-gray-900 mb-4">相关动态</h2>
            <div id="dynamics-related" class="space-y-3 text-sm">
              <div class="text-gray-400">加载中…</div>
            </div>
          </section>

          <section class="bg-white border border-gray-200 rounded-lg p-6">
            <h2 class="text-lg font-bold text-gray-900 mb-4">更多操作</h2>
            <div class="space-y-3">
              <a href="product-dynamics.jsp" class="inline-flex w-full items-center justify-center bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 px-4 py-2.5 rounded text-sm font-medium transition">返回产品动态</a>
              <a href="products.jsp" class="inline-flex w-full items-center justify-center bg-primary hover:bg-primary-hover text-white px-4 py-2.5 rounded text-sm font-medium transition">查看产品购买</a>
            </div>
          </section>
        </aside>
      </div>
    </section>
  </main>

  <div id="site-footer"></div>
  <script src="assets/js/dynamics.js?v=20260612-13"></script>
  <script src="assets/js/ai-guide.js?v=20260613-1"></script>
  <script src="assets/js/nav-auth.js?v=20260428-3"></script>
</body>
</html>
