# sobel_filter UVM Testbench (3x3 블록 / C 골든 레퍼런스 전용)

DUT: `sobel_filter` (`rtl/sobel_filter.v`, THRESHOLD=95 기본값) 단독 검증.
블록 다이어그램상 "Sobel ISP (Upper Path)"의 `sobel` 블록만 대상으로 함.

사용자가 제공한 C 코드(`golden/sobel_golden.c`)를 **그대로** 골든 레퍼런스로
사용해서, `random_0_255.txt` 를 9개씩 끊은 3x3 non-overlapping 블록 단위로
DUT 를 검증하는 **`sobel_module_test` 전용 환경**이다.
(참고: 실제 이미지 스트리밍처럼 한 픽셀씩 흘려보내는 라운드로빈 방식의
`sobel_base_test` 는 별도 버전에 있었으나, 이 프로젝트에서는 제외했다.)

## 디렉토리 구조

```
uvm_sobel/
├── rtl/
│   └── sobel_filter.v            DUT (원본 그대로 복사)
├── golden/
│   └── sobel_golden.c            사용자 제공 C 골든 레퍼런스 (원본 그대로)
├── tb/
│   ├── sobel_if.sv                interface (driver/monitor 연결)
│   ├── sobel_seq_item.sv          transaction
│   ├── sobel_sequencer.sv
│   ├── sobel_driver.sv
│   ├── sobel_monitor.sv
│   ├── sobel_agent.sv
│   ├── sobel_coverage.sv          functional coverage (uvm_subscriber)
│   ├── sobel_module_seq.sv         3x3 블록 file-read sequence
│   ├── sobel_module_scoreboard.sv  sobel_result.txt 기반 scoreboard
│   ├── sobel_module_env.sv         env
│   ├── sobel_module_test.sv        top-level test (sobel_module_test)
│   └── sobel_pkg.sv               위 클래스들을 의존성 순서대로 include
├── sobel_tb_top.sv                top module (clk/DUT/interface/run_test)
├── sim/
│   ├── filelist.f
│   ├── Makefile                   VCS 실행 스크립트 (기본 TEST=sobel_module_test)
│   ├── random_0_255.txt           자극 데이터 (100000개, 0~255)
│   └── sobel_result.txt           C 골든모델을 미리 돌려서 만든 기대값
│                                   (블록당 1줄, 11111줄)
└── verify/
    ├── module_check_tb.sv          (참고용) 블록 방식 검증용 plain(비-UVM) TB
    └── random_0_255.txt, sobel_result.txt
```

## 자극(stimulus) 방식 — 3x3 블록

`random_0_255.txt` 를 9개씩(3x3, non-overlapping) 읽어서 C 골든 레퍼런스와
동일한 방식으로 블록을 구성한다. 블록 1개(9개 값)당 **5 클럭 사이클**을
사용한다.

```
cycle 1 : line_data0=p[0][2] line_data1=p[1][2] line_data2=p[2][2]   (load, 열2)
cycle 2 : line_data0=p[0][1] line_data1=p[1][1] line_data2=p[2][1]   (load, 열1)
cycle 3 : line_data0=p[0][0] line_data1=p[1][0] line_data2=p[2][0]   (load, 열0)
cycle 4 : (settle #1 - line0/1/2 배열은 완성되지만 dx_r/dy_r 은 아직)
cycle 5 : (settle #2 - 이 edge 에서 dx_r/dy_r 이 register 되어 sdata 가
           이 블록의 정답을 반영 → scoreboard 는 이 사이클만 비교)
```

`swap` 은 항상 `0`(identity: line_data0→line0, line_data1→line1,
line_data2→line2) 으로 고정한다. 각 행(row)의 3개 값을 열 순서를
거꾸로(2→1→0) 넣어야 3번째 load 사이클이 끝났을 때 내부 shift register가
`line0=[p[0][0],p[0][1],p[0][2]]` 형태로 정확히 채워진다.

`swap` 은 블록 모드에서 항상 고정이라 실사용은 안 하지만, DUT 입장에서는
"어느 외부 입력을 어느 내부 line buffer 로 라우팅할지" 정하는 신호다.
실제 스트리밍(한 줄씩 흘려보내며 이전 두 줄을 재사용) 상황에서는 이 회전이
필요하지만, 블록 모드는 매번 3줄을 통째로 새로 채우기 때문에 재사용할 게
없어서 회전 자체가 필요 없다 — 그래서 항상 `swap=0`으로 고정해도 C 골든
모델(매번 9개 값을 통째로 새로 읽는 non-overlapping 블록 계산)과 정확히
대응된다.

**블록 개수**: `random_0_255.txt` 100000개 값 → `floor(100000/9) = 11111`
블록 (C 코드와 동일하게 나머지 1개 값은 버림).

## is_settle_point (TB 전용 사이드밴드 신호)

`sobel_if.sv` 에 `is_settle_point` 라는, **DUT 에는 연결되지 않는
testbench 전용 신호**가 있다. `sobel_module_seq` 가 블록의 마지막(settle #2)
사이클에서만 이 신호를 1로 세팅해서, driver → monitor → scoreboard 로
그대로 실어보낸다. scoreboard 는 이 플래그가 1인 사이클에서만 골든값과
비교한다.

이렇게 한 이유: 처음에는 "resetn 이 풀린 뒤 5 사이클마다 비교" 식의
카운터 방식으로 짰었는데, VCS 로 실제 돌려보니 driver 의 reset 로직이
resetn 을 올린 뒤에도 몇 사이클을 더 대기하면서 idle 사이클이 끼어들어
카운터가 밀리는 버그가 있었다. 카운터 대신 아이템 자체에 마킹하는 방식으로
바꾸면서 reset 타이밍/idle 사이클 수와 무관하게 항상 정확해졌다.

## 기대값(golden) 생성 방식

SV 안에서 알고리즘을 재구현하지 않고, `golden/sobel_golden.c` (사용자 제공
원본 그대로) 를 오프라인에서 컴파일/실행해서 `sim/sobel_result.txt`
(블록당 한 줄, 0 또는 1, 총 11111줄) 를 만들어뒀다.
`sobel_module_scoreboard` 는 이 파일을 그대로 읽어서 비교만 한다.

```bash
cd golden
gcc -O2 -o sobel_golden sobel_golden.c
cp ../sim/random_0_255.txt .
./sobel_golden          # sobel_result.txt 생성
cp sobel_result.txt ../sim/
```

## 실행 방법 (Synopsys VCS)

```bash
cd sim
make compile
make run                          # 기본 TEST=sobel_module_test
# 또는 명시적으로
make run TEST=sobel_module_test
```

`DATA_FILE`, `RESULT_FILE` 플러스아규먼트로 경로를 바꿀 수 있다:

```bash
./simv +UVM_TESTNAME=sobel_module_test +DATA_FILE=/path/to/other.txt +RESULT_FILE=/path/to/other_result.txt
```

## 검증 방법 (RTL 대비 정확성)

VCS 없이도 오픈소스 iverilog 로 실제 `rtl/sobel_filter.v` 를 직접 구동해서
`sobel_result.txt` 전체 11111개 블록을 대조하는 plain(비-UVM) testbench가
`verify/module_check_tb.sv` 에 있다. **11111 / 11111 완전 일치** 확인됨.

실제 VCS+UVM 환경에서도 동일하게:
```
total      : 11111
match      : 11111  (100.00%)
mismatch   : 0  (0.00%)
*** TEST PASSED ***
```

## Pass/Fail 판정

`sobel_module_scoreboard` 가 `is_settle_point=1` 사이클마다
`sobel_result.txt` 의 다음 줄과 실제 `sdata` 를 `===` 비교하며,
`report_phase` 에서:

- mismatch 0개 → `*** TEST PASSED ***`
- mismatch 1개 이상 → `uvm_error` + `*** TEST FAILED ***`

## Coverage

`sobel_coverage.sv` 에서 다음을 측정한다:

- `line_data0/1/2` 값 구간 (low/mid/high)
- `swap` 값 — 블록 모드는 항상 0 이므로 `s0`만 covered, `s1/s2/s3`는
  uncovered 가 정상 (버그 아님, swap 라우팅 기능 자체를 이 테스트가 안 씀)
- `sdata` toggle (0/1)
- `swap` x `sdata` cross coverage

VCS 커버리지(DB) 로 상세히 보려면:
```bash
make run TEST=sobel_module_test
verdi -cov -covdir cm_sobel_module_test.vdb &
```
