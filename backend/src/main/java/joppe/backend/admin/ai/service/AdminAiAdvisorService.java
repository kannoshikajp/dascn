package joppe.backend.admin.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import joppe.backend.admin.ai.dto.AdminAiChatRequest;
import joppe.backend.admin.ai.dto.AdminAiChatResponse;
import joppe.backend.admin.ai.dto.AdminAiChatResponse.ReferencedProductDto;
import joppe.backend.admin.dto.AnalyticsOverviewResponse;
import joppe.backend.admin.dto.ProductResponse;
import joppe.backend.admin.service.AdminAnalyticsService;
import joppe.backend.admin.service.AdminProductService;
import joppe.backend.domain.inventory.GoodReceiptService;
import joppe.backend.domain.inventory.dto.InventoryStockResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminAiAdvisorService {

    private final AdminProductService adminProductService;
    private final GoodReceiptService goodReceiptService;
    private final AdminAnalyticsService adminAnalyticsService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${joppe.ai.ninerouter.base-url:http://127.0.0.1:20128/v1}")
    private String nineRouterBaseUrl;

    @Value("${joppe.ai.ninerouter.api-key:sk-5a59f4e7909f9087-jglxfx-2d48738b}")
    private String nineRouterApiKey;

    @Value("${joppe.ai.ninerouter.model:claude-code-1m}")
    private String nineRouterModel;

    @Value("${joppe.ai.ninerouter.timeout-seconds:90}")
    private int timeoutSeconds;

    private static final int MAX_TOOL_HOPS = 3;

    public AdminAiChatResponse chat(AdminAiChatRequest request) {
        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(15))
                .build();

        List<String> executedTools = new ArrayList<>();
        Map<String, ReferencedProductDto> referencedProducts = new LinkedHashMap<>();

        // 1. Build initial message sequence
        ArrayNode messages = objectMapper.createArrayNode();

        // System prompt
        ObjectNode systemMessage = objectMapper.createObjectNode();
        systemMessage.put("role", "system");
        systemMessage.put("content", """
                You are the Joppe AI Operations Assistant for store managers and staff.
                Your duties:
                1. Assist with inventory audits, low-stock alerts, and hardware catalog inquiries.
                2. Use the provided tools (search_products, check_inventory_stock, get_analytics_summary) to retrieve accurate data before answering.
                3. Cite exact SKUs, quantities, and prices in VND.
                4. Always respond concisely in polite Vietnamese (or the user's preferred language) using clear Markdown.
                """);
        messages.add(systemMessage);

        // Previous history
        if (request.history() != null) {
            for (var h : request.history()) {
                if (h.content() != null && !h.content().isBlank()) {
                    ObjectNode historyMsg = objectMapper.createObjectNode();
                    historyMsg.put("role", "user".equalsIgnoreCase(h.role()) ? "user" : "assistant");
                    historyMsg.put("content", h.content());
                    messages.add(historyMsg);
                }
            }
        }

        // Current user message
        ObjectNode userMessage = objectMapper.createObjectNode();
        userMessage.put("role", "user");
        userMessage.put("content", request.message());
        messages.add(userMessage);

        // 2. Build Tools Schema
        ArrayNode tools = buildToolsSchema();

        // 3. Execution loop (up to MAX_TOOL_HOPS rounds)
        for (int hop = 0; hop < MAX_TOOL_HOPS; hop++) {
            ObjectNode payload = objectMapper.createObjectNode();
            payload.put("model", nineRouterModel);
            payload.put("stream", false);
            payload.set("messages", messages);
            payload.set("tools", tools);
            payload.put("tool_choice", "auto");

            JsonNode responseJson;
            try {
                responseJson = callNineRouter(client, payload);
            } catch (Exception e) {
                log.warn("9Router call failed at {}: {}", nineRouterBaseUrl, e.getMessage());
                // ponytail: offline fallback when 9router gateway is unreachable
                return fallbackDirectResponse(request.message());
            }

            JsonNode choices = responseJson.path("choices");
            if (!choices.isArray() || choices.isEmpty()) {
                return new AdminAiChatResponse("Không nhận được phản hồi từ AI gateway.", Collections.emptyList(), executedTools);
            }

            JsonNode messageNode = choices.get(0).path("message");
            messages.add(messageNode);

            JsonNode toolCalls = messageNode.path("tool_calls");
            if (toolCalls.isArray() && !toolCalls.isEmpty()) {
                // Execute each tool call
                for (JsonNode toolCall : toolCalls) {
                    String toolCallId = toolCall.path("id").asText();
                    String functionName = toolCall.path("function").path("name").asText();
                    String argumentsStr = toolCall.path("function").path("arguments").asText("{}");

                    executedTools.add(functionName);
                    String resultJson = executeTool(functionName, argumentsStr, referencedProducts);

                    ObjectNode toolResultMsg = objectMapper.createObjectNode();
                    toolResultMsg.put("role", "tool");
                    toolResultMsg.put("tool_call_id", toolCallId);
                    toolResultMsg.put("content", resultJson);
                    messages.add(toolResultMsg);
                }
            } else {
                // Final textual content reached
                String finalAnswer = messageNode.path("content").asText("");
                return new AdminAiChatResponse(finalAnswer, new ArrayList<>(referencedProducts.values()), executedTools);
            }
        }

        // If looped max times, return latest message content
        JsonNode lastMessage = messages.get(messages.size() - 1);
        String fallbackAnswer = lastMessage.path("content").asText("Đã xử lý thông tin yêu cầu.");
        return new AdminAiChatResponse(fallbackAnswer, new ArrayList<>(referencedProducts.values()), executedTools);
    }

    private JsonNode callNineRouter(HttpClient client, ObjectNode payload) throws IOException, InterruptedException {
        String endpoint = nineRouterBaseUrl.endsWith("/") ? nineRouterBaseUrl + "chat/completions" : nineRouterBaseUrl + "/chat/completions";
        HttpRequest httpRequest = HttpRequest.newBuilder()
                .uri(URI.create(endpoint))
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + nineRouterApiKey)
                .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                .build();

        HttpResponse<String> response = client.send(httpRequest, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 200 && response.statusCode() < 300) {
            return objectMapper.readTree(response.body());
        }

        // Auto-discover model if configured model is invalid or unavailable
        if (response.statusCode() == 404 || response.statusCode() == 400 || response.statusCode() == 403) {
            String activeModel = discoverAvailableModel(client);
            if (activeModel != null && !activeModel.equals(payload.path("model").asText())) {
                log.info("9Router returned {}, switching to active model: {}", response.statusCode(), activeModel);
                payload.put("model", activeModel);
                HttpRequest retryReq = HttpRequest.newBuilder()
                        .uri(URI.create(endpoint))
                        .timeout(Duration.ofSeconds(timeoutSeconds))
                        .header("Content-Type", "application/json")
                        .header("Authorization", "Bearer " + nineRouterApiKey)
                        .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                        .build();
                HttpResponse<String> retryRes = client.send(retryReq, HttpResponse.BodyHandlers.ofString());
                if (retryRes.statusCode() >= 200 && retryRes.statusCode() < 300) {
                    return objectMapper.readTree(retryRes.body());
                }
            }
        }

        throw new IOException("HTTP " + response.statusCode() + ": " + response.body());
    }

    private String discoverAvailableModel(HttpClient client) {
        try {
            String modelsEndpoint = nineRouterBaseUrl.endsWith("/") ? nineRouterBaseUrl + "models" : nineRouterBaseUrl + "/models";
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(modelsEndpoint))
                    .timeout(Duration.ofSeconds(10))
                    .header("Authorization", "Bearer " + nineRouterApiKey)
                    .GET()
                    .build();
            HttpResponse<String> res = client.send(request, HttpResponse.BodyHandlers.ofString());
            if (res.statusCode() >= 200 && res.statusCode() < 300) {
                JsonNode root = objectMapper.readTree(res.body());
                JsonNode data = root.path("data");
                if (data.isArray() && !data.isEmpty()) {
                    return data.get(0).path("id").asText(null);
                }
            }
        } catch (Exception e) {
            log.debug("9Router model discovery failed: {}", e.getMessage());
        }
        return null;
    }

    private String executeTool(String functionName, String argumentsStr, Map<String, ReferencedProductDto> referencedProducts) {
        try {
            JsonNode args = objectMapper.readTree(argumentsStr);
            switch (functionName) {
                case "search_products": {
                    String keyword = args.path("keyword").asText(null);
                    Integer categoryId = args.has("categoryId") ? args.path("categoryId").asInt() : null;
                    List<ProductResponse> products = adminProductService.listProducts(keyword, categoryId, null, null);

                    ArrayNode resultList = objectMapper.createArrayNode();
                    for (ProductResponse p : products.stream().limit(5).toList()) {
                        ObjectNode item = objectMapper.createObjectNode();
                        item.put("id", p.id() != null ? p.id().toString() : "");
                        item.put("sku", p.sku() != null ? p.sku() : "");
                        item.put("name", p.productName());
                        item.put("minPrice", p.minPrice() != null ? p.minPrice().longValue() : 0L);
                        item.put("maxPrice", p.maxPrice() != null ? p.maxPrice().longValue() : 0L);
                        item.put("totalStock", p.totalStock() != null ? p.totalStock() : 0);
                        resultList.add(item);

                        if (p.sku() != null) {
                            referencedProducts.put(p.sku(), new ReferencedProductDto(
                                    p.id() != null ? p.id().toString() : "",
                                    p.sku(),
                                    p.productName(),
                                    p.minPrice() != null ? p.minPrice().longValue() : 0L,
                                    p.maxPrice() != null ? p.maxPrice().longValue() : 0L,
                                    p.totalStock() != null ? p.totalStock() : 0
                            ));
                        }
                    }
                    return resultList.toString();
                }
                case "check_inventory_stock": {
                    Boolean lowStockOnly = args.has("lowStockOnly") ? args.path("lowStockOnly").asBoolean() : null;
                    String search = args.path("search").asText(null);
                    List<InventoryStockResponse> stocks = goodReceiptService.listInventoryStock(lowStockOnly, search, null, null);

                    ArrayNode resultList = objectMapper.createArrayNode();
                    for (InventoryStockResponse s : stocks.stream().limit(6).toList()) {
                        ObjectNode item = objectMapper.createObjectNode();
                        item.put("variantId", s.variantId() != null ? s.variantId().toString() : "");
                        item.put("sku", s.sku());
                        item.put("productName", s.productName());
                        item.put("quantityOnHand", s.quantityOnHand());
                        item.put("reorderLevel", s.reorderLevel());
                        item.put("isLowStock", s.isLowStock());
                        resultList.add(item);

                        if (s.sku() != null) {
                            referencedProducts.put(s.sku(), new ReferencedProductDto(
                                    s.variantId() != null ? s.variantId().toString() : "",
                                    s.sku(),
                                    s.productName() + (s.variantName() != null ? " (" + s.variantName() + ")" : ""),
                                    0L,
                                    0L,
                                    s.quantityOnHand()
                            ));
                        }
                    }
                    return resultList.toString();
                }
                case "get_analytics_summary": {
                    AnalyticsOverviewResponse overview = adminAnalyticsService.getOverview();
                    ObjectNode summary = objectMapper.createObjectNode();
                    summary.put("totalRevenue", overview.revenueSummary().totalRevenue());
                    summary.put("pendingRevenue", overview.revenueSummary().pendingRevenue());
                    summary.put("totalOrders", overview.revenueSummary().totalOrders());
                    summary.put("pendingOrders", overview.revenueSummary().pendingOrders());
                    summary.put("totalProducts", overview.inventoryHealth().totalProducts());
                    summary.put("lowStockCount", overview.inventoryHealth().lowStockCount());
                    summary.put("outOfStockCount", overview.inventoryHealth().outOfStockCount());
                    return summary.toString();
                }
                default:
                    return "{\"error\":\"Unknown tool: " + functionName + "\"}";
            }
        } catch (Exception e) {
            log.error("Tool execution failed for {}: {}", functionName, e.getMessage());
            return "{\"error\":\"" + e.getMessage() + "\"}";
        }
    }

    private ArrayNode buildToolsSchema() {
        ArrayNode tools = objectMapper.createArrayNode();

        // 1. search_products
        ObjectNode searchProductsTool = objectMapper.createObjectNode();
        searchProductsTool.put("type", "function");
        ObjectNode fn1 = objectMapper.createObjectNode();
        fn1.put("name", "search_products");
        fn1.put("description", "Tìm kiếm sản phẩm trong kho Joppe theo tên hoặc mã SKU");
        ObjectNode params1 = objectMapper.createObjectNode();
        params1.put("type", "object");
        ObjectNode props1 = objectMapper.createObjectNode();
        ObjectNode kw1 = objectMapper.createObjectNode();
        kw1.put("type", "string");
        kw1.put("description", "Từ khóa tìm kiếm (tên sản phẩm, dòng máy hoặc SKU)");
        props1.set("keyword", kw1);
        params1.set("properties", props1);
        fn1.set("parameters", params1);
        searchProductsTool.set("function", fn1);
        tools.add(searchProductsTool);

        // 2. check_inventory_stock
        ObjectNode stockTool = objectMapper.createObjectNode();
        stockTool.put("type", "function");
        ObjectNode fn2 = objectMapper.createObjectNode();
        fn2.put("name", "check_inventory_stock");
        fn2.put("description", "Kiểm tra số lượng tồn kho thực tế và danh sách các linh kiện sắp hết hàng (low stock)");
        ObjectNode params2 = objectMapper.createObjectNode();
        params2.put("type", "object");
        ObjectNode props2 = objectMapper.createObjectNode();
        ObjectNode lowStockProp = objectMapper.createObjectNode();
        lowStockProp.put("type", "boolean");
        lowStockProp.put("description", "true nếu chỉ muốn xem các mặt hàng có tồn kho dưới định mức (cần nhập thêm)");
        props2.set("lowStockOnly", lowStockProp);
        ObjectNode searchProp = objectMapper.createObjectNode();
        searchProp.put("type", "string");
        searchProp.put("description", "Tên hoặc SKU sản phẩm cần kiểm tra tồn");
        props2.set("search", searchProp);
        params2.set("properties", props2);
        fn2.set("parameters", params2);
        stockTool.set("function", fn2);
        tools.add(stockTool);

        // 3. get_analytics_summary
        ObjectNode analyticsTool = objectMapper.createObjectNode();
        analyticsTool.put("type", "function");
        ObjectNode fn3 = objectMapper.createObjectNode();
        fn3.put("name", "get_analytics_summary");
        fn3.put("description", "Lấy thống kê tổng quan kinh doanh của sàn: tổng doanh thu, số đơn chờ xử lý, số linh kiện sắp hết");
        ObjectNode params3 = objectMapper.createObjectNode();
        params3.put("type", "object");
        fn3.set("parameters", params3);
        analyticsTool.set("function", fn3);
        tools.add(analyticsTool);

        return tools;
    }

    private AdminAiChatResponse fallbackDirectResponse(String prompt) {
        String lower = prompt.toLowerCase();
        List<ReferencedProductDto> refs = new ArrayList<>();
        List<String> tools = new ArrayList<>();

        if (lower.contains("tồn kho") || lower.contains("hết hàng") || lower.contains("stock")) {
            tools.add("check_inventory_stock");
            var stocks = goodReceiptService.listInventoryStock(true, null, null, null);
            long lowCount = stocks.size();
            for (var s : stocks.stream().limit(4).toList()) {
                refs.add(new ReferencedProductDto(
                        s.variantId() != null ? s.variantId().toString() : "",
                        s.sku(),
                        s.productName(),
                        0L,
                        0L,
                        s.quantityOnHand()
                ));
            }
            return new AdminAiChatResponse(
                    "*(Chế độ tra cứu trực tiếp kho Joppe)*\n\nHiện tại có **" + lowCount + "** linh kiện đang ở mức tồn thấp cần bổ sung nhập kho.",
                    refs,
                    tools
            );
        }

        if (lower.contains("doanh thu") || lower.contains("đơn hàng") || lower.contains("analytics")) {
            tools.add("get_analytics_summary");
            var overview = adminAnalyticsService.getOverview();
            return new AdminAiChatResponse(
                    "*(Chế độ tra cứu trực tiếp dữ liệu sàn)*\n\n- **Tổng doanh thu:** " + overview.revenueSummary().totalRevenue() + " VND\n- **Đơn hàng:** " + overview.revenueSummary().totalOrders() + " đơn\n- **Đơn chờ duyệt:** " + overview.revenueSummary().pendingOrders() + " đơn\n- **Linh kiện tồn thấp:** " + overview.inventoryHealth().lowStockCount() + " món.",
                    refs,
                    tools
            );
        }

        // Product search fallback
        tools.add("search_products");
        var products = adminProductService.listProducts(prompt, null, null, null);
        if (products.isEmpty()) {
            for (String word : prompt.split("\\s+")) {
                String cleanWord = word.replaceAll("[^a-zA-Z0-9]", "");
                if (cleanWord.length() >= 3 && !List.of("find", "the", "has", "good", "price", "best", "some", "with", "tim", "kiem", "cho", "cac", "nhung").contains(cleanWord.toLowerCase())) {
                    var sub = adminProductService.listProducts(cleanWord, null, null, null);
                    if (!sub.isEmpty()) {
                        products = sub;
                        break;
                    }
                }
            }
        }
        for (var p : products.stream().limit(4).toList()) {
            refs.add(new ReferencedProductDto(
                    p.id() != null ? p.id().toString() : "",
                    p.sku(),
                    p.productName(),
                    p.minPrice() != null ? p.minPrice().longValue() : 0L,
                    p.maxPrice() != null ? p.maxPrice().longValue() : 0L,
                    p.totalStock() != null ? p.totalStock() : 0
            ));
        }

        String reply = products.isEmpty()
                ? "Không tìm thấy linh kiện nào khớp với yêu cầu: \"" + prompt + "\"."
                : "Tìm thấy **" + products.size() + "** sản phẩm phù hợp trong kho:";

        return new AdminAiChatResponse(reply, refs, tools);
    }
}
