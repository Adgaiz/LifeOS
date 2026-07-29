package com.adgaiz.lifeos.shared.error;

import org.springframework.http.HttpStatus;

public enum ErrorCode {
  VALIDATION_FAILED(HttpStatus.BAD_REQUEST, "请求参数校验失败"),
  MALFORMED_REQUEST(HttpStatus.BAD_REQUEST, "请求内容无法解析"),
  INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "服务暂时不可用，请稍后重试");

  private final HttpStatus status;
  private final String defaultMessage;

  ErrorCode(HttpStatus status, String defaultMessage) {
    this.status = status;
    this.defaultMessage = defaultMessage;
  }

  public HttpStatus status() {
    return status;
  }

  public String defaultMessage() {
    return defaultMessage;
  }
}
