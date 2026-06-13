<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="active" value="dynamics"/>
<c:set var="isEdit" value="${formMode eq 'edit'}"/>
<c:set var="pageTitle" value="${isEdit ? '编辑动态' : '发布动态'}"/>
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
                <a href="${pageContext.request.contextPath}/admin/dynamics" class="hover:text-primary">产品动态</a>
                <span class="mx-2">/</span>
                <span class="text-gray-900">${pageTitle}</span>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl">
                <c:if test="${not empty error}">
                    <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                        <i class="fa-solid fa-circle-exclamation"></i> ${error}
                    </div>
                </c:if>

                <form action="${pageContext.request.contextPath}/admin/dynamics" method="post" class="space-y-5">
                    <input type="hidden" name="action" value="save">
                    <input type="hidden" name="id" value="${post.id}">

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">URL 标识 <span class="text-red-500">*</span></label>
                            <input type="text" name="slug" value="${post.slug}" required
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary font-mono"
                                   placeholder="如 release-a100">
                            <p class="text-xs text-gray-400 mt-1">前台详情页 ?id= 取此值，全站唯一</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">分类</label>
                            <select name="category"
                                    class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                <c:forEach var="cat" items="${categories}">
                                    <option value="${cat.code}" ${post.category eq cat.code ? 'selected' : ''}>${cat.name}</option>
                                </c:forEach>
                            </select>
                            <p class="text-xs text-gray-400 mt-1"><a href="${pageContext.request.contextPath}/admin/dynamic-categories" class="hover:text-primary">管理分类 →</a></p>
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">标题 <span class="text-red-500">*</span></label>
                        <input type="text" name="title" value="${post.title}" required
                               class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                               placeholder="如 GPU A100 训练实例上线">
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">列表摘要</label>
                        <input type="text" name="summary" value="${post.summary}"
                               class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                               placeholder="动态列表卡片上展示的一句话摘要">
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">正文</label>
                        <textarea name="content" rows="10"
                                  class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary resize-y"
                                  placeholder="详情页正文，段落之间用空行分隔">${post.content}</textarea>
                        <p class="text-xs text-gray-400 mt-1">段落之间留一个空行，前台会自动分段</p>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">适用产品 / 影响范围</label>
                            <input type="text" name="productScope" value="${post.productScope}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 适用产品：GPU 云服务器">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">角标文案 <span class="text-gray-400 text-xs">(留空用分类名)</span></label>
                            <input type="text" name="badgeText" value="${post.badgeText}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 配套支持">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">发布日期</label>
                            <input type="date" name="publishedAt" value="${post.publishedAt}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">排序权重</label>
                            <input type="number" name="sortOrder" value="${post.sortOrder}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                        <div class="flex items-end pb-2.5">
                            <label class="inline-flex items-center text-sm text-gray-700">
                                <input type="checkbox" name="published" value="1" ${post.published ? 'checked' : ''}
                                       class="w-4 h-4 mr-2 accent-primary">
                                发布（前台可见）
                            </label>
                        </div>
                    </div>

                    <div class="flex items-center gap-3 pt-2 border-t border-gray-100">
                        <button type="submit"
                                class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
                            ${isEdit ? '保存修改' : '发布动态'}
                        </button>
                        <a href="${pageContext.request.contextPath}/admin/dynamics"
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
