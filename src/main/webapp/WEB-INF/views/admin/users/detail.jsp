<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="users"/>
<c:set var="pageTitle" value="用户详情"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>用户详情 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <div class="text-sm text-gray-500 mb-4">
                <a href="${pageContext.request.contextPath}/admin/users" class="hover:text-primary">用户管理</a>
                <span class="mx-2">/</span>
                <span class="text-gray-900">用户详情</span>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl">
                <%-- 头部 --%>
                <div class="flex items-center pb-5 border-b border-gray-100">
                    <c:choose>
                        <c:when test="${not empty user.picture}">
                            <img src="${user.picture}" alt="" class="w-16 h-16 rounded-full mr-4" referrerpolicy="no-referrer">
                        </c:when>
                        <c:otherwise>
                            <span class="w-16 h-16 rounded-full bg-blue-50 text-primary flex items-center justify-center mr-4"><i class="fa-solid fa-user text-2xl"></i></span>
                        </c:otherwise>
                    </c:choose>
                    <div>
                        <div class="text-xl font-bold text-gray-900">${empty user.displayName ? '(未命名)' : user.displayName}</div>
                        <div class="text-sm text-gray-500">${user.email}</div>
                        <div class="mt-1">
                            <c:choose>
                                <c:when test="${user.disabled}"><span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">已禁用</span></c:when>
                                <c:otherwise><span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">正常</span></c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </div>

                <%-- 字段明细 --%>
                <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-4 py-5 text-sm">
                    <div><dt class="text-gray-500">来源</dt><dd class="text-gray-900 mt-0.5">${user.google ? 'Google 登录' : '邮箱注册'}</dd></div>
                    <div><dt class="text-gray-500">来源 ID</dt><dd class="text-gray-900 mt-0.5 font-mono text-xs break-all">${user.extId}</dd></div>
                    <div><dt class="text-gray-500">邮箱是否已验证</dt><dd class="text-gray-900 mt-0.5">${user.emailVerified ? '已验证' : '未验证'}</dd></div>
                    <div><dt class="text-gray-500">累计登录次数</dt><dd class="text-gray-900 mt-0.5">${user.loginCount}</dd></div>
                    <c:if test="${user.google}">
                        <div><dt class="text-gray-500">Google Sub</dt><dd class="text-gray-900 mt-0.5 font-mono text-xs break-all">${user.googleSub}</dd></div>
                    </c:if>
                    <div><dt class="text-gray-500">注册时间</dt><dd class="text-gray-900 mt-0.5"><fmt:formatDate value="${user.createdAt}" pattern="yyyy-MM-dd HH:mm"/></dd></div>
                    <div><dt class="text-gray-500">最近登录</dt><dd class="text-gray-900 mt-0.5"><c:choose><c:when test="${empty user.lastLoginAt}">—</c:when><c:otherwise><fmt:formatDate value="${user.lastLoginAt}" pattern="yyyy-MM-dd HH:mm"/></c:otherwise></c:choose></dd></div>
                </dl>

                <%-- 操作 --%>
                <div class="flex items-center gap-3 pt-4 border-t border-gray-100">
                    <form method="post" action="${pageContext.request.contextPath}/admin/users">
                        <input type="hidden" name="action" value="toggle">
                        <input type="hidden" name="id" value="${user.id}">
                        <input type="hidden" name="status" value="${user.disabled ? 'active' : 'disabled'}">
                        <button type="submit" class="border border-gray-300 bg-white text-gray-700 rounded px-5 py-2.5 text-sm hover:text-primary hover:border-primary transition">
                            ${user.disabled ? '启用账号' : '禁用账号'}
                        </button>
                    </form>
                    <form method="post" action="${pageContext.request.contextPath}/admin/users"
                          onsubmit="return confirm('确定删除该用户？');">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="${user.id}">
                        <button type="submit" class="border border-red-200 bg-white text-red-500 rounded px-5 py-2.5 text-sm hover:bg-red-50 transition">删除用户</button>
                    </form>
                    <a href="${pageContext.request.contextPath}/admin/users" class="ml-auto text-sm text-gray-500 hover:text-primary">返回列表</a>
                </div>
            </div>

            <%-- 该用户购买的云实例 / 订单：支持复选批量删除，删除后前台控制台不再显示 --%>
            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl mt-6">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-base font-bold text-gray-900">购买的云实例 / 订单（${orders.size()}）</h3>
                </div>

                <c:if test="${param.ordersDeleted eq '1'}">
                    <div class="mb-4 rounded bg-green-50 border border-green-200 text-green-600 text-sm px-4 py-2.5">
                        <i class="fa-solid fa-circle-check"></i> 已删除所选记录，前台该用户控制台将不再显示
                    </div>
                </c:if>

                <c:choose>
                    <c:when test="${empty orders}">
                        <p class="text-sm text-gray-400 py-6 text-center">该用户暂无购买记录</p>
                    </c:when>
                    <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/admin/users"
                              onsubmit="return confirm('确定删除选中的购买记录？删除后前台控制台将不再显示。');">
                            <input type="hidden" name="action" value="deleteOrders">
                            <input type="hidden" name="id" value="${user.id}">
                            <div class="overflow-hidden border border-gray-100 rounded-lg">
                                <table class="w-full text-sm">
                                    <thead>
                                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                                            <th class="px-3 py-2.5 w-10"><input type="checkbox" id="check-all" title="全选"></th>
                                            <th class="px-3 py-2.5 font-medium">实例 / 订单号</th>
                                            <th class="px-3 py-2.5 font-medium">规格 / 地域</th>
                                            <th class="px-3 py-2.5 font-medium">金额</th>
                                            <th class="px-3 py-2.5 font-medium">状态</th>
                                            <th class="px-3 py-2.5 font-medium">到期时间</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach var="o" items="${orders}">
                                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                                <td class="px-3 py-2.5"><input type="checkbox" name="orderIds" value="${o.id}" class="order-check"></td>
                                                <td class="px-3 py-2.5">
                                                    <div class="text-gray-900">${o.instanceName}</div>
                                                    <div class="text-xs text-gray-400 font-mono">${o.orderNo}</div>
                                                </td>
                                                <td class="px-3 py-2.5 text-gray-600">${o.instanceCode}<div class="text-xs text-gray-400">${o.regionLabel}</div></td>
                                                <td class="px-3 py-2.5 font-medium text-gray-900">¥${o.amount}</td>
                                                <td class="px-3 py-2.5">
                                                    <c:choose>
                                                        <c:when test="${o.status eq 'running'}"><span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">运行中</span></c:when>
                                                        <c:when test="${o.status eq 'pending'}"><span class="text-xs bg-orange-50 text-orange-500 border border-orange-200 rounded-full px-2 py-0.5">待支付</span></c:when>
                                                        <c:when test="${o.status eq 'expired'}"><span class="text-xs bg-red-50 text-red-500 border border-red-200 rounded-full px-2 py-0.5">已到期</span></c:when>
                                                        <c:otherwise><span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">${o.statusLabel}</span></c:otherwise>
                                                    </c:choose>
                                                </td>
                                                <td class="px-3 py-2.5 text-gray-500"><c:choose><c:when test="${empty o.expireAt}">—</c:when><c:otherwise><fmt:formatDate value="${o.expireAt}" pattern="yyyy-MM-dd"/></c:otherwise></c:choose></td>
                                            </tr>
                                        </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                            <div class="flex items-center gap-3 mt-4">
                                <button type="submit"
                                        class="border border-red-200 bg-white text-red-500 rounded px-5 py-2.5 text-sm hover:bg-red-50 transition">
                                    <i class="fa-solid fa-trash-can mr-1"></i> 批量删除选中
                                </button>
                                <span class="text-xs text-gray-400">勾选后删除；删除后前台用户控制台实时同步，不再显示</span>
                            </div>
                        </form>
                        <script>
                            (function () {
                                var all = document.getElementById('check-all');
                                if (!all) { return; }
                                all.addEventListener('change', function () {
                                    document.querySelectorAll('.order-check').forEach(function (cb) {
                                        cb.checked = all.checked;
                                    });
                                });
                            })();
                        </script>
                    </c:otherwise>
                </c:choose>
            </div>
        </main>
    </div>
</div>
</body>
</html>
