// 产品列表页的分类、实例规格、价格和展示样式配置。
window.PRODUCT_PAGE_CONFIG = {
  hero: {
    title: '选择适合您的云服务器',
    description: '提供多种实例规格，满足不同场景的计算需求，支持一键选购配置。'
  },
  sections: [
    {
      id: 'cpu',
      title: '通用计算型 (CPU)',
      icon: 'fa-solid fa-server',
      iconClass: 'text-primary',
      headingClass: '',
      gridClass: 'mb-12',
      cardHoverClass: 'hover:border-primary',
      buttonClass: 'bg-primary hover:bg-primary-hover',
      products: [
        {
          title: '入门型 2c4g',
          description: '通用型 g7 | 适合个人开发者建站、测试',
          instance: '2c4g',
          badge: {
            text: '畅销',
            className: 'bg-blue-100 text-primary'
          },
          specs: [
            { icon: 'fa-solid fa-microchip', text: '2核 vCPU' },
            { icon: 'fa-solid fa-memory', text: '4GB 内存' },
            { icon: 'fa-solid fa-network-wired', text: '最高 5Gbps 内网带宽' }
          ],
          price: '60',
          unit: '/月起'
        },
        {
          title: '企业型 4c8g',
          description: '通用型 g7 | 适合中小企业应用、数据库',
          instance: '4c8g',
          specs: [
            { icon: 'fa-solid fa-microchip', text: '4核 vCPU' },
            { icon: 'fa-solid fa-memory', text: '8GB 内存' },
            { icon: 'fa-solid fa-network-wired', text: '最高 10Gbps 内网带宽' }
          ],
          price: '120',
          unit: '/月起'
        },
        {
          title: '高计算型 8c16g',
          description: '计算型 c7 | 高并发Web、大型游戏服',
          instance: '8c16g',
          specs: [
            { icon: 'fa-solid fa-microchip', text: '8核 vCPU' },
            { icon: 'fa-solid fa-memory', text: '16GB 内存' },
            { icon: 'fa-solid fa-network-wired', text: '最高 15Gbps 内网带宽' }
          ],
          price: '250',
          unit: '/月起'
        }
      ]
    },
    {
      id: 'gpu',
      title: '异构计算型 (GPU)',
      icon: 'fa-solid fa-robot',
      iconClass: 'text-purple-600',
      headingClass: 'mt-8',
      gridClass: '',
      cardHoverClass: 'hover:border-purple-500',
      buttonClass: 'bg-purple-600 hover:bg-purple-700',
      products: [
        {
          title: 'AI 推理型 T4',
          description: '含 1 * NVIDIA T4 | 轻量级AI推理、云游戏',
          instance: 'gpu_t4',
          specs: [
            { icon: 'fa-solid fa-microchip', text: '4核 16G 基础计算' },
            { icon: 'fa-solid fa-memory', text: '16GB 显存容量' },
            { icon: 'fa-solid fa-gauge-high', text: '130 TOPS INT8 算力' }
          ],
          price: '1200',
          unit: '/月起'
        },
        {
          title: 'AI 训练型 A100',
          description: '含 1 * NVIDIA A100 | 深度学习、大模型训练',
          instance: 'gpu_a100',
          specs: [
            { icon: 'fa-solid fa-microchip', text: '12核 96G 基础计算' },
            { icon: 'fa-solid fa-memory', text: '40GB/80GB 显存容量' },
            { icon: 'fa-solid fa-gauge-high', text: '624 TFLOPS 算力' }
          ],
          price: '8500',
          unit: '/月起'
        }
      ]
    }
  ]
};
