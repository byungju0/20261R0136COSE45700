package com.tracker.api.exception;

public class InvalidFilterParamException extends RuntimeException {

    public InvalidFilterParamException(String message) {
        super(message);
    }
}
