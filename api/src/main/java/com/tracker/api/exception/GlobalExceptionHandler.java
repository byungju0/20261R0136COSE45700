package com.tracker.api.exception;

import jakarta.validation.ConstraintViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import org.springframework.web.context.request.WebRequest;

@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(InvalidFilterParamException.class)
    public ProblemDetail handleInvalidFilterParam(InvalidFilterParamException ex) {
        return invalidFilterProblem(ex.getMessage());
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ProblemDetail handleConstraintViolation(ConstraintViolationException ex) {
        return invalidFilterProblem(ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ProblemDetail handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        return invalidFilterProblem("파라미터 '%s'의 값이 올바르지 않습니다: %s".formatted(
                ex.getName(), ex.getValue()));
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleAll(Exception ex) {
        logger.error("Unhandled exception", ex);
        var pd = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "서버 내부 오류가 발생했습니다.");
        pd.setTitle("Internal Server Error");
        pd.setProperty("errorCode", "INTERNAL_SERVER_ERROR");
        return pd;
    }

    @Override
    protected ResponseEntity<Object> handleExceptionInternal(
            Exception ex,
            Object body,
            HttpHeaders headers,
            HttpStatusCode statusCode,
            WebRequest request) {

        Object responseBody = body;
        if (responseBody instanceof ProblemDetail problemDetail) {
            problemDetail.setProperty("errorCode", errorCodeFor(statusCode));
        } else if (responseBody == null) {
            var problemDetail = ProblemDetail.forStatus(statusCode);
            problemDetail.setTitle(statusCode.is4xxClientError() ? "Invalid Parameter" : "Internal Server Error");
            problemDetail.setProperty("errorCode", errorCodeFor(statusCode));
            responseBody = problemDetail;
        }

        return super.handleExceptionInternal(ex, responseBody, headers, statusCode, request);
    }

    private ProblemDetail invalidFilterProblem(String detail) {
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, detail);
        pd.setTitle("Invalid Parameter");
        pd.setProperty("errorCode", "INVALID_FILTER_PARAM");
        return pd;
    }

    private String errorCodeFor(HttpStatusCode statusCode) {
        return statusCode.is4xxClientError() ? "INVALID_FILTER_PARAM" : "INTERNAL_SERVER_ERROR";
    }
}
