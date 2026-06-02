# Localization Second-Pass QA Report

## Scope

- Reviewed catalogs: `Nevernote/Localizable.xcstrings`, `Nevernote/InfoPlist.xcstrings`
- Locale count reviewed: 60
- Total locale-string pairs reviewed: 7142
- Total locale-string pairs changed: 19

## Summary by Locale

| Locale | Reviewed count | Changed count |
|---|---:|---:|
| af | 119 | 0 |
| am | 119 | 0 |
| ar | 119 | 0 |
| az | 119 | 0 |
| bg | 119 | 0 |
| bn | 119 | 0 |
| ca | 119 | 0 |
| cs | 119 | 0 |
| da | 119 | 0 |
| de | 119 | 0 |
| el | 119 | 0 |
| en | 121 | 0 |
| es | 119 | 2 |
| et | 119 | 0 |
| eu | 119 | 0 |
| fi | 119 | 0 |
| fr | 119 | 0 |
| ga | 119 | 0 |
| gl | 119 | 0 |
| he | 119 | 0 |
| hi | 119 | 6 |
| hr | 119 | 0 |
| hu | 119 | 0 |
| id | 119 | 0 |
| is | 119 | 0 |
| it | 119 | 0 |
| ja | 119 | 0 |
| kk | 119 | 0 |
| km | 119 | 0 |
| ko | 119 | 0 |
| lo | 119 | 0 |
| lt | 119 | 0 |
| lv | 119 | 0 |
| mk | 119 | 0 |
| mr | 119 | 0 |
| ms | 119 | 0 |
| my | 119 | 0 |
| nb | 119 | 0 |
| ne | 119 | 0 |
| nl | 119 | 0 |
| pl | 119 | 0 |
| pt-BR | 119 | 0 |
| pt-PT | 119 | 5 |
| ro | 119 | 0 |
| ru | 119 | 0 |
| sk | 119 | 0 |
| sl | 119 | 0 |
| sr | 119 | 6 |
| sv | 119 | 0 |
| sw | 119 | 0 |
| ta | 119 | 0 |
| te | 119 | 0 |
| th | 119 | 0 |
| tr | 119 | 0 |
| uk | 119 | 0 |
| ur | 119 | 0 |
| vi | 119 | 0 |
| zh-Hans | 119 | 0 |
| zh-Hant | 119 | 0 |
| zu | 119 | 0 |

## Top Recurring Issues Found

- Regional variant leakage: pt-PT entries were mostly identical to pt-BR (lexicon like “câmera/arquivos/sua”).
- Brand term drift: a few hi/sr strings transliterated the app name instead of preserving “NeverNote”.
- Privacy permission tone: some strings used less iOS-native wording; improved for clarity and explicit purpose.

## High-Impact Fixes (Before → After)

- `pt-PT` / `Localizable.xcstrings` / `Browse Files…`  
  - Before: Navegar pelos arquivos…
  - After: Navegar pelos ficheiros…
- `pt-PT` / `Localizable.xcstrings` / `Camera`  
  - Before: Câmera
  - After: Câmara
- `sr` / `Localizable.xcstrings` / `Choose a photo from your library or files. NeverNote will read any text in the image and add it to your note. QR codes in the image are added at the bottom of the note.`  
  - Before: Изаберите фотографију из своје библиотеке или датотека. НеверНоте ће прочитати било који текст на слици и додати га у вашу белешку. КР кодови на слици се додају на дно напомене.
  - After: Изаберите фотографију из своје библиотеке или датотека. NeverNote ће прочитати било који текст на слици и додати га у вашу белешку. КР кодови на слици се додају на дно напомене.
- `pt-PT` / `Localizable.xcstrings` / `Choose a photo from your library or files. NeverNote will read any text in the image and add it to your note. QR codes in the image are added at the bottom of the note.`  
  - Before: Escolha uma foto da sua biblioteca ou arquivos. NeverNote irá ler qualquer texto da imagem e adicioná-lo à sua nota. Os códigos QR na imagem são adicionados na parte inferior da nota.
  - After: Escolha uma foto da sua biblioteca ou ficheiros. NeverNote irá ler qualquer texto da imagem e adicioná-lo à sua nota. Os códigos QR na imagem são adicionados na parte inferior da nota.
- `hi` / `Localizable.xcstrings` / `Choose a photo from your library or files. NeverNote will read any text in the image and add it to your note. QR codes in the image are added at the bottom of the note.`  
  - Before: अपनी लाइब्रेरी या फ़ाइलों से एक फ़ोटो चुनें। नेवरनोट छवि में मौजूद किसी भी पाठ को पढ़ेगा और उसे आपके नोट में जोड़ देगा। छवि में क्यूआर कोड नोट के नीचे जोड़े गए हैं।
  - After: अपनी लाइब्रेरी या फ़ाइलों से एक फ़ोटो चुनें। NeverNote छवि में मौजूद किसी भी पाठ को पढ़ेगा और उसे आपके नोट में जोड़ देगा। छवि में क्यूआर कोड नोट के नीचे जोड़े गए हैं।
- `sr` / `Localizable.xcstrings` / `NeverNote will read any text in the image and add it to your note.`  
  - Before: НеверНоте ће прочитати било који текст на слици и додати га у вашу белешку.
  - After: NeverNote ће прочитати било који текст на слици и додати га у вашу белешку.
- `hi` / `Localizable.xcstrings` / `NeverNote will read any text in the image and add it to your note.`  
  - Before: नेवरनोट छवि में मौजूद किसी भी पाठ को पढ़ेगा और उसे आपके नोट में जोड़ देगा।
  - After: NeverNote छवि में मौजूद किसी भी पाठ को पढ़ेगा और उसे आपके नोट में जोड़ देगा।
- `sr` / `Localizable.xcstrings` / `Take a photo or choose one from your library. NeverNote will read any text in the image and add it to your note.`  
  - Before: Снимите фотографију или изаберите једну из своје библиотеке. НеверНоте ће прочитати било који текст на слици и додати га у вашу белешку.
  - After: Снимите фотографију или изаберите једну из своје библиотеке. NeverNote ће прочитати било који текст на слици и додати га у вашу белешку.
- `hi` / `Localizable.xcstrings` / `Take a photo or choose one from your library. NeverNote will read any text in the image and add it to your note.`  
  - Before: एक फ़ोटो लें या अपनी लाइब्रेरी से कोई एक चुनें। नेवरनोट छवि में मौजूद किसी भी पाठ को पढ़ेगा और उसे आपके नोट में जोड़ देगा।
  - After: एक फ़ोटो लें या अपनी लाइब्रेरी से कोई एक चुनें। NeverNote छवि में मौजूद किसी भी पाठ को पढ़ेगा और उसे आपके नोट में जोड़ देगा।
- `sr` / `Localizable.xcstrings` / `Take a photo or choose one from your library. NeverNote will read any text in the image and add it to your note. QR codes in the image are added at the bottom of the note.`  
  - Before: Снимите фотографију или изаберите једну из своје библиотеке. НеверНоте ће прочитати било који текст на слици и додати га у вашу белешку. КР кодови на слици се додају на дно напомене.
  - After: Снимите фотографију или изаберите једну из своје библиотеке. NeverNote ће прочитати било који текст на слици и додати га у вашу белешку. КР кодови на слици се додају на дно напомене.
- `hi` / `Localizable.xcstrings` / `Take a photo or choose one from your library. NeverNote will read any text in the image and add it to your note. QR codes in the image are added at the bottom of the note.`  
  - Before: एक फ़ोटो लें या अपनी लाइब्रेरी से कोई एक चुनें। नेवरनोट छवि में मौजूद किसी भी पाठ को पढ़ेगा और उसे आपके नोट में जोड़ देगा। छवि में क्यूआर कोड नोट के नीचे जोड़े गए हैं।
  - After: एक फ़ोटो लें या अपनी लाइब्रेरी से कोई एक चुनें। NeverNote छवि में मौजूद किसी भी पाठ को पढ़ेगा और उसे आपके नोट में जोड़ देगा। छवि में क्यूआर कोड नोट के नीचे जोड़े गए हैं।
- `sr` / `InfoPlist.xcstrings` / `NSCameraUsageDescription`  
  - Before: НеверНоте користи камеру да фотографише текст и увезе га у белешку.
  - After: NeverNote користи камеру да фотографише текст и увезе га у белешку.

## Uncertain Translations Needing Human/Native Review

- Some long help strings in low-resource locales (e.g., am, lo, km, sw) are understandable but could benefit from native in-country review for style nuance and readability at small UI widths.
- A full in-context UI truncation check on compact-width devices is still recommended for longer explanatory strings.
