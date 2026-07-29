package com.adgaiz.lifeos.shared.error;

import java.util.Objects;

public class DomainException extends RuntimeException {

  private final ErrorCode errorCode;

  public DomainException(ErrorCode errorCode) {
    this(errorCode, errorCode.defaultMessage());
  }

  public DomainException(ErrorCode errorCode, String message) {
    super(message);
    this.errorCode = Objects.requireNonNull(errorCode, "errorCode must not be null");
  }

  public ErrorCode errorCode() {
    return errorCode;
  }
}
