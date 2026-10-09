package lab.neeko.joppe.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;

@Entity
@Table(name = "permission_groups")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PermissionGroup {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // e.g., "USER", "REGISTER_USER", "SELL", "ACCOUNTANT", "ADMIN"
    @Column(name = "group_name", length = 50, nullable = false, unique = true)
    private String groupName;

    @Column(name = "description", length = 255)
    private String description;

    @Column(name = "is_built_in", columnDefinition = "boolean default false")
    private Boolean isBuiltIn = false;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "group_permissions",
        joinColumns = @JoinColumn(name = "group_id"),
        inverseJoinColumns = @JoinColumn(name = "permission_id")
    )
    private java.util.Set<Permission> permissions;
}
