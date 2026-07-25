package com.afab.finance.service;

import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.*;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;

    public TransactionService(TransactionRepository transactionRepository,
                              CategoryRepository categoryRepository,
                              UserRepository userRepository,
                              BusinessRepository businessRepository) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional(readOnly = true)
    public TransactionResponseDTO getTransactions(String userEmail, String type, UUID categoryId, String search, int page, int size) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        Page<Transaction> txPage = transactionRepository.searchTransactions(
                business.getId(),
                (type != null && !type.isBlank()) ? type.toUpperCase() : null,
                categoryId,
                (search != null && !search.isBlank()) ? search.trim() : null,
                PageRequest.of(page, size)
        );

        List<TransactionDTO> dtos = txPage.getContent().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());

        BigDecimal totalInflow = transactionRepository.sumAmountByBusinessAndType(business.getId(), "INCOME");
        BigDecimal totalOutflow = transactionRepository.sumAmountByBusinessAndType(business.getId(), "EXPENSE");
        BigDecimal netBalance = totalInflow.subtract(totalOutflow);

        return new TransactionResponseDTO(
                dtos,
                txPage.getNumber(),
                txPage.getSize(),
                txPage.getTotalElements(),
                txPage.getTotalPages(),
                totalInflow,
                totalOutflow,
                netBalance,
                (business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD"
        );
    }

    @Transactional
    public TransactionDTO createTransaction(String userEmail, CreateTransactionRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        Transaction tx = new Transaction();
        tx.setBusiness(business);
        tx.setType(request.getType().toUpperCase());
        tx.setAmount(request.getAmount());
        tx.setCurrency((business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD");
        tx.setDescription(request.getDescription());
        tx.setTransactionDate(request.getTransactionDate());
        tx.setPaymentMethod(request.getPaymentMethod() != null ? request.getPaymentMethod() : "BANK_TRANSFER");
        tx.setStatus(request.getStatus() != null ? request.getStatus() : "COMPLETED");
        tx.setNotes(request.getNotes());

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId()).orElse(null);
            tx.setCategory(category);
        }

        tx = transactionRepository.save(tx);
        return mapToDTO(tx);
    }

    @Transactional
    public void deleteTransaction(String userEmail, UUID transactionId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));

        if (!tx.getBusiness().getId().equals(business.getId())) {
            throw new IllegalArgumentException("Unauthorized transaction access");
        }

        transactionRepository.delete(tx);
    }

    @Transactional(readOnly = true)
    public List<CategoryDTO> getCategories(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        return categoryRepository.findAllForBusiness(business.getId()).stream()
                .map(c -> new CategoryDTO(c.getId(), c.getName(), c.getType(), c.getIcon(), c.getColor()))
                .collect(Collectors.toList());
    }

    private TransactionDTO mapToDTO(Transaction tx) {
        Category cat = tx.getCategory();
        String curr = tx.getCurrency();
        if ((curr == null || curr.isBlank()) && tx.getBusiness() != null) {
            curr = tx.getBusiness().getCurrency();
        }
        if (curr == null || curr.isBlank()) curr = "USD";

        return new TransactionDTO(
                tx.getId(),
                tx.getType(),
                tx.getAmount(),
                curr,
                tx.getDescription(),
                tx.getTransactionDate(),
                tx.getPaymentMethod(),
                tx.getStatus(),
                cat != null ? cat.getName() : "Uncategorized",
                cat != null && cat.getColor() != null ? cat.getColor() : "#6b7280",
                cat != null && cat.getIcon() != null ? cat.getIcon() : "Tag",
                cat != null ? cat.getId() : null
        );
    }
}
