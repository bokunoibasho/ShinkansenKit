# ShinkansenKit

東海道・山陽新幹線の予約情報を Swift で扱うためのライブラリ。

カレンダーに登録された EX 予約のテキストをパースして、列車種別・列車番号・乗車駅・降車駅・時刻・席種・号車・座席・人数・商品・編成といった構造化データを取り出す。

A Swift library for parsing Tokaido / Sanyo Shinkansen reservation data (e.g. EX reservations registered as calendar events).

## Requirements

- Swift 6.0+
- iOS 17 / macOS 14 / watchOS 10 以上（`ShinkansenKitEventKit` を使う場合）
- `ShinkansenKitCore` 単体はプラットフォーム非依存

## Installation

`Package.swift`:

```swift
.package(url: "https://github.com/bokunoibasho/ShinkansenKit.git", from: "0.1.0")
```

Target dependencies:

```swift
.product(name: "ShinkansenKitCore", package: "ShinkansenKit"),
// EventKit 連携を使う場合（iOS/macOS のみ）
.product(name: "ShinkansenKitEventKit", package: "ShinkansenKit"),
```

## Usage

### Core (プラットフォーム非依存)

```swift
import ShinkansenKitCore

let parser = ReservationParser()
let reservation = parser.parse(
    title: event.title,
    location: event.location,
    notes: event.notes
)
```

### EventKit 連携

```swift
import EventKit
import ShinkansenKitEventKit

let reservation = Reservation(from: ekEvent)
```

## Supported reservation patterns

v0.1.0 では以下 4 パターンをサポートする:

1. 自由席（列車番号・時刻なし）
2. 指定席（普通車）/ 複数名 / 複数席
3. 指定席（普通車）/ 単独席
4. グリーン車

途中駅での乗り換え（multi-leg）行程は未対応。

## License

MIT
