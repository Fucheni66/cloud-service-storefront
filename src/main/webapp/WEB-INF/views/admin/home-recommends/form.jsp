<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="active" value="home-recommends"/>
<c:set var="isEdit" value="${formMode eq 'edit'}"/>
<c:set var="pageTitle" value="${isEdit ? '编辑推荐卡片' : '新增推荐卡片'}"/>
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
            <div class="text-sm text-gray-500 mb-4">
                <a href="${pageContext.request.contextPath}/admin/home-recommends" class="hover:text-primary">首页推荐</a>
                <span class="mx-2">/</span>
                <span class="text-gray-900">${pageTitle}</span>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl">
                <c:if test="${not empty error}">
                    <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                        <i class="fa-solid fa-circle-exclamation"></i> ${error}
                    </div>
                </c:if>

                <form action="${pageContext.request.contextPath}/admin/home-recommends" method="post" class="space-y-5">
                    <input type="hidden" name="action" value="save">
                    <input type="hidden" name="id" value="${item.id}">

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">所属标签 <span class="text-red-500">*</span></label>
                            <select name="tab" class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                <c:forEach var="t" items="${tabs}">
                                    <option value="${t.key}" ${item.tab eq t.key ? 'selected' : ''}>${t.value}</option>
                                </c:forEach>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">标题 <span class="text-red-500">*</span></label>
                            <input type="text" name="title" value="${item.title}" required
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 个人网站服务器">
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">描述</label>
                        <textarea name="description" rows="2"
                                  class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary resize-y"
                                  placeholder="一句话说明适用场景">${item.description}</textarea>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">图标 class</label>
                            <input type="text" name="icon" value="${empty item.icon ? 'fa-solid fa-server' : item.icon}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary font-mono"
                                   placeholder="如 fa-solid fa-globe">
                            <p class="text-xs text-gray-400 mt-1">FontAwesome 图标类名，如 fa-solid fa-robot</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">推荐配置文案</label>
                            <input type="text" name="specText" value="${item.specText}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 2核 4G / 40GB SSD">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">展示价格</label>
                            <input type="text" name="price" value="${item.price}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 60">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">价格单位</label>
                            <input type="text" name="unit" value="${empty item.unit ? '/月起' : item.unit}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">排序权重</label>
                            <input type="number" name="sortOrder" value="${item.sortOrder}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                            <p class="text-xs text-gray-400 mt-1">同标签内升序排列</p>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">跳转规格标识 <span class="text-gray-400 text-xs">(可选)</span></label>
                            <input type="text" name="instanceCode" value="${item.instanceCode}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary font-mono"
                                   placeholder="如 2c4g / gpu_t4">
                            <p class="text-xs text-gray-400 mt-1">点击「立即选购」跳转 purchase.jsp?instance= 的规格</p>
                        </div>
                        <div class="flex items-end pb-2.5">
                            <label class="inline-flex items-center text-sm text-gray-700">
                                <input type="checkbox" name="active" value="1" ${(item.id eq 0 or item.active) ? 'checked' : ''}
                                       class="w-4 h-4 mr-2 accent-primary">
                                在首页展示
                            </label>
                        </div>
                    </div>

                    <div class="flex items-center gap-3 pt-2 border-t border-gray-100">
                        <button type="submit"
                                class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
                            ${isEdit ? '保存修改' : '创建卡片'}
                        </button>
                        <a href="${pageContext.request.contextPath}/admin/home-recommends"
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
