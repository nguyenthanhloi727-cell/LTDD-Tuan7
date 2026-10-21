using System.Diagnostics;

namespace NguyenThanhLoi_2380601289.Services
{
    // "Gui SMS" gia lap (UP6): backend chay cung may voi Android emulator nen tu goi
    //   adb -s emulator-5554 emu sms send <sdt> "<noi dung>"
    // -> may ao nhan duoc tin nhan nhu that, app dung smart_auth doc ma.
    // Khong co adb / khong co may ao (vd. dung dien thoai that) -> chi ghi log, nguoi dung go tay ma.
    public class SmsSimulator
    {
        private static readonly TimeSpan Delay = TimeSpan.FromSeconds(1.5);

        private readonly IConfiguration _configuration;
        private readonly ILogger<SmsSimulator> _logger;

        public SmsSimulator(IConfiguration configuration, ILogger<SmsSimulator> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        // Chay nen, khong bat API send-otp phai cho adb.
        // Doi 1,5 giay de app kip bat dau cho SMS (User Consent chi bat tin den sau luc bat dau cho).
        public void SendInBackground(string phone, string message)
        {
            if (!_configuration.GetValue("SmsSimulator:Enabled", true)) return;

            _ = Task.Run(async () =>
            {
                try
                {
                    await Task.Delay(Delay);
                    await SendAsync(phone, message);
                }
                catch (Exception e)
                {
                    _logger.LogWarning("[SMS gia lap] Loi khi goi adb: {Error}", e.Message);
                }
            });
        }

        private async Task SendAsync(string phone, string message)
        {
            var adb = FindAdb();
            if (adb == null)
            {
                _logger.LogWarning("[SMS gia lap] Khong tim thay adb.exe (dat SmsSimulator:AdbPath trong appsettings.json)");
                return;
            }

            // Lay may ao dau tien trong "adb devices" (dien thoai that khong nhan lenh "emu")
            var (_, devices) = await RunAdbAsync(adb, "devices");
            var emulator = devices
                .Split('\n', StringSplitOptions.RemoveEmptyEntries)
                .Select(line => line.Split('\t'))
                .FirstOrDefault(p => p.Length == 2 && p[0].StartsWith("emulator-") && p[1].Trim() == "device")?[0];
            if (emulator == null)
            {
                _logger.LogWarning("[SMS gia lap] Khong thay may ao Android dang chay, nhap ma OTP bang tay");
                return;
            }

            var (exitCode, output) = await RunAdbAsync(adb, "-s", emulator, "emu", "sms", "send", phone, message);
            if (exitCode == 0)
                _logger.LogInformation("[SMS gia lap] Da gui SMS toi {Phone} tren {Emulator}", phone, emulator);
            else
                _logger.LogWarning("[SMS gia lap] adb loi ({Code}): {Output}", exitCode, output.Trim());
        }

        // Thu lan luot: cau hinh -> ANDROID_HOME / ANDROID_SDK_ROOT -> thu muc SDK mac dinh cua Android Studio -> PATH
        private string? FindAdb()
        {
            var configured = _configuration["SmsSimulator:AdbPath"];
            if (!string.IsNullOrWhiteSpace(configured)) return File.Exists(configured) ? configured : null;

            var exe = OperatingSystem.IsWindows() ? "adb.exe" : "adb";
            var sdkDirs = new[]
            {
                Environment.GetEnvironmentVariable("ANDROID_HOME"),
                Environment.GetEnvironmentVariable("ANDROID_SDK_ROOT"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Android", "Sdk"),
            };
            foreach (var dir in sdkDirs)
            {
                if (string.IsNullOrWhiteSpace(dir)) continue;
                var path = Path.Combine(dir, "platform-tools", exe);
                if (File.Exists(path)) return path;
            }

            var pathDirs = (Environment.GetEnvironmentVariable("PATH") ?? "").Split(Path.PathSeparator);
            return pathDirs.Select(d => Path.Combine(d.Trim(), exe)).FirstOrDefault(File.Exists);
        }

        // ArgumentList tu xu ly dau cach / dau ngoac kep trong noi dung tin nhan
        private static async Task<(int exitCode, string output)> RunAdbAsync(string adb, params string[] args)
        {
            var info = new ProcessStartInfo(adb)
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            };
            foreach (var a in args) info.ArgumentList.Add(a);

            using var process = Process.Start(info)!;
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
            var stdout = process.StandardOutput.ReadToEndAsync();
            var stderr = process.StandardError.ReadToEndAsync();
            await process.WaitForExitAsync(timeout.Token);
            return (process.ExitCode, await stdout + await stderr);
        }
    }
}
