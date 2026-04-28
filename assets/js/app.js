// 购买配置页的实例选择、价格计算、支付弹窗和支付状态轮询逻辑。

// 参数配置统一维护在 assets/js/config/purchase.config.js。
const purchaseConfig = window.PURCHASE_PAGE_CONFIG;
// state 保存用户当前选择的购买配置，例如实例、地域、系统盘和计费方式。
const state = { ...purchaseConfig.defaultState };
// pricing、names、规则和默认值都从配置文件读取，避免把价格写死在逻辑里。
const pricing = purchaseConfig.pricing;
const names = purchaseConfig.names;
const tabClasses = purchaseConfig.tabClasses;
const billingRules = purchaseConfig.billingRules;
const defaultInstances = purchaseConfig.defaultInstances;
// 支付接口配置由 assets/js/config/payment.config.js 注入。
const paymentApiConfig = window.PAYMENT_API_CONFIG || {};
// 购买成功后会先写入浏览器本地，控制台可用它做前端预览和后端失败兜底。
const purchasedServicesStorageKey = "ajou_purchased_services";
// 当前支付订单信息用于生成二维码、轮询查询和购买记录写入。
let currentPaymentOrderId = "";
let currentPaymentAmount = "";
let paymentQueryTimer = null;

// jQuery 页面就绪后初始化购买页。
$(function () {
  initPurchasePage();
});

function initPurchasePage() {
  // 只有购买配置页存在 purchase-form 时才执行，避免其他页面加载该脚本时报错。
  if (!$("#purchase-form").length) {
    return;
  }

  // 初始化购买页所有交互：规格选择、实例切换、磁盘输入、支付弹窗和默认实例。
  bindOptionButtons();
  bindInstanceTabs();
  bindDiskInputs();
  bindModal();
  applyInitialInstanceFromQuery();
  calculatePrice();
}

function bindOptionButtons() {
  // 统一绑定所有配置选项按钮，例如计费模式、地域、实例规格、系统盘类型等。
  $(".option-btn[data-group][data-value]").on("click", function () {
    const $button = $(this);
    selectOption($button.attr("data-group"), $button.attr("data-value"));
  });
}

function bindInstanceTabs() {
  // CPU / GPU 标签切换时，只显示对应的实例列表。
  $("[data-instance-tab]").on("click", function () {
    switchInstanceTab($(this).attr("data-instance-tab"), true);
  });
}

function bindDiskInputs() {
  // 系统盘容量同时支持滑块和数字输入，两者需要保持同步。
  $("#diskSize").on("input", function () {
    updateDiskSize($(this).val());
  });

  $("#diskSizeInput").on("input", function () {
    updateDiskSlider($(this).val());
  });
}

function bindModal() {
  // 购买按钮负责打开支付弹窗，关闭按钮负责隐藏弹窗，支付按钮负责重新请求二维码。
  $("#showBuyModal").on("click", showModal);
  $("[data-close-modal]").on("click", hideModal);
  $("#createPaymentButton").on("click", createBackendPayment);
}

function applyInitialInstanceFromQuery() {
  // 支持 purchase.html?instance=2c4g 这种 URL，进入页面后自动选中对应实例。
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
  // 更新当前选择状态。
  state[group] = value;

  // 同组按钮只保留一个 active 状态。
  $(`.option-btn[data-group="${group}"]`).each(function () {
    const $button = $(this);
    $button.toggleClass("active", $button.attr("data-value") === value);
  });

  if (group === "billing") {
    // 按量计费不需要选择购买时长，包年包月需要显示时长选项。
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

  // 任意配置变化后都重新计算费用和摘要。
  calculatePrice();
}

function switchInstanceTab(type, shouldSelectDefault) {
  // 根据 CPU / GPU 类型切换实例列表，并同步标签样式。
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

    // 用户主动切换标签时，自动选中该分类下的默认实例。
    if (shouldSelectDefault) {
      selectOption("instance", defaultInstances.cpu);
    }
  } else {
    $cpuView.addClass("hidden");
    $gpuView.removeClass("hidden");

    // 用户主动切换到 GPU 时，自动选中默认 GPU 实例。
    if (shouldSelectDefault) {
      selectOption("instance", defaultInstances.gpu);
    }
  }
}

function updateDiskSize(value) {
  // 滑块变化时同步数字输入框，并重新计算价格。
  $("#diskSizeInput").val(value);
  state.diskSize = Number.parseInt(value, 10);
  calculatePrice();
}

function updateDiskSlider(value) {
  // 数字输入框变化时限制容量范围，避免出现小于 40GB 或大于 500GB 的值。
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
  // 价格和摘要节点不存在时直接退出，避免脚本在非购买页报错。
  const $totalPrice = $("#total-price");
  const $summary = $("#summary-text");

  if (!$totalPrice.length || !$summary.length) {
    return;
  }

  // 月价 = 实例价格 + 系统盘单价 * 系统盘容量。
  const instancePrice = pricing.instance[state.instance] || 0;
  const diskPrice = (pricing.disk[state.diskType] || 0) * state.diskSize;
  const baseMonthlyPrice = instancePrice + diskPrice;
  let totalPrice = 0;

  if (state.billing === "hourly") {
    // 按量计费按小时展示，统一保留两位小数。
    totalPrice =
      (baseMonthlyPrice / billingRules.hourlyHoursPerMonth) *
      billingRules.hourlyMultiplier;
    $totalPrice.text(`${totalPrice.toFixed(2)} / 小时`);
  } else {
    // 包年包月根据购买时长计算折扣后的总价。
    const duration = Number.parseInt(state.duration, 10);
    const discount = billingRules.durationDiscounts[duration] || 1;

    totalPrice = baseMonthlyPrice * duration * discount;
    $totalPrice.text(totalPrice.toFixed(2));
  }

  // 摘要用于底部确认区域和支付弹窗展示。
  $summary.text(`${names.billing[state.billing]}, ${names.region[state.region]}, ${names.instance[state.instance]}, ${state.diskSize}GB ${names.diskType[state.diskType]}`);
}

async function showModal() {
  // 每次打开支付弹窗都生成新的订单号和支付金额。
  const orderId = createPaymentOrderId();
  currentPaymentOrderId = orderId;
  currentPaymentAmount = getCurrentPaymentAmount();

  // 将页面当前价格、配置摘要和订单号同步到弹窗中。
  $("#modal-price").text($("#total-price").text());
  $("#modal-summary").text($("#summary-text").text());
  $("#modal-order-id").text(orderId);
  setPaymentStatus("正在生成支付二维码...");
  renderPaymentQrLoading();
  $("#buy-modal").removeClass("hidden");

  // 弹窗打开后自动请求后端生成支付二维码。
  await createBackendPayment();
}

function hideModal() {
  // 关闭弹窗时停止支付状态轮询。
  $("#buy-modal").addClass("hidden");
  stopPaymentQueryPolling();
}

async function createBackendPayment() {
  // 请求生成支付二维码期间禁用按钮，避免重复提交。
  const $button = $("#createPaymentButton");

  $button.text("生成中...").prop("disabled", true);
  setPaymentStatus("正在请求支付接口...");
  setPaymentStatusLoading(false);
  stopPaymentQueryPolling();
  renderPaymentQrLoading();

  try {
    // 调用后端创建支付订单，subject 不能包含中文，避免支付宝接口参数异常。
    const data = await postPaymentJson(paymentApiConfig.createPayment, {
      order_id: currentPaymentOrderId,
      amount: currentPaymentAmount,
      subject: buildPaymentSubject(),
    });

    if (!data.success) {
      throw new Error(data.message || data.error || "支付二维码生成失败");
    }

    // 后端返回支付链接后，通过二维码接口生成可扫码图片，并开始轮询支付状态。
    renderPaymentQr(data.pay_url || data.qr_code);
    setPaymentStatus("等待用户扫码支付");
    startPaymentQueryPolling();
  } catch (error) {
    // 接口失败时在二维码区域展示错误状态。
    renderPaymentQrError();
    setPaymentStatus(error.message || "支付二维码生成失败");
  } finally {
    $button.text("重新生成二维码").prop("disabled", false);
  }
}

function createPaymentOrderId() {
  // 订单号包含实例规格和时间戳，方便控制台从订单号反推出购买规格。
  return `pay_${state.instance}_${Date.now()}`;
}

async function queryBackendPaymentStatus() {
  // 每次轮询时显示查询中的状态提示。
  setPaymentStatusLoading(true);
  setPaymentStatus("正在查询支付状态...");

  try {
    // 通过订单号查询后端支付状态。
    const data = await getPaymentJson(
      `${paymentApiConfig.queryPayment}?order_id=${encodeURIComponent(currentPaymentOrderId)}`,
    );

    if (!data.success) {
      throw new Error(data.message || data.error || "支付状态查询失败");
    }

    if (data.paid) {
      // 支付成功后停止轮询，写入购买记录，再跳转支付成功页。
      stopPaymentQueryPolling();
      setPaymentStatus("支付成功，正在写入购买记录...");
      await savePurchasedService(currentPaymentOrderId);
      setPaymentStatus("支付成功，正在跳转...");
      redirectToPaymentSuccess(currentPaymentOrderId);
      return;
    }

    // 未支付时展示后端返回的交易状态说明。
    setPaymentStatus(getPaymentStatusText(data.trade_status));
  } catch (error) {
    setPaymentStatus(error.message || "支付状态查询失败");
  } finally {
    // 如果轮询已经停止，则隐藏加载动画。
    if (!paymentQueryTimer) {
      setPaymentStatusLoading(false);
    }
  }
}

function redirectToPaymentSuccess(orderId) {
  // 支付完成后带订单号进入成功页，成功页可以展示当前订单。
  const successPage = paymentApiConfig.successPage || "/payment-success.html";
  window.location.href = `${successPage}?order_id=${encodeURIComponent(orderId || "")}`;
}

function buildPaymentSubject() {
  // 支付宝 subject 使用英文，避免接口对中文参数处理不一致。
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
  // 根据当前购买配置组装控制台展示需要的服务记录。
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
  // 支付成功后先写入 localStorage，确保前端控制台立刻可见。
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
    // 同步购买记录到后端，用于后续按用户读取已购资源。
    const result = await syncPurchaseToBackend(service);
    console.log("购买记录已写入后端：", result.item || service);
  } catch (error) {
    // 后端写入失败不影响前端展示，本地记录会保留。
    console.warn(
      "购买记录后端写入失败，已保留本地记录：",
      error.message || error,
    );
  }

  return service;
}

function getStoredPurchasedServices() {
  // 读取本地购买记录，解析失败时返回空数组。
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
  // 后端购买记录写入需要登录 token。
  const token = getAuthToken();

  if (!token) {
    throw new Error("用户未登录");
  }

  // 把订单金额、支付标题和服务信息提交给后端保存。
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
  // token 可能单独存储，也可能保存在完整登录信息里，两处都兼容。
  const loginInfo = readJsonStorage("ajou_login_info");
  return (
    localStorage.getItem("ajou_auth_token") ||
    (loginInfo && loginInfo.token) ||
    ""
  );
}

function readJsonStorage(key) {
  // localStorage 内容可能被手动修改，JSON 解析失败时返回 null。
  try {
    return JSON.parse(localStorage.getItem(key) || "null");
  } catch (error) {
    return null;
  }
}

function getOsName(os) {
  // 将内部系统代号转换成控制台展示名称。
  const osNames = {
    ubuntu: "Ubuntu 22.04 LTS",
    centos: "CentOS 7.9",
    windows: "Windows Server 2022",
  };

  return osNames[os] || os;
}

function getExpireDate(months) {
  // 包年包月资源根据购买月数计算到期日期。
  const date = new Date();
  date.setMonth(date.getMonth() + months);
  return date.toISOString().slice(0, 10);
}

function getCurrentPaymentAmount() {
  // 从页面价格文本中提取数字，作为支付接口的 amount。
  const priceText = $("#total-price").text();
  const match = priceText.match(/\d+(?:\.\d+)?/);
  const amount = match ? Number.parseFloat(match[0]) : 0;

  if (!Number.isFinite(amount) || amount <= 0) {
    // 支付宝测试金额至少保留 0.01，避免 0 元订单。
    return "0.01";
  }

  return Math.max(amount, 0.01).toFixed(2);
}

function setPaymentStatus(text) {
  // 更新弹窗里的支付状态文字。
  $("#payment-status-text").text(text);
}

function setPaymentStatusLoading(isLoading) {
  // 控制支付状态右侧的转圈加载动画。
  $("#payment-status-loading")
    .toggleClass("hidden", !isLoading)
    .toggleClass("flex", isLoading);
}

function startPaymentQueryPolling() {
  // 每 3 秒查询一次支付状态，开始前先清理旧定时器。
  stopPaymentQueryPolling();
  setPaymentStatusLoading(true);
  paymentQueryTimer = window.setInterval(queryBackendPaymentStatus, 3000);
}

function stopPaymentQueryPolling() {
  // 停止支付轮询并隐藏查询动画。
  if (paymentQueryTimer) {
    window.clearInterval(paymentQueryTimer);
    paymentQueryTimer = null;
  }

  setPaymentStatusLoading(false);
}

function renderPaymentQrLoading() {
  // 生成二维码过程中显示加载态。
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
  // 后端返回支付链接后，再通过二维码接口把链接转换成二维码图片。
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
  // 支付接口异常时显示错误态，提示检查后端服务。
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
  // 将支付宝交易状态转换成页面可读文案。
  const statusTextMap = {
    WAIT_BUYER_PAY: "已生成订单，等待买家付款",
    TRADE_CLOSED: "交易已关闭",
    TRADE_FINISHED: "交易已结束",
    TRADE_SUCCESS: "支付成功",
  };

  return statusTextMap[status] || "等待用户扫码支付";
}

function buildApiUrl(path) {
  // 统一拼接后端接口地址，避免 baseUrl 末尾斜杠导致双斜杠。
  const baseUrl = (paymentApiConfig.baseUrl || "").replace(/\/+$/, "");
  return `${baseUrl}${path || ""}`;
}

async function postPaymentJson(path, data, headers = {}) {
  // jQuery POST JSON 请求封装，用于创建支付和写入购买记录。
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
  // jQuery GET 请求封装，用于查询支付状态。
  const text = await requestPaymentText({
    path,
    method: "GET",
  });

  return parsePaymentText(text);
}

function requestPaymentText(options) {
  // 使用 $.ajax 统一发送接口请求，并按文本接收结果，方便手动解析错误信息。
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
  // 后端可能返回非 JSON 文本，先按文本读取，再手动解析，便于给出错误提示。
  try {
    return JSON.parse(text);
  } catch (error) {
    throw new Error(text || "支付接口返回格式错误");
  }
}

function parsePaymentErrorText(text) {
  // 请求失败时优先从 JSON 错误响应里提取 message 或 error。
  try {
    const data = JSON.parse(text || "{}");
    return data.message || data.error || text || "接口请求失败";
  } catch (error) {
    return text || "接口请求失败";
  }
}
