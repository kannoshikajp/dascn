package joppe.backend.domain.interaction;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PcBuildService {

    private final SavedPcBuildRepository savedPcBuildRepository;

    @Transactional
    public UUID saveBuild(
            UUID userId,
            String buildName,
            BigDecimal totalPrice,
            int estimatedWattage,
            String itemsJson,
            boolean isPublic) {

        SavedPcBuild build = SavedPcBuild.builder()
                .userId(userId)
                .buildName(buildName)
                .totalPrice(totalPrice)
                .estimatedWattage(estimatedWattage)
                .items(itemsJson)
                .isPublic(isPublic)
                .build();

        return savedPcBuildRepository.save(build).getId();
    }

    @Transactional(readOnly = true)
    public List<SavedPcBuild> getUserBuilds(UUID userId) {
        return savedPcBuildRepository.findByUserId(userId);
    }

    @Transactional(readOnly = true)
    public List<SavedPcBuild> getPublicBuilds() {
        return savedPcBuildRepository.findByIsPublicTrue();
    }

    @Transactional(readOnly = true)
    public Optional<SavedPcBuild> getPublicBuildById(UUID buildId) {
        return savedPcBuildRepository.findByIdAndIsPublicTrue(buildId);
    }

    @Transactional
    public void setPublic(UUID buildId, UUID userId, boolean isPublic) {
        savedPcBuildRepository.updatePublicStatus(buildId, userId, isPublic);
    }

    @Transactional
    public void deleteBuild(UUID buildId) {
        savedPcBuildRepository.deleteById(buildId);
    }
}
