// 购买配置页的默认参数、价格规则
window.PURCHASE_PAGE_CONFIG = {
  defaultState: {
    billing: "monthly",
    region: "beijing",
    instance: "2c4g",
    os: "ubuntu",
    diskType: "ssd",
    diskSize: 40,
    duration: "1",
  },

  pricing: {
    instance: {
      "2c4g": 60,
      "4c8g": 120,
      "8c16g": 250,
      gpu_t4: 1200,
      gpu_a100: 8500,
    },
    disk: {
      ssd: 0.5,
      essd: 1,
    },
  },

  billingRules: {
    hourlyHoursPerMonth: 720,
    hourlyMultiplier: 1,
    durationDiscounts: {
      1: 1,
      3: 0.9,
      6: 0.85,
      12: 0.8,
    },
  },

  defaultInstances: {
    cpu: "2c4g",
    gpu: "gpu_t4",
  },

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

  tabClasses: {
    active:
      "instance-tab px-4 py-1 rounded bg-white shadow-sm text-primary font-medium text-sm transition",
    inactive:
      "instance-tab px-4 py-1 rounded text-gray-600 hover:text-primary text-sm transition",
  },
};
