package com.afab.receipts;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.receipts.domain.Receipt;
import com.afab.receipts.dto.ReceiptDTO;
import com.afab.receipts.repository.ReceiptRepository;
import com.afab.receipts.service.ObjectStorageService;
import com.afab.receipts.service.ReceiptService;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReceiptServiceTest {

    @Mock private ReceiptRepository receiptRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private ObjectStorageService objectStorageService;
    @Mock private AuditService auditService;

    private ReceiptService receiptService;
    private User user;
    private Business bizA;
    private Business bizB;
    private Transaction txA;

    @BeforeEach
    void setUp() {
        receiptService = new ReceiptService(
                receiptRepository,
                transactionRepository,
                currentBusinessService,
                objectStorageService,
                auditService,
                1024 * 1024, // 1 MB test limit
                300
        );

        user = new User();
        user.setId(UUID.randomUUID());
        user.setEmail("owner@afab.test");

        bizA = new Business();
        bizA.setId(UUID.randomUUID());
        bizA.setName("Biz A");

        bizB = new Business();
        bizB.setId(UUID.randomUUID());
        bizB.setName("Biz B");

        txA = new Transaction();
        txA.setId(UUID.randomUUID());
        txA.setBusiness(bizA);
    }

    @Test
    void uploadsValidPdfWithPrivateTenantScopedKeyAndChecksum() {
        byte[] pdfBytes = "%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF".getBytes(StandardCharsets.US_ASCII);
        MockMultipartFile file = new MockMultipartFile("file", "../evil/invoice_01.pdf", "application/pdf", pdfBytes);

        when(currentBusinessService.getCurrentUser("owner@afab.test")).thenReturn(user);
        when(currentBusinessService.getCurrentBusiness("owner@afab.test")).thenReturn(bizA);
        when(transactionRepository.findActiveById(txA.getId())).thenReturn(Optional.of(txA));
        when(receiptRepository.save(any(Receipt.class))).thenAnswer(inv -> {
            Receipt r = inv.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });

        ReceiptDTO dto = receiptService.upload("owner@afab.test", txA.getId(), file);

        assertThat(dto.businessId()).isEqualTo(bizA.getId());
        assertThat(dto.transactionId()).isEqualTo(txA.getId());
        assertThat(dto.contentType()).isEqualTo("application/pdf");
        assertThat(dto.originalFilename()).isEqualTo("invoice_01.pdf"); // path traversal stripped
        assertThat(dto.sha256Checksum()).hasSize(64);

        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        verify(objectStorageService).putObject(keyCaptor.capture(), eq(pdfBytes), eq("application/pdf"));
        assertThat(keyCaptor.getValue())
                .startsWith("businesses/" + bizA.getId() + "/transactions/" + txA.getId() + "/")
                .endsWith(".pdf");
    }

    @Test
    void rejectsDisguisedHtmlOrExecutableUploadedAsPng() {
        byte[] htmlPayload = "<html><script>alert(1)</script></html>".getBytes(StandardCharsets.UTF_8);
        MockMultipartFile malicious = new MockMultipartFile("file", "receipt.png", "image/png", htmlPayload);

        when(currentBusinessService.getCurrentUser("owner@afab.test")).thenReturn(user);
        when(currentBusinessService.getCurrentBusiness("owner@afab.test")).thenReturn(bizA);
        when(transactionRepository.findActiveById(txA.getId())).thenReturn(Optional.of(txA));

        assertThatThrownBy(() -> receiptService.upload("owner@afab.test", txA.getId(), malicious))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unsupported or invalid file content");

        verify(objectStorageService, never()).putObject(any(), any(), any());
    }

    @Test
    void rejectsOversizedReceiptFile() {
        byte[] huge = new byte[1024 * 1024 + 10];
        huge[0] = '%'; huge[1] = 'P'; huge[2] = 'D'; huge[3] = 'F'; huge[4] = '-';
        MockMultipartFile file = new MockMultipartFile("file", "huge.pdf", "application/pdf", huge);

        assertThatThrownBy(() -> receiptService.upload("owner@afab.test", txA.getId(), file))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("maximum allowed size");

        verify(objectStorageService, never()).putObject(any(), any(), any());
    }

    @Test
    void rejectsCrossTenantPresignDownloadAndDelete() {
        Receipt receiptInBizB = new Receipt();
        receiptInBizB.setId(UUID.randomUUID());
        receiptInBizB.setBusiness(bizB);
        receiptInBizB.setObjectKey("businesses/" + bizB.getId() + "/transactions/x/y.pdf");

        when(currentBusinessService.getCurrentBusiness("owner@afab.test")).thenReturn(bizA);
        when(currentBusinessService.getCurrentUser("owner@afab.test")).thenReturn(user);
        when(receiptRepository.findActiveById(receiptInBizB.getId())).thenReturn(Optional.of(receiptInBizB));

        assertThatThrownBy(() -> receiptService.getDownloadUrl("owner@afab.test", receiptInBizB.getId()))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> receiptService.downloadContent("owner@afab.test", receiptInBizB.getId()))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> receiptService.delete("owner@afab.test", receiptInBizB.getId()))
                .isInstanceOf(ForbiddenException.class);

        verify(objectStorageService, never()).generatePresignedGetUrl(any(), anyInt());
        verify(objectStorageService, never()).deleteObject(any());
    }

    @Test
    void deletesReceiptFromStorageAndMarksSoftDeleted() {
        Receipt receipt = new Receipt();
        receipt.setId(UUID.randomUUID());
        receipt.setBusiness(bizA);
        receipt.setObjectKey("businesses/" + bizA.getId() + "/transactions/" + txA.getId() + "/abc.png");

        when(currentBusinessService.getCurrentUser("owner@afab.test")).thenReturn(user);
        when(currentBusinessService.getCurrentBusiness("owner@afab.test")).thenReturn(bizA);
        when(receiptRepository.findActiveById(receipt.getId())).thenReturn(Optional.of(receipt));
        when(receiptRepository.save(any(Receipt.class))).thenAnswer(inv -> inv.getArgument(0));

        receiptService.delete("owner@afab.test", receipt.getId());

        verify(objectStorageService).deleteObject(receipt.getObjectKey());
        assertThat(receipt.getDeletedAt()).isNotNull();
    }
}
