# Vuiiger Engine

## Dependancies.

- [RGBDS 0.5.2 master branch](https://github.com/gbdev/rgbds)
- Python 3
- GNU Make 4.3
- [SuperFamiconvX](https://github.com/ISSOtm/SuperFamiconvX)

Windows is not supported by any means. Use [WSL](https://docs.microsoft.com/en-us/windows/wsl/install).

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
