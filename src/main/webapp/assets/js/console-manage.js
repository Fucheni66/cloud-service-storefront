// 云服务独立管理页面：根据 URL 参数 id 渲染实例信息，并提供「实时监控 + 模拟运维操作」。
// 监控数据（CPU/内存/磁盘/带宽）在前端按秒级随机游走模拟变化；
// 开机/关机/重启/重装系统为模拟操作（无真实后端调用），带状态机、进度反馈与操作日志。
let backendPurchasesLoaded = false;

$(async function () {
  const serviceId = new URLSearchParams(window.location.search).get('id') || '';

  const config = window.CONSOLE_PAGE_CONFIG || {};

  renderManageLoading();
  const services = await getConsoleServices(config);

  const service = services.find((item) => item.id === serviceId) || (backendPurchasesLoaded ? null : buildServiceFromId(serviceId));

  $('#console-manage-root').empty().append(
    service ? renderManageView(service) : renderManageNotFound(serviceId)
  );
});

async function getConsoleServices(config) {
  const backendServices = await getBackendPurchasedServices(config);

  if (backendServices) {
    return backendServices.map((service) => normalizeAllocatedService(service));
  }

  return [...getStoredPurchasedServices(), ...(config.services || [])]
    .filter((service) => !isDemoService(service))
    .map((service) => normalizeAllocatedService(service));
}

async function getBackendPurchasedServices(config) {
  const token = getAuthToken();

  if (!token) {
    return [];
  }

  try {
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
    console.warn('后端购买记录读取失败，使用本地记录：', error.message || error);
    return null;
  }
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

function getAuthToken() {
  const loginInfo = readJsonStorage('ajou_login_info');
  return localStorage.getItem('ajou_auth_token') || (loginInfo && loginInfo.token) || '';
}

function readJsonStorage(key) {
  try {
    return JSON.parse(localStorage.getItem(key) || 'null');
  } catch (error) {
    return null;
  }
}

function buildConsoleApiUrl(config, path) {
  const baseUrl = (config.apiBaseUrl || '').replace(/\/+$/, '');
  return `${baseUrl}${path || ''}`;
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
  if (!serviceId) {
    return null;
  }

  const instanceMap = {
    '2c4g': '2核 4G',
    '4c8g': '4核 8G',
    '8c16g': '8核 16G',
    gpu_t4: '4核 16G + NVIDIA T4',
    gpu_a100: '12核 96G + NVIDIA A100',
  };

  // 支持 pay_<code>_<ts> 形式，也兼容任意 id（演示用占位实例）
  const match = serviceId.match(/^pay_(.+)_\d+$/);
  const code = match ? match[1] : '2c4g';
  const instance = instanceMap[code] || code;
  const isGpu = code.startsWith('gpu');

  return {
    id: serviceId,
    name: `${instance} 云服务器`,
    category: isGpu ? 'GPU 云服务器' : '云服务器 ECS',
    instance,
    region: '华北2(北京)',
    status: '运行中',
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
  $('#console-manage-root').empty().append(
    $('<div>', { class: 'bg-white rounded-xl border border-gray-200 shadow-sm p-10 text-center text-gray-500' }).append(
      $('<i>', { class: 'fa-solid fa-spinner fa-spin text-primary text-2xl mb-3' }),
      $('<div>', { class: 'text-sm', text: '正在读取云服务信息...' })
    )
  );
}

// ===================== 模拟运维：状态机与上下文 =====================

const POWER = {
  ON: 'on',
  OFF: 'off',
  STARTING: 'starting',
  STOPPING: 'stopping',
  RESTARTING: 'restarting',
  REBUILDING: 'rebuilding',
};

const OS_IMAGES = ['Ubuntu 22.04 LTS', 'CentOS 7.9', 'Debian 12', 'AlmaLinux 9', 'Windows Server 2022'];

let simTimer = null; // 监控定时器
let ctx = null;      // 当前渲染上下文

function powerMeta(power) {
  switch (power) {
    case POWER.ON: return { label: '运行中', cls: 'bg-green-50 text-green-600 border-green-200', dot: '#16a34a', spin: false };
    case POWER.OFF: return { label: '已停止', cls: 'bg-gray-100 text-gray-500 border-gray-200', dot: '#9ca3af', spin: false };
    case POWER.STARTING: return { label: '启动中', cls: 'bg-orange-50 text-orange-600 border-orange-200', dot: '#ea580c', spin: true };
    case POWER.STOPPING: return { label: '关机中', cls: 'bg-orange-50 text-orange-600 border-orange-200', dot: '#ea580c', spin: true };
    case POWER.RESTARTING: return { label: '重启中', cls: 'bg-orange-50 text-orange-600 border-orange-200', dot: '#ea580c', spin: true };
    case POWER.REBUILDING: return { label: '重装中', cls: 'bg-orange-50 text-orange-600 border-orange-200', dot: '#ea580c', spin: true };
    default: return { label: '未知', cls: 'bg-gray-100 text-gray-500 border-gray-200', dot: '#9ca3af', spin: false };
  }
}

function stateStorageKey(id) {
  return 'ajou_console_state_' + id;
}

function loadInstanceState(service) {
  const saved = readJsonStorage(stateStorageKey(service.id)) || {};
  const defaultPower = service.status === '运行中' ? POWER.ON : POWER.OFF;
  const power = (saved.power === POWER.ON || saved.power === POWER.OFF) ? saved.power : defaultPower;
  return { power, os: saved.os || service.os };
}

function saveInstanceState() {
  if (!ctx) {
    return;
  }
  // 过渡态不落库，统一记为稳定态
  const stable = (ctx.state.power === POWER.ON || ctx.state.power === POWER.OFF) ? ctx.state.power : POWER.ON;
  try {
    localStorage.setItem(stateStorageKey(ctx.service.id), JSON.stringify({ power: stable, os: ctx.state.os }));
  } catch (error) {
    /* localStorage 不可用时忽略 */
  }
}

function renderManageView(service) {
  if (simTimer) {
    clearInterval(simTimer);
    simTimer = null;
  }

  const saved = loadInstanceState(service);
  service.os = saved.os || service.os; // 反映已持久化的重装结果

  ctx = {
    service,
    state: { power: saved.power, os: saved.os || service.os },
    metrics: { cpu: 0, mem: 0, disk: 0, net: 0 },
    history: { cpu: [], mem: [], disk: [], net: [] },
    logs: [],
    busy: false,
    activeOp: null,
  };

  if (ctx.state.power === POWER.ON) {
    seedMetrics();
  } else {
    resetMetricsZero();
  }

  seedInitialLogs(service);

  const view = $('<div>', { class: 'space-y-6' }).append(
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
  );

  // 首次渲染动态区 + 启动监控轮询
  setTimeout(function () {
    applyAll();
    startSimulation();
  }, 0);

  return view[0];
}

function renderManageHeader(service) {
  const expired = service.status === '已到期';
  return $('<div>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<div>', { class: 'flex flex-col lg:flex-row lg:items-start lg:justify-between gap-5' }).append(
      $('<div>').append(
        $('<div>', { class: 'flex flex-wrap items-center gap-3' }).append(
          $('<h2>', { class: 'text-2xl font-bold text-gray-900', text: service.name }),
          $('<span>', { id: 'cm-status', class: 'inline-flex items-center' }),
          expired ? $('<span>', { class: 'border bg-red-50 text-red-500 border-red-200 text-xs font-medium px-2.5 py-1 rounded-full whitespace-nowrap', text: '已到期' }) : null
        ),
        $('<p>', { class: 'text-sm text-gray-500 mt-2 font-mono break-all', text: service.id }),
        $('<div>', { class: 'flex flex-wrap gap-2 mt-4 text-xs text-gray-500' }).append(
          $('<span>', { class: 'px-2 py-1 bg-gray-50 border border-gray-100 rounded', text: service.category }),
          $('<span>', { class: 'px-2 py-1 bg-gray-50 border border-gray-100 rounded', text: service.instance }),
          $('<span>', { class: 'px-2 py-1 bg-gray-50 border border-gray-100 rounded', text: service.region })
        )
      ),
      $('<div>', { class: 'flex flex-wrap gap-2' }).append(
        $('<a>', { href: 'console.jsp', class: 'inline-flex items-center px-4 py-2 rounded border border-gray-300 bg-white text-gray-700 hover:text-primary hover:border-primary text-sm transition' }).append(
          $('<i>', { class: 'fa-solid fa-arrow-left mr-2 text-xs' }),
          '返回列表'
        ),
        $('<a>', { href: 'purchase.jsp', class: 'inline-flex items-center px-4 py-2 rounded bg-primary text-white hover:bg-primary-hover text-sm transition' }).append(
          $('<i>', { class: 'fa-solid fa-plus mr-2 text-xs' }),
          '购买新服务'
        )
      )
    )
  )[0];
}

function renderMonitorPanel() {
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<div>', { class: 'flex items-center justify-between gap-4 mb-5' }).append(
      $('<h3>', { class: 'text-lg font-bold text-gray-900', text: '监控概览' }),
      $('<span>', { class: 'text-xs text-gray-400', text: '每 2 秒刷新 · 本机实时监控' })
    ),
    $('<div>', { id: 'cm-monitor-body' })
  )[0];
}

function renderNetworkPanel(service) {
  return $('<section>', { id: 'cm-network', class: 'bg-white border border-gray-200 rounded-xl p-5 shadow-sm' }).append(
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

function renderOperationLog() {
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<h3>', { class: 'text-lg font-bold text-gray-900 mb-5', text: '操作日志' }),
    $('<div>', { id: 'cm-log', class: 'space-y-4 text-sm' })
  )[0];
}

function renderActionPanel() {
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<h3>', { class: 'text-lg font-bold text-gray-900 mb-4', text: '实例操作' }),
    $('<div>', { id: 'cm-actions', class: 'grid grid-cols-2 gap-3' }),
    $('<p>', { class: 'text-xs text-gray-400 mt-4 leading-5', text: '以下为模拟运维操作：开机 / 关机 / 重启 / 重装系统会实时改变实例状态与监控数据（不影响真实资源）。' })
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
    $('<a>', { href: 'purchase.jsp', class: 'mt-5 inline-flex w-full items-center justify-center bg-primary hover:bg-primary-hover text-white px-4 py-2.5 rounded text-sm font-medium transition' }).append(
      '续费 / 升配',
      $('<i>', { class: 'fa-solid fa-arrow-right ml-2 text-xs' })
    )
  )[0];
}

function renderSupportPanel() {
  return $('<section>', { class: 'bg-white border border-gray-200 rounded-xl p-6 shadow-sm' }).append(
    $('<h3>', { class: 'text-lg font-bold text-gray-900 mb-4', text: '支持入口' }),
    $('<div>', { class: 'space-y-3 text-sm' }).append(
      $('<a>', { href: 'product-dynamics-detail.jsp?id=support-help', class: 'flex items-center justify-between text-gray-600 hover:text-primary' }).append(
        $('<span>').append($('<i>', { class: 'fa-solid fa-circle-question mr-2 text-primary' }), '帮助中心'),
        $('<i>', { class: 'fa-solid fa-angle-right text-xs' })
      ),
      $('<a>', { href: 'product-dynamics-detail.jsp?id=support-ticket', class: 'flex items-center justify-between text-gray-600 hover:text-primary' }).append(
        $('<span>').append($('<i>', { class: 'fa-solid fa-headset mr-2 text-primary' }), '提交工单'),
        $('<i>', { class: 'fa-solid fa-angle-right text-xs' })
      )
    )
  )[0];
}

// ===================== 监控数据模拟 =====================

function walk(cur, min, max, step) {
  let next = cur + (Math.random() * 2 - 1) * step;
  if (Math.random() < 0.12) {
    next += (Math.random() * 2 - 1) * 22; // 偶发尖峰
  }
  return Math.round(Math.max(min, Math.min(max, next)));
}

function seedMetrics() {
  let c = { cpu: 14, mem: 46, disk: 12, net: 10 };
  const H = { cpu: [], mem: [], disk: [], net: [] };
  for (let i = 0; i < 30; i++) {
    c = {
      cpu: walk(c.cpu, 4, 92, 7),
      mem: walk(c.mem, 30, 82, 4),
      disk: walk(c.disk, 0, 70, 8),
      net: walk(c.net, 0, 95, 11),
    };
    H.cpu.push(c.cpu); H.mem.push(c.mem); H.disk.push(c.disk); H.net.push(c.net);
  }
  ctx.metrics = { ...c };
  ctx.history = H;
}

function resetMetricsZero() {
  ctx.metrics = { cpu: 0, mem: 0, disk: 0, net: 0 };
  ctx.history = { cpu: Array(30).fill(0), mem: Array(30).fill(0), disk: Array(30).fill(0), net: Array(30).fill(0) };
}

// 监控数据来源：优先调用本机真实监控接口 /api/system-monitor（CPU/内存/磁盘/带宽）；
// 接口不可用（未登录/出错）时降级为本地随机游走，保证 UI 仍有动效。
let monitorInFlight = false;

function startSimulation() {
  simTimer = setInterval(tickMetrics, 2000);
}

async function tickMetrics() {
  const { state, metrics, history } = ctx;

  if (state.power !== POWER.ON) {
    metrics.cpu = 0; metrics.mem = 0; metrics.disk = 0; metrics.net = 0;
    pushHistory();
    renderMetrics();
    return;
  }

  const real = await fetchRealMetrics();
  if (real) {
    metrics.cpu = real.cpu;
    metrics.mem = real.mem;
    metrics.disk = real.disk;
    metrics.net = real.net;
  } else {
    // 降级：本地随机游走
    metrics.cpu = walk(metrics.cpu, 4, 94, 7);
    metrics.mem = walk(metrics.mem, 30, 84, 4);
    metrics.disk = walk(metrics.disk, 0, 72, 9);
    metrics.net = walk(metrics.net, 0, 96, 12);
  }
  pushHistory();
  renderMetrics();
}

function pushHistory() {
  const { metrics, history } = ctx;
  ['cpu', 'mem', 'disk', 'net'].forEach(function (k) {
    history[k].push(metrics[k]);
    if (history[k].length > 30) { history[k].shift(); }
  });
}

async function fetchRealMetrics() {
  if (monitorInFlight) {
    return null;
  }
  const config = window.CONSOLE_PAGE_CONFIG || {};
  const path = config.monitorPath;
  const token = getAuthToken();
  if (!path || !token) {
    return null;
  }
  monitorInFlight = true;
  try {
    const response = await fetch(buildConsoleApiUrl(config, path), {
      headers: { Authorization: `Bearer ${token}` },
    });
    const data = await response.json();
    if (!response.ok || !data.success) {
      return null;
    }
    return {
      cpu: clampMetric(data.cpu),
      mem: clampMetric(data.mem),
      disk: clampMetric(data.disk),
      net: Math.max(0, Math.round(Number(data.net) || 0)),
    };
  } catch (error) {
    return null;
  } finally {
    monitorInFlight = false;
  }
}

function clampMetric(v) {
  const n = Math.round(Number(v) || 0);
  return Math.max(0, Math.min(100, n));
}

function linePath(vals, w, h) {
  if (!vals || !vals.length) { return ''; }
  const n = vals.length;
  return vals.map(function (v, i) {
    const x = (n === 1 ? 0 : (i / (n - 1)) * w).toFixed(1);
    const y = (h - (Math.max(0, Math.min(100, v)) / 100) * h).toFixed(1);
    return (i === 0 ? 'M' : 'L') + x + ' ' + y;
  }).join(' ');
}

function areaPath(vals, w, h) {
  const lp = linePath(vals, w, h);
  return lp ? `${lp} L ${w} ${h} L 0 ${h} Z` : '';
}

function sparkSvg(vals, color) {
  const w = 100;
  const h = 28;
  return `<svg viewBox="0 0 ${w} ${h}" preserveAspectRatio="none" style="width:100%;height:28px">`
    + `<path d="${areaPath(vals, w, h)}" fill="${color}" fill-opacity="0.10"></path>`
    + `<path d="${linePath(vals, w, h)}" fill="none" stroke="${color}" stroke-width="1.5" stroke-linejoin="round"></path>`
    + `</svg>`;
}

function metricTile(label, value, unit, color, vals) {
  return `<div class="border border-gray-200 rounded-lg p-4">`
    + `<div class="flex items-center justify-between mb-1">`
    + `<span class="text-sm text-gray-500">${label}</span>`
    + `<span class="text-lg font-bold text-gray-900">${value}<span class="text-xs text-gray-400 font-normal ml-0.5">${unit}</span></span>`
    + `</div>`
    + sparkSvg(vals, color)
    + `</div>`;
}

function renderMetrics() {
  const body = document.getElementById('cm-monitor-body');
  if (!body || !ctx) { return; }

  const live = ctx.state.power === POWER.ON;
  const m = ctx.metrics;
  const H = ctx.history;

  // CPU 主图
  const cw = 320;
  const ch = 96;
  const grid = [24, 48, 72].map(function (y) {
    return `<line x1="0" y1="${y}" x2="${cw}" y2="${y}" stroke="#f1f5f9" stroke-width="1"></line>`;
  }).join('');
  const chart = `<svg viewBox="0 0 ${cw} ${ch}" preserveAspectRatio="none" style="width:100%;height:120px">`
    + grid
    + `<path d="${areaPath(H.cpu, cw, ch)}" fill="#0052d9" fill-opacity="0.10"></path>`
    + `<path d="${linePath(H.cpu, cw, ch)}" fill="none" stroke="#0052d9" stroke-width="2" stroke-linejoin="round"></path>`
    + `</svg>`;

  const liveDot = `<span style="display:inline-block;width:8px;height:8px;border-radius:9999px;background:${live ? '#16a34a' : '#9ca3af'};margin-right:6px"></span>`;
  const liveText = live
    ? `<span class="text-xs text-green-600 font-medium">实时</span>`
    : `<span class="text-xs text-gray-400 font-medium">实例已停止，无监控数据</span>`;

  body.innerHTML =
    `<div class="border border-gray-200 rounded-lg p-4 mb-4">`
    + `<div class="flex items-center justify-between mb-2">`
    + `<div class="flex items-center">${liveDot}<span class="text-sm text-gray-500">CPU 使用率</span></div>`
    + `<span class="text-2xl font-bold text-gray-900">${m.cpu}<span class="text-sm text-gray-400 font-normal ml-0.5">%</span></span>`
    + `</div>`
    + chart
    + `<div class="mt-1 text-right">${liveText}</div>`
    + `</div>`
    + `<div class="grid grid-cols-1 md:grid-cols-3 gap-4">`
    + metricTile('内存使用率', m.mem, '%', '#4f46e5', H.mem)
    + metricTile('磁盘使用率', m.disk, '%', '#ea580c', H.disk)
    + metricTile('公网带宽', m.net, 'Mbps', '#16a34a', H.net)
    + `</div>`;
}

// ===================== 状态展示同步 =====================

function applyAll() {
  applyPowerUI();
  refreshActionButtons();
  renderMetrics();
  renderLog();
}

function applyPowerUI() {
  const box = document.getElementById('cm-status');
  if (!box || !ctx) { return; }
  const meta = powerMeta(ctx.state.power);
  const spin = meta.spin
    ? `<i class="fa-solid fa-spinner fa-spin mr-1.5 text-xs"></i>`
    : `<span style="display:inline-block;width:7px;height:7px;border-radius:9999px;background:${meta.dot};margin-right:6px"></span>`;
  box.className = `inline-flex items-center border text-xs font-medium px-2.5 py-1 rounded-full whitespace-nowrap ${meta.cls}`;
  box.innerHTML = `${spin}${meta.label}`;
}

function refreshActionButtons() {
  const wrap = document.getElementById('cm-actions');
  if (!wrap || !ctx) { return; }
  const p = ctx.state.power;
  const busy = ctx.busy;
  const actions = [
    { key: 'start', label: '开机', icon: 'fa-solid fa-play', enabled: p === POWER.OFF },
    { key: 'stop', label: '关机', icon: 'fa-solid fa-power-off', enabled: p === POWER.ON },
    { key: 'restart', label: '重启', icon: 'fa-solid fa-rotate-right', enabled: p === POWER.ON },
    { key: 'rebuild', label: '重装系统', icon: 'fa-solid fa-compact-disc', enabled: p === POWER.ON || p === POWER.OFF },
  ];

  wrap.innerHTML = actions.map(function (a) {
    const disabled = busy || !a.enabled;
    const showSpin = busy && ctx.activeOp === a.key;
    const cls = disabled
      ? 'border-gray-200 bg-gray-50 text-gray-400 cursor-not-allowed'
      : 'border-gray-300 bg-white text-gray-700 hover:text-primary hover:border-primary';
    const icon = showSpin ? 'fa-solid fa-spinner fa-spin' : a.icon;
    return `<button type="button" data-cm-action="${a.key}" ${disabled ? 'disabled' : ''} `
      + `class="inline-flex items-center justify-center px-3 py-2 rounded border text-sm transition ${cls}">`
      + `<i class="${icon} mr-2 text-xs"></i>${a.label}</button>`;
  }).join('');
}

// 事件委托：操作按钮（容器会被反复重建，用委托避免重复绑定）
$(document).on('click', '[data-cm-action]', function () {
  doOperation($(this).attr('data-cm-action'));
});

// ===================== 操作日志 =====================

function seedInitialLogs(service) {
  ctx.logs = [
    { title: '资源写入控制台', desc: formatDateTime(service.paidAt), icon: 'fa-solid fa-check', state: 'done' },
    { title: '支付成功', desc: formatDateTime(service.paidAt), icon: 'fa-solid fa-credit-card', state: 'done' },
    { title: '订单创建', desc: service.id, icon: 'fa-solid fa-file-lines', state: 'done' },
  ];
}

function addLog(title, desc, icon, state) {
  ctx.logs.unshift({ title, desc, icon, state: state || 'done', time: formatDateTime(new Date()) });
  renderLog();
}

function renderLog() {
  const box = document.getElementById('cm-log');
  if (!box || !ctx) { return; }
  box.innerHTML = ctx.logs.map(function (l) {
    const pending = l.state === 'pending';
    const ring = pending ? 'bg-orange-50 text-orange-500' : 'bg-blue-50 text-primary';
    const icon = pending ? 'fa-solid fa-spinner fa-spin' : l.icon;
    const desc = [l.time, l.desc].filter(Boolean).join(' · ');
    return `<div class="flex items-start gap-3">`
      + `<div class="w-8 h-8 rounded-full ${ring} flex items-center justify-center flex-shrink-0"><i class="${icon} text-xs"></i></div>`
      + `<div><div class="font-medium text-gray-900">${escapeHtml(l.title)}</div>`
      + `<div class="text-xs text-gray-400 mt-1 break-all">${escapeHtml(desc || '-')}</div></div>`
      + `</div>`;
  }).join('');
}

// ===================== 操作（模拟） =====================

function doOperation(kind) {
  if (!ctx || ctx.busy) { return; }
  if (kind === 'start') {
    startInstance();
  } else if (kind === 'stop') {
    if (window.confirm('确定要关机吗？关机后实例将停止运行，监控数据归零。')) { stopInstance(); }
  } else if (kind === 'restart') {
    if (window.confirm('确定要重启实例吗？重启过程中服务会短暂中断。')) { restartInstance(); }
  } else if (kind === 'rebuild') {
    openRebuildDialog();
  }
}

function runTransition(opts) {
  ctx.busy = true;
  ctx.activeOp = opts.op;
  ctx.state.power = opts.mid;
  addLog(opts.startTitle, opts.startDesc, opts.icon, 'pending');
  applyAll();

  setTimeout(function () {
    ctx.state.power = opts.finalPower;
    if (opts.finalPower === POWER.ON) { seedMetrics(); } else { resetMetricsZero(); }
    ctx.busy = false;
    ctx.activeOp = null;
    saveInstanceState();
    addLog(opts.doneTitle, opts.doneDesc, opts.icon, 'done');
    applyAll();
    toast(opts.toast, 'success');
  }, opts.duration);
}

function startInstance() {
  runTransition({
    op: 'start', mid: POWER.STARTING, finalPower: POWER.ON, duration: 3000, icon: 'fa-solid fa-play',
    startTitle: '开机中…', startDesc: '正在启动实例并加载系统', doneTitle: '开机完成', doneDesc: '实例已进入运行中状态',
    toast: '实例已开机',
  });
}

function stopInstance() {
  runTransition({
    op: 'stop', mid: POWER.STOPPING, finalPower: POWER.OFF, duration: 2200, icon: 'fa-solid fa-power-off',
    startTitle: '关机中…', startDesc: '正在安全关闭实例', doneTitle: '关机完成', doneDesc: '实例已停止运行',
    toast: '实例已关机',
  });
}

function restartInstance() {
  runTransition({
    op: 'restart', mid: POWER.RESTARTING, finalPower: POWER.ON, duration: 4200, icon: 'fa-solid fa-rotate-right',
    startTitle: '重启中…', startDesc: '正在重启实例', doneTitle: '重启完成', doneDesc: '实例已恢复运行',
    toast: '实例已重启',
  });
}

// ---- 重装系统：弹窗选镜像 + 进度 ----

function openRebuildDialog() {
  if (ctx.busy) { return; }

  const overlay = document.createElement('div');
  overlay.style.cssText = 'position:fixed;inset:0;background:rgba(15,23,42,0.45);display:flex;align-items:center;justify-content:center;z-index:60;padding:16px';

  const options = OS_IMAGES.map(function (os) {
    return `<option value="${escapeHtml(os)}" ${os === ctx.service.os ? 'selected' : ''}>${escapeHtml(os)}</option>`;
  }).join('');

  overlay.innerHTML =
    `<div style="background:#fff;border-radius:12px;max-width:440px;width:100%;box-shadow:0 20px 60px -15px rgba(0,0,0,0.3)" class="p-6">`
    + `<h3 class="text-lg font-bold text-gray-900 mb-1">重装系统</h3>`
    + `<p class="text-sm text-gray-500 mb-4">选择系统镜像重新安装。该操作为模拟演示，不影响真实数据。</p>`
    + `<label class="block text-sm font-medium text-gray-700 mb-1.5">系统镜像</label>`
    + `<select id="cm-rebuild-os" class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary mb-4">${options}</select>`
    + `<div class="bg-red-50 border border-red-100 text-red-500 text-xs rounded p-3 mb-5"><i class="fa-solid fa-triangle-exclamation mr-1"></i> 重装将清空系统盘数据并重置实例，请谨慎操作。</div>`
    + `<div class="flex justify-end gap-3">`
    + `<button type="button" id="cm-rebuild-cancel" class="px-4 py-2 rounded border border-gray-300 bg-white text-gray-700 text-sm hover:text-primary hover:border-primary transition">取消</button>`
    + `<button type="button" id="cm-rebuild-ok" class="px-4 py-2 rounded bg-primary text-white text-sm hover:bg-primary-hover transition">确认重装</button>`
    + `</div>`
    + `</div>`;

  document.body.appendChild(overlay);

  function close() {
    if (overlay.parentNode) { overlay.parentNode.removeChild(overlay); }
  }
  overlay.addEventListener('click', function (e) { if (e.target === overlay) { close(); } });
  overlay.querySelector('#cm-rebuild-cancel').addEventListener('click', close);
  overlay.querySelector('#cm-rebuild-ok').addEventListener('click', function () {
    const os = overlay.querySelector('#cm-rebuild-os').value;
    close();
    runRebuild(os);
  });
}

function runRebuild(os) {
  ctx.busy = true;
  ctx.activeOp = 'rebuild';
  ctx.state.power = POWER.REBUILDING;
  addLog('重装系统…', '目标镜像：' + os, 'fa-solid fa-compact-disc', 'pending');
  applyAll();

  const steps = ['卸载原系统盘', '写入镜像 ' + os, '初始化系统配置', '启动实例'];
  const overlay = document.createElement('div');
  overlay.style.cssText = 'position:fixed;inset:0;background:rgba(15,23,42,0.45);display:flex;align-items:center;justify-content:center;z-index:60;padding:16px';
  overlay.innerHTML =
    `<div style="background:#fff;border-radius:12px;max-width:420px;width:100%;box-shadow:0 20px 60px -15px rgba(0,0,0,0.3)" class="p-6 text-center">`
    + `<i class="fa-solid fa-compact-disc fa-spin text-primary text-3xl mb-3"></i>`
    + `<h3 class="text-lg font-bold text-gray-900 mb-1">正在重装系统</h3>`
    + `<p id="cm-rebuild-step" class="text-sm text-gray-500 mb-4">准备中…</p>`
    + `<div class="h-2 bg-gray-100 rounded overflow-hidden"><div id="cm-rebuild-bar" class="h-full bg-primary rounded" style="width:0%;transition:width .3s"></div></div>`
    + `<p id="cm-rebuild-pct" class="text-xs text-gray-400 mt-2">0%</p>`
    + `</div>`;
  document.body.appendChild(overlay);

  const barEl = overlay.querySelector('#cm-rebuild-bar');
  const stepEl = overlay.querySelector('#cm-rebuild-step');
  const pctEl = overlay.querySelector('#cm-rebuild-pct');

  let pct = 0;
  const timer = setInterval(function () {
    pct = Math.min(100, pct + Math.round(6 + Math.random() * 10));
    barEl.style.width = pct + '%';
    pctEl.textContent = pct + '%';
    stepEl.textContent = steps[Math.min(steps.length - 1, Math.floor((pct / 100) * steps.length))];

    if (pct >= 100) {
      clearInterval(timer);
      setTimeout(function () {
        if (overlay.parentNode) { overlay.parentNode.removeChild(overlay); }
        finishRebuild(os);
      }, 400);
    }
  }, 600);
}

function finishRebuild(os) {
  ctx.service.os = os;
  ctx.state.os = os;
  ctx.state.power = POWER.ON;
  ctx.busy = false;
  ctx.activeOp = null;
  saveInstanceState();

  // 系统镜像影响登录方式/端口，重渲染网络面板
  const net = renderNetworkPanel(ctx.service);
  const oldNet = document.getElementById('cm-network');
  if (oldNet && net) { oldNet.replaceWith(net); }

  seedMetrics();
  addLog('重装系统完成', '当前系统：' + os, 'fa-solid fa-compact-disc', 'done');
  applyAll();
  toast('系统已重装为 ' + os, 'success');
}

// ===================== 轻量 Toast =====================

function toast(message, type) {
  let host = document.getElementById('cm-toast-host');
  if (!host) {
    host = document.createElement('div');
    host.id = 'cm-toast-host';
    host.style.cssText = 'position:fixed;right:24px;bottom:24px;z-index:70;display:flex;flex-direction:column;gap:10px';
    document.body.appendChild(host);
  }
  const color = type === 'error' ? '#ef4444' : (type === 'info' ? '#0052d9' : '#16a34a');
  const icon = type === 'error' ? 'fa-circle-xmark' : (type === 'info' ? 'fa-circle-info' : 'fa-circle-check');
  const item = document.createElement('div');
  item.style.cssText = 'background:#fff;border-left:4px solid ' + color + ';box-shadow:0 10px 30px -10px rgba(0,0,0,0.25);border-radius:8px;padding:12px 16px;min-width:220px;display:flex;align-items:center;gap:10px;font-size:14px;color:#1f2937';
  item.innerHTML = `<i class="fa-solid ${icon}" style="color:${color}"></i><span>${escapeHtml(message)}</span>`;
  host.appendChild(item);
  setTimeout(function () {
    item.style.transition = 'opacity .3s';
    item.style.opacity = '0';
    setTimeout(function () { if (item.parentNode) { item.parentNode.removeChild(item); } }, 300);
  }, 2600);
}

// ===================== 通用渲染辅助 =====================

function renderCompactInfoItem(label, value, icon) {
  return $('<div>', { class: 'flex items-center gap-3 border-b border-gray-100 py-2 min-w-0' }).append(
    $('<i>', { class: `${icon} text-gray-400 w-4 flex-shrink-0` }),
    $('<span>', { class: 'text-gray-400 text-xs w-16 flex-shrink-0', text: label }),
    $('<span>', { class: 'text-gray-800 font-medium truncate', title: value || '-', text: value || '-' })
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
    $('<a>', { href: 'console.jsp', class: 'inline-flex items-center justify-center mt-5 bg-primary hover:bg-primary-hover text-white px-5 py-2.5 rounded text-sm font-medium transition shadow-sm', text: '返回控制台' })
  )[0];
}

function escapeHtml(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
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
