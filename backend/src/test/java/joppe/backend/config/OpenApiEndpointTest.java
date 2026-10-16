package joppe.backend.config;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest(properties = {
    "spring.flyway.enabled=false",
    "spring.jpa.hibernate.ddl-auto=none",
    "app.admin.auto-create=false"
})
class OpenApiEndpointTest {

    @MockitoBean
    private DataSource dataSource;

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    void apiDocsEndpointIsAccessibleWithoutAuth() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Joppe E-Commerce & Tech API")))
                .andExpect(content().string(containsString("BearerAuth")));
    }

    @Test
    void swaggerUiEndpointIsAccessibleWithoutAuth() throws Exception {
        mockMvc.perform(get("/swagger-ui/index.html"))
                .andExpect(status().isOk());
    }
}
