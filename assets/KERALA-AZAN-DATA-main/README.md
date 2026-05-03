# 🕋 Kerala Regional Azaan Data (Perpetual)

[![GitHub stars](https://img.shields.io/github/stars/Its-me-nishmal/KERALA-AZAN-DATA.svg?style=social)](https://github.com/Its-me-nishmal/KERALA-AZAN-DATA)
[![Build Status](https://img.shields.io/badge/Status-Complete-brightgreen)](https://github.com/Its-me-nishmal/KERALA-AZAN-DATA)

> **Digitized and curated by [Cipher Nichu](https://github.com/Its-me-nishmal)**
>
> ⭐ **If this data helps your project, please give it a Star on GitHub!**

A high-precision, **perpetual** dataset of prayer (Azaan) times for **140+ locations** across Kerala, India. This project eliminates the need for manual updates and brings regional accuracy to digital prayer platforms.

---

## 👨‍💻 Developed By: **Cipher Nichu**
This dataset was meticulously extracted, validated, and structured into a developer-friendly API format by **Cipher Nichu**. The goal is to provide the community with a reliable, digital-first source for regional prayer timings.

---

## 🌟 Major Benefits

- **♾️ Perpetual Data:** Valid for over **40 years (until 2060)**. Never worry about "2026 update" or "2027 update" again.
- **📍 Ultra-Local Accuracy:** Covers individual towns and villages, solving the common issue of 5-15 minute errors found in broad zone-based apps.
- **🚀 Static API Ready:** Hosted on GitHub Pages for blazing-fast access without needing a backend server.
- **📦 Offline-First:** Extremely lightweight JSON files (approx. 60KB per location) perfect for bundling inside mobile apps for 100% offline use.
- **⚡ Zero Maintenance:** Once integrated, your app's prayer timing engine will remain accurate for decades.

---

## 🌐 Quick Access (API Endpoints)

Use the following endpoints to fetch data directly in your applications:

- **Master Index:**  
  [`https://its-me-nishmal.github.io/KERALA-AZAN-DATA/index.json`](https://its-me-nishmal.github.io/KERALA-AZAN-DATA/index.json)
- **Location Data (Example - Manjeshwaram):**  
  [`https://its-me-nishmal.github.io/KERALA-AZAN-DATA/101.json`](https://its-me-nishmal.github.io/KERALA-AZAN-DATA/101.json)
- **Location Data (Example - Wandoor):**  
  [`https://its-me-nishmal.github.io/KERALA-AZAN-DATA/504.json`](https://its-me-nishmal.github.io/KERALA-AZAN-DATA/504.json)

---

## 📜 Credits & Source

This data is based on the authoritative regional prayer timings prepared by:

### **Dr. Mustafa Darimi Karippur**
Prepared with the approval of the **Samastha Kerala Islam Matha Vidyabhyasa Board**.

- **Website:** [www.musthafadarimikaripur.com](http://www.musthafadarimikaripur.com)
- **Official Documentation:** These timings are intended for use in all Masjids for Baang (Azaan) and Prayer.

---

## 🛠 Data Structure

### `index.json`
Maps location IDs to names and districts.
```json
{
  "id": 1,
  "name": "Kasaragod",
  "locations": [
    {"id": 101, "name": "Manjeshwaram"}
  ]
}
```

### `[id].json` (e.g., `101.json`)
The perpetual calendar with `MM-DD` format.
```json
{
  "date": "01-01",
  "fajr": "5:26",
  "sunrise": "6:51",
  "dhuhr": "12:35",
  "asr": "3:52",
  "maghrib": "6:19",
  "isha": "7:32"
}
```

---
*Developed for the benefit of the Ummah by **Cipher Nichu**.*
