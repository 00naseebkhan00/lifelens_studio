# LifeLens Studio

Turn everyday photos into smart, AI-guided shots.

LifeLens Studio is a Flutter app powered by *Google Gemini*.  
It has two main modes:

- *Scan Mode 🔍* – Understand what’s in any image and get smart tips.
- *Capture Mode 📸* – Get vibe filters and photo advice for portraits and baby photos.

All AI intelligence (descriptions, tips, vibes) comes from *Gemini 2.5 Flash*.

---

## ✨ Features

### 🔍 Scan Mode

- Pick any image from your device (phone or web).
- The app sends the image to *Gemini 2.5 Flash*.
- Gemini returns:
  - A short *title*
  - A clear *description* of what’s in the photo
  - 2–4 *practical tips*  
    (e.g. photography tips, safety notes, creative suggestions)
- Results are shown in a clean panel with:

  > AI Insight  
  > Powered by Google Gemini badge

This makes Scan Mode useful for:
- Understanding digital art / photos  
- Learning how to improve shots  
- Getting ideas for creative use of images

---

### 📸 Capture Mode

Capture Mode is like a mini AI photo coach.

- User picks a portrait / child photo / aesthetic image.
- Gemini analyzes the image and returns:
  - A descriptive *title*  
    (e.g. Cute Child in a Patriotic Hat, Adorable Baby in Stacked Hats)
  - A *style / mood explanation*
  - Multiple *tips* for better future photos  
    (light, angles, posing, safety, comfort)

LifeLens Studio then:

- Extracts the text and tips from Gemini.
- Chooses a *vibe filter name* based on the mood, for example:
  - Soft Family Dream
  - Midnight Street Glow
  - Golden Hour Warmth
  - Clean Neutral Look
  - Crisp Portrait Focus
- Applies a simple *visual style* to the preview using Flutter’s ColorFiltered.

The user can switch between:

- *Original* – the raw photo  
- *Styled* – photo with the vibe filter applied

So every capture becomes a *before/after lesson* with real guidance, not just a random filter.

---

### 🧠 Powered by Google Gemini

- Uses *Gemini 2.5 Flash* through the Generative Language API.
- Calls the REST endpoint from Dart using http.post.
- Sends:
  - Image bytes (inline_data)
  - A carefully designed prompt
- Receives:
  - Either *markdown text* (Scan Mode)
  - Or *JSON* (Capture Mode, with response_mime_type: application/json)

The app then:

- Parses the response
- Shows AI output in the UI
- Maps it to vibe names and styles

---

## 🛠 Tech Stack

- *Flutter* (Android + Web)
- *Dart*
- *Google Gemini 2.5 Flash* (Generative Language API)
- No custom backend – everything runs from the Flutter app.

---

## 🔑 API Key Setup

> ⚠ Never commit your real API key to a public repo.

In the project, the Gemini calls are inside:

lib/services/gemini_service.dart

There is a line:

```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
