// 使用 jQuery 根据控制台配置渲染用户已购买云服务列表。
$(async function () {
  // 控制台接口地址和默认展示配置由 console.config.js 注入。
  const config = window.CONSOLE_PAGE_CONFIG;

  // 配置缺失时直接停止，避免页面出现脚本错误。
  if (!config) {
    return;
  }

  // 兼容旧地址：console.html#订单号 自动跳转到独立管理页。
  if (redirectHashToManagePage()) {
    return;
  }

  // 先显示加载状态，再读取后端或本地购买记录。
  renderLoadingState();
  const services = await getConsoleServices(config);
  renderServiceCards(services);
});

async function getConsoleServices(config) {
  // 优先读取后端接口里的真实购买记录。
  const backendServices = await getBackendPurchasedServices(config);

  if (backendServices) {
    return backendServices.map((service) => normalizeAllocatedService(service));
  }

  // 后端请求失败时使用浏览器本地存储记录，并过滤旧的演示数据。
  return [...getStoredPurchasedServices(), ...(config.services || [])]
    .filter((service) => !isDemoService(service))
    .map((service) => normalizeAllocatedService(service));
}

async function getBackendPurchasedServices(config) {
  // 购买记录接口需要登录 token，没有 token 时返回空列表。
  const token = getAuthToken();

  if (!token) {
    return [];
  }

  try {
    // 使用 fetch 请求后端用户购买内容接口，接口地址从配置中拼接。
    const response = await fetch(buildConsoleApiUrl(config, config.purchasesPath || '/purchases'), {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    const data = await response.json();

    if (!response.ok || !data.success || !Array.isArray(data.items)) {
      throw new Error(data.message || data.error || '购买记录读取失败');
    }

    return data.items;
  } catch (error) {
    // 后端不可用时不阻断页面，回退到 localStorage 里的购买记录。
    console.warn('后端购买记录读取失败，使用本地记录：', error.message || error);
    return null;
  }
}

function normalizeAllocatedService(service) {
  // 支付完成后购买页可能先写入“资源分配中”，控制台统一展示为“分配成功”。
  if (service.status !== '资源分配中') {
    return service;
  }

  return {
    ...service,
    status: '分配成功',
    statusClass: 'bg-green-50 text-green-600 border-green-200',
  };
}

function getStoredPurchasedServices() {
  // 本地购买记录用于前端预览和后端不可用时的降级展示。
  try {
    const services = JSON.parse(localStorage.getItem('ajou_purchased_services') || '[]');
    return Array.isArray(services) ? services : [];
  } catch (error) {
    return [];
  }
}

function getAuthToken() {
  // token 可能单独存储，也可能保存在完整登录信息里，两处都兼容读取。
  const loginInfo = readJsonStorage('ajou_login_info');
  return localStorage.getItem('ajou_auth_token') || (loginInfo && loginInfo.token) || '';
}

function readJsonStorage(key) {
  // localStorage 里的 JSON 可能被用户手动修改，解析失败时返回 null。
  try {
    return JSON.parse(localStorage.getItem(key) || 'null');
  } catch (error) {
    return null;
  }
}

function buildConsoleApiUrl(config, path) {
  // 去掉 baseUrl 末尾多余斜杠，避免拼出双斜杠接口地址。
  const baseUrl = (config.apiBaseUrl || '').replace(/\/+$/, '');
  return `${baseUrl}${path || ''}`;
}

function isDemoService(service) {
  // 旧版页面内置的演示数据不再默认显示，只展示用户实际购买内容。
  const demoIds = [
    'ecs-20260427001',
    'gpu-20260427002',
    'rds-20260427003',
    'cdn-20260427004',
  ];

  return demoIds.includes(service.id);
}

function renderServiceCards(services) {
  // 每次渲染前清空容器，避免重复追加卡片。
  const container = $('#console-services').empty();

  if (!services.length) {
    // 没有购买记录时显示空状态和购买入口。
    container.append(renderEmptyState());
    return;
  }

  // services.map 返回 DOM 节点数组，jQuery append 会一次性插入。
  container.append(services.map((service) => renderServiceCard(service)));
}

function renderLoadingState() {
  // 数据请求过程中显示加载卡片，避免页面空白。
  $('#console-services').empty().append(
    $('<div>', { class: 'lg:col-span-2 bg-white rounded-xl border border-gray-200 shadow-sm p-10 text-center text-gray-500' }).append(
      $('<i>', { class: 'fa-solid fa-spinner fa-spin text-primary text-2xl mb-3' }),
      $('<div>', { class: 'text-sm', text: '正在读取购买记录...' })
    )
  );
}

function redirectHashToManagePage() {
  // 如果用户访问 console.html#order_id，自动转成 console-manage.html?id=order_id。
  const serviceId = decodeURIComponent(window.location.hash.replace('#', '').trim());

  if (!serviceId) {
    return false;
  }

  window.location.replace(`console-manage.html?id=${encodeURIComponent(serviceId)}`);
  return true;
}

function renderEmptyState() {
  // 空状态使用 jQuery 创建 DOM，避免在 HTML 中维护重复结构。
  return $('<div>', { class: 'lg:col-span-2 bg-white rounded-xl border border-gray-200 shadow-sm p-10 text-center' }).append(
    $('<div>', { class: 'w-14 h-14 rounded-full bg-blue-50 text-primary flex items-center justify-center mx-auto mb-4' }).append(
      $('<i>', { class: 'fa-solid fa-server text-2xl' })
    ),
    $('<h3>', { class: 'text-lg font-bold text-gray-900', text: '暂无已购买服务' }),
    $('<p>', { class: 'text-sm text-gray-500 mt-2', text: '购买成功后，资源会显示在这里。' }),
    $('<a>', { href: 'products.html', class: 'inline-flex items-center justify-center mt-5 bg-primary hover:bg-primary-hover text-white px-5 py-2.5 rounded text-sm font-medium transition shadow-sm', text: '去购买服务' })
  )[0];
}

function renderServiceCard(service) {
  // 单个云服务卡片：头部展示名称状态，中部展示规格信息，底部展示费用和操作入口。
  return $('<article>', { class: 'bg-white rounded-xl border border-gray-200 shadow-sm hover:shadow-md transition overflow-hidden' }).append(
    $('<div>', { class: 'p-6 border-b border-gray-100 flex items-start justify-between gap-4' }).append(
      $('<div>').append(
        $('<p>', { class: 'text-xs text-gray-500 mb-2', text: service.category }),
        $('<h3>', { class: 'text-lg font-bold text-gray-900', text: service.name }),
        $('<p>', { class: 'text-sm text-gray-500 mt-1', text: service.id })
      ),
      $('<span>', { class: `border text-xs font-medium px-2.5 py-1 rounded-full whitespace-nowrap ${service.statusClass}`, text: service.status })
    ),
    $('<div>', { class: 'p-6 grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm' }).append(
      renderMetaItem('规格', service.instance, 'fa-solid fa-microchip'),
      renderMetaItem('地域', service.region, 'fa-solid fa-location-dot'),
      renderMetaItem('公网 / 地址', service.publicIp, 'fa-solid fa-globe'),
      renderMetaItem('系统 / 类型', service.os, 'fa-solid fa-server'),
      renderMetaItem('存储', service.disk, 'fa-solid fa-hard-drive'),
      renderMetaItem('到期时间', service.expireAt, 'fa-solid fa-calendar-day')
    ),
    $('<div>', { class: 'px-6 py-4 bg-gray-50 flex flex-col sm:flex-row sm:items-center justify-between gap-3' }).append(
      $('<div>', { class: 'text-sm text-gray-600' }).append(
        $('<span>', { text: `${service.billing} · ` }),
        $('<span>', { class: 'text-[#FF6A00] font-bold', text: `¥${service.monthlyCost}` }),
        $('<span>', { text: ' / 月预估' })
      ),
      $('<div>', { class: 'flex gap-2' }).append(
        $('<a>', { href: 'purchase.html', class: 'px-3 py-2 rounded border border-gray-300 bg-white text-gray-700 hover:text-primary hover:border-primary text-sm transition', text: '续费' }),
        $('<a>', { href: `console-manage.html?id=${encodeURIComponent(service.id)}`, class: 'px-3 py-2 rounded bg-primary text-white hover:bg-primary-hover text-sm transition', text: '管理' })
      )
    )
  )[0];
}

function renderMetaItem(label, value, icon) {
  // 卡片里的“规格 / 地域 / 公网地址”等小字段统一由这个方法生成。
  return $('<div>', { class: 'flex items-start gap-3' }).append(
    $('<i>', { class: `${icon} text-gray-400 mt-1 w-4` }),
    $('<div>').append(
      $('<p>', { class: 'text-gray-400 text-xs mb-1', text: label }),
      $('<p>', { class: 'text-gray-700 font-medium', text: value })
    )
  )[0];
}
