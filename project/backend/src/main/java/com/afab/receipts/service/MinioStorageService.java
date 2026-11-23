package com.afab.receipts.service;

import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.GetPresignedObjectUrlArgs;
import io.minio.Http;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * MinIO / S3-compatible private object storage implementation.
 * Buckets are created private (no public read policy); access is exclusively via
 * authenticated API streaming or short-lived presigned GET URLs.
 */
@Service
public class MinioStorageService implements ObjectStorageService {

    private static final Logger log = LoggerFactory.getLogger(MinioStorageService.class);

    private final String endpoint;
    private final String publicEndpoint;
    private final String accessKey;
    private final String secretKey;
    private final String bucket;

    private volatile MinioClient internalClient;
    private volatile MinioClient presignClient;
    private final AtomicBoolean bucketReady = new AtomicBoolean(false);

    public MinioStorageService(
            @Value("${afab.minio.endpoint:http://localhost:9000}") String endpoint,
            @Value("${afab.minio.public-endpoint:${afab.minio.endpoint:http://localhost:9000}}") String publicEndpoint,
            @Value("${afab.minio.access-key:}") String accessKey,
            @Value("${afab.minio.secret-key:}") String secretKey,
            @Value("${afab.minio.bucket:afab-receipts}") String bucket
    ) {
        this.endpoint = endpoint;
        this.publicEndpoint = (publicEndpoint != null && !publicEndpoint.isBlank()) ? publicEndpoint : endpoint;
        this.accessKey = accessKey;
        this.secretKey = secretKey;
        this.bucket = bucket;
    }

    @Override
    public void putObject(String objectKey, byte[] content, String contentType) {
        MinioClient client = getInternalClient();
        ensurePrivateBucket(client);
        try (InputStream in = new ByteArrayInputStream(content)) {
            client.putObject(
                    PutObjectArgs.builder()
                            .bucket(bucket)
                            .object(objectKey)
                            .stream(in, (long) content.length, -1L)
                            .contentType(contentType)
                            .build()
            );
        } catch (Exception ex) {
            log.error("MinIO putObject failed for bucket={} key={}: {}", bucket, objectKey, ex.getMessage());
            throw new IllegalStateException("Receipt storage service failed while storing file.", ex);
        }
    }

    @Override
    public byte[] getObject(String objectKey) {
        MinioClient client = getInternalClient();
        try (InputStream stream = client.getObject(
                GetObjectArgs.builder()
                        .bucket(bucket)
                        .object(objectKey)
                        .build()
        )) {
            return stream.readAllBytes();
        } catch (Exception ex) {
            log.error("MinIO getObject failed for bucket={} key={}: {}", bucket, objectKey, ex.getMessage());
            throw new IllegalStateException("Receipt storage service failed while reading file.", ex);
        }
    }

    @Override
    public void deleteObject(String objectKey) {
        MinioClient client = getInternalClient();
        try {
            client.removeObject(
                    RemoveObjectArgs.builder()
                            .bucket(bucket)
                            .object(objectKey)
                            .build()
            );
        } catch (Exception ex) {
            log.error("MinIO removeObject failed for bucket={} key={}: {}", bucket, objectKey, ex.getMessage());
            throw new IllegalStateException("Receipt storage service failed while deleting file.", ex);
        }
    }

    @Override
    public String generatePresignedGetUrl(String objectKey, int expirySeconds) {
        MinioClient signer = getPresignClient();
        ensurePrivateBucket(getInternalClient());
        try {
            return signer.getPresignedObjectUrl(
                    GetPresignedObjectUrlArgs.builder()
                            .method(Http.Method.GET)
                            .bucket(bucket)
                            .object(objectKey)
                            .expiry(expirySeconds, TimeUnit.SECONDS)
                            .build()
            );
        } catch (Exception ex) {
            log.error("MinIO presign failed for bucket={} key={}: {}", bucket, objectKey, ex.getMessage());
            throw new IllegalStateException("Receipt storage service failed while generating signed URL.", ex);
        }
    }

    private MinioClient getInternalClient() {
        if (internalClient == null) {
            synchronized (this) {
                if (internalClient == null) {
                    requireCredentials();
                    internalClient = MinioClient.builder()
                            .endpoint(endpoint)
                            .credentials(accessKey, secretKey)
                            .build();
                }
            }
        }
        return internalClient;
    }

    private MinioClient getPresignClient() {
        if (publicEndpoint.equals(endpoint)) {
            return getInternalClient();
        }
        if (presignClient == null) {
            synchronized (this) {
                if (presignClient == null) {
                    requireCredentials();
                    presignClient = MinioClient.builder()
                            .endpoint(publicEndpoint)
                            .credentials(accessKey, secretKey)
                            .build();
                }
            }
        }
        return presignClient;
    }

    private void requireCredentials() {
        if (accessKey == null || accessKey.isBlank() || secretKey == null || secretKey.isBlank()) {
            throw new IllegalStateException("MinIO storage credentials (MINIO_ACCESS_KEY / MINIO_SECRET_KEY) are not configured.");
        }
    }

    private void ensurePrivateBucket(MinioClient client) {
        if (bucketReady.get()) {
            return;
        }
        synchronized (this) {
            if (bucketReady.get()) {
                return;
            }
            try {
                boolean exists = client.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
                if (!exists) {
                    client.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
                    log.info("Created private MinIO bucket '{}'", bucket);
                }
                bucketReady.set(true);
            } catch (Exception ex) {
                log.error("Failed ensuring MinIO bucket '{}': {}", bucket, ex.getMessage());
                throw new IllegalStateException("Receipt object storage is unavailable.", ex);
            }
        }
    }
}
