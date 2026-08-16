# kbox

```bash
cd /Volumes/Dev/study/linux
./kbox.sh defconfig
./kbox.sh Image
```

## 명령

| 명령                     | 하는 일                                             |
| ------------------------ | --------------------------------------------------- |
| `./kbox.sh`            | 기본값. `Image`와 `modules`를 빌드                  |
| `./kbox.sh Image`      | 커널 본체만. 코드 읽고 고치는 단계에서 가장 자주 씀 |
| `./kbox.sh defconfig`  | 설정 초기화                                         |
| `./kbox.sh menuconfig` | 설정 변경 (TTY 필요)                                |
| `./kbox.sh fs/ext4/`   | 특정 디렉터리만 컴파일. 문법 확인에 유용            |
| `./kbox.sh clean`      | 오브젝트만 삭제, `.config` 유지                     |
| `./kbox.sh mrproper`   | 설정까지 전부 삭제                                  |
| `./kbox.sh shell`      | 빌드 환경 셸로 진입                                 |

소스를 고친 뒤에는 같은 명령을 다시 치면 됩니다. 바뀐 파일만 다시 컴파일합니다.

### 아키텍처 선택

```bash
./kbox.sh -a x86_64 defconfig      # x86_64 크로스컴파일
./kbox.sh -a x86_64                # bzImage + modules
./kbox.sh --arch arm64 Image
```

`-a`(`--arch`) 옵션이 없으면 현재 시스템 아키텍처를 감지해 네이티브 빌드합니다. 지원 값은 `arm64`, `x86_64`(별칭: `aarch64`, `amd64`, `x86`)이며, 호스트와 다른 아키텍처를 지정하면 자동으로 크로스컴파일러(`x86_64-linux-gnu-` 등)를 사용합니다.

아키텍처별로 산출물이 `.build/<arch>/`에 분리되므로 서로 덮어쓰지 않습니다. 아키텍처마다 `defconfig`를 한 번씩 실행해야 합니다. 기본 타깃도 아키텍처를 따라갑니다(arm64는 `Image`, x86_64는 `bzImage`).

### 조절 가능한 값

```bash
CPUS=10 JOBS=10 MEM=8g ./kbox.sh Image
```

| 변수     | 기본값    | 비고               |
| -------- | --------- | ------------------ |
| `CPUS`   | 6         | VM에 줄 CPU 수     |
| `JOBS`   | `$CPUS`   | `make -j` 값       |
| `MEM`    | 4g        | VM 메모리          |
| `OUT`    | `.build/<arch>` | 빌드 산출물 위치 |
| `CCACHE` | `.ccache` | 컴파일 캐시 위치   |
| `IMAGE`  | `kbox`  | 사용할 이미지 이름 |

## 디렉터리 구조

```
linux/
├── kbox.sh            맥에서 실행하는 진입점
├── .kbox/
│   ├── Dockerfile       툴체인 이미지 정의
│   └── README.md        이 문서
├── .build/              빌드 산출물 (out-of-tree, 아키텍처별 하위 디렉터리)
│   ├── arm64/
│   └── x86_64/
└── .ccache/             컴파일 캐시
```

`.build/`, `.ccache/` 두 항목은 `.git/info/exclude`에 등록해 `git status`에 뜨지 않습니다.

`kbox.sh`와 `.kbox/`는 fork(master)에 커밋해 보존합니다. upstream 트리에 없는 경로라 `git pull --rebase`로 최신 커밋을 받아도 충돌 없이 로컬 커밋만 위로 얹힙니다.

## 환경 구축 방식

### 이미지

`.kbox/Dockerfile`이 `ubuntu:26.04` 위에 툴체인을 얹습니다.

`kbox.sh`는 이미지가 **없을 때만** 자동으로 빌드합니다.

**Dockerfile을 고쳤다면 반드시 직접 다시 구워야 합니다.** 그러지 않으면 예전 이미지가 계속 쓰이면서 변경이 조용히 무시됩니다.

```bash
container build -t kbox -f .kbox/Dockerfile .kbox
```
