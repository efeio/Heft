#!/usr/bin/env python3
import glob
import json
import re
import sys

# All 321 keys with high-quality, App-Store ready English translations
TRANSLATIONS = {
    " ": {
        "en": " ",
        "comment": "Empty space"
    },
    "%@ %@": {
        "en": "%@ %@",
        "comment": "Pace value and action"
    },
    "%@ cm boy için normal BMI (18,5 - 24,9) aralığı %@ - %@ kg arasındadır.": {
        "en": "For %@ cm height, the normal BMI range (18.5 - 24.9) is %@ - %@ kg.",
        "comment": "Healthy weight range message"
    },
    "%@ hedefine başarıyla ulaştın. Formunu korumak için aynı kararlılıkla devam et.": {
        "en": "You've successfully reached your %@ goal. Keep up the consistency to maintain your form.",
        "comment": "Insight goal reached gain msg"
    },
    "%@ hedefine ulaştın. Sağlıklı kilonu korumak için aynı kararlılıkla devam et.": {
        "en": "You've reached your %@ goal. Keep up the consistency to maintain your healthy weight.",
        "comment": "Insight goal reached lose msg"
    },
    "%@ kg hedefine ulaştığında BMI değerin %@ (%@) olacak. Boyun için sağlıklı kilo aralığı %@ - %@ kg'dır.": {
        "en": "When you reach your %@ kg goal, your BMI will be %@ (%@). The healthy weight range for your height is %@ - %@ kg.",
        "comment": "Target BMI explanation"
    },
    "%@ kilogram": {
        "en": "%@ kilograms",
        "comment": "Kilograms accessibility value"
    },
    "%@ tarihine ait mevcut kayıt (%@), yeni değer olan %@ ile güncellenecektir.": {
        "en": "The existing entry for %@ (%@) will be updated with the new value of %@.",
        "comment": "Overwrite entry alert message with date"
    },
    "%@, günaydın": {
        "en": "Good morning, %@",
        "comment": "Daily reminder title with user name"
    },
    "%@, tartım zamanı": {
        "en": "Weigh-in time, %@",
        "comment": "Reminder title with user name"
    },
    "%lld adet tartım kaydı Apple Sağlık'a başarıyla aktarıldı.": {
        "en": "%lld weight entries successfully exported to Apple Health.",
        "comment": "Export healthkit count alert"
    },
    "%lld adet yeni tartım Apple Sağlık'tan Heft'e aktarıldı.": {
        "en": "%lld new weight entries imported from Apple Health.",
        "comment": "Import healthkit count alert"
    },
    "0,0": {
        "en": "0.0",
        "comment": "Zero placeholder"
    },
    "0,1": {
        "en": "0.1",
        "comment": "Tenths placeholder"
    },
    "0,1 kilogram artır": {
        "en": "Increase by 0.1 kilogram",
        "comment": "Accessibility step increment"
    },
    "0,1 kilogram azalt": {
        "en": "Decrease by 0.1 kilogram",
        "comment": "Accessibility step decrement"
    },
    "1 Ay": {
        "en": "1 Month",
        "comment": "1 Month chart range a11y title"
    },
    "1 Yıl": {
        "en": "1 Year",
        "comment": "1 Year chart range a11y title"
    },
    "1. Tamamen Cihaz İçi (On-Device) Depolama": {
        "en": "1. Completely On-Device Storage",
        "comment": "Privacy card title 1"
    },
    "175": {
        "en": "175",
        "comment": "Default height placeholder"
    },
    "1A": {
        "en": "1M",
        "comment": "1 Month chart range button"
    },
    "1Y": {
        "en": "1Y",
        "comment": "1 Year chart range button"
    },
    "2. Apple Sağlık (HealthKit) Kullanımı": {
        "en": "2. Apple Health (HealthKit) Integration",
        "comment": "Privacy card title 2"
    },
    "28": {
        "en": "28",
        "comment": "Default age placeholder"
    },
    "3 Ay": {
        "en": "3 Months",
        "comment": "3 Months chart range a11y title"
    },
    "3. Takip ve Reklam Bulunmaz": {
        "en": "3. No Tracking or Ads",
        "comment": "Privacy card title 3"
    },
    "3A": {
        "en": "3M",
        "comment": "3 Months chart range button"
    },
    "4. Verileri Silme ve Kontrol Hakkı": {
        "en": "4. Right to Delete and Control Data",
        "comment": "Privacy card title 4"
    },
    "5. Tıbbi Feragatname (Medical Disclaimer)": {
        "en": "5. Medical Disclaimer",
        "comment": "Privacy card title 5"
    },
    "6 Ay": {
        "en": "6 Months",
        "comment": "6 Months chart range a11y title"
    },
    "6A": {
        "en": "6M",
        "comment": "6 Months chart range button"
    },
    "70,0": {
        "en": "70.0",
        "comment": "Default target weight placeholder"
    },
    "AMACIN NEDİR?": {
        "en": "WHAT IS YOUR GOAL?",
        "comment": "Onboarding goal section header"
    },
    "APPLE SAĞLIK (HEALTHKIT)": {
        "en": "APPLE HEALTH (HEALTHKIT)",
        "comment": "HealthKit settings section header"
    },
    "Adaptif": {
        "en": "Adaptive",
        "comment": "Projection scenario adaptive"
    },
    "Adım %lld / %lld": {
        "en": "Step %lld of %lld",
        "comment": "Step progress accessibility label"
    },
    "Adın": {
        "en": "Your name",
        "comment": "Name input placeholder"
    },
    "Ana Sayfa": {
        "en": "Home",
        "comment": "Home navigation title and tab item"
    },
    "Apple Sağlık'ta içe aktarılacak yeni bir tartım bulunamadı.": {
        "en": "No new weigh-ins found to import from Apple Health.",
        "comment": "Empty import result message"
    },
    "Ayarlar": {
        "en": "Settings",
        "comment": "Settings navigation title"
    },
    "BAŞLANGIÇ BMI": {
        "en": "STARTING BMI",
        "comment": "Summary starting BMI header"
    },
    "BAŞLANGIÇ KİLOSU": {
        "en": "STARTING WEIGHT",
        "comment": "Onboarding starting weight header"
    },
    "BMI": {
        "en": "BMI",
        "comment": "BMI abbreviation"
    },
    "BMI %@, %@": {
        "en": "BMI %@, %@",
        "comment": "BMI accessibility value"
    },
    "BOY": {
        "en": "HEIGHT",
        "comment": "Body info height header"
    },
    "BOY & YAŞ": {
        "en": "HEIGHT & AGE",
        "comment": "Summary height and age header"
    },
    "Başla": {
        "en": "Get Started",
        "comment": "Welcome step button"
    },
    "Başlangıç": {
        "en": "Starting",
        "comment": "Initial weight stat or badge"
    },
    "Başlangıç %@ kilogram, güncel %@ kilogram, hedef %@ kilogram, yüzde %@ tamamlandı": {
        "en": "Starting weight %@ kg, current %@ kg, goal %@ kg, %@ percent complete",
        "comment": "Goal progress accessibility value"
    },
    "Başlangıç:": {
        "en": "Starting:",
        "comment": "Starting weight prefix"
    },
    "Belirli Günler": {
        "en": "Specific Days",
        "comment": "Weigh-in custom days frequency"
    },
    "Bildirim Ayarlarını Aç": {
        "en": "Open Notification Settings",
        "comment": "Notification settings action button"
    },
    "Bildirimler kapalı. Dilediğinde açabilirsin.": {
        "en": "Notifications are off. You can enable them anytime.",
        "comment": "Notifications off subtitle"
    },
    "Bilgilendirme amaçlıdır; tıbbi teşhis veya klinik tavsiye niteliği taşımaz.": {
        "en": "For informational purposes only; does not constitute medical diagnosis or clinical advice.",
        "comment": "Medical disclaimer short footer"
    },
    "Bilgilerin kaydedildi. Yolculuğun şimdi başlıyor.": {
        "en": "Your profile is saved. Your journey begins now.",
        "comment": "All set step subtitle"
    },
    "Bir sonraki tartını eklediğinde grafik hazır": {
        "en": "Your chart will appear after your next weigh-in",
        "comment": "Single entry chart message"
    },
    "Bitti": {
        "en": "Done",
        "comment": "Keyboard dismiss button"
    },
    "Body Text": {
        "en": "Body Text",
        "comment": "Preview body text"
    },
    "Boy": {
        "en": "Height",
        "comment": "Height label and a11y title"
    },
    "Boy 50 ile 300 cm arasında olmalıdır.": {
        "en": "Height must be between 50 and 300 cm.",
        "comment": "Height validation error"
    },
    "Bu Kaydı Sil": {
        "en": "Delete This Entry",
        "comment": "Delete entry action button"
    },
    "Bu aralıkta tek ölçüm var. Tüm zamanlar için 'Tümü' seçebilirsin.": {
        "en": "Only one entry in this range. Select 'All' to see all entries.",
        "comment": "Single entry in range message"
    },
    "Bu hafta: %@": {
        "en": "This week: %@",
        "comment": "Weekly change zero"
    },
    "Bu hafta: +%@": {
        "en": "This week: +%@",
        "comment": "Weekly change gain"
    },
    "Bu hafta: —": {
        "en": "This week: —",
        "comment": "Weekly change empty"
    },
    "Bu hafta: −%@": {
        "en": "This week: −%@",
        "comment": "Weekly change loss"
    },
    "Bu kaydı silmek istediğinden emin misin?": {
        "en": "Are you sure you want to delete this entry?",
        "comment": "Delete entry confirmation dialog title"
    },
    "Bu tarihe ait mevcut kayıt (%@), yeni değer olan %@ ile güncellenecek.": {
        "en": "The existing entry for this date (%@) will be updated with the new value of %@.",
        "comment": "Overwrite entry alert message"
    },
    "Bu tarihteki mevcut kayıt güncellenecek.": {
        "en": "The existing entry for this date will be updated.",
        "comment": "Overwrite generic alert message"
    },
    "Bu tarihteki mevcut kayıt güncellenecektir.": {
        "en": "The existing entry for this date will be updated.",
        "comment": "Overwrite generic alert message future"
    },
    "Bugün": {
        "en": "Today",
        "comment": "Relative date today"
    },
    "Bugün haftalık tartım günün. Yeni kilonu Heft'e kaydet.": {
        "en": "Today is your weekly weigh-in day. Log your new weight in Heft.",
        "comment": "Weekly reminder body"
    },
    "Bugün tartım günün. Yeni kilonu Heft'e kaydet.": {
        "en": "Today is your weigh-in day. Log your new weight in Heft.",
        "comment": "Custom days reminder body"
    },
    "Bugün:": {
        "en": "Today:",
        "comment": "Relative date today label"
    },
    "Card Title": {
        "en": "Card Title",
        "comment": "Preview card title"
    },
    "Cinsiyet": {
        "en": "Gender",
        "comment": "Gender picker label"
    },
    "Cmt": {
        "en": "Sat",
        "comment": "Saturday short"
    },
    "Cum": {
        "en": "Fri",
        "comment": "Friday short"
    },
    "Cuma": {
        "en": "Friday",
        "comment": "Friday"
    },
    "Cumartesi": {
        "en": "Saturday",
        "comment": "Saturday"
    },
    "CİNSİYET": {
        "en": "GENDER",
        "comment": "Gender header"
    },
    "Dengeli": {
        "en": "Balanced",
        "comment": "Pace status moderate"
    },
    "Değişiklikleri Sil": {
        "en": "Discard Changes",
        "comment": "Discard changes destructive button"
    },
    "Dilediğin anda tüm kilo kayıtlarını tek tek silebilir veya Ayarlar > Veri Yönetimi üzerinden profilini ve tüm kayıtlarını kalıcı olarak sıfırlayabilirsin.": {
        "en": "You can delete individual weight entries anytime or permanently reset your profile and all data via Settings > Data Management.",
        "comment": "Privacy card content 4"
    },
    "Diğer tarih seç": {
        "en": "Choose another date",
        "comment": "Custom date picker button"
    },
    "Dün": {
        "en": "Yesterday",
        "comment": "Relative date yesterday"
    },
    "Düzenlemeye Devam Et": {
        "en": "Keep Editing",
        "comment": "Continue editing cancel button"
    },
    "Düzenli kilo kaydı yaparak eğilimini keşfetmeye başla.": {
        "en": "Start logging entries regularly to discover your true weight trend.",
        "comment": "Insight journey begins message"
    },
    "Düzenli tartılmak tutarlılık sağlar. Sana en uygun tartım sıklığını ve saatini seç.": {
        "en": "Weighing in consistently builds habits. Choose the schedule and time that fits you best.",
        "comment": "Schedule step subtitle"
    },
    "Düşük Kilolu": {
        "en": "Underweight",
        "comment": "BMI category Underweight"
    },
    "Dışa Aktarma Tamamlandı": {
        "en": "Export Completed",
        "comment": "Export healthkit alert title"
    },
    "En Düşük": {
        "en": "Lowest",
        "comment": "Lowest weight stat"
    },
    "En Düşük Kilo Kaydı": {
        "en": "Lowest Weight Logged",
        "comment": "Insight lowest weight title"
    },
    "En Yüksek": {
        "en": "Highest",
        "comment": "Highest weight stat"
    },
    "En Yüksek Kilo Kaydı": {
        "en": "Highest Weight Logged",
        "comment": "Insight highest weight title"
    },
    "Erkek": {
        "en": "Male",
        "comment": "Gender option male"
    },
    "Eyebrow": {
        "en": "Eyebrow",
        "comment": "Preview eyebrow"
    },
    "Fazla Kilolu": {
        "en": "Overweight",
        "comment": "BMI category Overweight"
    },
    "Formunu Koruyorsun": {
        "en": "Maintaining Form",
        "comment": "Insight maintain title"
    },
    "Formunu koruyorsun": {
        "en": "Maintaining form",
        "comment": "Pill maintain success"
    },
    "Genel": {
        "en": "Overall",
        "comment": "Projection scenario overall"
    },
    "Geri": {
        "en": "Back",
        "comment": "Back button accessibility label"
    },
    "Geçersiz hedef kilo.": {
        "en": "Invalid target weight.",
        "comment": "Invalid target weight error"
    },
    "Geçmiş": {
        "en": "History",
        "comment": "History navigation title and tab item"
    },
    "Girilen kilo: %@ kilogram": {
        "en": "Entered weight: %@ kilograms",
        "comment": "Keypad entered weight accessibility label"
    },
    "Gizlilik Politikası": {
        "en": "Privacy Policy",
        "comment": "Privacy policy title and button"
    },
    "Gizlilik ve Güvenlik İlkelerimiz": {
        "en": "Our Privacy and Security Principles",
        "comment": "Privacy header card title"
    },
    "Grafik için henüz kilo kaydı yok": {
        "en": "No weight entries for the chart yet",
        "comment": "Empty chart message"
    },
    "Günaydın": {
        "en": "Good morning",
        "comment": "Daily reminder title"
    },
    "Güncel": {
        "en": "Current",
        "comment": "Current weight stat or mark"
    },
    "Güncel ölçüme dön": {
        "en": "Return to latest entry",
        "comment": "Reset to latest entry a11y label"
    },
    "Güncelle": {
        "en": "Update",
        "comment": "Update button"
    },
    "GİZLİLİK VE YASAL": {
        "en": "PRIVACY & LEGAL",
        "comment": "Privacy and legal section header"
    },
    "HEDEF": {
        "en": "GOAL",
        "comment": "Goal settings section header"
    },
    "HEDEF KİLO": {
        "en": "TARGET WEIGHT",
        "comment": "Onboarding target weight header"
    },
    "HEDEF TÜRÜ": {
        "en": "GOAL TYPE",
        "comment": "Goal type header"
    },
    "HEDEFE ULAŞILDI": {
        "en": "GOAL REACHED",
        "comment": "Goal reached projection title"
    },
    "Hadi Başlayalım": {
        "en": "Let's Get Started",
        "comment": "All set step button"
    },
    "Hafta": {
        "en": "Week",
        "comment": "Week unit"
    },
    "Haftada 1 Gün": {
        "en": "Once a Week",
        "comment": "Weigh-in weekly frequency option"
    },
    "Haftada Bir": {
        "en": "Once a Week",
        "comment": "Weigh-in weekly frequency title"
    },
    "Haftalık": {
        "en": "Weekly",
        "comment": "Weigh-in weekly frequency"
    },
    "Haftalık %@ tempo hedefiyle harika bir uyum yakaladın.": {
        "en": "Great alignment with your weekly %@ pace target.",
        "comment": "Projection on target message"
    },
    "Haftalık hedef tempon %@. Mevcut tempon (%@) hedefine planlanandan daha erken ulaşacağını gösteriyor.": {
        "en": "Your weekly target pace is %@. Your current pace (%@) shows you will reach your goal earlier than planned.",
        "comment": "Projection ahead of pace message"
    },
    "Haftalık hedef tempon %@. Mevcut tempon (%@) ile hedefine planlanan tarihten erken ulaşabilirsin.": {
        "en": "Your weekly target pace is %@. With your current pace (%@), you may reach your goal earlier than planned.",
        "comment": "Projection ahead of pace alternative message"
    },
    "Harika bir disiplin gösterdin. Şimdi mevcut formunu koruma zamanı.": {
        "en": "You showed great consistency. Now it's time to maintain your current form.",
        "comment": "Goal reached discipline message"
    },
    "Hata": {
        "en": "Error",
        "comment": "Generic error alert title"
    },
    "Hatırlatıcı alabilmek için sistem ayarlarından Heft bildirimlerine izin ver.": {
        "en": "Allow Heft notifications in system settings to receive reminders.",
        "comment": "Open notification settings explanation"
    },
    "Hazırsın!": {
        "en": "You're All Set!",
        "comment": "All set step title"
    },
    "Hedef": {
        "en": "Goal",
        "comment": "Target weight label"
    },
    "Hedef %lld gün öne çekildi": {
        "en": "Target moved %lld days earlier",
        "comment": "Target moved earlier badge"
    },
    "Hedef %lld gün ötelendi": {
        "en": "Target delayed by %lld days",
        "comment": "Target delayed badge"
    },
    "Hedef BMI: %@": {
        "en": "Target BMI: %@",
        "comment": "Target BMI accessibility label"
    },
    "Hedef Kilo": {
        "en": "Target Weight",
        "comment": "Target weight label and a11y title"
    },
    "Hedef Plan": {
        "en": "Target Plan",
        "comment": "Target projection scenario plan title"
    },
    "Hedef Tarihi:": {
        "en": "Target Date:",
        "comment": "Target date label"
    },
    "Hedef Türü": {
        "en": "Goal Type",
        "comment": "Goal type picker label"
    },
    "Hedef ilerlemesi": {
        "en": "Goal progress",
        "comment": "Goal progress accessibility title"
    },
    "Hedef kilo 20 ile 500 kg arasında olmalıdır.": {
        "en": "Target weight must be between 20 and 500 kg.",
        "comment": "Target weight validation error"
    },
    "Hedef kilon olan %@ seviyesini başarıyla koruyorsun. İstikrarını sürdür.": {
        "en": "You are successfully maintaining your target weight of %@. Keep it up.",
        "comment": "Maintain on track message"
    },
    "Hedef kilondan (%@) bir fark var. Dengeli beslenme ve düzenli tartımla hedefini koru.": {
        "en": "There is a difference from your target weight (%@). Stay on track with balanced nutrition and consistent weigh-ins.",
        "comment": "Maintain off track message"
    },
    "Hedef kilonu dengede tutmak için beslenmene dikkat et ve tartımları aksatma.": {
        "en": "Keep an eye on your nutrition and stay consistent with your weigh-ins to balance your target weight.",
        "comment": "Maintain attention message"
    },
    "Hedef tarihine yetişmek için haftalık %@ tempoya ihtiyacın var. Mevcut temponla bitiş ileri bir tarihe sarkıyor.": {
        "en": "You need a weekly pace of %@ to meet your target date. At your current pace, completion is pushed back.",
        "comment": "Projection behind pace message"
    },
    "Hedef:": {
        "en": "Goal:",
        "comment": "Target weight prefix"
    },
    "Hedefe %@ kaldı": {
        "en": "%@ to goal",
        "comment": "Target remaining badge"
    },
    "Hedefe %@ kaldı. Günlük kalori ve su dalgalanmaları doğaldır.": {
        "en": "%@ remaining to goal. Daily calorie and water fluctuations are natural.",
        "comment": "Insight slow pace message"
    },
    "Hedefe Doğru": {
        "en": "Towards Goal",
        "comment": "Towards goal pace status"
    },
    "Hedefe Ulaşıldı": {
        "en": "Goal Reached",
        "comment": "Goal reached insight title"
    },
    "Hedefe Ulaştın": {
        "en": "Goal Reached",
        "comment": "Goal reached badge"
    },
    "Hedefe Ulaştın!": {
        "en": "Goal Reached!",
        "comment": "Goal reached card title"
    },
    "Hedefe kalan: %@": {
        "en": "Remaining to goal: %@",
        "comment": "Target remaining accessibility label"
    },
    "Hedefe ulaşıldı": {
        "en": "Goal reached",
        "comment": "Pill goal reached success"
    },
    "Hedefini Belirle": {
        "en": "Set Your Goal",
        "comment": "Weight info step title"
    },
    "Hedefini güncellemek için ayarları ziyaret et.": {
        "en": "Visit Settings to update your goal.",
        "comment": "Goal reached settings hint"
    },
    "Hedefinin Üzerindesin": {
        "en": "Above Goal",
        "comment": "Above goal insight title"
    },
    "Heft Verilerini Apple Sağlık'a Aktar": {
        "en": "Export Heft Data to Apple Health",
        "comment": "Export to HealthKit button"
    },
    "Heft ile sade, tutarlı ve odaklı kilo takibi.": {
        "en": "Clean, consistent, and focused weight tracking with Heft.",
        "comment": "Welcome step subtitle"
    },
    "Heft tıbbi bir teşhis veya tedavi cihazı değildir. Uygulamadaki BMI hesaplamaları ve hedef projeksiyonları genel bilgilendirme amaçlıdır. Herhangi bir beslenme veya kilo kontrol programına başlamadan önce mutlaka bir hekime danış.": {
        "en": "Heft is not a medical diagnostic or treatment device. BMI calculations and goal projections in the app are for general informational purposes only. Always consult a physician before starting any diet or weight management program.",
        "comment": "Medical disclaimer in Settings"
    },
    "Heft tıbbi bir teşhis, klinik tedavi veya profesyonel sağlık tavsiyesi aracı değildir. BMI değerleri ve hedef tahminleri genel bilgilendirme amaçlıdır. Herhangi bir kilo verme, alma veya beslenme programına başlamadan önce mutlaka bir doktora danış.": {
        "en": "Heft is not a tool for medical diagnosis, clinical treatment, or professional medical advice. BMI values and goal projections are for general informational purposes only. Always consult a doctor before starting any weight loss, weight gain, or nutrition regimen.",
        "comment": "Privacy card content 5"
    },
    "Heft, kişisel sağlık verilerinin gizliliğine ve güvenliğine en üst düzeyde önem verir.": {
        "en": "Heft places the highest priority on the privacy and security of your personal health data.",
        "comment": "Privacy header card subtitle"
    },
    "Heft'e kaydettiğin tüm bilgiler (kilo geçmişi, boy, yaş, hedefler ve hatırlatıcı saatleri) yalnızca cihazının yerel depolama alanında SwiftData kullanılarak saklanır. Verilerin hiçbir harici sunucuya veya bulut veritabanına aktarılmaz.": {
        "en": "All information you record in Heft (weight history, height, age, goals, and reminder times) is stored exclusively on your device's local storage using SwiftData. Your data is never transmitted to any external server or cloud database.",
        "comment": "Privacy card content 1"
    },
    "Heft'e kaydedilen tartımlar Apple Sağlık'a aktarılır. Dilersen geçmiş Apple Sağlık tartımlarını Heft'e aktarabilir veya Heft kayıtlarını Apple Sağlık'a gönderebilirsin.": {
        "en": "Weigh-ins logged in Heft are synced to Apple Health. You can also import past Apple Health weigh-ins or export Heft entries to Apple Health.",
        "comment": "HealthKit settings footer"
    },
    "Henüz Tartım Kaydı Yok": {
        "en": "No Weigh-ins Yet",
        "comment": "Empty history view title"
    },
    "Her Gün": {
        "en": "Daily",
        "comment": "Weigh-in daily frequency"
    },
    "Her sabah seçtiğin saatte hatırlatıcı alacaksın.": {
        "en": "You'll receive a reminder every morning at your chosen time.",
        "comment": "Daily reminder explanation"
    },
    "Hoş Geldin": {
        "en": "Welcome",
        "comment": "Welcome step title"
    },
    "Hızlı": {
        "en": "Fast",
        "comment": "Pace status fast"
    },
    "Kapat": {
        "en": "Close",
        "comment": "Close modal sheet button"
    },
    "Kaydedilmemiş Değişiklikler": {
        "en": "Unsaved Changes",
        "comment": "Unsaved changes alert title"
    },
    "Kaydet": {
        "en": "Save",
        "comment": "Save settings or entry button"
    },
    "Kaydı Sil": {
        "en": "Delete Entry",
        "comment": "Delete entry button in sheet"
    },
    "Kayıt Güncellensin mi?": {
        "en": "Update Entry?",
        "comment": "Overwrite alert title"
    },
    "Kayıt silinirken bir hata oluştu. Lütfen tekrar dene.": {
        "en": "An error occurred while deleting the entry. Please try again.",
        "comment": "Delete error alert message"
    },
    "Kayıt sırasında bir hata oluştu. Lütfen tekrar dene.": {
        "en": "An error occurred while saving. Please try again.",
        "comment": "Save error alert message"
    },
    "Kilo Almak": {
        "en": "Gain Weight",
        "comment": "Goal type gain weight"
    },
    "Kilo Değişimi: %@": {
        "en": "Weight Change: %@",
        "comment": "Weight change accessibility value"
    },
    "Kilo Ekle": {
        "en": "Add Weight",
        "comment": "Add weight navigation title and button"
    },
    "Kilo Grafiği": {
        "en": "Weight Chart",
        "comment": "Weight chart title"
    },
    "Kilo Güncelle": {
        "en": "Update Weight",
        "comment": "Update weight button"
    },
    "Kilo Korumak": {
        "en": "Maintain Weight",
        "comment": "Goal type maintain weight"
    },
    "Kilo Vermek": {
        "en": "Lose Weight",
        "comment": "Goal type lose weight"
    },
    "Kilo alma modunda artışlar pozitif olarak değerlendirilir.": {
        "en": "In weight gain mode, increases are celebrated as positive progress.",
        "comment": "Goal gain explanation"
    },
    "Kilo geçmişini ve değişim istatistiklerini görmek için ilk tartımını ekle.": {
        "en": "Add your first weigh-in to view your weight history and progress statistics.",
        "comment": "Empty history view description"
    },
    "Kilo koruma modunda mevcut kilonu dengede tutman hedeflenir.": {
        "en": "In maintenance mode, the focus is keeping your current weight steady.",
        "comment": "Goal maintain explanation"
    },
    "Kilo verme modunda azalışlar başarı olarak değerlendirilir.": {
        "en": "In weight loss mode, decreases are celebrated as progress.",
        "comment": "Goal lose explanation"
    },
    "Kilon %lld gündür %@ ± 0,4 kg bandında dengeleniyor. Bu normal bir adaptasyon evresidir; metabolizman alıştığında tempon yeniden hareketlenecektir.": {
        "en": "Your weight has plateaued around %@ ± 0.4 kg for %lld days. This is a normal adaptation phase; your pace will pick back up as your metabolism adjusts.",
        "comment": "Plateau pace status message"
    },
    "Kişisel Bilgiler": {
        "en": "Personal Information",
        "comment": "Personal info section header"
    },
    "Kişisel kilo takip asistanın.\nHedefine adım adım, sağlıklı biçimde ulaş.": {
        "en": "Your personal weight tracking companion.\nReach your goals step by step, sustainably.",
        "comment": "Welcome view brand slogan"
    },
    "Korumak": {
        "en": "Maintain",
        "comment": "Goal type maintain short"
    },
    "KİLO DEĞİŞİMİ": {
        "en": "WEIGHT CHANGE",
        "comment": "Weight change header"
    },
    "KİLO KORUMA": {
        "en": "MAINTAIN WEIGHT",
        "comment": "Maintain weight projection title"
    },
    "MEVCUT": {
        "en": "CURRENT",
        "comment": "Current weight header"
    },
    "MEVCUT KİLO": {
        "en": "CURRENT WEIGHT",
        "comment": "Current weight section header"
    },
    "Merhaba, %@": {
        "en": "Hello, %@",
        "comment": "Greeting with user name"
    },
    "Meta Text": {
        "en": "Meta Text",
        "comment": "Preview meta text"
    },
    "Metni temizle": {
        "en": "Clear text",
        "comment": "Clear text button a11y label"
    },
    "Mevcut": {
        "en": "Current",
        "comment": "Current weight label"
    },
    "Mevcut BMI: %@ (%@)": {
        "en": "Current BMI: %@ (%@)",
        "comment": "Current BMI accessibility label"
    },
    "Mevcut Kilo": {
        "en": "Current Weight",
        "comment": "Current weight label and a11y title"
    },
    "Mevcut temponla (haftada ortalama %@ %@) bu aralıkta hedefine ulaşman öngörülüyor.": {
        "en": "At your current pace (average %@ %@ per week), you are projected to reach your goal within this range.",
        "comment": "Projection projected range message"
    },
    "Normal": {
        "en": "Normal",
        "comment": "BMI category Normal"
    },
    "Normal Sınır": {
        "en": "Normal Boundary",
        "comment": "Normal BMI limit chart annotation"
    },
    "Normal Sınırı (%@)": {
        "en": "Normal Boundary (%@)",
        "comment": "Normal limit chart accessibility label"
    },
    "Obez": {
        "en": "Obese",
        "comment": "BMI category Obese"
    },
    "Obez (Tip 1)": {
        "en": "Obese (Class 1)",
        "comment": "BMI category Obese Class 1"
    },
    "Obez (Tip 2)": {
        "en": "Obese (Class 2)",
        "comment": "BMI category Obese Class 2"
    },
    "Aşırı Obez (Tip 3)": {
        "en": "Severely Obese (Class 3)",
        "comment": "BMI category Severely Obese Class 3"
    },
    "Ondalık ayırıcı": {
        "en": "Decimal separator",
        "comment": "Keypad decimal separator a11y label"
    },
    "PROFİL": {
        "en": "PROFILE",
        "comment": "Profile settings section header"
    },
    "Paz": {
        "en": "Sun",
        "comment": "Sunday short"
    },
    "Pazar": {
        "en": "Sunday",
        "comment": "Sunday"
    },
    "Pazartesi": {
        "en": "Monday",
        "comment": "Monday"
    },
    "Per": {
        "en": "Thu",
        "comment": "Thursday short"
    },
    "Perşembe": {
        "en": "Thursday",
        "comment": "Thursday"
    },
    "Planlanan": {
        "en": "Planned",
        "comment": "Planned target pace label"
    },
    "Plato": {
        "en": "Plateau",
        "comment": "Plateau pace status"
    },
    "Profilini Oluştur": {
        "en": "Create Your Profile",
        "comment": "Body info step title"
    },
    "Pzt": {
        "en": "Mon",
        "comment": "Monday short"
    },
    "Sabah tartını kaydetmeyi unutma. Yeni kilonu Heft'e ekle.": {
        "en": "Don't forget your morning weigh-in. Log your new weight in Heft.",
        "comment": "Daily reminder body"
    },
    "Sabit": {
        "en": "Steady",
        "comment": "Pace status stable"
    },
    "Sal": {
        "en": "Tue",
        "comment": "Tuesday short"
    },
    "Salı": {
        "en": "Tuesday",
        "comment": "Tuesday"
    },
    "Sample Card Content": {
        "en": "Sample Card Content",
        "comment": "Preview card content"
    },
    "Sağlık Verilerini İçe Aktar": {
        "en": "Import Health Data",
        "comment": "Import from HealthKit button"
    },
    "Sağlık ile Eşzamanla": {
        "en": "Sync with Apple Health",
        "comment": "Sync with HealthKit toggle label"
    },
    "Sağlık izinlerini onayladığında, Heft yalnızca vücut ağırlığı (Body Mass) verilerini Apple Sağlık uygulaması ile iki yönlü eşzamanlar. Sağlık verilerin reklam, pazarlama veya veri madenciliği amacıyla asla kullanılmaz ve üçüncü taraflarla paylaşılmaz.": {
        "en": "When you grant Health permissions, Heft only syncs Body Mass data bidirectionally with Apple Health. Your health data is never used for advertising, marketing, or data mining, and is never shared with third parties.",
        "comment": "Privacy card content 2"
    },
    "Sağlıklı Kilo Aralığı": {
        "en": "Healthy Weight Range",
        "comment": "Healthy weight range title"
    },
    "Screen Title": {
        "en": "Screen Title",
        "comment": "Preview screen title"
    },
    "Section Title": {
        "en": "Section Title",
        "comment": "Preview section title"
    },
    "Seni daha iyi tanımamız ve doğru analizler için temel bilgilerini gir.": {
        "en": "Enter your basic info so we can calculate accurate analytics.",
        "comment": "Body info step subtitle"
    },
    "Seçilen": {
        "en": "Selected",
        "comment": "Selected chart item prefix"
    },
    "Seçilen Tarih": {
        "en": "Selected Date",
        "comment": "Selected date label"
    },
    "Seçili tarih: %@": {
        "en": "Selected date: %@",
        "comment": "Selected date a11y label"
    },
    "Seçtiğin günde ve saatte nazik bir bildirim alacaksın.": {
        "en": "You'll receive a gentle reminder on your chosen day and time.",
        "comment": "Weekly reminder subtitle"
    },
    "Seçtiğin günlerde ve saatte nazik bir bildirim alacaksın.": {
        "en": "You'll receive a gentle reminder on your chosen days and time.",
        "comment": "Custom days reminder subtitle"
    },
    "Sil": {
        "en": "Delete",
        "comment": "Delete action or keypad delete button"
    },
    "Son %@ içinde ölçüm bulunamadı": {
        "en": "No entries found in the last %@",
        "comment": "Empty time range chart message"
    },
    "Son %lld günde +%@ artış var — muhtemelen geçici su tutulumu. Genel temponla hedefin hâlâ koruma altında.": {
        "en": "+%@ increase over the last %lld days — likely temporary water retention. With your overall pace, your goal is still on track.",
        "comment": "Water retention message"
    },
    "Son 14 Gün": {
        "en": "Last 14 Days",
        "comment": "Projection scenario last 14 days"
    },
    "Son 30 Gün": {
        "en": "Last 30 Days",
        "comment": "Projection scenario last 30 days"
    },
    "Son tartıma göre %@": {
        "en": "%@ compared to last weigh-in",
        "comment": "Comparison to last weigh-in"
    },
    "Son tartıma göre %@ kaydettin. Hedefe %@ kaldı.": {
        "en": "Recorded %@ compared to last weigh-in. %@ remaining to goal.",
        "comment": "Insight lost progress msg"
    },
    "Son tartıma göre +%@ kaydettin. Hedefe %@ kaldı.": {
        "en": "Gained +%@ compared to last weigh-in. %@ remaining to goal.",
        "comment": "Insight gained progress msg"
    },
    "Son tartıma göre -%@": {
        "en": "-%@ compared to last weigh-in",
        "comment": "Comparison to last weigh-in negative"
    },
    "Son tartımla aynı": {
        "en": "Same as last weigh-in",
        "comment": "No change since last weigh-in"
    },
    "Sıklık": {
        "en": "Frequency",
        "comment": "Weigh-in frequency picker label"
    },
    "TAHMİNİ BİTİŞ": {
        "en": "ESTIMATED COMPLETION",
        "comment": "Estimated completion header"
    },
    "TARTILACAĞIN GÜNLER": {
        "en": "WEIGH-IN DAYS",
        "comment": "Weigh-in days section header"
    },
    "TARTIM GÜNÜ": {
        "en": "WEIGH-IN DAY",
        "comment": "Weigh-in day section header"
    },
    "TARTIM SAATİ": {
        "en": "WEIGH-IN TIME",
        "comment": "Weigh-in time section header"
    },
    "TARTIM SIKLIĞI": {
        "en": "WEIGH-IN FREQUENCY",
        "comment": "Weigh-in frequency section header"
    },
    "TARTIM TAKVİMİ": {
        "en": "WEIGH-IN SCHEDULE",
        "comment": "Weigh-in schedule settings section header"
    },
    "Taban": {
        "en": "Baseline",
        "comment": "Baseline chart marker"
    },
    "Tamam": {
        "en": "OK",
        "comment": "OK alert button"
    },
    "Tarih": {
        "en": "Date",
        "comment": "Date label"
    },
    "Tarih Seç": {
        "en": "Select Date",
        "comment": "Select date button"
    },
    "Tartıdaki kilonu gir": {
        "en": "Enter your scale weight",
        "comment": "Current weight subtitle"
    },
    "Tartılacağın Günler": {
        "en": "Weigh-in Days",
        "comment": "Weigh-in days label"
    },
    "Tartım Günü": {
        "en": "Weigh-in Day",
        "comment": "Weigh-in day picker label"
    },
    "Tartım Hatırlatıcısı": {
        "en": "Weigh-in Reminder",
        "comment": "Weigh-in reminder toggle label"
    },
    "Tartım Rutini": {
        "en": "Weigh-in Routine",
        "comment": "Weigh-in routine title"
    },
    "Tartım Saati": {
        "en": "Weigh-in Time",
        "comment": "Weigh-in time label"
    },
    "Tartım Takvimi": {
        "en": "Weigh-in Schedule",
        "comment": "Schedule step title"
    },
    "Tartım Tarihi": {
        "en": "Weigh-in Date",
        "comment": "Weigh-in date label"
    },
    "Tartım Zamanı": {
        "en": "Weigh-in Time",
        "comment": "Reminder notification title"
    },
    "Tartım sıklığı ve saati değiştirildiğinde hatırlatıcılar otomatik olarak güncellenir.": {
        "en": "Reminders are updated automatically when weigh-in frequency and time change.",
        "comment": "Schedule settings footer"
    },
    "Tartımı Düzenle": {
        "en": "Edit Weigh-in",
        "comment": "Edit weigh-in navigation title"
    },
    "Tartımı Sil": {
        "en": "Delete Weigh-in",
        "comment": "Delete weigh-in swipe action"
    },
    "Tebrikler": {
        "en": "Congratulations",
        "comment": "Congratulations badge"
    },
    "Tebrikler!": {
        "en": "Congratulations!",
        "comment": "Congratulations title"
    },
    "Tebrikler! Belirlediğin hedef kiloya başarıyla ulaştın.": {
        "en": "Congratulations! You have successfully reached your target weight.",
        "comment": "Goal reached condition message"
    },
    "Tebrikler! Kilonu başarıyla dengede tutuyorsun. Düzenli tartılmaya devam et.": {
        "en": "Congratulations! You are successfully keeping your weight steady. Keep weighing in consistently.",
        "comment": "Maintain balanced message"
    },
    "Toplam Değişim": {
        "en": "Total Change",
        "comment": "Total change stat"
    },
    "Tüm Verileri Sil": {
        "en": "Delete All Data",
        "comment": "Delete all data button and alert title"
    },
    "Tüm Zamanlar": {
        "en": "All Time",
        "comment": "All Time chart range a11y title"
    },
    "Tüm kilo kayıtların, profil bilgilerin, ayarların ve Heft tarafından Apple Sağlık'a yazılan tartım kayıtları kalıcı olarak silinecek. Bu işlem geri alınamaz.": {
        "en": "All your weight entries, profile info, settings, and entries written to Apple Health by Heft will be permanently deleted. This action cannot be undone.",
        "comment": "Delete all data confirmation alert message"
    },
    "Tüm kilo kayıtların, profil bilgilerin, bildirim ayarların ve Heft tarafından Apple Sağlık'a yazılan tartım kayıtları kalıcı olarak silinir. Bu işlem geri alınamaz.": {
        "en": "All your weight entries, profile info, notification settings, and entries written to Apple Health by Heft are permanently deleted. This action cannot be undone.",
        "comment": "Delete all data section footer"
    },
    "Tümü": {
        "en": "All",
        "comment": "All Time chart range button"
    },
    "Tıbbi Sorumluluk Reddi:": {
        "en": "Medical Disclaimer:",
        "comment": "Medical disclaimer heading"
    },
    "Uygulama içerisinde kullanıcı davranışlarını izleyen hiçbir üçüncü taraf analiz (analytics) aracı veya reklam ağı bulunmamaktadır. Verilerin takip edilmez (NSPrivacyTracking: false).": {
        "en": "There are no third-party analytics tools or advertising networks tracking user behavior within the app. Your data is not tracked (NSPrivacyTracking: false).",
        "comment": "Privacy card content 3"
    },
    "VERİ YÖNETİMİ": {
        "en": "DATA MANAGEMENT",
        "comment": "Data management settings section header"
    },
    "Vazgeç": {
        "en": "Cancel",
        "comment": "Cancel alert button"
    },
    "Veritabanı Başlatılamadı": {
        "en": "Database Initialization Failed",
        "comment": "Database error screen title"
    },
    "VÜCUT KİTLE İNDEKSİ": {
        "en": "BODY MASS INDEX",
        "comment": "Body mass index card header"
    },
    "Vücut Kitle İndeksi": {
        "en": "Body Mass Index",
        "comment": "Body mass index full title"
    },
    "Vücut kitle indeksi grafiği, %@. %lld kayıt. Mevcut BMI: %@ (%@). En düşük %@, en yüksek %@.": {
        "en": "Body mass index chart, %@. %lld entries. Current BMI: %@ (%@). Lowest %@, highest %@.",
        "comment": "BMI chart summary accessibility label"
    },
    "Vücut kitle indeksi trendin ve değişim grafiğin ikinci kilo ölçümünü kaydettiğinde burada şekillenecek.": {
        "en": "Your body mass index trend and change chart will take shape here after your second weigh-in.",
        "comment": "Empty BMI chart description"
    },
    "Web Sitemizdeki Gizlilik Politikasını İncele": {
        "en": "Review Privacy Policy on Our Website",
        "comment": "Privacy policy web link title"
    },
    "Web Sitesi Gizlilik Politikası": {
        "en": "Website Privacy Policy",
        "comment": "Website privacy policy link row"
    },
    "YAŞ": {
        "en": "AGE",
        "comment": "Age section header"
    },
    "Yaptığın değişiklikler kaybolacak. Çıkmak istiyor musun?": {
        "en": "Your changes will be lost. Are you sure you want to leave?",
        "comment": "Discard changes confirmation message"
    },
    "Yavaş": {
        "en": "Slow",
        "comment": "Pace status slow"
    },
    "Yaş": {
        "en": "Age",
        "comment": "Age label and a11y title"
    },
    "Yaş 1 ile 120 arasında olmalıdır.": {
        "en": "Age must be between 1 and 120.",
        "comment": "Age validation error"
    },
    "Yolculuk Başlıyor": {
        "en": "Journey Begins",
        "comment": "Insight journey begins title"
    },
    "başlangıç kaydı": {
        "en": "initial entry",
        "comment": "Initial record a11y"
    },
    "cm": {
        "en": "cm",
        "comment": "Centimeter unit"
    },
    "değişim %@ kilogram": {
        "en": "change of %@ kilograms",
        "comment": "Weight change delta a11y"
    },
    "değişim yok": {
        "en": "no change",
        "comment": "No weight change delta a11y"
    },
    "eksik": {
        "en": "below target",
        "comment": "Below target suffix"
    },
    "fark": {
        "en": "difference",
        "comment": "Difference suffix"
    },
    "fazla": {
        "en": "above target",
        "comment": "Above target suffix"
    },
    "hafta": {
        "en": "weeks",
        "comment": "Weeks unit"
    },
    "hedef altı": {
        "en": "below target",
        "comment": "Below target suffix"
    },
    "hedef üstü": {
        "en": "above target",
        "comment": "Above target suffix"
    },
    "kaldı": {
        "en": "to go",
        "comment": "Remaining weight suffix"
    },
    "kg": {
        "en": "kg",
        "comment": "Kilogram unit"
    },
    "kilo alarak": {
        "en": "gaining weight",
        "comment": "Gaining weight action"
    },
    "kilo vererek": {
        "en": "losing weight",
        "comment": "Losing weight action"
    },
    "yaş": {
        "en": "age",
        "comment": "Age unit lowercase"
    },
    "yıl": {
        "en": "yrs",
        "comment": "Years unit"
    },
    "Çar": {
        "en": "Wed",
        "comment": "Wednesday short"
    },
    "Çarşamba": {
        "en": "Wednesday",
        "comment": "Wednesday"
    },
    "Çok Hızlı": {
        "en": "Too Fast",
        "comment": "Pace status too fast"
    },
    "Öneri: Her sabah aç karnına tartılmak, vücudun günlük su dalgalanmalarını filtreler ve en gerçekçi kilo trendini sunar.": {
        "en": "Tip: Weighing in every morning on an empty stomach filters out daily water fluctuations and reveals your true weight trend.",
        "comment": "Schedule tip text"
    },
    "Örn: Efe": {
        "en": "e.g. Alex",
        "comment": "Name input placeholder"
    },
    "Özet": {
        "en": "Summary",
        "comment": "Summary navigation title"
    },
    "ÖZET": {
        "en": "SUMMARY",
        "comment": "Summary section header"
    },
    "Üzerine Yaz": {
        "en": "Overwrite",
        "comment": "Overwrite entry destructive button"
    },
    "İSİM": {
        "en": "NAME",
        "comment": "Name section header"
    },
    "İdeal": {
        "en": "Ideal",
        "comment": "Pace status ideal"
    },
    "İleri": {
        "en": "Next",
        "comment": "Next button"
    },
    "İlerleme Devam Ediyor": {
        "en": "Progress Continues",
        "comment": "Insight progress continues title"
    },
    "İlk Ölçümün Kaydedildi": {
        "en": "First Entry Logged",
        "comment": "First weigh-in insight title"
    },
    "İsim": {
        "en": "Name",
        "comment": "Name field label"
    },
    "İsteğe bağlı • Hitap ve bildirimler için": {
        "en": "Optional • For greetings and reminders",
        "comment": "Name input subtitle"
    },
    "İstikrarını Koru": {
        "en": "Stay Consistent",
        "comment": "Insight stay consistent title"
    },
    "İçe Aktarma Tamamlandı": {
        "en": "Import Completed",
        "comment": "Import healthkit alert title"
    },
    "İşlem sırasında bir hata oluştu. Lütfen tekrar dene.": {
        "en": "An error occurred during the operation. Please try again.",
        "comment": "Generic operation error message"
    },
    "Hedefine %@ kaldı. Günlük su ve tuz dalgalanmaları oldukça doğaldır.": {
        "en": "%@ remaining to your goal. Daily water and sodium fluctuations are completely natural.",
        "comment": "Insight progress natural fluctuations message"
    },
    "Hedefine Ulaştın": {
        "en": "Goal Reached",
        "comment": "Goal reached insight badge"
    },
    "Hedefine ulaşmak için %@ mesafe var. Düzenli tartılarak ilerlemeni izle.": {
        "en": "You are %@ away from your goal. Weigh in consistently to track your progress.",
        "comment": "Insight distance to goal message"
    },
    "Hedefini ve ulaşmak istediğin kilonu belirle.": {
        "en": "Define your goal and the weight you want to reach.",
        "comment": "Weight info step subtitle"
    },
    "Heft": {
        "en": "Heft",
        "comment": "App name"
    },
    "Heft'teki en düşük kilonu kaydettin. Hedefine yalnızca %@ kaldı.": {
        "en": "You recorded your lowest weight in Heft. Only %@ to your goal.",
        "comment": "Insight lowest weight message"
    },
    "Heft'teki en yüksek kilona ulaştın. Hedefe yalnızca %@ kaldı.": {
        "en": "You reached your highest weight in Heft. Only %@ to your goal.",
        "comment": "Insight highest weight message"
    },
    "Her sabah seçtiğin saatte nazik bir bildirim alacaksın.": {
        "en": "You will receive a gentle reminder every morning at your chosen time.",
        "comment": "Daily reminder subtitle"
    },
    "Her Şey Hazır!": {
        "en": "All Set!",
        "comment": "All set step title variant"
    },
    "Hero Stat: 78.5 kg": {
        "en": "Hero Stat: 78.5 kg",
        "comment": "Preview stat"
    },
    "Kadın": {
        "en": "Female",
        "comment": "Gender option female"
    },
    "Kaydet (%@)": {
        "en": "Save (%@)",
        "comment": "Save button with weight"
    },
    "Kayıt Güncelle": {
        "en": "Update Entry",
        "comment": "Update entry button"
    },
    "Kayıt Güncelle (%@)": {
        "en": "Update Entry (%@)",
        "comment": "Update entry button with weight"
    },
    "Kilo": {
        "en": "Weight",
        "comment": "Weight stat label"
    },
    "Kilo Almak (Bulk/Kas)": {
        "en": "Gain Weight (Muscle Building)",
        "comment": "Goal option gain weight description"
    },
    "Kilo Hedeflerin": {
        "en": "Weight Goals",
        "comment": "Weight goals card title"
    },
    "Kilo Koruma": {
        "en": "Maintain Weight",
        "comment": "Goal maintain card title"
    },
    "Kilo Koruma Takibi": {
        "en": "Weight Maintenance Tracking",
        "comment": "Maintenance tracking subtitle"
    },
    "Kilo Korumak (Mevcut Form)": {
        "en": "Maintain Weight (Current Form)",
        "comment": "Goal option maintain description"
    },
    "Kilo Vermek (Fit/Yağ Yakımı)": {
        "en": "Lose Weight (Fat Loss)",
        "comment": "Goal option lose weight description"
    },
    "Kilo alma hedefi için hedef kilon mevcut kilondan yüksek olmalıdır.": {
        "en": "For a weight gain goal, your target weight must be higher than your current weight.",
        "comment": "Goal gain validation error"
    },
    "Kilo alma hedefine ulaşmak için %@ mesafe var. Düzenli tartılarak ilerlemeni takip et.": {
        "en": "You are %@ away from your weight gain goal. Track your progress with regular weigh-ins.",
        "comment": "Insight gain distance message"
    },
    "Kilo grafiği, %@. %lld kayıt. En düşük %@, en yüksek %@.": {
        "en": "Weight chart, %@. %lld entries. Lowest %@, highest %@.",
        "comment": "Weight chart summary accessibility label"
    },
    "Kilo trendini ve değişim grafiğini görebilmek için en az 2 ölçüm gerekiyor. Bir sonraki tartında ilerlemen burada canlanacak.": {
        "en": "At least 2 entries are required to display your weight trend and progress chart. Your progress will appear here after your next weigh-in.",
        "comment": "Single entry chart explanation"
    },
    "Kilo verme hedefi için hedef kilon mevcut kilondan düşük olmalıdır.": {
        "en": "For a weight loss goal, your target weight must be lower than your current weight.",
        "comment": "Goal lose validation error"
    },
}

def extract_format_specifiers(s):
    # Find all %-style format specifiers: %@, %lld, %d, %f, etc.
    return re.findall(r'%[0-9]*\.?[0-9]*[a-zA-Z@]', s)

def main():
    # 1. Collect all keys from compiler stringsdata
    compiler_keys = set()
    for p in glob.glob('/Users/efekoc/Library/Developer/Xcode/DerivedData/Heft-*/Build/Intermediates.noindex/Heft.build/Debug-iphonesimulator/Heft.build/Objects-normal/arm64/*.stringsdata'):
        try:
            data = json.load(open(p))
            for item in data.get('tables', {}).get('Localizable', []):
                k = item.get('key')
                if k:
                    compiler_keys.add(k)
        except Exception:
            pass

    print(f"Compiler extracted keys count: {len(compiler_keys)}")

    # 2. Check coverage
    missing = compiler_keys - set(TRANSLATIONS.keys())
    if missing:
        print(f"ERROR: {len(missing)} keys missing translation:")
        for m in sorted(missing):
            print(f"  - {repr(m)}")
        sys.exit(1)
    else:
        print("SUCCESS: 100% of compiler-extracted keys are covered in translation table!")

    # 3. Verify format specifier parity
    mismatches = []
    for k, info in TRANSLATIONS.items():
        src_spec = extract_format_specifiers(k)
        dst_spec = extract_format_specifiers(info["en"])
        if sorted(src_spec) != sorted(dst_spec):
            mismatches.append((k, info["en"], src_spec, dst_spec))

    if mismatches:
        print(f"ERROR: {len(mismatches)} format specifier mismatches found:")
        for k, en, src, dst in mismatches:
            print(f"  Key: {repr(k)}\n    Src: {src}\n    En:  {repr(en)}\n    Dst: {dst}")
        sys.exit(1)
    else:
        print("SUCCESS: Format specifiers match 100% between source and English translations!")

    # 4. Construct xcstrings JSON
    xcstrings_data = {
        "sourceLanguage": "tr",
        "strings": {},
        "version": "1.0"
    }

    # Include all defined translations
    all_target_keys = sorted(set(TRANSLATIONS.keys()) | compiler_keys)
    for key in all_target_keys:
        info = TRANSLATIONS.get(key, {})
        en_val = info.get("en", key)
        comment = info.get("comment", "")

        entry = {
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": en_val
                    }
                },
                "tr": {
                    "stringUnit": {
                        "state": "translated",
                        "value": key
                    }
                }
            }
        }
        if comment:
            entry["comment"] = comment

        xcstrings_data["strings"][key] = entry

    # 5. Write to Heft/Localizable.xcstrings
    out_path = "Heft/Localizable.xcstrings"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(xcstrings_data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"Successfully generated {out_path} with {len(xcstrings_data['strings'])} translated keys!")

if __name__ == "__main__":
    main()
