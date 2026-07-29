package com.adgaiz.lifeos.shared.error;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

  private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);
  private final Clock clock;

  public GlobalExceptionHandler() {
    this(Clock.systemUTC());
  }

  GlobalExceptionHandler(Clock clock) {
    this.clock = clock;
  }

  @ExceptionHandler(DomainException.class)
  ResponseEntity<ApiError> handleDomainException(
      DomainException exception, HttpServletRequest request) {
    return response(exception.errorCode(), exception.getMessage(), List.of(), request);
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ApiError> handleValidation(
      MethodArgumentNotValidException exception, HttpServletRequest request) {
    List<ApiError.FieldViolation> details =
        exception.getBindingResult().getFieldErrors().stream()
            .map(
                error ->
                    new ApiError.FieldViolation(
                        error.getField(),
                        error.getDefaultMessage() == null ? "字段值无效" : error.getDefaultMessage()))
            .toList();
    return response(
        ErrorCode.VALIDATION_FAILED,
        ErrorCode.VALIDATION_FAILED.defaultMessage(),
        details,
        request);
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  ResponseEntity<ApiError> handleMalformedRequest(
      HttpMessageNotReadableException exception, HttpServletRequest request) {
    return response(
        ErrorCode.MALFORMED_REQUEST,
        ErrorCode.MALFORMED_REQUEST.defaultMessage(),
        List.of(),
        request);
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<ApiError> handleUnexpected(Exception exception, HttpServletRequest request) {
    log.error("event=unhandled_exception path={}", request.getRequestURI(), exception);
    return response(
        ErrorCode.INTERNAL_ERROR, ErrorCode.INTERNAL_ERROR.defaultMessage(), List.of(), request);
  }

  private ResponseEntity<ApiError> response(
      ErrorCode code,
      String message,
      List<ApiError.FieldViolation> details,
      HttpServletRequest request) {
    ApiError body =
        new ApiError(
            Instant.now(clock),
            code.status().value(),
            code.name(),
            message,
            MDC.get("requestId"),
            request.getRequestURI(),
            details);
    return ResponseEntity.status(code.status()).body(body);
  }
}
