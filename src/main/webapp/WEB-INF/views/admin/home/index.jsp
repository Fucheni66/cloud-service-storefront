<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="active" value="home"/>
<c:set var="pageTitle" value="首页配置"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>首页配置 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6 space-y-6">
            <div class="flex items-center justify-between">
                <div>
                    <h2 class="text-xl font-bold text-gray-900">首页配置</h2>
                    <p class="text-sm text-gray-500 mt-1">配置首页「产品动态」展示内容与「热门产品」权重；推荐卡片在「首页推荐」中维护</p>
                </div>
                <a href="${pageContext.request.contextPath}/index.jsp" target="_blank"
                   class="inline-flex items-center bg-white border border-gray-300 text-gray-700 hover:text-primary hover:border-primary rounded px-4 py-2.5 text-sm font-medium transition">
                    <i class="fa-solid fa-up-right-from-square mr-2"></i> 预览首页
                </a>
            </div>

            <c:if test="${saved eq 'dynamic'}">
                <div class="rounded bg-green-50 border border-green-200 text-green-600 text-sm px-4 py-2.5">
                    <i class="fa-solid fa-circle-check"></i> 产品动态展示设置已保存
                </div>
            </c:if>
            <c:if test="${saved eq 'weights'}">
                <div class="rounded bg-green-50 border border-green-200 text-green-600 text-sm px-4 py-2.5">
                    <i class="fa-solid fa-circle-check"></i> 热门产品权重已保存
                </div>
            </c:if>

            <%-- 1) 产品动态展示设置 --%>
            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl">
                <h3 class="text-base font-bold text-gray-900 mb-1">首页产品动态展示</h3>
                <p class="text-sm text-gray-500 mb-5">首页浮层底部展示的一条产品动态，可指定分类或具体某篇文章</p>
                <form action="${pageContext.request.contextPath}/admin/home" method="post" class="space-y-5">
                    <input type="hidden" name="action" value="dynamic">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">展示分类</label>
                            <select name="dynCategory" class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                <option value="">不限分类（取最新一条）</option>
                                <c:forEach var="cat" items="${categories}">
                                    <option value="${cat.code}" ${dynCategory eq cat.code ? 'selected' : ''}>${cat.name}</option>
                                </c:forEach>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">指定文章</label>
                            <select name="dynSlug" class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                <option value="">该分类最新一条</option>
                                <c:forEach var="p" items="${posts}">
                                    <option value="${p.slug}" ${dynSlug eq p.slug ? 'selected' : ''}>[${p.categoryLabel}] ${p.title}</option>
                                </c:forEach>
                            </select>
                            <p class="text-xs text-gray-400 mt-1">选具体文章后忽略上方分类；留空则取所选分类最新一条</p>
                        </div>
                    </div>
                    <div class="pt-2 border-t border-gray-100">
                        <button type="submit" class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
                            保存动态设置
                        </button>
                    </div>
                </form>
            </div>

            <%-- 2) 热门产品权重 --%>
            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
                <div class="flex items-center justify-between mb-1">
                    <h3 class="text-base font-bold text-gray-900">首页热门产品权重</h3>
                    <a href="${pageContext.request.contextPath}/admin/products" class="text-sm text-primary hover:underline">前往产品规格管理</a>
                </div>
                <p class="text-sm text-gray-500 mb-5">权重 &gt;0 才在首页顶部「热门产品」展示，按权重从高到低取前 4 个（需已上架）</p>
                <form action="${pageContext.request.contextPath}/admin/home" method="post">
                    <input type="hidden" name="action" value="weights">
                    <div style="overflow-x:auto">
                    <table class="w-full text-sm whitespace-nowrap" style="min-width:760px">
                        <thead>
                            <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                                <th class="px-4 py-3 font-medium">规格</th>
                                <th class="px-4 py-3 font-medium">标识</th>
                                <th class="px-4 py-3 font-medium">类型</th>
                                <th class="px-4 py-3 font-medium">月付价</th>
                                <th class="px-4 py-3 font-medium">上架</th>
                                <th class="px-4 py-3 font-medium">首页权重</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="p" items="${products}">
                                <tr class="border-b border-gray-50">
                                    <td class="px-4 py-3 font-medium text-gray-900">${p.title}</td>
                                    <td class="px-4 py-3"><span class="font-mono text-gray-700">${p.instanceCode}</span></td>
                                    <td class="px-4 py-3 text-gray-600">${p.gpu ? 'GPU' : 'CPU'}</td>
                                    <td class="px-4 py-3 text-gray-600">¥${p.priceMonthly}</td>
                                    <td class="px-4 py-3">
                                        <c:choose>
                                            <c:when test="${p.active}">
                                                <span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">已上架</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">已下架</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="px-4 py-3">
                                        <input type="number" name="weight_${p.id}" value="${p.homeWeight}" min="0"
                                               class="w-24 border border-gray-300 rounded px-2 py-1.5 text-sm focus:outline-none focus:border-primary">
                                    </td>
                                </tr>
                            </c:forEach>
                            <c:if test="${empty products}">
                                <tr><td colspan="6" class="px-4 py-10 text-center text-gray-400">暂无产品规格</td></tr>
                            </c:if>
                        </tbody>
                    </table>
                    </div>
                    <div class="pt-4 mt-2 border-t border-gray-100">
                        <button type="submit" class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
                            保存权重
                        </button>
                    </div>
                </form>
            </div>
        </main>
    </div>
</div>
</body>
</html>
