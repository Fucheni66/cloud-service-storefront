// 云服务独立管理页面，根据 URL 参数 id 渲染服务管理信息。
$(function () {
  const serviceId = new URLSearchParams(window.location.search).get('id') || '';
  const services = getConsoleServices((window.CONSOLE_PAGE_CONFIG || {}).services || []);
  const service = services.find((item) => item.id === serviceId) || buildServiceFromId(serviceId);

  $('#console-manage-root').append(
    service ? renderManageView(service) : renderManageNotFound(serviceId)
  );
});

function getConsoleServices(configServices) {
  return [...getStoredPurchasedServices(), ...configServices]
    .filter((service) => !isDemoService(service))
    .map((service) => normalizeAllocatedService(service));
}

function normalizeAllocatedService(service) {
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
  try {
    const services = JSON.parse(localStorage.getItem('ajou_purchased_services') || '[]');
    return Array.isArray(services) ? services : [];
  } catch (error) {
    return [];
  }
}

function isDemoService(service) {
  return [
    'ecs-20260427001',
    'gpu-20260427002',
    'rds-20260427003',
    'cdn-20260427004',
  ].includes(service.id);
}

function buildServiceFromId(serviceId) {
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

function renderManageView(service) {
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
  return $('<div>', { class: 'flex items-center gap-3 border-b border-gray-100 py-2 min-w-0' }).append(
    $('<i>', { class: `${icon} text-gray-400 w-4 flex-shrink-0` }),
    $('<span>', { class: 'text-gray-400 text-xs w-16 flex-shrink-0', text: label }),
    $('<span>', { class: 'text-gray-800 font-medium truncate', title: value || '-', text: value || '-' })
  )[0];
}

function renderMetricCard(label, value, icon) {
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
  return $('<div>', { class: 'flex items-center justify-between border-b border-gray-100 pb-3 last:border-b-0 last:pb-0' }).append(
    $('<span>', { class: 'text-gray-500', text: label }),
    $('<span>', { class: 'font-medium text-gray-900 text-right', text: value || '-' })
  )[0];
}

function renderManageNotFound(serviceId) {
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
  return service.status === '资源分配中' ? '0%' : '18%';
}

function getMemoryUsage(service) {
  return service.status === '资源分配中' ? '0%' : '42%';
}

function getNetworkUsage(service) {
  return service.status === '资源分配中' ? '0%' : '26%';
}

function parseMetricPercent(value) {
  const percent = Number.parseInt(String(value).replace('%', ''), 10);
  return Number.isFinite(percent) ? Math.max(0, Math.min(100, percent)) : 0;
}

function formatDateTime(value) {
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
