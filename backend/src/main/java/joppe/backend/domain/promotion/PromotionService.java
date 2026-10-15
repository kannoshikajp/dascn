package joppe.backend.domain.promotion;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PromotionService {

    private final PromotionRepository promotionRepository;

    @Transactional
    public UUID createPromotion(
            String code,
            String discountType,
            BigDecimal discountValue,
            BigDecimal minOrderValue,
            BigDecimal maxDiscount,
            Integer usageLimit,
            int usagePerUser,
            OffsetDateTime startAt,
            OffsetDateTime endAt) {

        if (promotionRepository.existsByCode(code)) {
            throw new IllegalArgumentException("Promotion code already exists: " + code);
        }

        Promotion promo = Promotion.builder()
                .code(code)
                .discountType(discountType)
                .discountValue(discountValue)
                .minOrderValue(minOrderValue)
                .maxDiscount(maxDiscount)
                .usageLimit(usageLimit)
                .usagePerUser(usagePerUser)
                .startAt(startAt)
                .endAt(endAt)
                .isActive(true)
                .build();

        return promotionRepository.save(promo).getId();
    }

    @Transactional(readOnly = true)
    public Optional<Promotion> findByCode(String code) {
        return promotionRepository.findByCode(code);
    }

    @Transactional(readOnly = true)
    public boolean isValidPromotion(String code, BigDecimal orderSubtotal) {
        Optional<Promotion> promoOpt = promotionRepository.findByCode(code);
        if (promoOpt.isEmpty()) {
            return false;
        }

        Promotion p = promoOpt.get();
        if (!Boolean.TRUE.equals(p.getIsActive())) {
            return false;
        }

        OffsetDateTime now = OffsetDateTime.now();
        if (p.getStartAt() != null && now.isBefore(p.getStartAt())) {
            return false;
        }
        if (p.getEndAt() != null && now.isAfter(p.getEndAt())) {
            return false;
        }

        if (p.getUsageLimit() != null && p.getUsageLimit() <= 0) {
            return false;
        }

        return orderSubtotal.compareTo(p.getMinOrderValue()) >= 0;
    }

    @Transactional(readOnly = true)
    public BigDecimal calculateDiscount(String code, BigDecimal orderSubtotal) {
        Optional<Promotion> promoOpt = promotionRepository.findByCode(code);
        if (promoOpt.isEmpty() || !isValidPromotion(code, orderSubtotal)) {
            return BigDecimal.ZERO;
        }

        Promotion p = promoOpt.get();
        BigDecimal discount;

        if ("PERCENTAGE".equalsIgnoreCase(p.getDiscountType())) {
            discount = orderSubtotal
                    .multiply(p.getDiscountValue())
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

            if (p.getMaxDiscount() != null && discount.compareTo(p.getMaxDiscount()) > 0) {
                discount = p.getMaxDiscount();
            }
        } else {
            discount = p.getDiscountValue();
        }

        if (discount.compareTo(orderSubtotal) > 0) {
            discount = orderSubtotal;
        }

        return discount;
    }

    @Transactional
    public void recordUsage(UUID promotionId) {
        promotionRepository.decrementUsageLimit(promotionId);
    }
}
