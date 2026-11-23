package com.afab.receipts.service;

public interface ObjectStorageService {

    void putObject(String objectKey, byte[] content, String contentType);

    byte[] getObject(String objectKey);

    void deleteObject(String objectKey);

    String generatePresignedGetUrl(String objectKey, int expirySeconds);
}
