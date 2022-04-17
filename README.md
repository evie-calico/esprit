# Vuiiger Engine

## Dependancies.

I use bleeding-edge RGBDS versions to help the maintainers test new features.
You will likely need to compile the master branch of RGBDS manually to be able
to build this project.

- [RGBDS 0.5.2 master branch](https://github.com/gbdev/rgbds) (For `-S` flag)
- [RGBGFX CXX Branch](https://github.com/ISSOtm/rgbds/tree/rgbgfx-cxx) (For testing new features)
- [GNU Make 4.3](https://www.gnu.org/software/make/)
- [SuperFamiconvX](https://github.com/ISSOtm/SuperFamiconvX) (Until RGBGFX-CXX is finished)
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
