<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="active" value="dynamic-categories"/>
<c:set var="isEdit" value="${formMode eq 'edit'}"/>
<c:set var="pageTitle" value="${isEdit ? '编辑分类' : '新增分类'}"/>
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
                <a href="${pageContext.request.contextPath}/admin/dynamic-categories" class="hover:text-primary">动态分类</a>
                <span class="mx-2">/</span>
                <span class="text-gray-900">${pageTitle}</span>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-2xl">
                <c:if test="${not empty error}">
                    <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                        <i class="fa-solid fa-circle-exclamation"></i> ${error}
                    </div>
                </c:if>

                <form action="${pageContext.request.contextPath}/admin/dynamic-categories" method="post" class="space-y-5">
                    <input type="hidden" name="action" value="save">
                    <input type="hidden" name="id" value="${category.id}">

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">分类标识 <span class="text-red-500">*</span></label>
                            <input type="text" name="code" value="${category.code}" required
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary font-mono"
                                   placeholder="如 release / tutorial">
                            <p class="text-xs text-gray-400 mt-1">字母数字下划线连字符，全站唯一；修改后引用此分类的文章会同步更新</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">分类名称 <span class="text-red-500">*</span></label>
                            <input type="text" name="name" value="${category.name}" required
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 新品发布 / 精选教程">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">角标配色</label>
                            <select name="color"
                                    class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                <c:forEach var="col" items="${colors}">
                                    <option value="${col.key}" ${category.color eq col.key ? 'selected' : ''}>${col.label}（${col.key}）</option>
                                </c:forEach>
                            </select>
                            <div class="mt-2 flex flex-wrap gap-2">
                                <c:forEach var="col" items="${colors}">
                                    <span class="inline-flex items-center text-xs font-medium px-2 py-1 rounded ${col.badge}">${col.label}</span>
                                </c:forEach>
                            </div>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">排序权重</label>
                            <input type="number" name="sortOrder" value="${category.sortOrder}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                        <div class="flex items-end pb-2.5">
                            <label class="inline-flex items-center text-sm text-gray-700">
                                <input type="checkbox" name="active" value="1" ${category.id eq 0 or category.active ? 'checked' : ''}
                                       class="w-4 h-4 mr-2 accent-primary">
                                启用
                            </label>
                        </div>
                    </div>

                    <div class="flex items-center gap-3 pt-2 border-t border-gray-100">
                        <button type="submit"
                                class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
                            ${isEdit ? '保存修改' : '创建分类'}
                        </button>
                        <a href="${pageContext.request.contextPath}/admin/dynamic-categories"
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
