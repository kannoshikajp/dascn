package joppe.backend.domain.user;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserAddressRepository extends JpaRepository<UserAddress, UUID> {

    List<UserAddress> findByUserId(UUID userId);

    Optional<UserAddress> findByIdAndUserId(UUID id, UUID userId);

    Optional<UserAddress> findByUserIdAndIsDefaultTrue(UUID userId);

    @Modifying
    @Query("UPDATE UserAddress a SET a.isDefault = false WHERE a.userId = :userId")
    int clearDefaultAddresses(@Param("userId") UUID userId);

    @Modifying
    @Query("UPDATE UserAddress a SET a.isDefault = true WHERE a.id = :id AND a.userId = :userId")
    int setDefaultAddress(@Param("id") UUID id, @Param("userId") UUID userId);
}
