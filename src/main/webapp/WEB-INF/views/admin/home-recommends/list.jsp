<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="active" value="home-recommends"/>
<c:set var="pageTitle" value="首页推荐"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>首页推荐 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <div class="flex items-center justify-between mb-6">
                <div>
                    <h2 class="text-xl font-bold text-gray-900">首页热门产品推荐</h2>
                    <p class="text-sm text-gray-500 mt-1">
                        <c:choose>
                            <c:when test="${not empty tabFilter}">「${tabs[tabFilter]}」共 ${items.size()} 张卡片</c:when>
                            <c:otherwise>共 ${items.size()} 张卡片 · 对应首页「热门产品推荐」三个标签，按标签内排序展示</c:otherwise>
                        </c:choose>
                    </p>
                </div>
                <a href="${pageContext.request.contextPath}/admin/home-recommends?action=new"
                   class="inline-flex items-center bg-primary hover:bg-primary-hover text-white rounded px-5 py-2.5 text-sm font-medium transition shadow-sm">
                    <i class="fa-solid fa-plus mr-2"></i> 新增卡片
                </a>
            </div>

            <%-- 标签筛选：切换下拉自动刷新，默认展示第一个标签 --%>
            <form method="get" action="${pageContext.request.contextPath}/admin/home-recommends"
                  class="flex items-center gap-2 mb-4">
                <label class="text-sm text-gray-500">标签</label>
                <select name="tab" onchange="this.form.submit()"
                        class="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary sm:w-56">
                    <c:forEach var="t" items="${tabs}">
                        <option value="${t.key}" ${tabFilter eq t.key ? 'selected' : ''}>${t.value}</option>
                    </c:forEach>
                    <option value="" ${empty tabFilter ? 'selected' : ''}>全部标签</option>
                </select>
            </form>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <div style="overflow-x:auto">
                <table class="w-full text-sm whitespace-nowrap" style="min-width:980px">
                    <thead>
                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 font-medium">标签</th>
                            <th class="px-4 py-3 font-medium">排序</th>
                            <th class="px-4 py-3 font-medium">图标</th>
                            <th class="px-4 py-3 font-medium">标题 / 描述</th>
                            <th class="px-4 py-3 font-medium">推荐配置</th>
                            <th class="px-4 py-3 font-medium">价格</th>
                            <th class="px-4 py-3 font-medium">跳转规格</th>
                            <th class="px-4 py-3 font-medium">状态</th>
                            <th class="px-4 py-3 font-medium text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="r" items="${items}">
                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                <td class="px-4 py-3">
                                    <span class="inline-flex items-center text-xs font-medium px-2 py-1 rounded
                                        ${r.gpu ? 'bg-purple-50 text-purple-600 border border-purple-100' : 'bg-blue-50 text-primary border border-blue-100'}">
                                        ${r.tabLabel}
                                    </span>
                                </td>
                                <td class="px-4 py-3 text-gray-400">${r.sortOrder}</td>
                                <td class="px-4 py-3 text-gray-500 ${r.gpu ? 'text-purple-600' : 'text-primary'} text-lg">
                                    <i class="${r.icon}"></i>
                                </td>
                                <td class="px-4 py-3" style="white-space:normal;min-width:240px;max-width:380px">
                                    <div class="font-medium text-gray-900">${r.title}</div>
                                    <div class="text-xs text-gray-400">${r.description}</div>
                                </td>
                                <td class="px-4 py-3 text-gray-600">${r.specText}</td>
                                <td class="px-4 py-3 text-gray-600">
                                    <c:if test="${not empty r.price}">¥${r.price}<span class="text-xs text-gray-400 ml-0.5">${r.unit}</span></c:if>
                                </td>
                                <td class="px-4 py-3"><span class="font-mono text-gray-700">${r.instanceCode}</span></td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${r.active}">
                                            <span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">展示中</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">已隐藏</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-end gap-2">
                                        <a href="${pageContext.request.contextPath}/admin/home-recommends?action=edit&id=${r.id}"
                                           class="text-primary hover:underline">编辑</a>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/home-recommends" class="inline">
                                            <input type="hidden" name="action" value="toggle">
                                            <input type="hidden" name="id" value="${r.id}">
                                            <input type="hidden" name="active" value="${r.active ? 0 : 1}">
                                            <button type="submit" class="text-gray-500 hover:text-primary">${r.active ? '隐藏' : '展示'}</button>
                                        </form>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/home-recommends" class="inline"
                                              onsubmit="return confirm('确定删除卡片「${r.title}」？');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="id" value="${r.id}">
                                            <button type="submit" class="text-red-500 hover:underline">删除</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty items}">
                            <tr><td colspan="9" class="px-4 py-10 text-center text-gray-400">暂无推荐卡片，点击右上角「新增卡片」添加</td></tr>
                        </c:if>
                    </tbody>
                </table>
                </div>
            </div>
        </main>
    </div>
</div>
</body>
</html>
