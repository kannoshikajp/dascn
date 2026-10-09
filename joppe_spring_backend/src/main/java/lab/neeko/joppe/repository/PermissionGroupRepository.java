package lab.neeko.joppe.repository;

import lab.neeko.joppe.entity.PermissionGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PermissionGroupRepository extends JpaRepository<PermissionGroup, Integer> {
    Optional<PermissionGroup> findByGroupName(String groupName);
}
