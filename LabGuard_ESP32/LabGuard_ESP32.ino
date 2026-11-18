#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <Preferences.h>
#include <time.h>
#include <math.h>

constexpr char WIFI_SSID[] = "didil";
constexpr char WIFI_PASSWORD[] = "didilhensem";
constexpr char FIREBASE_API_KEY[] = "AIzaSyCSlW3seUvudPDNlznPzQsROXltw04awh4";
constexpr char FIREBASE_DATABASE_URL[] = "https://labguard-419c6-default-rtdb.asia-southeast1.firebasedatabase.app";
constexpr char DEVICE_EMAIL[] = "tboom743@gmail.com";
constexpr char DEVICE_PASSWORD[] = "123456";
constexpr char LAB_ID[] = "lab01";

constexpr int DHT_PIN = 18;
constexpr int GAS_PIN = 34;
constexpr int FLAME_PIN = 33;
constexpr int RELAY_PIN = 16;
constexpr bool RELAY_ACTIVE_LOW = true;
constexpr bool FLAME_ACTIVE_LOW = true;
constexpr unsigned long GAS_WARMUP_MS = 60000;

struct SafetySettings {
  float temperatureHigh = 40.0f;
  float temperatureClear = 38.0f;
  int gasHigh = 2200;
  int gasClear = 2000;

  bool valid() const {
    return temperatureHigh >= 30 && temperatureHigh <= 60 &&
      temperatureClear >= 20 && temperatureClear <= temperatureHigh - 1 &&
      gasHigh >= 100 && gasHigh <= 4000 && gasClear >= 0 && gasClear < gasHigh;
  }
};

enum class AlarmReason { None, Flame, Gas, Temperature, Multiple, ManualTest, SensorFault };

inline const char* reasonName(AlarmReason reason);

inline const char* reasonName(AlarmReason reason) {
  switch (reason) {
    case AlarmReason::Flame: return "flame";
    case AlarmReason::Gas: return "gas";
    case AlarmReason::Temperature: return "temperature";
    case AlarmReason::Multiple: return "multiple";
    case AlarmReason::ManualTest: return "manual_test";
    case AlarmReason::SensorFault: return "sensor_fault";
    default: return "none";
  }
}

class SafetyLogic {
 public:
  bool gasAlarm = false;
  bool temperatureAlarm = false;
  bool manualActive = false;
  bool alarmOn = false;
  AlarmReason reason = AlarmReason::None;

  void startTest(uint32_t now) { manualStarted = now; manualActive = true; }
  void stopTest() { manualActive = false; }

  void update(bool flame, int gas, bool gasReady, float temperature,
              bool temperatureValid, uint32_t now, const SafetySettings& settings) {
    if (manualActive && uint32_t(now - manualStarted) >= 10000) manualActive = false;
    if (gasReady) {
      if (gas >= settings.gasHigh) gasAlarm = true;
      else if (gas <= settings.gasClear) gasAlarm = false;
    } else gasAlarm = false;
    if (temperatureValid) {
      if (temperature >= settings.temperatureHigh) temperatureAlarm = true;
      else if (temperature <= settings.temperatureClear) temperatureAlarm = false;
    }
    const int hazards = int(flame) + int(gasAlarm) + int(temperatureAlarm);
    alarmOn = hazards > 0 || manualActive;
    reason = hazards > 1 ? AlarmReason::Multiple : flame ? AlarmReason::Flame :
      gasAlarm ? AlarmReason::Gas : temperatureAlarm ? AlarmReason::Temperature :
      manualActive ? AlarmReason::ManualTest : AlarmReason::None;
  }

 private:
  uint32_t manualStarted = 0;
};

static const char FIREBASE_ROOTS[] = R"CERTS(
-----BEGIN CERTIFICATE-----
MIIFVzCCAz+gAwIBAgINAgPlk28xsBNJiGuiFzANBgkqhkiG9w0BAQwFADBHMQsw
CQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZpY2VzIExMQzEU
MBIGA1UEAxMLR1RTIFJvb3QgUjEwHhcNMTYwNjIyMDAwMDAwWhcNMzYwNjIyMDAw
MDAwWjBHMQswCQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZp
Y2VzIExMQzEUMBIGA1UEAxMLR1RTIFJvb3QgUjEwggIiMA0GCSqGSIb3DQEBAQUA
A4ICDwAwggIKAoICAQC2EQKLHuOhd5s73L+UPreVp0A8of2C+X0yBoJx9vaMf/vo
27xqLpeXo4xL+Sv2sfnOhB2x+cWX3u+58qPpvBKJXqeqUqv4IyfLpLGcY9vXmX7w
Cl7raKb0xlpHDU0QM+NOsROjyBhsS+z8CZDfnWQpJSMHobTSPS5g4M/SCYe7zUjw
TcLCeoiKu7rPWRnWr4+wB7CeMfGCwcDfLqZtbBkOtdh+JhpFAz2weaSUKK0Pfybl
qAj+lug8aJRT7oM6iCsVlgmy4HqMLnXWnOunVmSPlk9orj2XwoSPwLxAwAtcvfaH
szVsrBhQf4TgTM2S0yDpM7xSma8ytSmzJSq0SPly4cpk9+aCEI3oncKKiPo4Zor8
Y/kB+Xj9e1x3+naH+uzfsQ55lVe0vSbv1gHR6xYKu44LtcXFilWr06zqkUspzBmk
MiVOKvFlRNACzqrOSbTqn3yDsEB750Orp2yjj32JgfpMpf/VjsPOS+C12LOORc92
wO1AK/1TD7Cn1TsNsYqiA94xrcx36m97PtbfkSIS5r762DL8EGMUUXLeXdYWk70p
aDPvOmbsB4om3xPXV2V4J95eSRQAogB/mqghtqmxlbCluQ0WEdrHbEg8QOB+DVrN
VjzRlwW5y0vtOUucxD/SVRNuJLDWcfr0wbrM7Rv1/oFB2ACYPTrIrnqYNxgFlQID
AQABo0IwQDAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
FgQU5K8rJnEaK0gnhS9SZizv8IkTcT4wDQYJKoZIhvcNAQEMBQADggIBAJ+qQibb
C5u+/x6Wki4+omVKapi6Ist9wTrYggoGxval3sBOh2Z5ofmmWJyq+bXmYOfg6LEe
QkEzCzc9zolwFcq1JKjPa7XSQCGYzyI0zzvFIoTgxQ6KfF2I5DUkzps+GlQebtuy
h6f88/qBVRRiClmpIgUxPoLW7ttXNLwzldMXG+gnoot7TiYaelpkttGsN/H9oPM4
7HLwEXWdyzRSjeZ2axfG34arJ45JK3VmgRAhpuo+9K4l/3wV3s6MJT/KYnAK9y8J
ZgfIPxz88NtFMN9iiMG1D53Dn0reWVlHxYciNuaCp+0KueIHoI17eko8cdLiA6Ef
MgfdG+RCzgwARWGAtQsgWSl4vflVy2PFPEz0tv/bal8xa5meLMFrUKTX5hgUvYU/
Z6tGn6D/Qqc6f1zLXbBwHSs09dR2CQzreExZBfMzQsNhFRAbd03OIozUhfJFfbdT
6u9AWpQKXCBfTkBdYiJ23//OYb2MI3jSNwLgjt7RETeJ9r/tSQdirpLsQBqvFAnZ
0E6yove+7u7Y/9waLd64NnHi/Hm3lCXRSHNboTXns5lndcEZOitHTtNCjv0xyBZm
2tIMPNuzjsmhDYAPexZ3FL//2wmUspO8IFgV6dtxQ/PeEMMA3KgqlbbC1j+Qa3bb
bP6MvPJwNQzcmRk13NfIRmPVNnGuV/u3gm3c
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIFVzCCAz+gAwIBAgINAgPlrsWNBCUaqxElqjANBgkqhkiG9w0BAQwFADBHMQsw
CQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZpY2VzIExMQzEU
MBIGA1UEAxMLR1RTIFJvb3QgUjIwHhcNMTYwNjIyMDAwMDAwWhcNMzYwNjIyMDAw
MDAwWjBHMQswCQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZp
Y2VzIExMQzEUMBIGA1UEAxMLR1RTIFJvb3QgUjIwggIiMA0GCSqGSIb3DQEBAQUA
A4ICDwAwggIKAoICAQDO3v2m++zsFDQ8BwZabFn3GTXd98GdVarTzTukk3LvCvpt
nfbwhYBboUhSnznFt+4orO/LdmgUud+tAWyZH8QiHZ/+cnfgLFuv5AS/T3KgGjSY
6Dlo7JUle3ah5mm5hRm9iYz+re026nO8/4Piy33B0s5Ks40FnotJk9/BW9BuXvAu
MC6C/Pq8tBcKSOWIm8Wba96wyrQD8Nr0kLhlZPdcTK3ofmZemde4wj7I0BOdre7k
RXuJVfeKH2JShBKzwkCX44ofR5GmdFrS+LFjKBC4swm4VndAoiaYecb+3yXuPuWg
f9RhD1FLPD+M2uFwdNjCaKH5wQzpoeJ/u1U8dgbuak7MkogwTZq9TwtImoS1mKPV
+3PBV2HdKFZ1E66HjucMUQkQdYhMvI35ezzUIkgfKtzra7tEscszcTJGr61K8Yzo
dDqs5xoic4DSMPclQsciOzsSrZYuxsN2B6ogtzVJV+mSSeh2FnIxZyuWfoqjx5RW
Ir9qS34BIbIjMt/kmkRtWVtd9QCgHJvGeJeNkP+byKq0rxFROV7Z+2et1VsRnTKa
G73VululycslaVNVJ1zgyjbLiGH7HrfQy+4W+9OmTN6SpdTi3/UGVN4unUu0kzCq
gc7dGtxRcw1PcOnlthYhGXmy5okLdWTK1au8CcEYof/UVKGFPP0UJAOyh9OktwID
AQABo0IwQDAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
FgQUu//KjiOfT5nK2+JopqUVJxce2Q4wDQYJKoZIhvcNAQEMBQADggIBAB/Kzt3H
vqGf2SdMC9wXmBFqiN495nFWcrKeGk6c1SuYJF2ba3uwM4IJvd8lRuqYnrYb/oM8
0mJhwQTtzuDFycgTE1XnqGOtjHsB/ncw4c5omwX4Eu55MaBBRTUoCnGkJE+M3DyC
B19m3H0Q/gxhswWV7uGugQ+o+MePTagjAiZrHYNSVc61LwDKgEDg4XSsYPWHgJ2u
NmSRXbBoGOqKYcl3qJfEycel/FVL8/B/uWU9J2jQzGv6U53hkRrJXRqWbTKH7QMg
yALOWr7Z6v2yTcQvG99fevX4i8buMTolUVVnjWQye+mew4K6Ki3pHrTgSAai/Gev
HyICc/sgCq+dVEuhzf9gR7A/Xe8bVr2XIZYtCtFenTgCR2y59PYjJbigapordwj6
xLEokCZYCDzifqrXPW+6MYgKBesntaFJ7qBFVHvmJ2WZICGoo7z7GJa7Um8M7YNR
TOlZ4iBgxcJlkoKM8xAfDoqXvneCbT+PHV28SSe9zE8P4c52hgQjxcCMElv924Sg
JPFI/2R80L5cFtHvma3AH/vLrrw4IgYmZNralw4/KBVEqE8AyvCazM90arQ+POuV
7LXTWtiBmelDGDfrs7vRWGJB82bSj6p4lVQgw1oudCvV0b4YacCs1aTPObpRhANl
6WLAYv7YTVWW4tAR+kg0Eeye7QUd5MjWHYbL
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIICCTCCAY6gAwIBAgINAgPluILrIPglJ209ZjAKBggqhkjOPQQDAzBHMQswCQYD
VQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZpY2VzIExMQzEUMBIG
A1UEAxMLR1RTIFJvb3QgUjMwHhcNMTYwNjIyMDAwMDAwWhcNMzYwNjIyMDAwMDAw
WjBHMQswCQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZpY2Vz
IExMQzEUMBIGA1UEAxMLR1RTIFJvb3QgUjMwdjAQBgcqhkjOPQIBBgUrgQQAIgNi
AAQfTzOHMymKoYTey8chWEGJ6ladK0uFxh1MJ7x/JlFyb+Kf1qPKzEUURout736G
jOyxfi//qXGdGIRFBEFVbivqJn+7kAHjSxm65FSWRQmx1WyRRK2EE46ajA2ADDL2
4CejQjBAMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQW
BBTB8Sa6oC2uhYHP0/EqEr24Cmf9vDAKBggqhkjOPQQDAwNpADBmAjEA9uEglRR7
VKOQFhG/hMjqb2sXnh5GmCCbn9MN2azTL818+FsuVbu/3ZL3pAzcMeGiAjEA/Jdm
ZuVDFhOD3cffL74UOO0BzrEXGhF16b0DjyZ+hOXJYKaV11RZt+cRLInUue4X
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIICCTCCAY6gAwIBAgINAgPlwGjvYxqccpBQUjAKBggqhkjOPQQDAzBHMQswCQYD
VQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZpY2VzIExMQzEUMBIG
A1UEAxMLR1RTIFJvb3QgUjQwHhcNMTYwNjIyMDAwMDAwWhcNMzYwNjIyMDAwMDAw
WjBHMQswCQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZpY2Vz
IExMQzEUMBIGA1UEAxMLR1RTIFJvb3QgUjQwdjAQBgcqhkjOPQIBBgUrgQQAIgNi
AATzdHOnaItgrkO4NcWBMHtLSZ37wWHO5t5GvWvVYRg1rkDdc/eJkTBa6zzuhXyi
QHY7qca4R9gq55KRanPpsXI5nymfopjTX15YhmUPoYRlBtHci8nHc8iMai/lxKvR
HYqjQjBAMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQW
BBSATNbrdP9JNqPV2Py1PsVq8JQdjDAKBggqhkjOPQQDAwNpADBmAjEA6ED/g94D
9J+uHXqnLrmvT/aDHQ4thQEd0dlq7A/Cr8deVl5c1RxYIigL9zC2L7F8AjEA8GE8
p/SgguMh1YQdc4acLa/KNJvxn7kjNuK8YAOdgLOaVsjh4rsUecrNIdSUtUlD
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
-----END CERTIFICATE-----
)CERTS";

struct DeviceSnapshot {
  float temperature = NAN;
  float humidity = NAN;
  int gas = 0;
  bool flame = false;
  bool dhtOk = false;
  bool gasReady = false;
  bool alarm = false;
  uint32_t warmupRemaining = 0;
  uint32_t uptime = 0;
  AlarmReason reason = AlarmReason::None;
  SafetySettings settings;
  char ackId[64] = "";
};

struct DeviceCommand { char id[64]; bool start; };
struct SafetyEvent { AlarmReason reason; bool active; uint64_t occurredAt; };

DHT dht(DHT_PIN, DHT11);
Preferences settingsStore;
SafetyLogic safety;
DeviceSnapshot snapshot;
portMUX_TYPE snapshotLock = portMUX_INITIALIZER_UNLOCKED;
QueueHandle_t commandQueue;
QueueHandle_t settingsQueue;
QueueHandle_t eventQueue;
String idToken;
uint32_t tokenStarted = 0;
uint32_t lastAuthAttempt = 0;
bool authAttempted = false;
uint32_t tokenLifetime = 3000000;
uint64_t bootEpoch = 0;

DeviceSnapshot readSnapshot();
void storeSnapshot(const DeviceSnapshot& value);
void fillReading(JsonObject target, const DeviceSnapshot& data);
void queueEvent(AlarmReason reason, bool active);

uint64_t epochMilliseconds() {
  timeval value;
  gettimeofday(&value, nullptr);
  return value.tv_sec >= 1700000000 ? uint64_t(value.tv_sec) * 1000 + value.tv_usec / 1000 : 0;
}

DeviceSnapshot readSnapshot() {
  DeviceSnapshot result;
  portENTER_CRITICAL(&snapshotLock);
  result = snapshot;
  portEXIT_CRITICAL(&snapshotLock);
  return result;
}

void storeSnapshot(const DeviceSnapshot& value) {
  portENTER_CRITICAL(&snapshotLock);
  snapshot = value;
  portEXIT_CRITICAL(&snapshotLock);
}

bool configured() {
  const char* values[] = {WIFI_SSID, WIFI_PASSWORD, FIREBASE_API_KEY,
    FIREBASE_DATABASE_URL, DEVICE_EMAIL, DEVICE_PASSWORD};
  for (const char* value : values) {
    if (strstr(value, "REPLACE_") != nullptr) return false;
  }
  return true;
}

int request(const String& url, const char* method, const String& payload, String& result) {
  result = "";
  WiFiClientSecure client;
  client.setCACert(FIREBASE_ROOTS);
  client.setHandshakeTimeout(8);

  HTTPClient http;
  http.setConnectTimeout(5000);
  http.setTimeout(4000);

  if (!http.begin(client, url)) {
    Serial.println("HTTPS setup failed. Check the configured URL.");
    return -1;
  }

  http.addHeader("Content-Type", "application/json");
  const int code = http.sendRequest(method, payload);

  if (code < 0) {
    const String error = HTTPClient::errorToString(code);
    Serial.printf("HTTPS transport error: %d (%s)\n", code, error.c_str());
    Serial.printf("Wi-Fi: %s | RSSI: %ld dBm\n",
      WiFi.status() == WL_CONNECTED ? "connected" : "disconnected",
      static_cast<long>(WiFi.RSSI()));

    char tlsError[160] = {};
    const int tlsCode = client.lastError(tlsError, sizeof(tlsError));

    if (tlsCode != 0) Serial.printf("TLS error: %d %s\n", tlsCode, tlsError);
    else Serial.println("TLS: no detailed error available.");
  }

  if (code > 0) result = http.getString();
  http.end();
  return code;
}

String databaseEndpoint(const String& path) {
  String base = FIREBASE_DATABASE_URL;
  while (base.endsWith("/")) base.remove(base.length() - 1);
  return base + "/labs/" + LAB_ID + path + ".json?auth=" + idToken;
}

int databaseRequest(const String& path, const char* method, const String& payload, String& response) {
  int code = request(databaseEndpoint(path), method, payload, response);
  if (code == 401 || code == 403) idToken = "";
  if (code < 200 || code >= 300) Serial.printf("Database request failed: %d\n", code);
  return code;
}

bool authenticate() {
  if (idToken.length() > 0 && uint32_t(millis() - tokenStarted) < tokenLifetime) return true;
  if (authAttempted && uint32_t(millis() - lastAuthAttempt) < 15000) return false;
  authAttempted = true;
  lastAuthAttempt = millis();
  JsonDocument payload;
  payload["email"] = DEVICE_EMAIL;
  payload["password"] = DEVICE_PASSWORD;
  payload["returnSecureToken"] = true;
  String body;
  serializeJson(payload, body);
  String response;
  int code = request(String("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=") +
    FIREBASE_API_KEY, "POST", body, response);
  if (code != 200) {
    idToken = "";
    Serial.printf("Device sign-in failed: %d\n", code);
    return false;
  }
  JsonDocument result;
  if (deserializeJson(result, response)) return false;
  idToken = result["idToken"].as<String>();
  const long expiresIn = result["expiresIn"].as<String>().toInt();
  tokenLifetime = expiresIn > 120 ? uint32_t(expiresIn - 120) * 1000 : 3000000;
  tokenStarted = millis();
  Serial.println("Device signed in.");
  return idToken.length() > 0;
}

void fillReading(JsonObject target, const DeviceSnapshot& data) {
  if (data.dhtOk) {
    target["temperatureC"] = data.temperature;
    target["humidityPct"] = data.humidity;
  } else {
    target["temperatureC"] = nullptr;
    target["humidityPct"] = nullptr;
  }
  target["gasRaw"] = data.gas;
  target["flameDetected"] = data.flame;
  target["dhtOk"] = data.dhtOk;
  target["gasReady"] = data.gasReady;
  target["gasWarmupRemainingS"] = data.warmupRemaining;
  target["alarmOn"] = data.alarm;
  target["alarmReason"] = reasonName(data.reason);
  target["safetyStatus"] = data.alarm ? "alarm" : !data.dhtOk ? "sensor_fault" :
    !data.gasReady ? "warming_up" : "normal";
  target["wifiRssi"] = WiFi.RSSI();
  target["uptimeS"] = data.uptime;
  target["updatedAt"][".sv"] = "timestamp";
  target["ackCommandId"] = data.ackId;
  target["ackResult"] = strlen(data.ackId) ? "accepted" : "none";
  target["firmwareVersion"] = "1.0.0";
  JsonObject settings = target["appliedSettings"].to<JsonObject>();
  settings["temperatureHigh"] = data.settings.temperatureHigh;
  settings["temperatureClear"] = data.settings.temperatureClear;
  settings["gasHigh"] = data.settings.gasHigh;
  settings["gasClear"] = data.settings.gasClear;
}

void pollCommand() {
  String response;
  if (databaseRequest("/command", "GET", "", response) != 200) return;
  JsonDocument document;
  if (deserializeJson(document, response) || document.isNull()) return;
  const String id = document["id"] | "";
  const String action = document["action"] | "";
  const uint64_t issued = document["issuedAt"] | uint64_t(0);
  const uint64_t now = epochMilliseconds();
  if (id.isEmpty() || id.length() >= 64 || id == readSnapshot().ackId) return;
  if (issued < bootEpoch || issued > now + 2000 || now > issued + 10000) return;
  if (action != "test_alarm" && action != "stop_test") return;
  DeviceCommand command;
  strlcpy(command.id, id.c_str(), sizeof(command.id));
  command.start = action == "test_alarm";
  xQueueSend(commandQueue, &command, 0);
}

void pollSettings() {
  String response;
  if (databaseRequest("/config", "GET", "", response) != 200) return;
  JsonDocument document;
  if (deserializeJson(document, response) || document.isNull()) return;
  if (!document["temperatureHigh"].is<float>() || !document["temperatureClear"].is<float>() ||
      !document["gasHigh"].is<int>() || !document["gasClear"].is<int>()) return;
  SafetySettings value;
  value.temperatureHigh = document["temperatureHigh"];
  value.temperatureClear = document["temperatureClear"];
  value.gasHigh = document["gasHigh"];
  value.gasClear = document["gasClear"];
  if (value.valid()) xQueueOverwrite(settingsQueue, &value);
}

void networkTask(void*) {
  Preferences eventStore;
  eventStore.begin("lab-events", false);
  uint32_t eventIndex = eventStore.getUInt("index", 0);
  uint32_t lastReconnect = 0;
  uint32_t lastPublish = 0;
  uint32_t lastCommand = 0;
  uint32_t lastSettings = 0;
  int64_t historyInterval = -1;
  SafetyEvent pendingEvent;
  bool hasPendingEvent = false;
  bool started = false;
  for (;;) {
    if (!configured()) { vTaskDelay(pdMS_TO_TICKS(1000)); continue; }
    if (!started) {
      WiFi.mode(WIFI_STA);
      WiFi.setAutoReconnect(true);
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
      configTime(0, 0, "pool.ntp.org", "time.google.com");
      started = true;
    }
    if (WiFi.status() != WL_CONNECTED) {
      if (uint32_t(millis() - lastReconnect) >= 15000) {
        lastReconnect = millis();
        WiFi.reconnect();
      }
      vTaskDelay(pdMS_TO_TICKS(200)); continue;
    }
    const uint64_t epoch = epochMilliseconds();
    if (epoch == 0) { vTaskDelay(pdMS_TO_TICKS(200)); continue; }
    if (bootEpoch == 0) bootEpoch = epoch - millis();
    if (!authenticate()) { vTaskDelay(pdMS_TO_TICKS(200)); continue; }
    if (uint32_t(millis() - lastCommand) >= 1500) {
      lastCommand = millis(); pollCommand();
    }
    if (uint32_t(millis() - lastSettings) >= 10000) {
      lastSettings = millis(); pollSettings();
    }
    if (uint32_t(millis() - lastPublish) >= 4000) {
      lastPublish = millis();
      const DeviceSnapshot data = readSnapshot();
      const int64_t interval = epochMilliseconds() / 30000;
      JsonDocument document;
      fillReading(document["current"].to<JsonObject>(), data);
      const bool saveHistory = interval != historyInterval;
      if (saveHistory) {
        const String slot = String("history/slot") + uint32_t(interval % 2880);
        fillReading(document[slot].to<JsonObject>(), data);
      }
      String payload;
      serializeJson(document, payload);
      String response;
      int code = databaseRequest("", "PATCH", payload, response);
      if (code >= 200 && code < 300 && saveHistory) historyInterval = interval;
    }
    if (!hasPendingEvent) hasPendingEvent = xQueueReceive(eventQueue, &pendingEvent, 0) == pdTRUE;
    if (hasPendingEvent && idToken.length()) {
      JsonDocument document;
      document["reason"] = reasonName(pendingEvent.reason);
      document["state"] = pendingEvent.active ? "active" : "clear";
      document["occurredAt"] = pendingEvent.occurredAt;
      document["updatedAt"][".sv"] = "timestamp";
      String payload;
      serializeJson(document, payload);
      String response;
      int code = databaseRequest(String("/alerts/slot") + (eventIndex % 100), "PUT", payload, response);
      if (code >= 200 && code < 300) {
        hasPendingEvent = false;
        eventStore.putUInt("index", ++eventIndex);
      }
    }
    vTaskDelay(pdMS_TO_TICKS(100));
  }
}

void queueEvent(AlarmReason reason, bool active) {
  SafetyEvent event{reason, active, epochMilliseconds()};
  if (xQueueSend(eventQueue, &event, 0) != pdTRUE) {
    SafetyEvent discarded;
    xQueueReceive(eventQueue, &discarded, 0);
    xQueueSend(eventQueue, &event, 0);
  }
}

void setup() {
  digitalWrite(RELAY_PIN, RELAY_ACTIVE_LOW ? HIGH : LOW);
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(115200);
  pinMode(FLAME_PIN, INPUT_PULLUP);
  pinMode(GAS_PIN, INPUT);
  analogReadResolution(12);
  analogSetPinAttenuation(GAS_PIN, ADC_11db);
  dht.begin();
  commandQueue = xQueueCreate(4, sizeof(DeviceCommand));
  settingsQueue = xQueueCreate(1, sizeof(SafetySettings));
  eventQueue = xQueueCreate(16, sizeof(SafetyEvent));
  if (!commandQueue || !settingsQueue || !eventQueue) {
    Serial.println("Queue allocation failed. Restart the device.");
    while (true) delay(1000);
  }
  settingsStore.begin("lab-settings", false);
  SafetySettings saved;
  saved.temperatureHigh = settingsStore.getFloat("tempHigh", 40);
  saved.temperatureClear = settingsStore.getFloat("tempClear", 38);
  saved.gasHigh = settingsStore.getInt("gasHigh", 2200);
  saved.gasClear = settingsStore.getInt("gasClear", 2000);
  if (saved.valid()) snapshot.settings = saved;
  BaseType_t created = xTaskCreatePinnedToCore(networkTask, "cloud", 16384, nullptr, 1, nullptr, 0);
  if (created != pdPASS) Serial.println("Cloud task unavailable. Local protection remains active.");
  Serial.println("LabGuard started. Serial speed: 115200.");
  if (!configured()) Serial.println("Complete the configuration at the top of LabGuard_ESP32.ino to enable cloud communication.");
}

void loop() {
  static DeviceSnapshot data = readSnapshot();
  static uint32_t lastSample = 0;
  static uint32_t lastDht = 0;
  static uint32_t lastPrint = 0;
  static int flameCount = 0;
  static bool gasInitialised = false;
  static bool gasWarmupComplete = false;
  static float filteredGas = 0;
  static AlarmReason previousEvent = AlarmReason::None;
  const uint32_t now = millis();
  if (uint32_t(now - lastSample) >= 20) {
    lastSample = now;
    bool detected = digitalRead(FLAME_PIN) == (FLAME_ACTIVE_LOW ? LOW : HIGH);
    flameCount = detected ? min(flameCount + 1, 3) : max(flameCount - 1, 0);
    if (flameCount == 3) data.flame = true;
    if (flameCount == 0) data.flame = false;
    const int sample = analogRead(GAS_PIN);
    if (!gasInitialised) { filteredGas = sample; gasInitialised = true; }
    else filteredGas = filteredGas * 0.85f + sample * 0.15f;
    data.gas = int(filteredGas + 0.5f);
  }
  if (uint32_t(now - lastDht) >= 2200) {
    lastDht = now;
    data.temperature = dht.readTemperature();
    data.humidity = dht.readHumidity();
    data.dhtOk = isfinite(data.temperature) && isfinite(data.humidity) &&
      data.temperature >= -20 && data.temperature <= 80 && data.humidity >= 0 && data.humidity <= 100;
  }
  SafetySettings settings;
  if (xQueueReceive(settingsQueue, &settings, 0) == pdTRUE && settings.valid()) {
    if (settings.temperatureHigh != data.settings.temperatureHigh ||
        settings.temperatureClear != data.settings.temperatureClear ||
        settings.gasHigh != data.settings.gasHigh || settings.gasClear != data.settings.gasClear) {
      data.settings = settings;
      settingsStore.putFloat("tempHigh", settings.temperatureHigh);
      settingsStore.putFloat("tempClear", settings.temperatureClear);
      settingsStore.putInt("gasHigh", settings.gasHigh);
      settingsStore.putInt("gasClear", settings.gasClear);
    }
  }
  DeviceCommand command;
  while (xQueueReceive(commandQueue, &command, 0) == pdTRUE) {
    if (strcmp(command.id, data.ackId) == 0) continue;
    if (command.start) safety.startTest(now); else safety.stopTest();
    strlcpy(data.ackId, command.id, sizeof(data.ackId));
  }
  gasWarmupComplete = gasWarmupComplete || now >= GAS_WARMUP_MS;
  data.gasReady = gasWarmupComplete;
  data.warmupRemaining = data.gasReady ? 0 : (GAS_WARMUP_MS - now + 999) / 1000;
  safety.update(data.flame, data.gas, data.gasReady, data.temperature, data.dhtOk, now, data.settings);
  data.alarm = safety.alarmOn;
  data.reason = safety.reason;
  data.uptime = now / 1000;
  digitalWrite(RELAY_PIN, data.alarm ? (RELAY_ACTIVE_LOW ? LOW : HIGH) : (RELAY_ACTIVE_LOW ? HIGH : LOW));
  storeSnapshot(data);
  AlarmReason event = safety.reason;
  if (event == AlarmReason::None && !data.dhtOk && now > 3000) event = AlarmReason::SensorFault;
  if (event != previousEvent) {
    if (event == AlarmReason::None) queueEvent(previousEvent, false);
    else queueEvent(event, true);
    previousEvent = event;
  }
  if (uint32_t(now - lastPrint) >= 2000) {
    lastPrint = now;
    Serial.printf("Temperature: %.1f C | Humidity: %.1f %% | Gas: %d | Flame: %s | Alarm: %s | %s\n",
      data.temperature, data.humidity, data.gas, data.flame ? "YES" : "NO", data.alarm ? "ON" : "OFF", reasonName(data.reason));
  }
  delay(5);
}
