# sdhash for Ubuntu 24.04 (protobuf 3.21 ready)
**日本語 / English**

---

## 🧩 概要（Japanese）
このリポジトリは、**Ubuntu 24.04 LTS**（gcc 13 / protobuf 3.21.x）環境で `sdhash` をビルド可能にするための修正版です。  
オリジナルの `sdhash` は古い protobuf (2.x〜3.6) 用に生成されたコードを含んでおり、  
そのままではコンパイルエラー（`kEmptyString` など）が発生するため、  
**`blooms.proto` から現行の `protoc` (3.21.x) で再生成した `blooms.pb.h` / `blooms.pb.cc`** を含めています。

- 元プロジェクト: https://github.com/sdhash/sdhash  
- ライセンス: Apache License 2.0（本リポジトリも継承）

---

## 🧾 Overview (English)
This repository provides a **buildable fork of sdhash for Ubuntu 24.04 LTS** (gcc 13 / protobuf 3.21.x).  
Older protobuf-generated files in the original repository caused build failures on modern systems.  
Here, we **regenerated `sdbf/blooms.pb.h` and `sdbf/blooms.pb.cc`** from `blooms.proto` using `protoc 3.21.x`.

- Upstream: https://github.com/sdhash/sdhash  
- License: Apache License 2.0 (inherited)

---

## 🧱 動作確認環境 / Tested Environment
| 項目 | バージョン |
|------|-------------|
| OS | Ubuntu 24.04 LTS |
| Compiler | gcc / g++ 13.x |
| Protobuf | protoc 3.21.x |
| OpenMP | libgomp (標準で付属) |

```bash
protoc --version   # libprotoc 3.21.x
g++ --version      # gcc (Ubuntu 13.x)
```

---

## ⚙️ 依存パッケージ / Dependencies
```bash
sudo apt update
sudo apt install -y   build-essential protobuf-compiler libprotobuf-dev   libssl-dev zlib1g-dev libmagic-dev
```

> Boost はリポジトリ同梱の `external/` 以下で自動ビルドされます。  
> 実行時に共有ライブラリが必要な場合は「ランタイム設定」を参照してください。

---

## 🛠️ ビルド手順 / Build Instructions

通常は以下の手順でビルドできます。

```bash
# 1) Clone
git clone https://github.com/bekuta-jp/sdhash_for_ubuntu24.04.git
cd sdhash_for_ubuntu24.04

# 2) Build
make -j"$(nproc)" || true
make -C sdhash-src -j"$(nproc)" || true
```

もし `sdhash` バイナリが生成されない場合は、下記の **手動リンク（フォールバック）** を実行してください。

---

## 🧩 フォールバック：手動リンク / Fallback: Manual Link
すでに `.o` と `libsdbf.a` は作られているので、リンクだけ明示的に行います。  
OpenMP 対応のために `-fopenmp` を忘れずに。

```bash
g++ -O3 -std=c++17 -fopenmp -o sdhash   sdhash-src/sdhash.o   sdhash-src/sdhash_threads.o   sdbf/blooms.pb.o   libsdbf.a   -Lexternal/stage/lib   -lboost_program_options -lboost_system -lboost_filesystem -lboost_thread   -lprotobuf -lssl -lcrypto -lz -lmagic -ldl -pthread
```

> If you see `omp_*` or `GOMP_*` undefined references, ensure `-fopenmp` is present.  
> If Boost shared libraries are missing, see **Runtime settings** below.

---

## 🧩 インストール & 動作確認 / Install & Verify
```bash
sudo install -m 755 ./sdhash /usr/local/bin/sdhash

which sdhash
sdhash -v
sdhash -f /etc/hosts | head -n 1   # → "sdbf:sha1:..." が出ればOK
```

---

## 🧠 ランタイム設定（必要に応じて） / Runtime Settings (if needed)

**一時的に LD_LIBRARY_PATH を追加:**
```bash
export LD_LIBRARY_PATH="$PWD/external/stage/lib:$LD_LIBRARY_PATH"
```

**永続的に登録:**
```bash
echo "$PWD/external/stage/lib" | sudo tee /etc/ld.so.conf.d/sdhash-boost.conf
sudo ldconfig
```

---

## 🔁 protobuf 再生成手順（任意） / (Optional) Regenerate protobuf

このリポジトリには **すでに再生成済みのファイル** が含まれていますが、  
別環境で再生成したい場合は以下のコマンドを実行します。

```bash
# 旧ファイルを退避（任意）
mkdir -p sdbf/_bak && mv sdbf/blooms.pb.* sdbf/_bak/ 2>/dev/null || true

# 再生成
protoc -I . --cpp_out=sdbf blooms.proto
```

> 警告を消したい場合は `blooms.proto` の先頭に  
> `syntax = "proto2";` を追加してください。

---

## 🔧 変更点 / What’s Changed
| 項目 | 内容 |
|------|------|
| protobuf 対応 | `blooms.pb.*` を Ubuntu 24.04 + protobuf 3.21 用に再生成 |
| ビルド改善 | `-fopenmp` を使用して OpenMP に対応 |
| ドキュメント | 新しいビルド手順を追加（英日併記） |
| 機能変更 | なし（ビルド互換性修正のみ） |

---

## 🪪 ライセンス / License
- 本リポジトリは **Apache License 2.0** に基づき公開されています。  
- オリジナルの `LICENSE` および `NOTICE` を保持しています。  
- This repository inherits **Apache License 2.0** from the original sdhash.  

---

## 🙏 謝辞 / Acknowledgements
- Original sdhash authors and contributors.  
- All developers maintaining protobuf and build environments for modern Linux distributions.

---

## ❓ FAQ

### Q1. Ubuntu 22.04 / 20.04 でも使えますか？
→ 多くの環境で動作しますが、protobuf バージョンが異なる場合は  
　`blooms.pb.*` の再生成を行ってください。

### Q2. Boost が見つからないと言われます。
→ 実行時に `LD_LIBRARY_PATH` または `ldconfig` で  
　`external/stage/lib` を参照できるようにしてください。

### Q3. OpenMP 関連のエラーが出ます。
→ `-fopenmp` オプションをリンク時に追加してください。必要に応じて `-lgomp` も追加。

---

## 🧰 簡易ビルドスクリプト（任意） / Optional Build Script
リポジトリ内に `build.sh` を置けばワンコマンドでセットアップできます。

```bash
#!/usr/bin/env bash
set -euo pipefail
sudo apt update
sudo apt install -y build-essential protobuf-compiler libprotobuf-dev                     libssl-dev zlib1g-dev libmagic-dev

make -j"$(nproc)" || true
make -C sdhash-src -j"$(nproc)" || true

if [[ ! -x ./sdhash && ! -x sdhash-src/sdhash ]]; then
  g++ -O3 -std=c++17 -fopenmp -o sdhash     sdhash-src/sdhash.o sdhash-src/sdhash_threads.o sdbf/blooms.pb.o libsdbf.a     -Lexternal/stage/lib     -lboost_program_options -lboost_system -lboost_filesystem -lboost_thread     -lprotobuf -lssl -lcrypto -lz -lmagic -ldl -pthread
fi

sudo install -m 755 ./sdhash /usr/local/bin/sdhash
sdhash -v
```

---

## 📦 再現性とバージョン情報 / Reproducibility
| 項目 | 値 |
|------|----|
| Ubuntu | 24.04 LTS |
| gcc/g++ | 13.2.0 |
| protobuf | 3.21.12 |
| sdhash | v3.6 (rebuild) |
| 最終更新 | 2025-10 |

---

## 🌐 リンク / Links
- Original: [sdhash/sdhash](https://github.com/sdhash/sdhash)
- Forked / Updated: [bekuta-jp/sdhash_for_ubuntu24.04](https://github.com/bekuta-jp/sdhash_for_ubuntu24.04)

---

> © 2025 bekuta-jp / Apache License 2.0  
> 本リポジトリは研究および再現実験目的で公開されています。
