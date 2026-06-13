<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>开发者社区 - AJOU</title>
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
          <span class="text-gray-900">开发者社区</span>
        </div>
        <h1 class="text-3xl font-bold text-gray-900 mb-3">开发者社区</h1>
        <p class="text-gray-500">获取云服务器实践教程、API 文档、常见问题和技术支持入口。</p>
      </div>
    </section>

    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6">
        <div class="space-y-6">
          <section id="help" class="bg-white border border-gray-200 rounded-lg p-6">
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-5">
              <h2 class="text-xl font-bold text-gray-900">社区问答</h2>
              <a href="community-publish.jsp" class="inline-flex items-center justify-center bg-primary hover:bg-primary-hover text-white px-4 py-2 rounded text-sm font-medium transition">
                <i class="fa-solid fa-pen-to-square mr-2 text-xs"></i> 发表
              </a>
            </div>
            <%-- 社区问答列表由 /api/community/questions 渲染，后台「开发者社区」管理 --%>
            <div id="community-list" class="space-y-4">
              <div class="border border-gray-200 rounded-lg p-4 text-sm text-gray-400">加载中…</div>
            </div>
          </section>
        </div>

        <aside class="space-y-6">
          <section id="ticket" class="bg-white border border-gray-200 rounded-lg p-6">
            <h2 class="text-lg font-bold text-gray-900 mb-4">技术支持</h2>
            <%-- 技术支持时效由后台「系统设置·站点」配置，community.js 读取 /api/site 填充 --%>
            <div class="space-y-3 text-sm text-gray-600">
              <div class="flex items-center justify-between border-b border-gray-100 pb-3">
                <span>在线工单</span>
                <span class="text-primary font-medium" id="support-ticket-hours">09:00-22:00</span>
              </div>
              <div class="flex items-center justify-between border-b border-gray-100 pb-3">
                <span>实例故障</span>
                <span class="text-primary font-medium" id="support-fault">优先响应</span>
              </div>
              <div class="flex items-center justify-between">
                <span>社区回复</span>
                <span class="text-primary font-medium" id="support-reply">工作日</span>
              </div>
            </div>
            <a href="console.jsp" class="mt-5 inline-flex w-full items-center justify-center bg-primary hover:bg-primary-hover text-white px-4 py-2.5 rounded text-sm font-medium transition">
              前往控制台 <i class="fa-solid fa-arrow-right ml-2 text-xs"></i>
            </a>
          </section>

          <section id="tutorials" class="bg-white border border-gray-200 rounded-lg p-6">
            <div class="flex items-center justify-between gap-4 mb-5">
              <h2 class="text-lg font-bold text-gray-900">精选教程</h2>
              <span class="text-sm text-gray-400">持续更新</span>
            </div>
            <%-- 精选教程 = 产品动态 tutorial 分类，由 /api/dynamics?category=tutorial 渲染，后台「产品动态」管理 --%>
            <div id="community-tutorials" class="divide-y divide-gray-100">
              <div class="py-4 text-sm text-gray-400">加载中…</div>
            </div>
          </section>
        </aside>
      </div>
    </section>
  </main>

  <div id="site-footer"></div>
  <script src="assets/js/community.js?v=20260612-13"></script>
  <script src="assets/js/ai-guide.js?v=20260613-1"></script>
  <script src="assets/js/nav-auth.js?v=20260428-3"></script>
</body>
</html>
