# Privacy Policy (English)

**Effective date**: 2026-10-01

**Scope**: This Privacy Policy applies to the reading application **Readnest** (hereinafter the "App") developed and published by **Tong Lin (individual developer)** (hereinafter "we", "us", or "our").

> Note: This policy is hosted on the developer's website so that both the stores and users can reach it:
> English `https://kjlintong.github.io/privacy-en.html` ｜ Chinese `https://kjlintong.github.io/privacy.html`
> The web version is generated from this file by `store/tools/build_site.py` (output in `store/web/`).
> Developer identity: **Tong Lin · ltong9463@gmail.com (individual developer, no registered company)**.

---

## 1. How We Approach Your Data

This App uses a **local-first** architecture:

- Your bookshelf, reading progress, notes, statistics, and settings are **stored entirely in an on-device local database (SQLite)**;
- We **do not provide any account system, nor do we operate backend servers that collect or store your data**;
- We **do not sell, rent, or share your personal data with any third party for advertising or marketing purposes**.

---

## 2. What Data We Process

- **Locally stored data**: Book information you add or import (title, author, category, progress, rating, notes, cover, etc.), reading statistics, and app settings. This data exists only on your device.
- **Credentials you enter**: If you use the "WeRead Sync" or "LLM" features, you enter the corresponding API Key / Base URL / model name in Settings. These credentials **are stored only in your device's system keystore (Android Keystore / iOS Keychain, via flutter_secure_storage)** and **are never written in plaintext to the app's SQLite database**; they are never uploaded to us and are sent only to the endpoints you specify.
- **What we do not collect**: The App integrates no third-party analytics, advertising, or crash-reporting SDKs, and does not collect device identifiers, precise location, or your behavioral data. There is exactly one exception: the **on-device text-recognition SDK used for photo import (Google ML Kit)** sends Google **anonymous operational metrics that carry no image content**. See section 3.4 below.

---

## 3. When Data Leaves Your Device

The App communicates with third-party services **only when you actively enable and configure the corresponding feature**. All communication goes through credentials you provide, to endpoints you choose.

### 3.1 WeRead Sync (optional)
- **Trigger**: You enter a WeRead API Key in Settings.
- **Recipient**: Tencent WeRead official gateway `https://i.weread.qq.com`.
- **Data sent**: API requests to fetch your bookshelf, reading progress, reading statistics, and store search.
- **Note**: Operated by Tencent with servers in China. If you do not enter the Key, the App never contacts this service.

### 3.2 LLM / AI Features (optional)
You may enter any OpenAI-compatible or Anthropic-protocol LLM endpoint (Base URL, API Key, model name). The following data is sent to your configured endpoint when you trigger the relevant feature:
- **Metadata completion**: A small amount of information (title, author) to complete missing book metadata.
- **Reading report generation**: **Aggregated reading statistics**, plus the **titles, authors, categories, reading status, and ratings of books that changed during the reporting period** (**excluding note content**).
- **Screenshot recognition (multimodal)**: When you enable "organize OCR results with LLM" or "multimodal model reads image" to import a bookshelf photo/screenshot, **the image (JPEG) you select is uploaded to your configured multimodal endpoint** to recognize book titles. This is optional and requires you to actively select and confirm the image each time.

> **Important consent**: Screenshots may contain personal information such as book titles and covers. Uploading images to a multimodal model is sensitive data processing; the App will **request your separate explicit consent** before using this feature, and you may disable it at any time in Settings.

### 3.3 Public Metadata Services (optional)
To complete book covers, descriptions, ISBN, etc., the App queries the following public APIs by title/author:
- Google Books API (`https://www.googleapis.com/books/v1/volumes`)
- Open Library (`https://openlibrary.org`)

These queries contain only the title/author of the book you are importing, used to match public bibliographic data. They are skipped automatically in networks where these services are unreachable, without interrupting import.

When a book has a cover image, the App **downloads that image directly from wherever it is hosted** (typically `books.google.com` or `covers.openlibrary.org`) in order to display it. Such a request contains nothing but the image address itself.

### 3.4 Operational metrics from the on-device text-recognition SDK (automatic)

Text recognition during photo and album import is performed **locally on your device by Google ML Kit**. **The image you select, and the text recognised from it, never leave your device.** However, under Google's official ML Kit terms of service, the SDK will:

- contact Google servers from time to time in order to receive bug fixes, updated models, and hardware-accelerator compatibility information; and
- send Google **metrics about the performance and utilization of the API within this App** (for example, how often it is invoked, how long processing takes, and the device model and OS version).

These metrics describe the SDK's own operation. They **do not contain the image you scanned, your book titles, or your notes**, and we — the developer — do not receive them either. This behaviour is determined by the SDK and cannot be switched off by the App. If you never use photo or album import, these requests never occur.

Source: https://developers.google.com/ml-kit/terms

---

## 4. Permissions

- **Camera**: To photograph your bookshelf for title recognition (camera import).
- **Photo / Media Library**: To pick bookshelf screenshots from the album for recognition (album import).
- **Internet**: For the sync, AI, and metadata features above.

We invoke the corresponding permission only when you actually use the related feature, following the principle of minimal permission and purpose disclosure.

---

## 5. Data Security

- Your data is stored in the device-private directory; both the app sandbox and the system keystore are protected by the OS.
- Your API keys are stored in system-level secure storage (Android Keystore / iOS Keychain, via `flutter_secure_storage`) and are never written in plaintext to the app's SQLite database.
- You may export your data as a JSON file via the in-app "Export / Restore" feature for backup. The file is stored where you choose and managed by you; the App does not upload it automatically.

---

## 6. Children's Privacy

The App is not specifically directed to children under 13 and does not knowingly collect children's personal information. As the App has no account system, we do not actively verify user age.

---

## 7. Your Rights and Data Deletion

Because the App has no account dependency and all data is stored locally:

- **Access & export**: You may view all data in-app at any time and obtain a JSON copy via export.
- **Deletion**: Clearing app data in system settings or uninstalling the App permanently deletes all local data; exported backup files are deleted by you.
- If your jurisdiction grants rights to access, rectify, delete, port, or object to processing of your data (e.g., GDPR in the EU, CCPA in California), contact us via the details below.

---

## 8. Changes to This Policy

We may update this policy from time to time. Material changes will be communicated via in-app notice or update notes.

---

## 9. Contact Us

For any questions about this policy or your data, contact: **ltong9463@gmail.com**
Developer website: **https://kjlintong.github.io/**
Data Controller: **Tong Lin (individual developer, no registered company)**, established in: **China**

---

## 10. Pricing and Tips

Every feature of the App can be used at no cost. The App contains **no advertising, no in-app purchases and no subscriptions**.

If you would like to support continued development, you can open an external tipping page (Ko-fi) from **Settings → Support the Developer**. Tipping is **entirely voluntary and unlocks nothing** — the App works exactly the same either way. The page opens in your system browser, payment is handled by that third-party platform, and the App **takes no part in the transaction and never sees your payment details**.

---

*This policy was drafted by the developer. Before release, we recommend a review by qualified legal counsel against current regulations (GDPR, CCPA, PIPL, etc.).*
