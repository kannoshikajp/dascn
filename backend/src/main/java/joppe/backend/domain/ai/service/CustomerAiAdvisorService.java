package joppe.backend.domain.ai.service;

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
import joppe.backend.admin.dto.ProductResponse;
import joppe.backend.admin.service.AdminProductService;
import joppe.backend.domain.ai.dto.CustomerAiChatRequest;
import joppe.backend.domain.ai.dto.CustomerAiChatResponse;
import joppe.backend.domain.ai.dto.CustomerAiChatResponse.ReferencedProductDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerAiAdvisorService {

    private final AdminProductService adminProductService;
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

    public CustomerAiChatResponse chat(CustomerAiChatRequest request) {
        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(15))
                .build();

        List<String> executedTools = new ArrayList<>();
        Map<String, ReferencedProductDto> referencedProducts = new LinkedHashMap<>();

        ArrayNode messages = objectMapper.createArrayNode();

        ObjectNode systemMessage = objectMapper.createObjectNode();
        systemMessage.put("role", "system");
        systemMessage.put("content", """
                Bạn là Trợ lý AI chuyên gia tư vấn phần cứng & Build PC của hệ thống cửa hàng Joppe.
                Nhiệm vụ của bạn:
                1. Tư vấn cấu hình PC theo ngân sách và nhu cầu (Gaming Esports/AAA, Đồ họa 3D, Render, AI, Văn phòng).
                2. Đánh giá tính tương thích phần cứng: Socket CPU - Bo mạch chủ, chuẩn RAM (DDR4/DDR5), công suất nguồn PSU khuyến nghị, và ước tính tỉ lệ nghẽn cổ chai (Bottleneck CPU - GPU).
                3. Sử dụng công cụ 'search_products' để tra cứu linh kiện thật đang kinh doanh tại Joppe kèm giá bán VND và tồn kho thực tế.
                4. Luôn trả lời bằng tiếng Việt thân thiện, súc tích, định dạng Markdown rõ ràng, làm nổi bật thông số và ưu/nhược điểm.
                """);
        messages.add(systemMessage);

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

        ObjectNode userMessage = objectMapper.createObjectNode();
        userMessage.put("role", "user");
        userMessage.put("content", request.message());
        messages.add(userMessage);

        ArrayNode tools = buildToolsSchema();

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
                log.warn("Customer AI 9Router gateway call failed: {}", e.getMessage());
                // ponytail: offline fallback search active products locally when LLM gateway unavailable
                return fallbackDirectResponse(request.message());
            }

            JsonNode choices = responseJson.path("choices");
            if (!choices.isArray() || choices.isEmpty()) {
                return new CustomerAiChatResponse("Hiện chưa nhận được phản hồi từ AI gateway. Vui lòng thử lại sau.",
                        Collections.emptyList(), defaultQuickReplies(), executedTools);
            }

            JsonNode messageNode = choices.get(0).path("message");
            messages.add(messageNode);

            JsonNode toolCalls = messageNode.path("tool_calls");
            if (toolCalls.isArray() && !toolCalls.isEmpty()) {
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
                String finalAnswer = messageNode.path("content").asText("");
                List<String> quickReplies = generateQuickReplies(request.message(), referencedProducts);
                return new CustomerAiChatResponse(finalAnswer, new ArrayList<>(referencedProducts.values()), quickReplies, executedTools);
            }
        }

        JsonNode lastMessage = messages.get(messages.size() - 1);
        String fallbackAnswer = lastMessage.path("content").asText("Đã phân tích yêu cầu cấu hình của bạn.");
        return new CustomerAiChatResponse(fallbackAnswer, new ArrayList<>(referencedProducts.values()), defaultQuickReplies(), executedTools);
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

        if (response.statusCode() == 404 || response.statusCode() == 400 || response.statusCode() == 403) {
            String activeModel = discoverAvailableModel(client);
            if (activeModel != null && !activeModel.equals(payload.path("model").asText())) {
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
        } catch (Exception ignored) {
        }
        return null;
    }

    private String executeTool(String functionName, String argumentsStr, Map<String, ReferencedProductDto> referencedProducts) {
        try {
            JsonNode args = objectMapper.readTree(argumentsStr);
            if ("search_products".equals(functionName)) {
                String keyword = args.path("keyword").asText(null);
                Integer categoryId = args.has("categoryId") ? args.path("categoryId").asInt() : null;
                List<ProductResponse> products = adminProductService.listProducts(keyword, categoryId, null, true);

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
            return "{\"error\":\"Unknown tool: " + functionName + "\"}";
        } catch (Exception e) {
            log.error("Tool execution failed for {}: {}", functionName, e.getMessage());
            return "{\"error\":\"" + e.getMessage() + "\"}";
        }
    }

    private ArrayNode buildToolsSchema() {
        ArrayNode tools = objectMapper.createArrayNode();

        ObjectNode searchTool = objectMapper.createObjectNode();
        searchTool.put("type", "function");
        ObjectNode fn = objectMapper.createObjectNode();
        fn.put("name", "search_products");
        fn.put("description", "Tìm kiếm linh kiện phần cứng hoặc phụ kiện đang có bán tại Joppe");
        ObjectNode params = objectMapper.createObjectNode();
        params.put("type", "object");
        ObjectNode props = objectMapper.createObjectNode();
        ObjectNode kw = objectMapper.createObjectNode();
        kw.put("type", "string");
        kw.put("description", "Tên linh kiện (CPU, VGA, RAM, Mainboard...) hoặc từ khóa");
        props.set("keyword", kw);
        params.set("properties", props);
        fn.set("parameters", params);
        searchTool.set("function", fn);
        tools.add(searchTool);

        return tools;
    }

    private List<String> defaultQuickReplies() {
        return List.of(
                "Build PC Gaming 15 triệu",
                "Tối ưu ngân sách cấu hình này",
                "Kiểm tra độ nghẽn cổ chai (Bottleneck)"
        );
    }

    private List<String> generateQuickReplies(String prompt, Map<String, ReferencedProductDto> referencedProducts) {
        List<String> replies = new ArrayList<>();
        if (!referencedProducts.isEmpty()) {
            replies.add("Linh kiện này bảo hành bao lâu?");
            replies.add("Có phương án nào tiết kiệm chi phí hơn không?");
        } else if (prompt.toLowerCase().contains("gaming") || prompt.toLowerCase().contains("chơi game")) {
            replies.add("Cấu hình này chiến mượt game AAA 2K không?");
            replies.add("Nên nâng cấp VGA hay RAM trước?");
        } else {
            replies.add("Tư vấn cấu hình Intel tương đương");
            replies.add("Tư vấn cấu hình AMD tương đương");
        }
        return replies;
    }

    private CustomerAiChatResponse fallbackDirectResponse(String prompt) {
        List<ReferencedProductDto> refs = new ArrayList<>();
        List<String> tools = List.of("search_products");

        var products = adminProductService.listProducts(prompt, null, null, true);
        if (products.isEmpty()) {
            for (String word : prompt.split("\\s+")) {
                String cleanWord = word.replaceAll("[^a-zA-Z0-9]", "");
                if (cleanWord.length() >= 3) {
                    var sub = adminProductService.listProducts(cleanWord, null, null, true);
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

        String reply = refs.isEmpty()
                ? "Dạ Joppe AI đã ghi nhận yêu cầu: \"" + prompt + "\". Hãy liên hệ kỹ thuật viên hoặc chọn linh kiện từ danh mục để được hỗ trợ chi tiết!"
                : "Dạ Joppe AI gợi ý các linh kiện phù hợp với yêu cầu của bạn hiện có tại cửa hàng:";

        return new CustomerAiChatResponse(reply, refs, defaultQuickReplies(), tools);
    }
}
