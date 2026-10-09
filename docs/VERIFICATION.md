# Verification / 검증

## Note links — v0.1.1, 2026-10-09

- Added HTTP/HTTPS web-link detection, including `www.` addresses, using Foundation data detection. Tests cover Korean/emoji UTF-16 ranges, surrounding punctuation, excluding other schemes, and removing links after an edit.
- `./scripts/test.sh`: six core tests passed. The universal development app compiled for `arm64` and `x86_64` and passed strict code-signature validation.
- The v0.1.1 release ZIP was extracted into a fresh directory. Its app version, universal architectures, property list, strict signature, archive contents, checksum, and all 18 native UI checks passed.
- Native AppKit diagnostics exercise single-click link activation, Option-click caret placement, dragging to select link text, pasting, editing a URL, text undo, closing/reopening, clear/undo, and restoring link metadata from an existing memo file. Click tests capture the requested URL without depending on network availability.
- An opt-in `--verify-open-link` check successfully handed a URL to the system's default-browser handler through `NSWorkspace`. Browser page loading was not independently verified through GUI automation.
- Diagnostics use separate test memo files and synthetic AppKit input events; physical mouse interaction and live IME composition remain manual checks. Link styling is skipped while IME text is marked.
- The feature is included in the public v0.1.1 universal preview release. Both website languages and READMEs link to v0.1.1; v0.1.0 is retained as a previous release.

### 메모 속 링크

HTTP/HTTPS 및 `www.` 주소를 감지하고, 한 번 클릭하면 기본 브라우저로 연결합니다. Option 클릭으로 주소를 편집하고 드래그로 선택할 수 있습니다. 한글·이모지의 UTF-16 범위, 주소 주변 문장부호, 다른 스킴 제외, 주소 수정 후 링크 해제를 포함해 핵심 테스트 6개가 통과했습니다.

v0.1.1 ZIP을 새 폴더에 풀어 앱 버전·유니버설 아키텍처·속성 목록·엄격한 서명·포함 파일·체크섬을 확인했고, 압축에서 꺼낸 앱의 네이티브 UI 진단 18개도 통과했습니다.

실제 AppKit 편집기에 합성 입력 이벤트를 보내 클릭·Option 클릭·드래그·붙여넣기·주소 수정·실행 취소·팝오버 다시 열기·비우기 되돌리기·저장 파일에서 링크 복원을 검사했습니다. 브라우저 연결 API의 요청 성공은 확인했지만 GUI 자동화로 웹페이지 로딩을 독립적으로 확인하지는 못했습니다. 물리 마우스 조작과 실제 한글 입력기 조합은 수동 확인 항목으로 남깁니다.

공개 유니버설 개발 버전 v0.1.1에 포함했습니다. 홈페이지와 두 README의 다운로드는 v0.1.1로 연결하며 v0.1.0은 이전 릴리스로 남깁니다.

Reproduce native checks with an isolated memo (the second run checks relaunch restoration):

```sh
./scripts/test.sh
./scripts/build.sh --universal
./build/BookmarkPet.app/Contents/MacOS/BookmarkPet --verify-ui "$PWD/.build/manual/link-ui.txt"
./build/BookmarkPet.app/Contents/MacOS/BookmarkPet --verify-ui "$PWD/.build/manual/link-ui.txt"
```

Every line in the resulting report must end in `: true`. Add `--verify-open-link` only when intentionally opening a test URL in the default browser. Use a fresh report path for the initial empty-note check.

## English

Development environment: macOS 26.6.2, Apple Silicon (arm64), Swift 6.3.3, Apple Command Line Tools. Minimum deployment target: macOS 13.

### Completed during app development — 2026-10-08

- Four core tests: exact whitespace preservation and badge rules; Korean, multiline, and long-text persistence across new sessions; clear/undo with persisted state; invalidating clear undo after a new edit.
- Native popover checks: opening, immediate editor focus, Command+V routing through the edit menu, saving and badge updates, reopening, clear/undo, 29 pt status-item width, and template icon rendering.
- UI automation: system-clipboard paste of Korean/multiline text, replacing a selection, Command+Z, relaunch restoration, clear/undo through the header menu, scrolling long notes, login toggle, and quitting through the menu.
- Dismissing the settings menu with one outside click also closes the popover. Selecting a menu item or clicking inside the note keeps the popover open.
- Light and dark popover appearance inspected visually. The menu bar icon uses the system template-image appearance; its badge still merits inspection on different displays and menu bar backgrounds.
- Login-item registration returned `enabled`; unregistering returned `notRegistered`. The test left launch at login disabled. This did not test a new login session.
- Ad hoc signature verification passed. One idle sample measured CPU 0.0% and RSS approximately 40 MB; this is not a performance benchmark.

### Release checks — 2026-10-09

- Re-ran `./scripts/test.sh`: all four core tests passed.
- Built the universal release with `./scripts/package.sh`; `lipo -archs` reports `x86_64 arm64`.
- Extracted the ZIP into a fresh directory. Strict code-signature verification and `Info.plist` validation passed.
- Ran the extracted app with an isolated test memo: all nine native UI smoke checks passed, including focus, empty/filled badge, Command+V, reopening, clear/undo, fixed width, and template icon.
- Verified the archive with `shasum -a 256 -c SHA256SUMS.txt`. The ZIP contains only the app executable, icon, property list, and signature files.
- Exported only the Git-indexed files to a clean directory and successfully ran the default native build there. Captured the actual popover using a separate sample note for both READMEs.
- Checked shell syntax and reviewed the publication file list. Promotional media, build products, test memo files, and local paths are excluded from the source repository. The ZIP is distributed only as a release asset.

### Manual checks still required

1. Put the app in `/Applications` or `~/Applications` and leave a note. Enable **로그인 시 실행** in the **☰** menu. Approve it in System Settings if requested.
2. Log out and back in, or restart the Mac. Confirm the pet and badge appear without opening a popover. Click the pet and check the exact saved note.
3. Edit a note and immediately sleep the Mac. Wake it and verify the note and badge. Repeat with screen lock/unlock.
4. Use a Korean IME to enter, revise, and commit composed text. Check closing during composition, newlines, paste, and reopening.
5. Inspect the pet and badge in light/dark mode, on different menu bar backgrounds, and on Retina/external displays. Test with Reduce Motion enabled.
6. Test the downloaded ZIP on a different Mac, including first-launch Gatekeeper behavior. Test the Intel slice on an Intel Mac and the minimum supported macOS version on a real installation.

Reboot/login, sleep/wake, lock/unlock, physical Intel/macOS 13 execution, and live IME composition have **not** been verified. Developer ID signing and Apple notarization are **not** configured.

## 한국어

개발 환경은 macOS 26.6.2, Apple Silicon(arm64), Swift 6.3.3, Apple Command Line Tools입니다. 최소 실행 버전은 macOS 13으로 지정했습니다.

### 앱 개발 중 확인 — 2026-10-08

- 핵심 테스트 4개: 공백과 원문 보존 및 배지 판정, 한글·여러 줄·긴 본문 저장과 새 세션 복원, 비우기·되돌리기의 저장 상태, 새 입력 시 비우기 되돌리기 해제.
- 네이티브 팝오버 진단: 열기, 즉시 포커스, 편집 메뉴를 통한 Command+V 처리, 저장과 배지 갱신, 다시 열기, 비우기·되돌리기, 메뉴바 폭 29pt 유지, 템플릿 아이콘.
- UI 자동화: 실제 클립보드의 한글·여러 줄 붙여넣기, 선택 영역 교체, Command+Z, 재실행 복원, 헤더 메뉴의 비우기·되돌리기, 긴 메모 스크롤, 로그인 토글, 메뉴에서 종료.
- 설정 메뉴를 연 뒤 바깥을 한 번 클릭하면 메뉴와 팝오버가 함께 닫힙니다. 메뉴 항목을 선택하거나 메모 영역을 클릭하면 팝오버를 유지합니다.
- 라이트·다크 모드 팝오버를 화면으로 확인했습니다. 메뉴바 아이콘은 시스템 템플릿 이미지이며, 다양한 화면과 메뉴바 배경에서의 배지 외관은 추가 확인이 필요합니다.
- 로그인 항목 등록 후 `enabled`, 해제 후 `notRegistered`를 확인했습니다. 테스트 종료 후 로그인 시 실행은 꺼 두었습니다. 실제 재로그인은 수행하지 않았습니다.
- 개발용 임시 서명 검증이 통과했습니다. 유휴 상태를 한 번 측정했을 때 CPU 0.0%, RSS 약 40MB였으며 성능 벤치마크 수치는 아닙니다.

### 배포 점검 — 2026-10-09

- `./scripts/test.sh`를 다시 실행해 핵심 테스트 4개가 모두 통과했습니다.
- `./scripts/package.sh`로 유니버설 배포 파일을 생성했고, `lipo -archs`에서 `x86_64 arm64`를 확인했습니다.
- ZIP을 새 폴더에 풀어 엄격한 코드 서명 검증과 `Info.plist` 검증을 통과했습니다.
- 압축에서 꺼낸 앱을 별도 테스트 메모로 실행해 네이티브 UI 진단 9개가 통과했습니다. 포커스, 빈 메모·본문의 배지, Command+V, 다시 열기, 비우기·되돌리기, 고정 폭, 템플릿 아이콘을 확인했습니다.
- `shasum -a 256 -c SHA256SUMS.txt`로 압축 파일을 확인했습니다. ZIP에는 앱 실행 파일, 아이콘, 속성 목록, 서명 파일만 포함합니다.
- Git에 포함한 파일만 새 폴더에 꺼내 기본 아키텍처 빌드가 성공하는지 확인했습니다. 두 README의 스크린샷은 별도의 예시 메모로 실행한 실제 팝오버를 촬영했습니다.
- 셸 문법과 공개 파일 목록을 검토했습니다. 홍보 영상, 빌드 결과, 테스트 메모와 로컬 경로는 소스 저장소에서 제외하고, ZIP은 릴리스 첨부 파일로만 배포합니다.

### 남아 있는 수동 확인

1. 앱을 `/Applications` 또는 `~/Applications`에 설치하고 메모를 남깁니다. **☰ → 로그인 시 실행**을 켜고 필요하면 시스템 설정에서 승인합니다.
2. 재로그인 또는 재부팅 후 팝오버가 자동으로 열리지 않고 펫과 배지가 표시되는지 확인합니다. 펫을 눌러 메모 원문도 확인합니다.
3. 메모 수정 직후 맥을 잠자기로 전환하고, 복귀 후 본문과 배지를 확인합니다. 화면 잠금·해제도 반복합니다.
4. 실제 한글 입력기로 조합·수정·확정을 수행합니다. 조합 중 닫기, 줄바꿈, 붙여넣기, 다시 열기도 확인합니다.
5. 라이트·다크 모드, 다른 메뉴바 배경, Retina·외장 화면에서 펫과 배지를 확인합니다. 모션 줄이기 설정도 확인합니다.
6. 다른 Mac에서 다운로드한 ZIP의 첫 실행과 Gatekeeper 안내를 확인합니다. Intel Mac과 실제 macOS 13에서도 실행을 확인합니다.

재부팅·재로그인, 잠자기·복귀, 잠금·해제, 실제 Intel·macOS 13 실행, 실제 한글 입력기 조합은 **검증하지 않았습니다**. Developer ID 서명과 Apple 공증은 **설정하지 않았습니다**.

## Website — 2026-10-09

The website uses a concise white-and-blue layout, Korean and English static routes, and an interactive browser demo. The macOS app and release archive are unchanged by the website update.

Twelve browser checks passed in local Chrome:

- Korean content and loaded artwork; English route, language navigation, page title, and canonical metadata.
- Whitespace-only badge state, Korean/multiline input, fixed icon width, long-note scrolling, immediate focus, and keeping text while closing/reopening the demo.
- Clear/undo synchronization, invalidating clear undo after a new edit, outside-click dismissal of both the settings menu and popover, Escape, and keyboard activation.
- First-launch instructions disclose missing Apple notarization. Download links point to the existing verified v0.1.0 universal release archive.
- Responsive layouts at 320, 390, 800, and 1440 CSS pixels; reduced-motion behavior; light website appearance under a dark system setting; no JavaScript runtime errors.
- No browser storage writes or third-party requests during the demo. The demo intentionally resets on page reload or language navigation and is not the native app's persistent storage.

Local asset references, anchor targets, duplicate IDs, JavaScript syntax, and sitemap XML were checked. Desktop Korean, desktop English, and mobile Korean screenshots were visually reviewed. English output is regenerated from the same HTML structure with `node scripts/build-site.mjs`.

### 홈페이지 검증

흰 배경·파란 버튼과 간결한 설명, 한국어·영어 정적 페이지, 브라우저 체험으로 구성했습니다. 홈페이지 추가로 macOS 앱이나 기존 배포 파일은 변경하지 않았습니다.

로컬 Chrome에서 브라우저 검사 12개가 통과했습니다. 언어 전환과 메타데이터, 메모·배지·비우기·되돌리기, 메뉴 바깥 클릭과 Escape, 포커스와 스크롤, 320·390·800·1440px 배치, 모션 줄이기, 오류 없는 실행을 확인했습니다. 체험 중 외부 요청과 브라우저 저장소 기록도 없었습니다.

데스크톱 한국어·영어와 모바일 한국어 화면을 직접 확인했습니다. 다운로드는 검증된 v0.1.0 릴리스로 연결하고, Apple 공증이 없는 개발 버전이라는 안내를 제공합니다. 체험 입력은 페이지 메모리에만 남으며 새로고침·언어 전환 시 초기화됩니다.
