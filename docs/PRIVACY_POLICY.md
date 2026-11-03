# Privacy Policy for Heft

**Effective Date:** November 3, 2026  
**Last Updated:** November 3, 2026  

Thank you for choosing **Heft** ("we", "our", or "the app"), created and maintained by **Efe Koç**. Your privacy is fundamentally important to us. Heft is designed with a strict privacy-first architecture: your health and weight data belongs solely to you.

---

## 1. Information We Do Not Collect

- We **do not** require you to create an account or provide personal credentials.
- We **do not** collect, store, or transmit your personal data, weight entries, body measurements, or health records to any external server or third party.
- We **do not** use third-party analytics, behavioral tracking frameworks, or advertising SDKs.

---

## 2. On-Device Data Storage

All data you enter into Heft (such as your weight records, target weight, height, age, and preferred units):
- Is stored locally on your device using Apple's secure on-device **SwiftData** framework.
- Is protected by iOS device-level encryption (`NSFileProtectionCompleteUntilFirstUserAuthentication`).
- Is never uploaded to our servers because we operate no servers for Heft data collection.

---

## 3. Apple Health (HealthKit) Integration

Heft integrates with Apple's **HealthKit** framework to provide seamless synchronization with Apple Health:

- **Read Access (`NSHealthShareUsageDescription`):** Heft requests permission to read your weight data from Apple Health to display your historical weight trends, charts, and progress toward your goal.
- **Write Access (`NSHealthUpdateUsageDescription`):** When enabled, weight entries logged in Heft are written to Apple Health so that your central health profile remains up to date.
- **No Third-Party Sharing:** In strict adherence to Apple's HealthKit guidelines:
  - We never share, sell, or disclose HealthKit data to advertising platforms, data brokers, or information resellers.
  - HealthKit data is never used for marketing, advertising, or data mining.
  - HealthKit data is never transferred off your device by Heft.
- **User Control:** You can enable, disable, or revoke HealthKit read and write permissions at any time via the iOS **Settings > Health > Data Access & Devices > Heft**.

---

## 4. Notifications

Heft may schedule local notifications on your device to remind you of your scheduled weigh-ins. These notifications are generated and scheduled strictly on your device using Apple's local notification framework (`UNUserNotificationCenter`). No remote notification servers are used.

---

## 5. Children’s Privacy

Heft does not knowingly collect or solicit personal information from children under the age of 13. Since no personal data is collected from any user, Heft complies with COPPA and global child privacy regulations.

---

## 6. Medical Disclaimer

Heft is an informational weight tracking and wellness visualization tool. It does not provide medical diagnosis, treatment, or clinical advice. Always consult a qualified healthcare professional regarding any medical condition, dietary changes, or weight management regimen.

---

## 7. Changes to This Privacy Policy

We may update our Privacy Policy from time to time. Any changes will be posted on this page with an updated effective date.

---

## 8. Contact Us

If you have any questions or feedback regarding this Privacy Policy, please contact us:

- **Developer:** Efe Koç
- **Email:** efe.koc@icloud.com
- **Website:** https://github.com/efekoc/Heft
