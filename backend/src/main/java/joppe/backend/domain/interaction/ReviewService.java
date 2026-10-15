package joppe.backend.domain.interaction;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;

    @Transactional
    public UUID submitReview(
            UUID userId,
            UUID productId,
            UUID orderId,
            int ratingStar,
            String comment,
            String mediaUrls) {

        if (ratingStar < 1 || ratingStar > 5) {
            throw new IllegalArgumentException("Rating star must be between 1 and 5");
        }

        Review review = Review.builder()
                .userId(userId)
                .productId(productId)
                .orderId(orderId)
                .ratingStar(ratingStar)
                .comment(comment)
                .mediaUrls(mediaUrls)
                .isVisible(true)
                .build();

        return reviewRepository.save(review).getId();
    }

    @Transactional(readOnly = true)
    public List<Review> getProductReviews(UUID productId) {
        return reviewRepository.findByProductIdAndIsVisibleTrue(productId);
    }

    @Transactional(readOnly = true)
    public double getAverageRating(UUID productId) {
        return reviewRepository.findAverageRatingByProductId(productId).orElse(0.0);
    }

    @Transactional(readOnly = true)
    public long getReviewCount(UUID productId) {
        return reviewRepository.countReviewsByProductId(productId);
    }

    @Transactional
    public void updateVisibility(UUID reviewId, boolean isVisible) {
        reviewRepository.updateVisibility(reviewId, isVisible);
    }
}
