package com.afab.common.security;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation to inject the currently authenticated user into controller method parameters.
 *
 * <p>Usage:
 * <pre>
 * {@code
 * @GetMapping("/profile")
 * public ApiResponse<UserDto> getProfile(@CurrentUser User user) {
 *     // user is the authenticated User entity
 * }
 * }
 * </pre>
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface CurrentUser {
}
