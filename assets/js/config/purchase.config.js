// 购买配置页的默认参数、价格规则
window.PURCHASE_PAGE_CONFIG = {
  // 页面首次打开时默认选中的配置项。
  defaultState: {
    billing: "monthly", // 默认计费模式：monthly=包年包月，hourly=按量计费。
    region: "beijing", // 默认地域。
    instance: "2c4g", // 默认实例规格。
    os: "ubuntu", // 默认操作系统。
    diskType: "ssd", // 默认系统盘类型。
    diskSize: 40, // 默认系统盘容量，单位 GB。
    duration: "1", // 默认购买时长，单位月。
  },

  // 价格配置，实例为元/月，磁盘为元/GB/月。
  pricing: {
    instance: {
      "2c4g": 60,
      "4c8g": 120,
      "8c16g": 250,
      gpu_t4: 1200,
      gpu_a100: 8500,
    },
    disk: {
      ssd: 0.5, // 通用型 SSD 单价，元/GB/月。
      essd: 1, // 极速型 ESSD 单价，元/GB/月。
    },
  },

  // 计费规则配置。
  billingRules: {
    hourlyHoursPerMonth: 720, // 按量计费用于换算的每月小时数。
    hourlyMultiplier: 1, // 按量计费相对包月单小时价格的倍率。
    durationDiscounts: {
      1: 1, // 1个月无折扣。
      3: 0.9, // 3个月 9折。
      6: 0.85, // 6个月 8.5折。
      12: 0.8, // 12个月 8折。
    },
  },

  // CPU/GPU Tab 切换时默认选中的实例。
  defaultInstances: {
    cpu: "2c4g",
    gpu: "gpu_t4",
  },

  // 配置摘要里显示的中文名称。
  names: {
    billing: {
      monthly: "包年包月",
      hourly: "按量计费",
    },
    region: {
      beijing: "华北2(北京)",
      shanghai: "华东2(上海)",
      guangzhou: "华南1(广州)",
      singapore: "亚太(新加坡)",
    },
    instance: {
      "2c4g": "2核 4G",
      "4c8g": "4核 8G",
      "8c16g": "8核 16G",
      gpu_t4: "GPU T4",
      gpu_a100: "GPU A100",
    },
    diskType: {
      ssd: "通用型SSD",
      essd: "极速型ESSD",
    },
  },

  // CPU/GPU Tab 的激活与未激活样式。
  tabClasses: {
    active:
      "instance-tab px-4 py-1 rounded bg-white shadow-sm text-primary font-medium text-sm transition",
    inactive:
      "instance-tab px-4 py-1 rounded text-gray-600 hover:text-primary text-sm transition",
  },
};
