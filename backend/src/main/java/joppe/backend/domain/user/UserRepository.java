package joppe.backend.domain.user;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmail(String email);

    Optional<User> findByPhoneNumber(String phoneNumber);

    boolean existsByEmail(String email);

    boolean existsByPhoneNumber(String phoneNumber);

    @Query("SELECT u.roleId FROM User u WHERE u.id = :id")
    Optional<Integer> findRoleIdByUserId(@Param("id") UUID id);

    @Query("SELECT u.fullName FROM User u WHERE u.id = :id")
    Optional<String> findFullNameByUserId(@Param("id") UUID id);

    @Query("SELECT u.isActive FROM User u WHERE u.id = :id")
    Optional<Boolean> findIsActiveByUserId(@Param("id") UUID id);

    @Modifying
    @Query("UPDATE User u SET u.isActive = :isActive WHERE u.id = :id")
    int updateActiveStatus(@Param("id") UUID id, @Param("isActive") boolean isActive);

    @Modifying
    @Query("UPDATE User u SET u.passwordHash = :newHash WHERE u.id = :id")
    int updatePasswordHash(@Param("id") UUID id, @Param("newHash") String newHash);

    long countByIsActiveTrue();

    long countByRoleIdAndIsActiveTrue(Integer roleId);
}
