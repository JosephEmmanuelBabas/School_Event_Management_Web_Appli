package com.school_event.school_event_management.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.CreateUserRequest;
import com.school_event.school_event_management.dto.UpdateUserRequest;
import com.school_event.school_event_management.dto.UserResponse;
import com.school_event.school_event_management.entity.Role;
import com.school_event.school_event_management.entity.userAccount;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.repository.roleRepository;
import com.school_event.school_event_management.repository.userAccountRepository;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UserServiceTest {

    @Mock
    private userAccountRepository users;

    @Mock
    private roleRepository roles;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private UserService userService;

    // Role has no public constructor, so tests use a stand-in object.
    private Role roleNamed(String name) {
        Role role = mock(Role.class);
        when(role.getRoleName()).thenReturn(name);
        return role;
    }

    @Test
    void create_rejectsShortPassword() {
        CreateUserRequest request =
                new CreateUserRequest("newuser", "short", "Ana", "Cruz", null, "Event Organizer");

        assertThrows(InvalidRequestException.class, () -> userService.create(request));

        verify(users, never()).save(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void create_rejectsDuplicateUsername() {
        when(users.existsByUsernameIgnoreCase("newuser")).thenReturn(true);
        CreateUserRequest request = new CreateUserRequest(
                "newuser", "a-long-password-1", "Ana", "Cruz", null, "Event Organizer");

        assertThrows(DuplicateResourceException.class, () -> userService.create(request));

        verify(users, never()).save(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void create_storesOnlyTheHash_andWritesAuditEntry() {
        Role organizer = roleNamed("Event Organizer");
        when(roles.findByRoleName("Event Organizer")).thenReturn(Optional.of(organizer));
        when(passwordEncoder.encode("a-long-password-1")).thenReturn("HASHED");
        when(users.save(any(userAccount.class))).thenAnswer(call -> call.getArgument(0));

        UserResponse response = userService.create(new CreateUserRequest(
                "  newuser ", "a-long-password-1", " Ana ", "Cruz", "  ", "Event Organizer"));

        ArgumentCaptor<userAccount> captor = ArgumentCaptor.forClass(userAccount.class);
        verify(users).save(captor.capture());
        assertEquals("HASHED", captor.getValue().getPasswordHash());
        assertEquals("newuser", captor.getValue().getUsername());
        assertEquals("Ana", captor.getValue().getFirstName());
        assertNull(captor.getValue().getEmail());
        assertEquals("Event Organizer", response.roleName());
        verify(auditService).log(eq(AuditAction.CREATED), eq("user_account"), any());
    }

    @Test
    void update_adminCannotChangeTheirOwnStatus() {
        Role admin = roleNamed("Super Admin");
        userAccount me = new userAccount("admin", "hash", "System", "Administrator", null, admin);
        when(users.findById(1)).thenReturn(Optional.of(me));
        when(roles.findByRoleName("Super Admin")).thenReturn(Optional.of(admin));
        UpdateUserRequest request = new UpdateUserRequest(
                "admin", "System", "Administrator", null, "Super Admin", "Inactive");

        assertThrows(InvalidRequestException.class, () -> userService.update(1, request, 1));

        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void update_cannotDemoteTheLastActiveSuperAdmin() {
        Role admin = roleNamed("Super Admin");
        Role organizer = roleNamed("Event Organizer");
        userAccount other = new userAccount("boss", "hash", "Bo", "Ss", null, admin);
        when(users.findById(2)).thenReturn(Optional.of(other));
        when(roles.findByRoleName("Event Organizer")).thenReturn(Optional.of(organizer));
        when(users.countByRole_RoleNameAndAccountStatus("Super Admin", "Active")).thenReturn(1L);
        UpdateUserRequest request =
                new UpdateUserRequest("boss", "Bo", "Ss", null, "Event Organizer", "Active");

        assertThrows(InvalidRequestException.class, () -> userService.update(2, request, 1));

        verify(auditService, never()).log(any(), any(), any());
    }
}