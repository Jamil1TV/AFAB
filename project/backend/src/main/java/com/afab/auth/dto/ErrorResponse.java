package com.afab.auth.dto;

/**
 * Standardized error response for authentication endpoints.
 * Returns structured JSON instead of plain text error messages.
 *
 * Example:
 * {
 *   "success": false,
 *   "code": "EMAIL_NOT_FOUND",
 *   "message": "No account exists with this email."
 * }
 */
public class ErrorResponse {

    private boolean success;
    private String code;
    private String message;

    public ErrorResponse() {}

    public ErrorResponse(boolean success, String code, String message) {
        this.success = success;
        this.code = code;
        this.message = message;
    }

    public static ErrorResponse error(String code, String message) {
        return new ErrorResponse(false, code, message);
    }

    public static ErrorResponse success(String message) {
        return new ErrorResponse(true, null, message);
    }

    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
