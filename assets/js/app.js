// 购买配置页的实例选择、价格计算和订单弹窗交互逻辑。
// 参数配置统一维护在 assets/js/config/purchase.config.js。
const purchaseConfig = window.PURCHASE_PAGE_CONFIG;
const state = { ...purchaseConfig.defaultState };
const pricing = purchaseConfig.pricing;
const names = purchaseConfig.names;
const tabClasses = purchaseConfig.tabClasses;
const billingRules = purchaseConfig.billingRules;
const defaultInstances = purchaseConfig.defaultInstances;
const paymentApiConfig = window.PAYMENT_API_CONFIG || {};
const purchasedServicesStorageKey = 'ajou_purchased_services';
let currentPaymentOrderId = '';
let currentPaymentAmount = '';
let paymentQueryTimer = null;

document.addEventListener('DOMContentLoaded', () => {
  initPurchasePage();
});

function initPurchasePage() {
  if (!document.getElementById('purchase-form')) {
    return;
  }

  bindOptionButtons();
  bindInstanceTabs();
  bindDiskInputs();
  bindModal();
  applyInitialInstanceFromQuery();
  calculatePrice();
}

function bindOptionButtons() {
  document.querySelectorAll('.option-btn[data-group][data-value]').forEach((button) => {
    button.addEventListener('click', () => {
      selectOption(button.dataset.group, button.dataset.value);
    });
  });
}

function bindInstanceTabs() {
  document.querySelectorAll('[data-instance-tab]').forEach((tab) => {
    tab.addEventListener('click', () => {
      switchInstanceTab(tab.dataset.instanceTab, true);
    });
  });
}

function bindDiskInputs() {
  const diskSize = document.getElementById('diskSize');
  const diskSizeInput = document.getElementById('diskSizeInput');

  diskSize.addEventListener('input', () => {
    updateDiskSize(diskSize.value);
  });

  diskSizeInput.addEventListener('input', () => {
    updateDiskSlider(diskSizeInput.value);
  });
}

function bindModal() {
  const showButton = document.getElementById('showBuyModal');
  const closeButtons = document.querySelectorAll('[data-close-modal]');
  const payButton = document.getElementById('createPaymentButton');

  showButton.addEventListener('click', showModal);
  closeButtons.forEach((button) => button.addEventListener('click', hideModal));
  payButton.addEventListener('click', createBackendPayment);
}

function applyInitialInstanceFromQuery() {
  const params = new URLSearchParams(window.location.search);
  const instance = params.get('instance');

  if (!instance || !pricing.instance[instance]) {
    return;
  }

  const isGpu = instance.startsWith('gpu');
  switchInstanceTab(isGpu ? 'gpu' : 'cpu', false);
  selectOption('instance', instance);
}

function selectOption(group, value) {
  state[group] = value;

  document.querySelectorAll(`.option-btn[data-group="${group}"]`).forEach((button) => {
    button.classList.toggle('active', button.dataset.value === value);
  });

  if (group === 'billing') {
    const durationContainer = document.getElementById('duration-container');

    if (value === 'hourly') {
      durationContainer.classList.add('hidden');
      state.duration = purchaseConfig.defaultState.duration;
    } else {
      durationContainer.classList.remove('hidden');
      selectOption('duration', state.duration || purchaseConfig.defaultState.duration);
    }
  }

  calculatePrice();
}

function switchInstanceTab(type, shouldSelectDefault) {
  const cpuView = document.getElementById('cpu-instances');
  const gpuView = document.getElementById('gpu-instances');
  const tabs = document.querySelectorAll('[data-instance-tab]');

  tabs.forEach((tab) => {
    tab.className = tab.dataset.instanceTab === type ? tabClasses.active : tabClasses.inactive;
  });

  if (type === 'cpu') {
    cpuView.classList.remove('hidden');
    gpuView.classList.add('hidden');

    if (shouldSelectDefault) {
      selectOption('instance', defaultInstances.cpu);
    }
  } else {
    cpuView.classList.add('hidden');
    gpuView.classList.remove('hidden');

    if (shouldSelectDefault) {
      selectOption('instance', defaultInstances.gpu);
    }
  }
}

function updateDiskSize(value) {
  document.getElementById('diskSizeInput').value = value;
  state.diskSize = Number.parseInt(value, 10);
  calculatePrice();
}

function updateDiskSlider(value) {
  let size = Number.parseInt(value, 10);

  if (Number.isNaN(size) || size < 40) {
    size = 40;
  }

  if (size > 500) {
    size = 500;
  }

  document.getElementById('diskSize').value = size;
  state.diskSize = size;
  calculatePrice();
}

function calculatePrice() {
  const totalPriceElement = document.getElementById('total-price');
  const summaryElement = document.getElementById('summary-text');

  if (!totalPriceElement || !summaryElement) {
    return;
  }

  const instancePrice = pricing.instance[state.instance] || 0;
  const diskPrice = (pricing.disk[state.diskType] || 0) * state.diskSize;
  const baseMonthlyPrice = instancePrice + diskPrice;
  let totalPrice = 0;

  if (state.billing === 'hourly') {
    totalPrice = (baseMonthlyPrice / billingRules.hourlyHoursPerMonth) * billingRules.hourlyMultiplier;
    totalPriceElement.innerText = `${totalPrice.toFixed(2)} / 小时`;
  } else {
    const duration = Number.parseInt(state.duration, 10);
    const discount = billingRules.durationDiscounts[duration] || 1;

    totalPrice = baseMonthlyPrice * duration * discount;
    totalPriceElement.innerText = totalPrice.toFixed(2);
  }

  summaryElement.innerText = `${names.billing[state.billing]}, ${names.region[state.region]}, ${names.instance[state.instance]}, ${state.diskSize}GB ${names.diskType[state.diskType]}`;
}

async function showModal() {
  const orderId = createPaymentOrderId();
  currentPaymentOrderId = orderId;
  currentPaymentAmount = getCurrentPaymentAmount();
  const baseUrl = (paymentApiConfig.baseUrl || '').replace(/\/+$/, '');

  document.getElementById('modal-price').innerText = document.getElementById('total-price').innerText;
  document.getElementById('modal-summary').innerText = document.getElementById('summary-text').innerText;
  document.getElementById('modal-order-id').innerText = orderId;
  setPaymentStatus('正在生成支付二维码...');
  renderPaymentQrLoading();
  document.getElementById('buy-modal').classList.remove('hidden');

  await createBackendPayment();
}

function hideModal() {
  document.getElementById('buy-modal').classList.add('hidden');
  stopPaymentQueryPolling();
}

async function createBackendPayment() {
  const button = document.getElementById('createPaymentButton');

  button.innerText = '生成中...';
  button.disabled = true;
  setPaymentStatus('正在请求支付接口...');
  setPaymentStatusLoading(false);
  stopPaymentQueryPolling();
  renderPaymentQrLoading();

  try {
    const data = await postPaymentJson(paymentApiConfig.createPayment, {
      order_id: currentPaymentOrderId,
      amount: currentPaymentAmount,
      subject: buildPaymentSubject(),
    });

    if (!data.success) {
      throw new Error(data.message || data.error || '支付二维码生成失败');
    }

    renderPaymentQr(data.pay_url || data.qr_code);
    setPaymentStatus('等待用户扫码支付');
    startPaymentQueryPolling();
  } catch (error) {
    renderPaymentQrError();
    setPaymentStatus(error.message || '支付二维码生成失败');
  } finally {
    button.innerText = '重新生成二维码';
    button.disabled = false;
  }
}

function createPaymentOrderId() {
  return `pay_${state.instance}_${Date.now()}`;
}

async function queryBackendPaymentStatus() {
  setPaymentStatusLoading(true);
  setPaymentStatus('正在查询支付状态...');

  try {
    const data = await getPaymentJson(`${paymentApiConfig.queryPayment}?order_id=${encodeURIComponent(currentPaymentOrderId)}`);

    if (!data.success) {
      throw new Error(data.message || data.error || '支付状态查询失败');
    }

    if (data.paid) {
      stopPaymentQueryPolling();
      setPaymentStatus('支付成功，正在跳转...');
      savePurchasedService(currentPaymentOrderId);
      redirectToPaymentSuccess(currentPaymentOrderId);
      return;
    }

    setPaymentStatus(getPaymentStatusText(data.trade_status));
  } catch (error) {
    setPaymentStatus(error.message || '支付状态查询失败');
  } finally {
    if (!paymentQueryTimer) {
      setPaymentStatusLoading(false);
    }
  }
}

function redirectToPaymentSuccess(orderId) {
  const successPage = paymentApiConfig.successPage || '/payment-success.html';
  window.location.href = `${successPage}?order_id=${encodeURIComponent(orderId || '')}`;
}

function buildPaymentSubject() {
  const subjects = {
    '2c4g': 'Server 2C 4G',
    '4c8g': 'Server 4C 8G',
    '8c16g': 'Server 8C 16G',
    gpu_t4: 'Server GPU T4',
    gpu_a100: 'Server GPU A100',
  };

  return subjects[state.instance] || `Server ${state.instance}`;
}

function buildPurchasedService(orderId) {
  const isGpu = state.instance.startsWith('gpu');
  const duration = Number.parseInt(state.duration, 10) || 1;

  return {
    id: orderId,
    name: `${names.instance[state.instance] || state.instance} 云服务器`,
    category: isGpu ? 'GPU 云服务器' : '云服务器 ECS',
    instance: names.instance[state.instance] || state.instance,
    region: names.region[state.region] || state.region,
    status: '分配成功',
    statusClass: 'bg-green-50 text-green-600 border-green-200',
    publicIp: '分配中',
    os: getOsName(state.os),
    disk: `${state.diskSize}GB ${names.diskType[state.diskType] || state.diskType}`,
    billing: names.billing[state.billing] || state.billing,
    expireAt: state.billing === 'hourly' ? '按量资源' : getExpireDate(duration),
    monthlyCost: currentPaymentAmount,
    paidAt: new Date().toISOString(),
  };
}

function savePurchasedService(orderId) {
  const service = buildPurchasedService(orderId);
  const services = getStoredPurchasedServices().filter((item) => item.id !== service.id);

  services.unshift(service);
  localStorage.setItem(purchasedServicesStorageKey, JSON.stringify(services.slice(0, 20)));
}

function getStoredPurchasedServices() {
  try {
    const services = JSON.parse(localStorage.getItem(purchasedServicesStorageKey) || '[]');
    return Array.isArray(services) ? services : [];
  } catch (error) {
    return [];
  }
}

function getOsName(os) {
  const osNames = {
    ubuntu: 'Ubuntu 22.04 LTS',
    centos: 'CentOS 7.9',
    windows: 'Windows Server 2022',
  };

  return osNames[os] || os;
}

function getExpireDate(months) {
  const date = new Date();
  date.setMonth(date.getMonth() + months);
  return date.toISOString().slice(0, 10);
}

function getCurrentPaymentAmount() {
  const priceText = document.getElementById('total-price').innerText;
  const match = priceText.match(/\d+(?:\.\d+)?/);
  const amount = match ? Number.parseFloat(match[0]) : 0;

  if (!Number.isFinite(amount) || amount <= 0) {
    return '0.01';
  }

  return Math.max(amount, 0.01).toFixed(2);
}

function setPaymentStatus(text) {
  document.getElementById('payment-status-text').innerText = text;
}

function setPaymentStatusLoading(isLoading) {
  const loading = document.getElementById('payment-status-loading');
  loading.classList.toggle('hidden', !isLoading);
  loading.classList.toggle('flex', isLoading);
}

function startPaymentQueryPolling() {
  stopPaymentQueryPolling();
  setPaymentStatusLoading(true);
  paymentQueryTimer = window.setInterval(queryBackendPaymentStatus, 3000);
}

function stopPaymentQueryPolling() {
  if (paymentQueryTimer) {
    window.clearInterval(paymentQueryTimer);
    paymentQueryTimer = null;
  }

  setPaymentStatusLoading(false);
}

function renderPaymentQrLoading() {
  const box = document.getElementById('payment-qr-box');
  document.getElementById('payment-qr-tip').innerText = '正在生成支付宝支付二维码';
  box.className = 'w-48 h-48 border border-dashed border-gray-300 rounded bg-gray-50 flex flex-col items-center justify-center text-gray-400';
  box.innerHTML = '<i class="fa-solid fa-spinner fa-spin text-4xl mb-3"></i><span class="text-sm">生成中</span>';
}

function renderPaymentQr(payUrl) {
  const box = document.getElementById('payment-qr-box');
  const qrUrl = buildApiUrl(`${paymentApiConfig.createQrCode}?url=${encodeURIComponent(payUrl)}&size=220`);

  document.getElementById('payment-qr-tip').innerText = '请使用支付宝扫码支付';
  box.className = 'w-48 h-48 border border-gray-200 rounded bg-white flex items-center justify-center';
  box.innerHTML = `<img class="w-44 h-44" src="${qrUrl}" alt="支付宝支付二维码">`;
}

function renderPaymentQrError() {
  const box = document.getElementById('payment-qr-box');
  document.getElementById('payment-qr-tip').innerText = '请检查后端支付服务是否已启动';
  box.className = 'w-48 h-48 border border-red-200 rounded bg-red-50 flex flex-col items-center justify-center text-red-500';
  box.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-4xl mb-3"></i><span class="text-sm">生成失败</span>';
}

function getPaymentStatusText(status) {
  const statusTextMap = {
    WAIT_BUYER_PAY: '已生成订单，等待买家付款',
    TRADE_CLOSED: '交易已关闭',
    TRADE_FINISHED: '交易已结束',
    TRADE_SUCCESS: '支付成功',
  };

  return statusTextMap[status] || '等待用户扫码支付';
}

function buildApiUrl(path) {
  const baseUrl = (paymentApiConfig.baseUrl || '').replace(/\/+$/, '');
  return `${baseUrl}${path || ''}`;
}

async function postPaymentJson(path, data) {
  const response = await fetch(buildApiUrl(path), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  return parsePaymentResponse(response);
}

async function getPaymentJson(path) {
  const response = await fetch(buildApiUrl(path));
  return parsePaymentResponse(response);
}

async function parsePaymentResponse(response) {
  const text = await response.text();

  try {
    return JSON.parse(text);
  } catch (error) {
    throw new Error(text || '支付接口返回格式错误');
  }
}
