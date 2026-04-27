// 使用 jQuery 根据控制台配置渲染用户已购买云服务列表。
$(function () {
  const config = window.CONSOLE_PAGE_CONFIG;

  if (!config) {
    return;
  }

  const services = getConsoleServices(config.services);

  if (redirectHashToManagePage()) {
    return;
  }

  renderServiceCards(services);
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
  const demoIds = [
    'ecs-20260427001',
    'gpu-20260427002',
    'rds-20260427003',
    'cdn-20260427004',
  ];

  return demoIds.includes(service.id);
}

function renderServiceCards(services) {
  const container = $('#console-services').empty();

  if (!services.length) {
    container.append(renderEmptyState());
    return;
  }

  container.append(services.map((service) => renderServiceCard(service)));
}

function redirectHashToManagePage() {
  const serviceId = decodeURIComponent(window.location.hash.replace('#', '').trim());

  if (!serviceId) {
    return false;
  }

  window.location.replace(`console-manage.html?id=${encodeURIComponent(serviceId)}`);
  return true;
}

function renderEmptyState() {
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
  return $('<div>', { class: 'flex items-start gap-3' }).append(
    $('<i>', { class: `${icon} text-gray-400 mt-1 w-4` }),
    $('<div>').append(
      $('<p>', { class: 'text-gray-400 text-xs mb-1', text: label }),
      $('<p>', { class: 'text-gray-700 font-medium', text: value })
    )
  )[0];
}
