package com.adgaiz.lifeos.shared.error;

import java.time.Instant;
import java.util.List;

public record ApiError(
    Instant timestamp,
    int status,
    String code,
    String message,
    String requestId,
    String path,
    List<FieldViolation> details) {

  public ApiError {
    details = details == null ? List.of() : List.copyOf(details);
  }

  public record FieldViolation(String field, String message) {}
}
