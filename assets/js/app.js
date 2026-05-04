// 购买配置页的实例选择、价格计算、支付弹窗和支付状态轮询逻辑。

const purchaseConfig = window.PURCHASE_PAGE_CONFIG;

const state = { ...purchaseConfig.defaultState };

const pricing = purchaseConfig.pricing;
const names = purchaseConfig.names;
const tabClasses = purchaseConfig.tabClasses;
const billingRules = purchaseConfig.billingRules;
const defaultInstances = purchaseConfig.defaultInstances;

const paymentApiConfig = window.PAYMENT_API_CONFIG || {};

const purchasedServicesStorageKey = "ajou_purchased_services";

let currentPaymentOrderId = "";
let currentPaymentAmount = "";
let paymentQueryTimer = null;

$(function () {
  initPurchasePage();
});

function initPurchasePage() {
  if (!$("#purchase-form").length) {
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
  $(".option-btn[data-group][data-value]").on("click", function () {
    const $button = $(this);
    selectOption($button.attr("data-group"), $button.attr("data-value"));
  });
}

function bindInstanceTabs() {
  $("[data-instance-tab]").on("click", function () {
    switchInstanceTab($(this).attr("data-instance-tab"), true);
  });
}

function bindDiskInputs() {
  $("#diskSize").on("input", function () {
    updateDiskSize($(this).val());
  });

  $("#diskSizeInput").on("input", function () {
    updateDiskSlider($(this).val());
  });
}

function bindModal() {
  $("#showBuyModal").on("click", showModal);
  $("[data-close-modal]").on("click", hideModal);
  $("#createPaymentButton").on("click", createBackendPayment);
}

function applyInitialInstanceFromQuery() {
  const params = new URLSearchParams(window.location.search);
  const instance = params.get("instance");

  if (!instance || !pricing.instance[instance]) {
    return;
  }

  const isGpu = instance.startsWith("gpu");
  switchInstanceTab(isGpu ? "gpu" : "cpu", false);
  selectOption("instance", instance);
}

function selectOption(group, value) {
  state[group] = value;

  $(`.option-btn[data-group="${group}"]`).each(function () {
    const $button = $(this);
    $button.toggleClass("active", $button.attr("data-value") === value);
  });

  if (group === "billing") {
    const $durationContainer = $("#duration-container");

    if (value === "hourly") {
      $durationContainer.addClass("hidden");
      state.duration = purchaseConfig.defaultState.duration;
    } else {
      $durationContainer.removeClass("hidden");
      selectOption(
        "duration",
        state.duration || purchaseConfig.defaultState.duration,
      );
    }
  }

  calculatePrice();
}

function switchInstanceTab(type, shouldSelectDefault) {
  const $cpuView = $("#cpu-instances");
  const $gpuView = $("#gpu-instances");

  $("[data-instance-tab]").each(function () {
    const $tab = $(this);
    $tab.attr(
      "class",
      $tab.attr("data-instance-tab") === type
        ? tabClasses.active
        : tabClasses.inactive,
    );
  });

  if (type === "cpu") {
    $cpuView.removeClass("hidden");
    $gpuView.addClass("hidden");

    if (shouldSelectDefault) {
      selectOption("instance", defaultInstances.cpu);
    }
  } else {
    $cpuView.addClass("hidden");
    $gpuView.removeClass("hidden");

    if (shouldSelectDefault) {
      selectOption("instance", defaultInstances.gpu);
    }
  }
}

function updateDiskSize(value) {
  $("#diskSizeInput").val(value);
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

  $("#diskSize").val(size);
  state.diskSize = size;
  calculatePrice();
}

function calculatePrice() {
  const $totalPrice = $("#total-price");
  const $summary = $("#summary-text");

  if (!$totalPrice.length || !$summary.length) {
    return;
  }

  const instancePrice = pricing.instance[state.instance] || 0;
  const diskPrice = (pricing.disk[state.diskType] || 0) * state.diskSize;
  const baseMonthlyPrice = instancePrice + diskPrice;
  let totalPrice = 0;

  if (state.billing === "hourly") {
    totalPrice =
      (baseMonthlyPrice / billingRules.hourlyHoursPerMonth) *
      billingRules.hourlyMultiplier;
    $totalPrice.text(`${totalPrice.toFixed(2)} / 小时`);
  } else {
    const duration = Number.parseInt(state.duration, 10);
    const discount = billingRules.durationDiscounts[duration] || 1;

    totalPrice = baseMonthlyPrice * duration * discount;
    $totalPrice.text(totalPrice.toFixed(2));
  }

  $summary.text(`${names.billing[state.billing]}, ${names.region[state.region]}, ${names.instance[state.instance]}, ${state.diskSize}GB ${names.diskType[state.diskType]}`);
}

async function showModal() {
  const orderId = createPaymentOrderId();
  currentPaymentOrderId = orderId;
  currentPaymentAmount = getCurrentPaymentAmount();

  $("#modal-price").text($("#total-price").text());
  $("#modal-summary").text($("#summary-text").text());
  $("#modal-order-id").text(orderId);
  setPaymentStatus("正在生成支付二维码...");
  renderPaymentQrLoading();
  $("#buy-modal").removeClass("hidden");

  await createBackendPayment();
}

function hideModal() {
  $("#buy-modal").addClass("hidden");
  stopPaymentQueryPolling();
}

async function createBackendPayment() {
  const $button = $("#createPaymentButton");

  $button.text("生成中...").prop("disabled", true);
  setPaymentStatus("正在请求支付接口...");
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
      throw new Error(data.message || data.error || "支付二维码生成失败");
    }

    renderPaymentQr(data.pay_url || data.qr_code);
    setPaymentStatus("等待用户扫码支付");
    startPaymentQueryPolling();
  } catch (error) {
    renderPaymentQrError();
    setPaymentStatus(error.message || "支付二维码生成失败");
  } finally {
    $button.text("重新生成二维码").prop("disabled", false);
  }
}

function createPaymentOrderId() {
  return `pay_${state.instance}_${Date.now()}`;
}

async function queryBackendPaymentStatus() {
  setPaymentStatusLoading(true);
  setPaymentStatus("正在查询支付状态...");

  try {
    const data = await getPaymentJson(
      `${paymentApiConfig.queryPayment}?order_id=${encodeURIComponent(currentPaymentOrderId)}`,
    );

    if (!data.success) {
      throw new Error(data.message || data.error || "支付状态查询失败");
    }

    if (data.paid) {
      stopPaymentQueryPolling();
      setPaymentStatus("支付成功，正在写入购买记录...");
      await savePurchasedService(currentPaymentOrderId);
      setPaymentStatus("支付成功，正在跳转...");
      redirectToPaymentSuccess(currentPaymentOrderId);
      return;
    }

    setPaymentStatus(getPaymentStatusText(data.trade_status));
  } catch (error) {
    setPaymentStatus(error.message || "支付状态查询失败");
  } finally {
    if (!paymentQueryTimer) {
      setPaymentStatusLoading(false);
    }
  }
}

function redirectToPaymentSuccess(orderId) {
  const successPage = paymentApiConfig.successPage || "/payment-success.html";
  window.location.href = `${successPage}?order_id=${encodeURIComponent(orderId || "")}`;
}

function buildPaymentSubject() {
  const subjects = {
    "2c4g": "Server 2C 4G",
    "4c8g": "Server 4C 8G",
    "8c16g": "Server 8C 16G",
    gpu_t4: "Server GPU T4",
    gpu_a100: "Server GPU A100",
  };

  return subjects[state.instance] || `Server ${state.instance}`;
}

function buildPurchasedService(orderId) {
  const isGpu = state.instance.startsWith("gpu");
  const duration = Number.parseInt(state.duration, 10) || 1;

  return {
    id: orderId,
    order_id: orderId,
    name: `${names.instance[state.instance] || state.instance} 云服务器`,
    category: isGpu ? "GPU 云服务器" : "云服务器 ECS",
    instance: names.instance[state.instance] || state.instance,
    region: names.region[state.region] || state.region,
    status: "分配成功",
    statusClass: "bg-green-50 text-green-600 border-green-200",
    publicIp: "分配中",
    os: getOsName(state.os),
    disk: `${state.diskSize}GB ${names.diskType[state.diskType] || state.diskType}`,
    billing: names.billing[state.billing] || state.billing,
    expireAt: state.billing === "hourly" ? "按量资源" : getExpireDate(duration),
    monthlyCost: currentPaymentAmount,
    productCode: state.instance,
    paidAt: new Date().toISOString(),
  };
}

async function savePurchasedService(orderId) {
  const service = buildPurchasedService(orderId);
  const services = getStoredPurchasedServices().filter(
    (item) => item.id !== service.id,
  );

  services.unshift(service);
  localStorage.setItem(
    purchasedServicesStorageKey,
    JSON.stringify(services.slice(0, 20)),
  );

  try {
    const result = await syncPurchaseToBackend(service);
    console.log("购买记录已写入后端：", result.item || service);
  } catch (error) {
    console.warn(
      "购买记录后端写入失败，已保留本地记录：",
      error.message || error,
    );
  }

  return service;
}

function getStoredPurchasedServices() {
  try {
    const services = JSON.parse(
      localStorage.getItem(purchasedServicesStorageKey) || "[]",
    );
    return Array.isArray(services) ? services : [];
  } catch (error) {
    return [];
  }
}

async function syncPurchaseToBackend(service) {
  const token = getAuthToken();

  if (!token) {
    throw new Error("用户未登录");
  }

  const data = await postPaymentJson(
    paymentApiConfig.purchases || "/purchases",
    {
      order_id: service.id,
      amount: currentPaymentAmount,
      subject: buildPaymentSubject(),
      service,
    },
    {
      Authorization: `Bearer ${token}`,
    },
  );

  if (!data.success) {
    throw new Error(data.message || data.error || "购买记录写入失败");
  }

  return data;
}

function getAuthToken() {
  const loginInfo = readJsonStorage("ajou_login_info");
  return (
    localStorage.getItem("ajou_auth_token") ||
    (loginInfo && loginInfo.token) ||
    ""
  );
}

function readJsonStorage(key) {
  try {
    return JSON.parse(localStorage.getItem(key) || "null");
  } catch (error) {
    return null;
  }
}

function getOsName(os) {
  const osNames = {
    ubuntu: "Ubuntu 22.04 LTS",
    centos: "CentOS 7.9",
    windows: "Windows Server 2022",
  };

  return osNames[os] || os;
}

function getExpireDate(months) {
  const date = new Date();
  date.setMonth(date.getMonth() + months);
  return date.toISOString().slice(0, 10);
}

function getCurrentPaymentAmount() {
  const priceText = $("#total-price").text();
  const match = priceText.match(/\d+(?:\.\d+)?/);
  const amount = match ? Number.parseFloat(match[0]) : 0;

  if (!Number.isFinite(amount) || amount <= 0) {
    return "0.01";
  }

  return Math.max(amount, 0.01).toFixed(2);
}

function setPaymentStatus(text) {
  $("#payment-status-text").text(text);
}

function setPaymentStatusLoading(isLoading) {
  $("#payment-status-loading")
    .toggleClass("hidden", !isLoading)
    .toggleClass("flex", isLoading);
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
  $("#payment-qr-tip").text("正在生成支付宝支付二维码");
  $("#payment-qr-box")
    .attr(
      "class",
      "w-48 h-48 border border-dashed border-gray-300 rounded bg-gray-50 flex flex-col items-center justify-center text-gray-400",
    )
    .empty()
    .append(
      $("<i>", { class: "fa-solid fa-spinner fa-spin text-4xl mb-3" }),
      $("<span>", { class: "text-sm", text: "生成中" }),
    );
}

function renderPaymentQr(payUrl) {
  const qrUrl = buildApiUrl(
    `${paymentApiConfig.createQrCode}?url=${encodeURIComponent(payUrl)}&size=220`,
  );

  $("#payment-qr-tip").text("请使用支付宝扫码支付");
  $("#payment-qr-box")
    .attr(
      "class",
      "w-48 h-48 border border-gray-200 rounded bg-white flex items-center justify-center",
    )
    .empty()
    .append($("<img>", {
      class: "w-44 h-44",
      src: qrUrl,
      alt: "支付宝支付二维码",
    }));
}

function renderPaymentQrError() {
  $("#payment-qr-tip").text("请检查后端支付服务是否已启动");
  $("#payment-qr-box")
    .attr(
      "class",
      "w-48 h-48 border border-red-200 rounded bg-red-50 flex flex-col items-center justify-center text-red-500",
    )
    .empty()
    .append(
      $("<i>", { class: "fa-solid fa-triangle-exclamation text-4xl mb-3" }),
      $("<span>", { class: "text-sm", text: "生成失败" }),
    );
}

function getPaymentStatusText(status) {
  const statusTextMap = {
    WAIT_BUYER_PAY: "已生成订单，等待买家付款",
    TRADE_CLOSED: "交易已关闭",
    TRADE_FINISHED: "交易已结束",
    TRADE_SUCCESS: "支付成功",
  };

  return statusTextMap[status] || "等待用户扫码支付";
}

function buildApiUrl(path) {
  const baseUrl = (paymentApiConfig.baseUrl || "").replace(/\/+$/, "");
  return `${baseUrl}${path || ""}`;
}

async function postPaymentJson(path, data, headers = {}) {
  const text = await requestPaymentText({
    path,
    method: "POST",
    headers,
    data: JSON.stringify(data),
    contentType: "application/json",
  });

  return parsePaymentText(text);
}

async function getPaymentJson(path) {
  const text = await requestPaymentText({
    path,
    method: "GET",
  });

  return parsePaymentText(text);
}

function requestPaymentText(options) {
  return $.ajax({
    url: buildApiUrl(options.path),
    method: options.method,
    headers: options.headers || {},
    data: options.data,
    contentType: options.contentType,
    dataType: "text",
  }).catch(function (xhr) {
    throw new Error(parsePaymentErrorText(xhr.responseText || xhr.statusText));
  });
}

function parsePaymentText(text) {
  try {
    return JSON.parse(text);
  } catch (error) {
    throw new Error(text || "支付接口返回格式错误");
  }
}

function parsePaymentErrorText(text) {
  try {
    const data = JSON.parse(text || "{}");
    return data.message || data.error || text || "接口请求失败";
  } catch (error) {
    return text || "接口请求失败";
  }
}
