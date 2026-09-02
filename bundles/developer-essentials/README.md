# Developer Essentials

A practical **developer workstation bootstrap** for Ryoku: Arch build basics,
Git and GitHub CLI, fast shell search tools, terminal workflow helpers, native
build/debug tools, major language runtimes, Docker, and Visual Studio Code.
Install it from **Settings, Extras, Developer Essentials, Install all**.

## Core workflow tools

| Tool | What it is | Source |
| --- | --- | --- |
| base-devel | Arch's essential build toolchain group for compiling AUR packages and local projects. | pacman |
| git | Distributed version control. | pacman |
| github-cli | GitHub CLI (`gh`) for pull requests, issues, releases, and auth. | pacman |
| curl / wget | Command-line download and API tools. | pacman |
| jq | JSON processor for shell pipelines and API output. | pacman |
| ripgrep / fd / fzf | Fast search, file finding, and fuzzy picking for source trees. | pacman |
| tmux | Persistent terminal sessions and split-pane workflows. | pacman |

## Build and debug

| Tool | What it is | Source |
| --- | --- | --- |
| cmake | Cross-platform build system generator. | pacman |
| ninja | Fast build executor, commonly paired with CMake and Meson. | pacman |
| gdb | GNU debugger for native applications. | pacman |
| clang | LLVM C/C++ compiler and tools. | pacman |
| lldb | LLVM debugger for C, C++, Rust, Swift, and other native code. | pacman |

## Languages and tooling

| Tool | What it is | Source |
| --- | --- | --- |
| python / python-pip | Python runtime and package installer. | pacman |
| nodejs / npm | JavaScript runtime and package manager. | pacman |
| bun | Fast JavaScript runtime, package manager, bundler, and test runner. | pacman |
| rustup | Rust toolchain installer and version manager. | pacman |
| go | Go compiler, standard tools, and runtime. | pacman |
| jdk-openjdk | OpenJDK Java runtime and compiler. | pacman |

## Containers and editor

| Tool | What it is | Source |
| --- | --- | --- |
| docker | Container engine for local services, tests, and images. | pacman |
| docker-compose | Compose plugin for multi-container dev environments. | pacman |
| visual-studio-code-bin | Official Microsoft Visual Studio Code build. | AUR |

## Notes

- Docker may need the service enabled and your user added to the `docker` group
  before rootless day-to-day use works in a new session.
- `rustup` installs Rust toolchains after package installation; run
  `rustup default stable` if no default toolchain is configured yet.
- The Java package is `jdk-openjdk`, which provides the `java` command and the
  JDK toolchain on Arch.
