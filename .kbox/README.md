# kbox

```bash
cd /Volumes/Dev/study/linux
./kbox.sh defconfig
./kbox.sh Image
```

macOS에서는 Apple `container` VM 안에서, 리눅스에서는 **네이티브로** 빌드합니다. 리눅스에서 네이티브 대신 Docker를 쓰려면 `-d`/`--docker`를 붙입니다.

- 네이티브 모드는 툴체인이 이미 설치돼 있다고 가정합니다(패키지 목록은 `Dockerfile` 참고 — 설치는 직접).
- 네이티브 산출물은 트리의 `.build/<arch>/`에, 컨테이너 모드는 볼륨의 `/build/<arch>/`에 들어갑니다.
- `-j` 기본값: 네이티브는 `nproc`, 컨테이너는 `$CPUS`.

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

아키텍처별로 산출물이 볼륨 안 `/build/<arch>/`에 분리되므로 서로 덮어쓰지 않습니다. 아키텍처마다 `defconfig`를 한 번씩 실행해야 합니다. 기본 타깃도 아키텍처를 따라갑니다(arm64는 `Image`, x86_64는 `bzImage`).

### 조절 가능한 값

```bash
CPUS=10 JOBS=10 MEM=8g ./kbox.sh Image
```

| 변수      | 기본값       | 비고                                 |
| --------- | ------------ | ------------------------------------ |
| `CPUS`    | 4            | VM에 줄 CPU 수                       |
| `JOBS`    | `$CPUS`      | `make -j` 값                         |
| `MEM`     | 4g           | VM 메모리                            |
| `VOL`     | `kbox-build` | 빌드 산출물을 담는 볼륨 이름         |
| `VOLSIZE` | 64G          | 볼륨 최대 크기 (sparse, 생성 시에만) |
| `IMAGE`   | `kbox`       | 사용할 이미지 이름                   |
| `OUT`     | `.build/<arch>` | 네이티브 모드의 산출물 위치       |

## 디렉터리 구조

```
linux/                   (virtiofs로 /src에 마운트)
├── kbox.sh              맥에서 실행하는 진입점
└── .kbox/
    ├── Dockerfile       툴체인 이미지 정의
    └── README.md        이 문서

kbox-build 볼륨          (virtio-blk + ext4로 /build에 마운트)
├── arm64/               빌드 산출물 (out-of-tree, 아키텍처별)
└── x86_64/
```

빌드 산출물은 호스트 디렉터리가 아니라 **`container volume`**(`kbox-build`)에 둡니다. virtiofs는 연산마다 게스트↔호스트 왕복이 붙어 오브젝트·의존성 파일처럼 자잘한 쓰기가 많은 빌드 출력에 극단적으로 불리한 반면, 볼륨은 VM에 블록 디바이스로 붙는 ext4라 게스트 커널이 전속력으로 씁니다. 소스 읽기는 virtiofs여도 ~16% 손해에 그쳐 그대로 둡니다.

볼륨은 첫 실행 때 자동 생성되고(sparse — 쓴 만큼만 디스크 차지), 컨테이너가 죽어도 유지되므로 인크리멘털 빌드가 됩니다. 실체는 `~/Library/Application Support/com.apple.container/volumes/` 아래 디스크 이미지이며, `container volume rm kbox-build`로 지우면 공간이 통째로 회수됩니다.

### 산출물 꺼내기

볼륨 내용물은 맥에서 직접 보이지 않으므로, 필요한 파일은 컨테이너를 통해 `/src`(= 이 트리)로 복사해 꺼냅니다:

```bash
./kbox.sh shell -c 'cp /build/arm64/arch/arm64/boot/Image /src/'
./kbox.sh shell -c 'cp /build/arm64/.config /src/'
```

### git 관리

`kbox.sh`와 `.kbox/`는 fork(master)에 커밋해 보존합니다. upstream 트리에 없는 경로라 `git pull --rebase`로 최신 커밋을 받아도 충돌 없이 로컬 커밋만 위로 얹힙니다.

## 환경 구축 방식

### 이미지

`.kbox/Dockerfile`이 `ubuntu:26.04` 위에 툴체인을 얹습니다.

`kbox.sh`는 이미지가 **없을 때만** 자동으로 빌드합니다.

**Dockerfile을 고쳤다면 반드시 직접 다시 구워야 합니다.** 그러지 않으면 예전 이미지가 계속 쓰이면서 변경이 조용히 무시됩니다.

```bash
container build -t kbox -f .kbox/Dockerfile .kbox
```
