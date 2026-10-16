package joppe.backend.common.mail;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.io.UnsupportedEncodingException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.from:noreply@joppe.vn}")
    private String defaultFromEmail;

    @Value("${app.mail.from-name:Joppe Tech Store}")
    private String defaultFromName;

    public void sendSimpleEmail(String to, String subject, String text) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(String.format("%s <%s>", defaultFromName, defaultFromEmail));
            message.setTo(to);
            message.setSubject(subject);
            message.setText(text);

            mailSender.send(message);
            log.info("Sent simple email to: [{}] with subject: [{}]", to, subject);
        } catch (Exception e) {
            log.error("Failed to send simple email to: [{}] with subject: [{}]", to, subject, e);
            throw new RuntimeException("Failed to send email: " + e.getMessage(), e);
        }
    }

    public void sendHtmlEmail(String to, String subject, String htmlBody) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, MimeMessageHelper.MULTIPART_MODE_MIXED_RELATED, "UTF-8");

            try {
                helper.setFrom(new InternetAddress(defaultFromEmail, defaultFromName, "UTF-8"));
            } catch (UnsupportedEncodingException e) {
                helper.setFrom(defaultFromEmail);
            }

            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlBody, true);

            mailSender.send(mimeMessage);
            log.info("Sent HTML email to: [{}] with subject: [{}]", to, subject);
        } catch (MessagingException e) {
            log.error("Failed to construct or send HTML email to: [{}] with subject: [{}]", to, subject, e);
            throw new RuntimeException("Failed to send HTML email: " + e.getMessage(), e);
        }
    }
}
