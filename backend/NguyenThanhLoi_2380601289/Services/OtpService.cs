using System.Security.Cryptography;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Caching.Memory;

namespace NguyenThanhLoi_2380601289.Services
{
    // Ma OTP dang ky: luu trong bo nho (IMemoryCache), tat backend la mat het ma - du cho bai hoc.
    // Khong thue dich vu SMS: ma chi in ra log, nguoi test tu gui SMS gia lap vao may ao.
    public class OtpService
    {
        public const int CodeLength = 6;
        public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(5);
        public static readonly TimeSpan ResendDelay = TimeSpan.FromSeconds(60);
        private const int MaxWrongAttempts = 5;

        private readonly IMemoryCache _cache;
        private readonly ILogger<OtpService> _logger;
        private readonly SmsSimulator _sms;

        public OtpService(IMemoryCache cache, ILogger<OtpService> logger, SmsSimulator sms)
        {
            _cache = cache;
            _logger = logger;
            _sms = sms;
        }

        private class OtpEntry
        {
            public string Code { get; init; } = string.Empty;
            public DateTime SentAt { get; init; }
            public int WrongAttempts { get; set; }
        }

        // "+84 912 345 678" / "0912345678" -> "0912345678"; sai dinh dang -> null
        public static string? NormalizePhone(string? phone)
        {
            if (string.IsNullOrWhiteSpace(phone)) return null;
            var digits = Regex.Replace(phone, @"[\s\-\.]", "");
            if (digits.StartsWith("+84")) digits = "0" + digits[3..];
            else if (digits.StartsWith("84") && digits.Length == 11) digits = "0" + digits[2..];
            return Regex.IsMatch(digits, @"^0\d{9}$") ? digits : null;
        }

        // Tao va "gui" ma moi cho SDT (da chuan hoa). Tra ve 0 neu da gui,
        // con trong 60 giay cho thi tra ve so giay phai doi (khong tao ma moi).
        public int Send(string phone)
        {
            if (_cache.TryGetValue(Key(phone), out OtpEntry? old) && old != null)
            {
                var wait = ResendDelay - (DateTime.UtcNow - old.SentAt);
                if (wait > TimeSpan.Zero) return (int)Math.Ceiling(wait.TotalSeconds);
            }

            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
            _cache.Set(Key(phone), new OtpEntry { Code = code, SentAt = DateTime.UtcNow }, Lifetime);

            // "Gui SMS": in ra log (de go tay khi dung dien thoai that) + tu gui SMS vao may ao (UP6)
            var message = $"Ma OTP dang ky cua ban la {code}";
            _logger.LogWarning("[OTP] {Phone}: {Code} | Gia lap gui SMS: adb emu sms send {Phone} \"{Message}\"",
                phone, code, phone, message);
            _sms.SendInBackground(phone, message);
            return 0;
        }

        // Kiem ma. Sai qua 5 lan -> xoa ma, phai gui lai.
        public bool Verify(string phone, string? code)
        {
            if (!_cache.TryGetValue(Key(phone), out OtpEntry? entry) || entry == null) return false;
            if (entry.Code == code?.Trim()) return true;

            entry.WrongAttempts++;
            if (entry.WrongAttempts >= MaxWrongAttempts) _cache.Remove(Key(phone));
            return false;
        }

        // Dang ky xong thi xoa ma (moi ma chi dung 1 lan)
        public void Remove(string phone) => _cache.Remove(Key(phone));

        private static string Key(string phone) => "otp:" + phone;
    }
}
