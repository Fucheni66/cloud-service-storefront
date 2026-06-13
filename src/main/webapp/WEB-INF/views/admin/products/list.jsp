<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="products"/>
<c:set var="pageTitle" value="云产品规格"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>云产品规格 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <%-- 标题行 + 新增按钮 --%>
            <div class="flex items-center justify-between mb-6">
                <div>
                    <h2 class="text-xl font-bold text-gray-900">云产品规格（SKU）</h2>
                    <p class="text-sm text-gray-500 mt-1">共 ${specs.size()} 个规格 · 管理云服务器实例的规格与定价</p>
                </div>
                <a href="${pageContext.request.contextPath}/admin/products?action=new"
                   class="inline-flex items-center bg-primary hover:bg-primary-hover text-white rounded px-5 py-2.5 text-sm font-medium transition shadow-sm">
                    <i class="fa-solid fa-plus mr-2"></i> 新增规格
                </a>
            </div>

            <%-- 列表表格 --%>
            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 font-medium">排序</th>
                            <th class="px-4 py-3 font-medium">规格标识</th>
                            <th class="px-4 py-3 font-medium">名称</th>
                            <th class="px-4 py-3 font-medium">类型</th>
                            <th class="px-4 py-3 font-medium">配置</th>
                            <th class="px-4 py-3 font-medium">月付价</th>
                            <th class="px-4 py-3 font-medium">状态</th>
                            <th class="px-4 py-3 font-medium text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="s" items="${specs}">
                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                <td class="px-4 py-3 text-gray-400">${s.sortOrder}</td>
                                <td class="px-4 py-3">
                                    <span class="font-mono text-gray-900">${s.instanceCode}</span>
                                    <c:if test="${not empty s.badgeText}">
                                        <span class="ml-1 text-[10px] bg-blue-100 text-primary rounded px-1.5 py-0.5">${s.badgeText}</span>
                                    </c:if>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="font-medium text-gray-900">${s.title}</div>
                                    <div class="text-xs text-gray-400">${s.description}</div>
                                </td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${s.gpu}">
                                            <span class="text-xs bg-purple-100 text-purple-600 rounded-full px-2 py-0.5">GPU</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-xs bg-blue-50 text-primary rounded-full px-2 py-0.5">CPU</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3 text-gray-600">
                                    ${s.vcpu}核 / ${s.memoryGb}G
                                    <c:if test="${not empty s.gpuInfo}"><div class="text-xs text-gray-400">${s.gpuInfo}</div></c:if>
                                </td>
                                <td class="px-4 py-3 font-medium text-gray-900">¥${s.priceMonthly}<span class="text-xs text-gray-400 font-normal">${s.unit}</span></td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${s.active}">
                                            <span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">已上架</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">已下架</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-end gap-2">
                                        <a href="${pageContext.request.contextPath}/admin/products?action=edit&id=${s.id}"
                                           class="text-primary hover:underline">编辑</a>
                                        <%-- 上下架切换 --%>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/products" class="inline">
                                            <input type="hidden" name="action" value="toggle">
                                            <input type="hidden" name="id" value="${s.id}">
                                            <input type="hidden" name="active" value="${s.active ? 0 : 1}">
                                            <button type="submit" class="text-gray-500 hover:text-primary">${s.active ? '下架' : '上架'}</button>
                                        </form>
                                        <%-- 删除 --%>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/products" class="inline"
                                              onsubmit="return confirm('确定删除规格「${s.title}」？');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="id" value="${s.id}">
                                            <button type="submit" class="text-red-500 hover:underline">删除</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty specs}">
                            <tr><td colspan="8" class="px-4 py-10 text-center text-gray-400">暂无规格，点击右上角「新增规格」添加</td></tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>
    </div>
</div>
</body>
</html>
