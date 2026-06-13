<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>AJOU - 高性能云服务器与GPU租赁</title>
    <script src="assets/js/vendor/tailwindcss-cdn.js?v=local-precompiled"></script>
    <script src="assets/js/tailwind-config.js?v=20260428-3"></script>
    <script src="assets/js/vendor/jquery-3.7.1.min.js?v=20260428-1"></script>
    <script src="assets/js/layout.js?v=20260612-4"></script>
    <link
      href="/assets/vendor/fontawesome/css/all.min.css"
      rel="stylesheet"
    />
    <link rel="stylesheet" href="assets/css/styles.css?v=20260504-5" />
    <style>
      .home-hero{
        padding: 4.25rem 0 13.5rem;
      }
    </style>
  </head>
  <body
    class="bg-bg-gray text-gray-800 font-sans antialiased min-h-screen flex flex-col"
  >
    <div id="site-header"></div>

    <main class="flex-grow flex flex-col relative">
      <section class="home-hero relative overflow-hidden">
        <img
          class="home-hero-server-image"
          src="assets/images/home-server-rack.png"
          alt="云服务器机柜"
        />
        <div
          class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 flex flex-col items-start text-left"
        >
          <h1
            class="text-4xl md:text-5xl lg:text-5xl font-extrabold tracking-tight mb-6 text-slate-900 leading-tight max-w-3xl"
          >
            <span
              class="lg:text-6xl text-transparent bg-clip-text bg-gradient-to-r from-blue-600 via-indigo-500 to-purple-600"
              >Ajou Cloud</span
            >
            <br />云服务器平台
          </h1>
          <p
            class="text-base md:text-xl text-gray-600 mb-8 max-w-2xl leading-relaxed"
          >
            面向个人网站、开发测试和业务系统部署，提供
            <span class="text-primary font-medium">CPU 云服务器</span> 与
            <span class="text-primary font-medium">GPU 云服务器</span>
            购买、支付、控制台管理的一体化流程。
          </p>

          <div class="w-full max-w-2xl mb-8 relative">
            <form
              action="products.jsp"
              class="hidden"
            >
              <div class="pl-4 text-gray-400">
                <i class="fa-solid fa-magnifying-glass"></i>
              </div>
              <input
                name="q"
                type="text"
                class="w-full px-4 py-3 outline-none text-gray-700 placeholder-gray-400 bg-transparent"
                placeholder="搜索产品名称，如：云服务器 ECS"
              />
              <button
                class="bg-primary hover:bg-primary-hover text-white px-8 h-full font-medium transition whitespace-nowrap flex-shrink-0 inline-flex items-center justify-center"
                type="submit"
              >
                搜索
              </button>
            </form>
            <div
              class="hidden"
            >
              <div
                class="text-sm text-gray-500 flex justify-start items-center space-x-4 overflow-x-auto whitespace-nowrap pb-1"
              >
                <span class="text-red-500 flex items-center font-medium"
                  ><i class="fa-solid fa-fire mr-1"></i> 热搜产品:</span
                >
                <a href="products.jsp" class="hover:text-primary transition"
                  >云服务器</a
                >

                <a href="products.jsp" class="hover:text-primary transition"
                  >轻量应用服务器</a
                >
              </div>
            </div>
            <a
              href="products.jsp"
              class="inline-flex items-center justify-center bg-primary hover:bg-primary-hover text-white font-bold py-3 px-8 rounded transition duration-300 shadow-md whitespace-nowrap"
              >立即选购
              <i class="fa-solid fa-arrow-right ml-2 text-sm opacity-80"></i
            ></a>
          </div>

          <div
            class="hidden"
          >
            <a
              href="products.jsp"
              class="bg-primary hover:bg-blue-600 text-white font-bold py-3 px-8 rounded flex items-center justify-center transition duration-300 shadow-md"
              >免费开始使用
              <i
                class="fa-solid fa-arrow-up-right-from-square ml-2 text-sm opacity-80"
              ></i
            ></a>
          </div>

          <div
            class="hidden"
          >
            <span class="flex items-center"
              ><i class="fa-solid fa-check text-blue-500 mr-1.5"></i> 80+
              云产品</span
            >
            <span class="flex items-center"
              ><i class="fa-solid fa-check text-blue-500 mr-1.5"></i> CPU / GPU
              云服务器</span
            >
          </div>
        </div>
      </section>

      <section
        class="home-overlap-panel max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-20 mb-16 w-full"
      >
        <div
          class="bg-white rounded-xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.1)] flex flex-col md:flex-row overflow-hidden border border-gray-100"
        >
          <div
            class="w-full md:w-1/3 xl:w-1/4 bg-gradient-to-b from-blue-500 to-blue-700 p-8 text-white flex flex-col justify-between relative overflow-hidden"
          >
            <i
              class="fa-solid fa-cube absolute -bottom-10 -right-10 text-9xl text-white opacity-10 transform rotate-12"
            ></i>
            <div class="relative z-10">
              <div class="flex items-center space-x-2 mb-2">
                <i class="fa-solid fa-gift text-xl"></i>
                <h3 class="text-xl font-bold tracking-wider">免费试用中心</h3>
              </div>
              <div
                class="bg-blue-600 text-xs inline-block px-2 py-0.5 rounded mb-4 font-medium border border-blue-400"
              >
                2026 年 第1期
              </div>
              <p class="text-blue-100 text-sm mb-8 leading-relaxed">
                60+款免费云产品，服务器最长体验3个月，助力您的业务轻松腾飞。
              </p>
              <a
                href="products.jsp"
                class="inline-block bg-white text-primary hover:bg-gray-50 font-bold py-2 px-6 rounded text-sm transition shadow"
                >立即前往</a
              >
            </div>
          </div>

          <div class="w-full md:w-2/3 xl:w-3/4 p-6 sm:p-8 bg-white">
            <div class="flex items-center justify-between mb-6">
              <div class="flex items-center border-l-4 border-primary pl-3">
                <h3 class="text-lg font-bold text-gray-900">热门产品</h3>
              </div>
              <a
                href="products.jsp"
                class="text-sm text-gray-500 hover:text-primary transition"
                >查看更多 <i class="fa-solid fa-angle-right"></i
              ></a>
            </div>

            <div
              id="home-hot-products"
              class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-2 xl:grid-cols-4 gap-6"
            ></div>

            <div
              class="mt-4 pt-4 border-t border-gray-100 flex items-center justify-between text-sm"
            >
              <%-- 产品动态：由 /api/home 的 dynamic 渲染，后台「首页配置」选择展示哪条 --%>
              <a
                id="home-dynamic"
                href="product-dynamics.jsp"
                class="flex items-center text-gray-600 truncate pr-4 min-w-0 hover:text-primary transition"
              >
                <span
                  class="font-bold text-primary mr-3 border-r border-gray-300 pr-3 flex-shrink-0"
                  >产品动态</span
                >
                <span class="truncate text-gray-400">加载中…</span>
              </a>
              <a
                href="product-dynamics.jsp"
                class="text-primary hover:text-blue-800 flex-shrink-0 whitespace-nowrap"
                >查看更多</a
              >
            </div>
          </div>
        </div>
      </section>

      <section id="architecture" class="py-20 bg-gray-50">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="text-center mb-16">
            <h2 class="text-3xl md:text-4xl font-bold text-gray-900">
              系统架构与核心特性
            </h2>
            <div class="w-16 h-1 bg-primary mx-auto mt-6 rounded"></div>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-10">
            <div
              class="bg-white p-8 rounded-2xl shadow-sm hover:shadow-xl transition-shadow duration-300 border border-gray-100 group"
            >
              <div
                class="w-14 h-14 bg-blue-50 group-hover:bg-primary group-hover:text-white text-primary rounded-xl flex items-center justify-center text-2xl mb-6 transition-colors"
              >
                <i class="fa-solid fa-microchip"></i>
              </div>
              <h3 class="text-xl font-bold mb-3 text-gray-900">
                虚拟化计算资源池
              </h3>
              <p class="text-gray-500 leading-relaxed">
                基于底层硬件虚拟化技术，实现对 CPU
                与内存资源的动态划分与调度，为不同算力需求提供相互独立的运行环境与资源隔离。
              </p>
            </div>
            <div
              class="bg-white p-8 rounded-2xl shadow-sm hover:shadow-xl transition-shadow duration-300 border border-gray-100 group"
            >
              <div
                class="w-14 h-14 bg-green-50 group-hover:bg-green-500 group-hover:text-white text-green-600 rounded-xl flex items-center justify-center text-2xl mb-6 transition-colors"
              >
                <i class="fa-solid fa-network-wired"></i>
              </div>
              <h3 class="text-xl font-bold mb-3 text-gray-900">
                网络隔离与存储架构
              </h3>
              <p class="text-gray-500 leading-relaxed">
                通过逻辑隔离构建虚拟私有网络（VPC）划分不同子网，搭配分布式块存储逻辑，保障系统在多租户环境下的数据安全性。
              </p>
            </div>
            <div
              class="bg-white p-8 rounded-2xl shadow-sm hover:shadow-xl transition-shadow duration-300 border border-gray-100 group"
            >
              <div
                class="w-14 h-14 bg-purple-50 group-hover:bg-purple-500 group-hover:text-white text-purple-600 rounded-xl flex items-center justify-center text-2xl mb-6 transition-colors"
              >
                <i class="fa-solid fa-database"></i>
              </div>
              <h3 class="text-xl font-bold mb-3 text-gray-900">
                生命周期与计费管理
              </h3>
              <p class="text-gray-500 leading-relaxed">
                实现从实例创建、运行监控到资源释放的完整生命周期管理。同时结合系统时钟，提供包月及按量两套标准化的资源计费估算模型。
              </p>
            </div>
          </div>
        </div>
      </section>

      <section id="recommended-products" class="py-20 bg-white">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div
            class="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-6 mb-10"
          >
            <div>
              <h2 class="text-3xl md:text-4xl font-bold text-gray-900">
                热门产品推荐
              </h2>
              <p class="text-gray-500 mt-4 max-w-2xl">
                按云服务器类型快速选择热门配置，从个人项目到企业应用都可以直接进入选购。
              </p>
            </div>
            <div
              class="home-product-tabs bg-gray-100 rounded-lg p-1 text-xs sm:text-sm font-medium"
            >
              <button
                type="button"
                class="popular-product-tab active min-w-0 sm:flex-none px-2 sm:px-4 py-2 rounded-md whitespace-nowrap"
                data-popular-product-tab="basic"
              >
                通用服务器
              </button>
              <button
                type="button"
                class="popular-product-tab min-w-0 sm:flex-none px-2 sm:px-4 py-2 rounded-md whitespace-nowrap"
                data-popular-product-tab="business"
              >
                业务部署
              </button>
              <button
                type="button"
                class="popular-product-tab min-w-0 sm:flex-none px-2 sm:px-4 py-2 rounded-md whitespace-nowrap"
                data-popular-product-tab="gpu"
              >
                GPU 算力
              </button>
            </div>
          </div>

          <%-- 三标签卡片：由 /api/home 的 recommend 渲染，后台「首页推荐」管理 --%>
          <div
            data-popular-product-panel="basic"
            id="recommend-basic"
            class="popular-product-panel active"
          ></div>

          <div
            data-popular-product-panel="business"
            id="recommend-business"
            class="popular-product-panel"
          ></div>

          <div
            data-popular-product-panel="gpu"
            id="recommend-gpu"
            class="popular-product-panel"
          ></div>
        </div>
      </section>
    </main>

    <div id="site-footer"></div>
    <script src="assets/js/home.js?v=20260612-3"></script>
    <script src="assets/js/ai-guide.js?v=20260613-1"></script>
    <script src="assets/js/nav-auth.js?v=20260428-3"></script>
</body>
</html>
