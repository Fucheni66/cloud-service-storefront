// 云服务独立管理页面，根据 URL 参数 id 渲染服务管理信息。
let backendPurchasesLoaded = false;

$(async function () {
  // 管理页通过 console-manage.html?id=xxx 获取当前要管理的服务 ID。
  const serviceId = new URLSearchParams(window.location.search).get('id') || '';
  // 控制台接口地址和默认配置由 console.config.js 注入。
  const config = window.CONSOLE_PAGE_CONFIG || {};

  // 先显示加载状态，再读取后端或本地购买记录。
  renderManageLoading();
  const services = await getConsoleServices(config);
  // 优先从购买记录中匹配服务；后端未成功返回时允许根据订单号生成本地预览数据。
  const service = services.find((item) => item.id === serviceId) || (backendPurchasesLoaded ? null : buildServiceFromId(serviceId));

  // 使用 jQuery 清空根容器，再插入管理页主体或未找到提示。
  $('#console-manage-root').empty().append(
    service ? renderManageView(service) : renderManageNotFound(serviceId)
  );
});

async function getConsoleServices(config) {
  // 优先读取后端真实购买记录。
  const backendServices = await getBackendPurchasedServices(config);

  if (backendServices) {
    return backendServices.map((service) => normalizeAllocatedService(service));
  }

  // 后端不可用时，回退到浏览器本地购买记录，并过滤旧版演示数据。
  return [...getStoredPurchasedServices(), ...(config.services || [])]
    .filter((service) => !isDemoService(service))
    .map((service) => normalizeAllocatedService(service));
}

async function getBackendPurchasedServices(config) {
  // 后端购买记录接口需要登录 token，没有 token 时返回空列表。
  const token = getAuthToken();

  if (!token) {
    return [];
  }

  try {
    // 根据配置拼接接口地址，请求当前用户已购买的服务列表。
    const response = await fetch(buildConsoleApiUrl(config, config.purchasesPath || '/purchases'), {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    const data = await response.json();

    if (!response.ok || !data.success || !Array.isArray(data.items)) {
      throw new Error(data.message || data.error || '购买记录读取失败');
    }

    backendPurchasesLoaded = true;
    return data.items;
  } catch (error) {
    // 后端不可用时不阻断页面，继续使用 localStorage 降级展示。
    console.warn('后端购买记录读取失败，使用本地记录：', error.message || error);
    return null;
  }
}

function normalizeAllocatedService(service) {
  // 支付成功后可能先写入“资源分配中”，管理页统一展示为“分配成功”。
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
  // 本地购买记录用于前端预览，也作为后端接口失败时的兜底数据。
  try {
    const services = JSON.parse(localStorage.getItem('ajou_purchased_services') || '[]');
    return Array.isArray(services) ? services : [];
  } catch (error) {
    return [];
  }
}

function getAuthToken() {
  // token 可能单独存储，也可能保存在完整登录信息中，两种方式都兼容。
  const loginInfo = readJsonStorage('ajou_login_info');
  return localStorage.getItem('ajou_auth_token') || (loginInfo && loginInfo.token) || '';
}

function readJsonStorage(key) {
  // localStorage 内容可能不是合法 JSON，解析失败时返回 null。
  try {
    return JSON.parse(localStorage.getItem(key) || 'null');
  } catch (error) {
    return null;
  }
}

function buildConsoleApiUrl(config, path) {
  // 去掉 apiBaseUrl 末尾斜杠，避免拼接出重复斜杠。
  const baseUrl = (config.apiBaseUrl || '').replace(/\/+$/, '');
  return `${baseUrl}${path || ''}`;
}

function isDemoService(service) {
  // 控制台默认不显示旧版静态演示服务，只展示实际购买记录。
  return [
    'ecs-20260427001',
    'gpu-20260427002',
    'rds-20260427003',
    'cdn-20260427004',
  ].includes(service.id);
}

function buildServiceFromId(serviceId) {
  // 本地预览兼容：从 pay_规格_时间戳 这样的订单号里反推出服务信息。
  const match = serviceId.match(/^pay_(.+)_\d+$/);

  if (!match) {
    return null;
  }

  const instanceMap = {
    '2c4g': '2核 4G',
    '4c8g': '4核 8G',
    '8c16g': '8核 16G',
    gpu_t4: '4核 16G + NVIDIA T4',
    gpu_a100: '12核 96G + NVIDIA A100',
  };
  const instance = instanceMap[match[1]] || match[1];
  const isGpu = match[1].startsWith('gpu');

  return {
    id: serviceId,
    name: `${instance} 云服务器`,
    category: isGpu ? 'GPU 云服务器' : '云服务器 ECS',
    instance,
    region: '华北2(北京)',
    status: '分配成功',
    statusClass: 'bg-green-50 text-green-600 border-green-200',
    publicIp: '39.105.18.26',
    os: 'Ubuntu 22.04 LTS',
    disk: '40GB 通用型SSD',
    billing: '按量计费',
    expireAt: '按量资源',
    monthlyCost: '0.00',
    paidAt: new Date().toISOString(),
  };
}

function renderManageLoading() {
  // 数据读取过程中显示加载卡片，避免页面主体空白。
  $('#console-manage-root').empty().append(
    $('<div>', { class: 'bg-white rounded-xl border border-gray-200 shadow-sm p-10 text-center text-gray-500' }).append(
      $('<i>', { class: 'fa-solid fa-spinner fa-spin text-primary text-2xl mb-3' }),
      $('<div>', { class: 'text-sm', text: '正在读取云服务信息...' })
    )
  );
}

function renderManageView(service) {
  // 管理页整体结构：顶部服务信息，左侧监控/网络/日志，右侧操作/费用/支持。
  return $('<div>', { class: 'space-y-6' }).append(
    renderManageHeader(service),
    $('<div>', { class: 'grid grid-cols-1 xl:grid-cols-[1fr_340px] gap-6' }).append(
      $('<div>', { class: 'space-y-6' }).append(
        renderMonitorPanel(service),
        renderNetworkPanel(service),
        renderOperationLog(service)
      ),
      $('<aside>', { class: 'space-y-6' }).append(
        renderActionPanel(service),
        renderBillingPanel(service),
        renderSupportPanel()
      )
    )
  )[0];
}

function renderManageHeader(service) {
  // 管理页头部展示服务名称、状态、规格标签和主要操作入口。
  return $('<div>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<div>', { class: 'flex flex-col lg:flex-row lg:items-start lg:justify-between gap-5' }).append(
      $('<div>').append(
        $('<div>', { class: 'flex flex-wrap items-center gap-3' }).append(
          $('<h2>', { class: 'text-2xl font-bold text-gray-900', text: service.name }),
          $('<span>', { class: `border text-xs font-medium px-2.5 py-1 rounded-full whitespace-nowrap ${service.statusClass}`, text: service.status })
        ),
        $('<p>', { class: 'text-sm text-gray-500 mt-2 font-mono break-all', text: service.id }),
        $('<div>', { class: 'flex flex-wrap gap-2 mt-4 text-xs text-gray-500' }).append(
          $('<span>', { class: 'px-2 py-1 bg-gray-50 border border-gray-100 rounded', text: service.category }),
          $('<span>', { class: 'px-2 py-1 bg-gray-50 border border-gray-100 rounded', text: service.instance }),
          $('<span>', { class: 'px-2 py-1 bg-gray-50 border border-gray-100 rounded', text: service.region })
        )
      ),
      $('<div>', { class: 'flex flex-wrap gap-2' }).append(
        $('<a>', { href: 'console.html', class: 'inline-flex items-center px-4 py-2 rounded border border-gray-300 bg-white text-gray-700 hover:text-primary hover:border-primary text-sm transition' }).append(
          $('<i>', { class: 'fa-solid fa-arrow-left mr-2 text-xs' }),
          '返回列表'
        ),
        $('<a>', { href: 'purchase.html', class: 'inline-flex items-center px-4 py-2 rounded bg-primary text-white hover:bg-primary-hover text-sm transition' }).append(
          $('<i>', { class: 'fa-solid fa-plus mr-2 text-xs' }),
          '购买新服务'
        )
      )
    )
  )[0];
}

function renderNetworkPanel(service) {
  // 连接与网络信息压缩展示，方便快速查看公网 IP、登录用户、端口和系统盘。
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-5 shadow-sm' }).append(
    $('<h3>', { class: 'text-base font-bold text-gray-900 mb-4', text: '连接与网络' }),
    $('<div>', { class: 'grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-2 text-sm' }).append(
      renderCompactInfoItem('公网 IP', service.publicIp, 'fa-solid fa-globe'),
      renderCompactInfoItem('登录用户', service.os && service.os.includes('Windows') ? 'Administrator' : 'root', 'fa-solid fa-user-shield'),
      renderCompactInfoItem('开放端口', service.os && service.os.includes('Windows') ? '3389 / 80 / 443' : '22 / 80 / 443', 'fa-solid fa-shield-halved'),
      renderCompactInfoItem('安全组', 'default-web-access', 'fa-solid fa-lock'),
      renderCompactInfoItem('系统镜像', service.os, 'fa-solid fa-server'),
      renderCompactInfoItem('系统盘', service.disk, 'fa-solid fa-hard-drive')
    )
  )[0];
}

function renderMonitorPanel(service) {
  // 监控概览放在管理内容最上方，展示 CPU、内存和公网流量。
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<div>', { class: 'flex items-center justify-between gap-4 mb-5' }).append(
      $('<h3>', { class: 'text-lg font-bold text-gray-900', text: '监控概览' }),
      $('<span>', { class: 'text-xs text-gray-400', text: '最近 1 小时' })
    ),
    $('<div>', { class: 'grid grid-cols-1 md:grid-cols-3 gap-4' }).append(
      renderMetricCard('CPU 使用率', getCpuUsage(service), 'fa-solid fa-chart-line'),
      renderMetricCard('内存使用率', getMemoryUsage(service), 'fa-solid fa-memory'),
      renderMetricCard('公网流量', getNetworkUsage(service), 'fa-solid fa-network-wired')
    )
  )[0];
}

function renderOperationLog(service) {
  // 操作日志用于展示购买后资源写入、支付成功和订单创建记录。
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<h3>', { class: 'text-lg font-bold text-gray-900 mb-5', text: '操作日志' }),
    $('<div>', { class: 'space-y-4 text-sm' }).append(
      renderLogItem('资源写入控制台', formatDateTime(service.paidAt), 'fa-solid fa-check'),
      renderLogItem('支付成功', formatDateTime(service.paidAt), 'fa-solid fa-credit-card'),
      renderLogItem('订单创建', service.id, 'fa-solid fa-file-lines')
    )
  )[0];
}

function renderActionPanel(service) {
  // 实例操作面板只做前端展示；资源分配中时禁用不可操作按钮。
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<h3>', { class: 'text-lg font-bold text-gray-900 mb-4', text: '实例操作' }),
    $('<div>', { class: 'grid grid-cols-2 gap-3' }).append(
      renderActionButton('启动', 'fa-solid fa-play', service.status !== '运行中'),
      renderActionButton('停止', 'fa-solid fa-stop', service.status === '资源分配中'),
      renderActionButton('重启', 'fa-solid fa-rotate-right', service.status === '资源分配中'),
      renderActionButton('重装系统', 'fa-solid fa-compact-disc', service.status === '资源分配中')
    ),
    $('<p>', { class: 'text-xs text-gray-400 mt-4 leading-5', text: '当前为本地控制台预览，操作按钮仅展示管理入口状态。' })
  )[0];
}

function renderBillingPanel(service) {
  // 费用信息从购买记录中读取，统一展示计费方式、月预估和到期时间。
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<h3>', { class: 'text-lg font-bold text-gray-900 mb-4', text: '费用信息' }),
    $('<div>', { class: 'space-y-3 text-sm' }).append(
      renderBillingRow('计费方式', service.billing),
      renderBillingRow('月预估', `¥${service.monthlyCost}`),
      renderBillingRow('到期时间', service.expireAt)
    ),
    $('<a>', { href: 'purchase.html', class: 'mt-5 inline-flex w-full items-center justify-center bg-primary hover:bg-primary-hover text-white px-4 py-2.5 rounded text-sm font-medium transition' }).append(
      '续费 / 升配',
      $('<i>', { class: 'fa-solid fa-arrow-right ml-2 text-xs' })
    )
  )[0];
}

function renderSupportPanel() {
  // 支持入口统一跳转到产品动态详情页里的帮助文章。
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<h3>', { class: 'text-lg font-bold text-gray-900 mb-4', text: '支持入口' }),
    $('<div>', { class: 'space-y-3 text-sm' }).append(
      $('<a>', { href: 'product-dynamics-detail.html?id=support-help', class: 'flex items-center justify-between text-gray-600 hover:text-primary' }).append(
        $('<span>').append($('<i>', { class: 'fa-solid fa-circle-question mr-2 text-primary' }), '帮助中心'),
        $('<i>', { class: 'fa-solid fa-angle-right text-xs' })
      ),
      $('<a>', { href: 'product-dynamics-detail.html?id=support-ticket', class: 'flex items-center justify-between text-gray-600 hover:text-primary' }).append(
        $('<span>').append($('<i>', { class: 'fa-solid fa-headset mr-2 text-primary' }), '提交工单'),
        $('<i>', { class: 'fa-solid fa-angle-right text-xs' })
      )
    )
  )[0];
}

function renderInfoItem(label, value, icon) {
  // 普通信息项组件，保留给后续扩展更多概览字段使用。
  return $('<div>', { class: 'border border-gray-200 rounded-lg p-4 min-h-[92px]' }).append(
    $('<div>', { class: 'flex items-start gap-3' }).append(
      $('<i>', { class: `${icon} text-gray-400 mt-1 w-4` }),
      $('<div>', { class: 'min-w-0' }).append(
        $('<p>', { class: 'text-gray-400 text-xs mb-1', text: label }),
        $('<p>', { class: 'text-gray-800 font-medium break-all', text: value || '-' })
      )
    )
  )[0];
}

function renderCompactInfoItem(label, value, icon) {
  // 连接与网络面板使用的紧凑信息项，长文本用 title 保留完整内容。
  return $('<div>', { class: 'flex items-center gap-3 border-b border-gray-100 py-2 min-w-0' }).append(
    $('<i>', { class: `${icon} text-gray-400 w-4 flex-shrink-0` }),
    $('<span>', { class: 'text-gray-400 text-xs w-16 flex-shrink-0', text: label }),
    $('<span>', { class: 'text-gray-800 font-medium truncate', title: value || '-', text: value || '-' })
  )[0];
}

function renderMetricCard(label, value, icon) {
  // 监控指标卡片，下方进度条根据百分比数值自动设置宽度。
  return $('<div>', { class: 'border border-gray-200 rounded-lg p-4' }).append(
    $('<div>', { class: 'flex items-center justify-between mb-3' }).append(
      $('<span>', { class: 'text-sm text-gray-500', text: label }),
      $('<i>', { class: `${icon} text-gray-400` })
    ),
    $('<div>', { class: 'text-2xl font-bold text-gray-900', text: value }),
    $('<div>', { class: 'mt-3 h-2 bg-gray-100 rounded overflow-hidden' }).append(
      $('<div>', { class: 'h-full bg-primary rounded', style: `width: ${parseMetricPercent(value)}%;` })
    )
  )[0];
}

function renderLogItem(title, description, icon) {
  // 操作日志单行组件，左侧为图标，右侧为标题和说明。
  return $('<div>', { class: 'flex items-start gap-3' }).append(
    $('<div>', { class: 'w-8 h-8 rounded-full bg-blue-50 text-primary flex items-center justify-center flex-shrink-0' }).append(
      $('<i>', { class: `${icon} text-xs` })
    ),
    $('<div>').append(
      $('<div>', { class: 'font-medium text-gray-900', text: title }),
      $('<div>', { class: 'text-xs text-gray-400 mt-1 break-all', text: description || '-' })
    )
  )[0];
}

function renderActionButton(label, icon, disabled) {
  // 根据 disabled 参数切换按钮可用和不可用样式。
  return $('<button>', {
    type: 'button',
    disabled,
    class: `inline-flex items-center justify-center px-3 py-2 rounded border text-sm transition ${
      disabled
        ? 'border-gray-200 bg-gray-50 text-gray-400 cursor-not-allowed'
        : 'border-gray-300 bg-white text-gray-700 hover:text-primary hover:border-primary'
    }`,
  }).append(
    $('<i>', { class: `${icon} mr-2 text-xs` }),
    label
  )[0];
}

function renderBillingRow(label, value) {
  // 费用信息里的键值行组件。
  return $('<div>', { class: 'flex items-center justify-between border-b border-gray-100 pb-3 last:border-b-0 last:pb-0' }).append(
    $('<span>', { class: 'text-gray-500', text: label }),
    $('<span>', { class: 'font-medium text-gray-900 text-right', text: value || '-' })
  )[0];
}

function renderManageNotFound(serviceId) {
  // URL 缺少 id 或购买记录中找不到对应服务时展示此状态。
  return $('<div>', { class: 'bg-white rounded-xl border border-gray-200 shadow-sm p-10 text-center' }).append(
    $('<div>', { class: 'w-14 h-14 rounded-full bg-red-50 text-red-500 flex items-center justify-center mx-auto mb-4' }).append(
      $('<i>', { class: 'fa-solid fa-triangle-exclamation text-2xl' })
    ),
    $('<h2>', { class: 'text-xl font-bold text-gray-900', text: '未找到云服务' }),
    $('<p>', { class: 'text-sm text-gray-500 mt-2 break-all', text: serviceId ? `当前订单或服务不存在：${serviceId}` : '缺少服务 ID。' }),
    $('<a>', { href: 'console.html', class: 'inline-flex items-center justify-center mt-5 bg-primary hover:bg-primary-hover text-white px-5 py-2.5 rounded text-sm font-medium transition shadow-sm', text: '返回控制台' })
  )[0];
}

function getCpuUsage(service) {
  // 本地预览监控数据：资源未分配时显示 0%，分配后显示固定示例值。
  return service.status === '资源分配中' ? '0%' : '18%';
}

function getMemoryUsage(service) {
  // 本地预览监控数据：资源未分配时显示 0%，分配后显示固定示例值。
  return service.status === '资源分配中' ? '0%' : '42%';
}

function getNetworkUsage(service) {
  // 本地预览监控数据：资源未分配时显示 0%，分配后显示固定示例值。
  return service.status === '资源分配中' ? '0%' : '26%';
}

function parseMetricPercent(value) {
  // 把“18%”这样的文本转换成 0-100 之间的数字，用于进度条宽度。
  const percent = Number.parseInt(String(value).replace('%', ''), 10);
  return Number.isFinite(percent) ? Math.max(0, Math.min(100, percent)) : 0;
}

function formatDateTime(value) {
  // 把 ISO 时间转换成页面展示用的 yyyy-mm-dd hh:mm。
  if (!value) {
    return '-';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  const pad = (number) => String(number).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}
