package com.adgaiz.lifeos;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LifeOsApplicationTests {

  @Autowired private MockMvc mockMvc;

  @Autowired private JdbcTemplate jdbcTemplate;

  @Test
  void contextLoadsAndFlywayAppliesBaseline() {
    String value =
        jdbcTemplate.queryForObject(
            "SELECT metadata_value FROM system_metadata WHERE metadata_key = ?",
            String.class,
            "schema_baseline");

    assertThat(value).isEqualTo("1");
  }

  @Test
  void systemStatusReturnsRequestId() throws Exception {
    mockMvc
        .perform(get("/api/v1/system/status").header("X-Request-Id", "test-request-id"))
        .andExpect(status().isOk())
        .andExpect(header().string("X-Request-Id", "test-request-id"))
        .andExpect(jsonPath("$.status").value("ok"))
        .andExpect(jsonPath("$.application").value("lifeos-server"))
        .andExpect(jsonPath("$.timestamp").isNotEmpty());
  }
}
