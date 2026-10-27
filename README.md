# Sonora — glass music player (Flutter demo)

Кроссплатформенный аудиоплеер в стиле «liquid glass»: реальное воспроизведение
звука, живой glassmorphism-интерфейс, физика нажатий, эквалайзер-UI и
**настоящий Discord Rich Presence** (чистый Dart: Win32 named pipe через FFI,
unix-socket на Linux).

Проект собирается и запускается на **Windows / Linux / Android**.

---

## 1. Быстрый старт

Нужен Flutter **3.19+** (Dart 3.3+). Проверка: `flutter doctor`.

```powershell
# из папки проекта
powershell -ExecutionPolicy Bypass -File tool/setup_platforms.ps1
flutter pub get
flutter run -d windows
```

Linux / macOS:

```bash
bash tool/setup_platforms.sh
flutter pub get
flutter run -d linux
```

> **Зачем setup_platforms?** В репозитории лежит только `lib/`, `assets/`,
> `shaders/` и `pubspec.yaml` — папки `windows/`, `linux/`, `android/`
> генерируются вашей версией Flutter (`flutter create` во временной папке и
> копирование), поэтому они гарантированно совместимы с вашим SDK и ничего не
> перезаписывают в `lib/`.

Android:

```bash
flutter run -d <device-id>      # или
flutter build apk --release
```

Если на Linux не собирается пакет `audioplayers_linux`:

```bash
sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

---

## 2. Что реально работает

| Фича | Статус |
|---|---|
| Воспроизведение звука (6 сгенерированных треков) | ✅ реально играет (`audioplayers` → MF/GStreamer/MediaPlayer) |
| Очередь, next/prev, seek, громкость, repeat/shuffle, лайки | ✅ |
| Glassmorphism: `BackdropFilter` + линза (`ImageFilter.matrix`) + GLSL-шейдер (`shaders/glass.frag`) | ✅ на всех 3 платформах |
| Пружинные кнопки (`SpringSimulation`), ripple-разлив, hover-свечение | ✅ |
| Анимированный фон, визуализатор, staggered/shimmer/hero | ✅ |
| 12 вкладок настроек с tooltip-ами и сохранением в JSON | ✅ |
| Эквалайзер (10 полос, пресеты, АЧХ) | 🟡 UI + профили работают, **DSP-мост — заглушка** (audioplayers не даёт доступ к аудио-буферу) |
| Discord Rich Presence | ✅ IPC, отправка `SET_ACTIVITY`, троттлинг 15 c, реконнект |
| Кастомизация RPC (текст, кнопки, ассеты, профили) | ✅ + превью-карточка в приложении |
| 🔒 Название трека в RPC | ✅ readonly **на уровне модели** (поля просто нет) |
| Android App Widget / Windows SMTC / Linux MPRIS / tray | ❌ нет (нужен нативный код) — вкладка настроек помечена `ROADMAP` |
| OAuth Яндекс/VK/Apple/Spotify, стриминг | ❌ заглушки (юридические ограничения) |
| Горячие клавиши в приложении | ✅ Space, ←/→, Ctrl+←/→, ↑/↓, M, L, S, R, Esc |

---

## 3. Discord Rich Presence: как включить

1. Откройте <https://discord.com/developers/applications> → **New Application**.
2. Скопируйте **Application ID**.
3. (Опционально) **Rich Presence → Art Assets** → загрузите PNG/JPG 512×512
   (до 512 КБ) и запомните имена артефактов, например `sonora_cover`.
4. Запустите **Discord Desktop** (Windows/Linux). На Android RPC не работает.
5. В приложении: **Настройки → Discord** → вставьте Application ID →
   «Применить и переподключиться».

Статус покажет: строку трека (не редактируется), вторую строку из шаблона
(`{artist}`, `{album}`, `{source}`, `{year}`, `{bpm}`, `{time}`), подпись,
до двух кнопок, прогресс и (если загружены артефакты) картинки.

Если Discord не запущен — статус честно покажет «Discord не запущен», а
превью-карточка в настройках продолжит работать.

---

## 4. Управление

* `Space` — play/pause
* `←` / `→` — перемотка на шаг (5/10/30 с, настраивается)
* `Ctrl + ←/→` — предыдущий/следующий
* `↑` / `↓` — громкость, `M` — mute
* `L` — лайк, `S` — shuffle, `R` — repeat
* `Esc` — закрыть плеер/диалог
* Клик по мини-плееру — полный экран (Hero-переход обложки)

---

## 5. Структура

```
lib/
  main.dart                     загрузка шейдера + runApp
  app.dart                      DI, бутстрап, фон, glow-курсор, хоткеи
  app_scope.dart                InheritedWidget: settings / player / discord
  core/                         палитры, тема, форматирование
  models/                       Track, MusicSource, AppSettings (+JSON), демо-библиотека
  state/                        SettingsController, PlayerController, PerformanceMonitor
  audio/audio_engine.dart       audioplayers + fallback "simulated clock"
  services/
    local_store.dart            сохранение настроек (без плагинов)
    discord/discord_ipc.dart    транспорт: Win32 pipe (FFI) / unix socket
    discord/discord_template.dart   шаблоны + 🔒 защита названия трека
    discord/discord_presence_service.dart  пайплайн, троттлинг, реконнект
  ui/
    glass/                      LiquidGlass, GlassButton, GlassSwitch, blur, шейдер
    animations/                 spring, Appear, shimmer, visualizer, фон, morph
    widgets/                    Artwork (процедурные обложки), TrackTile, MiniPlayer
    screens/                    home, search, library, downloads, now_playing, eq,
                                settings/ (12 вкладок)
assets/audio/                   6 WAV, сгенерированы tool/gen_audio.py
shaders/glass.frag              runtime fragment shader (specular + grain)
tool/                           генератор аудио + скрипты создания платформ
```

---

## 6. Производительность

`PerformanceMonitor` слушает `SchedulerBinding.addTimingsCallback` и при средней
длине кадра > 23 мс автоматически включает low-quality: blur ≤ 7 px,
преломление и шум-шейдер отключаются. Счётчик FPS включается в
**Настройки → Блюр и Glass → Счётчик FPS**.

---

## 7. Лицензии и право

Flutter (BSD-3), audioplayers (MIT), ffi (BSD-3). Демо-треки синтезированы
скриптом `tool/gen_audio.py` — сторонних фонограмм в репозитории нет.

Приложение не аффилировано со Spotify, Apple Music, Яндекс Музыкой, VK,
SoundCloud и YouTube, не обходит DRM и не извлекает защищённые потоки.
Стриминговые адаптеры требуют официальных SDK/договоров — в демо это заглушки.

---

## 8. Как получить готовый `.exe` / `.apk`

### Вариант A — локально (нужен Flutter + C++ toolchain)

```powershell
powershell -ExecutionPolicy Bypass -File tool/build.ps1 -Target windows -Run
# Android:
powershell -ExecutionPolicy Bypass -File tool/build.ps1 -Target android
```

Результат: `dist\Sonora\sonora.exe` (портативная папка, можно заархивировать) и
`dist\sonora.apk`. Для одного установщика:

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" tool\installer\sonora.iss
# → dist\Sonora-1.0.0-setup.exe
```

### Вариант B — в облаке, без локального тулчейна (GitHub Actions)

```bash
git init && git add . && git commit -m "Sonora"
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main
```

`.github/workflows/build.yml` сам:
1. сгенерирует `windows/`, `linux/`, `android/` (в репозитории их нет — см. `.gitignore`);
2. соберёт `Sonora-<ver>-portable-win64.zip`, `Sonora-<ver>-setup.exe` (Inno Setup),
   `Sonora-arm64.apk`, `Sonora-linux-x64.tar.gz`;
3. положит всё в **Artifacts** запуска.

Скачать: **Actions → build → последний run → Artifacts**.

Чтобы файлы прикрепились к релизу:

```bash
git tag v1.0.0 && git push --tags
```

Ограничения GitHub: публичные репозитории — Actions бесплатны без лимита,
приватные — 2000 минут/мес (Windows-раннер считается ×2). Полная сборка ~6–8 мин.

