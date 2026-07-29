package com.adgaiz.lifeos.shared.logging;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class RequestIdFilter extends OncePerRequestFilter {

  public static final String HEADER_NAME = "X-Request-Id";
  private static final int MAX_REQUEST_ID_LENGTH = 128;

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String requestId = normalize(request.getHeader(HEADER_NAME));
    MDC.put("requestId", requestId);
    response.setHeader(HEADER_NAME, requestId);
    try {
      filterChain.doFilter(request, response);
    } finally {
      MDC.remove("requestId");
    }
  }

  private String normalize(String candidate) {
    if (!StringUtils.hasText(candidate) || candidate.length() > MAX_REQUEST_ID_LENGTH) {
      return UUID.randomUUID().toString();
    }
    return candidate;
  }
}
