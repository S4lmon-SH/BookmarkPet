# Verification / 검증

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
