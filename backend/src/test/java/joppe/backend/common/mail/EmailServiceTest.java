package joppe.backend.common.mail;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import java.util.Properties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;

class EmailServiceTest {

    private JavaMailSender mailSender;
    private EmailService emailService;

    @BeforeEach
    void setUp() {
        mailSender = mock(JavaMailSender.class);
        emailService = new EmailService(mailSender);
        ReflectionTestUtils.setField(emailService, "defaultFromEmail", "noreply@joppe.vn");
        ReflectionTestUtils.setField(emailService, "defaultFromName", "Joppe Tech Store");
    }

    @Test
    void sendSimpleEmailSucceeds() {
        assertDoesNotThrow(() ->
                emailService.sendSimpleEmail("customer@example.com", "Welcome to Joppe", "Hello customer!")
        );

        verify(mailSender, times(1)).send(any(SimpleMailMessage.class));
    }

    @Test
    void sendHtmlEmailSucceeds() {
        MimeMessage mimeMessage = new MimeMessage(Session.getInstance(new Properties()));
        when(mailSender.createMimeMessage()).thenReturn(mimeMessage);

        assertDoesNotThrow(() ->
                emailService.sendHtmlEmail(
                        "customer@example.com",
                        "Order Confirmation #1001",
                        "<h1>Thank you for your order</h1><p>Items are on the way.</p>"
                )
        );

        verify(mailSender, times(1)).send(any(MimeMessage.class));
    }
}
