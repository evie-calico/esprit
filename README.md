# Vuiiger Engine

## Dependancies.

- [RGBDS 0.5.2 master branch](https://github.com/gbdev/rgbds) (For `-S` flag)
- [Python 3](https://www.python.org/)
- [GNU Make 4.3](https://www.gnu.org/software/make/)
- [SuperFamiconvX](https://github.com/ISSOtm/SuperFamiconvX)
- A C compiler

Windows is not supported by any means. Use [WSL](https://docs.microsoft.com/en-us/windows/wsl/install).

## Building

Navigate to the project root and execute `make`. This will build the ROM and any
tools needed by it, and place them in the `bin/` directory.

## Naming Conventions

- All labels are `PascalCase`
  - Prefix `x`: ROMX
  - Prefix `v`: VRAM
  - Prefix `s`: SRAM
  - Prefix `w`: WRAM
  - Prefix `h`: HRAM

- Constants are in `ALL_CAPS`
- Macros are in `snake_case`

- RGBDS directives are in all caps (Such as `SECTION`, `INCLUDE`, `ASSERT`, but not `db`, `ds`, etc...)
- Instructions are in lowercase (Such as `ld`, `call`, as well as `db`, `ds`, etc...)
