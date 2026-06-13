<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="active" value="products"/>
<c:set var="isEdit" value="${formMode eq 'edit'}"/>
<c:set var="pageTitle" value="${isEdit ? '编辑规格' : '新增规格'}"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>${pageTitle} · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <%-- 面包屑 --%>
            <div class="text-sm text-gray-500 mb-4">
                <a href="${pageContext.request.contextPath}/admin/products" class="hover:text-primary">云产品规格</a>
                <span class="mx-2">/</span>
                <span class="text-gray-900">${pageTitle}</span>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl">
                <c:if test="${not empty error}">
                    <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                        <i class="fa-solid fa-circle-exclamation"></i> ${error}
                    </div>
                </c:if>

                <form action="${pageContext.request.contextPath}/admin/products" method="post" class="space-y-5">
                    <input type="hidden" name="action" value="save">
                    <input type="hidden" name="id" value="${spec.id}">

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">规格标识 <span class="text-red-500">*</span></label>
                            <input type="text" name="instanceCode" value="${spec.instanceCode}" required
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary font-mono"
                                   placeholder="如 2c4g / gpu_t4">
                            <p class="text-xs text-gray-400 mt-1">字母、数字、下划线，全站唯一</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">展示名称 <span class="text-red-500">*</span></label>
                            <input type="text" name="title" value="${spec.title}" required
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 入门型 2c4g">
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">副标题 / 适用说明</label>
                        <input type="text" name="description" value="${spec.description}"
                               class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                               placeholder="如 通用型 g7 | 适合个人开发者建站、测试">
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">类型</label>
                            <select name="category"
                                    class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                <option value="cpu" ${spec.category eq 'gpu' ? '' : 'selected'}>通用计算型 (CPU)</option>
                                <option value="gpu" ${spec.category eq 'gpu' ? 'selected' : ''}>异构计算型 (GPU)</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">vCPU 核数</label>
                            <input type="number" name="vcpu" value="${spec.vcpu}" min="0"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">内存 (GB)</label>
                            <input type="number" name="memoryGb" value="${spec.memoryGb}" min="0"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">第三项规格</label>
                            <input type="text" name="featureSpec" value="${spec.featureSpec}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="CPU 填带宽 / GPU 填算力">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">GPU 信息 <span class="text-gray-400 text-xs">(CPU 型留空)</span></label>
                            <input type="text" name="gpuInfo" value="${spec.gpuInfo}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 1 * NVIDIA T4 16GB">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">月付价 (元)</label>
                            <input type="number" name="priceMonthly" value="${spec.priceMonthly}" min="0" step="0.01"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">价格单位</label>
                            <input type="text" name="unit" value="${empty spec.unit ? '/月起' : spec.unit}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">排序权重</label>
                            <input type="number" name="sortOrder" value="${spec.sortOrder}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">徽章文案 <span class="text-gray-400 text-xs">(可选)</span></label>
                            <input type="text" name="badgeText" value="${spec.badgeText}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 畅销">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">首页热门权重</label>
                            <input type="number" name="homeWeight" value="${spec.homeWeight}" min="0"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                            <p class="text-xs text-gray-400 mt-1">&gt;0 才在首页「热门产品」展示，按权重降序取前 4</p>
                        </div>
                        <div class="flex items-end pb-2.5">
                            <label class="inline-flex items-center text-sm text-gray-700">
                                <input type="checkbox" name="active" value="1" ${spec.active ? 'checked' : ''}
                                       class="w-4 h-4 mr-2 accent-primary">
                                上架（在前台可见）
                            </label>
                        </div>
                    </div>

                    <div class="flex items-center gap-3 pt-2 border-t border-gray-100">
                        <button type="submit"
                                class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
                            ${isEdit ? '保存修改' : '创建规格'}
                        </button>
                        <a href="${pageContext.request.contextPath}/admin/products"
                           class="border border-gray-300 bg-white text-gray-700 rounded px-5 py-2.5 text-sm hover:text-primary hover:border-primary transition">
                            取消
                        </a>
                    </div>
                </form>
            </div>
        </main>
    </div>
</div>
</body>
</html>
