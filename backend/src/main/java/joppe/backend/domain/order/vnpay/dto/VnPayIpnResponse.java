package joppe.backend.domain.order.vnpay.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record VnPayIpnResponse(
        @JsonProperty("RspCode") String rspCode,
        @JsonProperty("Message") String message
) {
    public static VnPayIpnResponse success() {
        return new VnPayIpnResponse("00", "Confirm Success");
    }

    public static VnPayIpnResponse orderNotFound() {
        return new VnPayIpnResponse("01", "Order not Found");
    }

    public static VnPayIpnResponse orderAlreadyConfirmed() {
        return new VnPayIpnResponse("02", "Order already confirmed");
    }

    public static VnPayIpnResponse invalidAmount() {
        return new VnPayIpnResponse("04", "Invalid Amount");
    }

    public static VnPayIpnResponse invalidChecksum() {
        return new VnPayIpnResponse("97", "Invalid Checksum");
    }

    public static VnPayIpnResponse unknownError(String msg) {
        return new VnPayIpnResponse("99", msg != null ? msg : "Unknown Error");
    }
}
