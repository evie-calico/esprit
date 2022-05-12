#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <setjmp.h>

#ifndef PLUM_DEFS

#define PLUM_DEFS

#include <stdint.h>

#if defined(PLUM_NO_STDINT) || defined(PLUM_NO_ANON_MEMBERS) || defined(PLUM_NO_VLA)
  #error libplum feature-test macros must not be defined when compiling the library.
#elif defined(__cplusplus)
  #error libplum cannot be compiled with a C++ compiler.
#elif __STDC_VERSION__ < 201710L
  #error libplum requires C17 or later.
#elif SIZE_MAX < 0xffffffffu
  #error libplum requires size_t to be at least 32 bits wide.
#endif

#ifdef noreturn
  #undef noreturn
#endif
#define noreturn _Noreturn void

#ifndef alignas
  #define alignas _Alignas
#endif

#ifdef PLUM_DEBUG
  #define internal
#else
  #define internal static
#endif

#define bytematch(address, ...) (!memcmp((address), (unsigned char []) {__VA_ARGS__}, sizeof (unsigned char []) {__VA_ARGS__}))
#define bytewrite(address, ...) (memcpy(address, (unsigned char []) {__VA_ARGS__}, sizeof (unsigned char []) {__VA_ARGS__}))
#define byteoutput(context, ...) (bytewrite(append_output_node((context), sizeof (unsigned char []) {__VA_ARGS__}), __VA_ARGS__))
#define byteappend(address, ...) (bytewrite(address, __VA_ARGS__), sizeof (unsigned char []) {__VA_ARGS__})

#endif

#ifndef PLUM_HEADER

#define PLUM_HEADER

#define PLUM_VERSION 10019

#include <stddef.h>
#ifndef PLUM_NO_STDINT
#include <stdint.h>
#endif

#if !defined(__cplusplus) && (__STDC_VERSION__ >= 199901L)
/* C99 or later, not C++, we can use restrict, and check for VLAs and anonymous struct members (C11) */
/* indented preprocessor directives and // comments are also allowed here, but we'll avoid them for consistency */
#define PLUM_RESTRICT restrict
#define PLUM_ANON_MEMBERS (__STDC_VERSION__ >= 201112L)
/* protect against really broken preprocessor implementations */
#if !defined(__STDC_NO_VLA__) || !(__STDC_NO_VLA__ + 0)
#define PLUM_VLA_SUPPORT 1
#else
#define PLUM_VLA_SUPPORT 0
#endif
#elif defined(__cplusplus)
/* C++ allows anonymous unions as struct members, but not restrict or VLAs */
#define PLUM_RESTRICT
#define PLUM_ANON_MEMBERS 1
#define PLUM_VLA_SUPPORT 0
#else
/* C89 (or, if we're really unlucky, non-standard C), so don't use any "advanced" C features */
#define PLUM_RESTRICT
#define PLUM_ANON_MEMBERS 0
#define PLUM_VLA_SUPPORT 0
#endif

#ifdef PLUM_NO_ANON_MEMBERS
#undef PLUM_ANON_MEMBERS
#define PLUM_ANON_MEMBERS 0
#endif

#ifdef PLUM_NO_VLA
#undef PLUM_VLA_SUPPORT
#define PLUM_VLA_SUPPORT 0
#endif

#define PLUM_MODE_FILENAME   ((size_t) -1)
#define PLUM_MODE_BUFFER     ((size_t) -2)
#define PLUM_MODE_CALLBACK   ((size_t) -3)
#define PLUM_MAX_MEMORY_SIZE ((size_t) -4)

/* legacy constants, for compatibility with the v0.4 API */
#define PLUM_FILENAME PLUM_MODE_FILENAME
#define PLUM_BUFFER   PLUM_MODE_BUFFER
#define PLUM_CALLBACK PLUM_MODE_CALLBACK

enum plum_flags {
  /* color formats */
  PLUM_COLOR_32     = 0, /* RGBA 8.8.8.8 */
  PLUM_COLOR_64     = 1, /* RGBA 16.16.16.16 */
  PLUM_COLOR_16     = 2, /* RGBA 5.5.5.1 */
  PLUM_COLOR_32X    = 3, /* RGBA 10.10.10.2 */
  PLUM_COLOR_MASK   = 3,
  PLUM_ALPHA_INVERT = 4,
  /* palettes */
  PLUM_PALETTE_NONE     =     0,
  PLUM_PALETTE_LOAD     = 0x200,
  PLUM_PALETTE_GENERATE = 0x400,
  PLUM_PALETTE_FORCE    = 0x600,
  PLUM_PALETTE_MASK     = 0x600,
  /* palette sorting */
  PLUM_SORT_LIGHT_FIRST =     0,
  PLUM_SORT_DARK_FIRST  = 0x800,
  /* other bit flags */
  PLUM_ALPHA_REMOVE   =  0x100,
  PLUM_SORT_EXISTING  = 0x1000,
  PLUM_PALETTE_REDUCE = 0x2000
};

enum plum_image_types {
  PLUM_IMAGE_NONE,
  PLUM_IMAGE_BMP,
  PLUM_IMAGE_GIF,
  PLUM_IMAGE_PNG,
  PLUM_IMAGE_APNG,
  PLUM_IMAGE_JPEG,
  PLUM_IMAGE_PNM,
  PLUM_NUM_IMAGE_TYPES
};

enum plum_metadata_types {
  PLUM_METADATA_NONE,
  PLUM_METADATA_COLOR_DEPTH,
  PLUM_METADATA_BACKGROUND,
  PLUM_METADATA_LOOP_COUNT,
  PLUM_METADATA_FRAME_DURATION,
  PLUM_METADATA_FRAME_DISPOSAL,
  PLUM_NUM_METADATA_TYPES
};

enum plum_frame_disposal_methods {
  PLUM_DISPOSAL_NONE,
  PLUM_DISPOSAL_BACKGROUND,
  PLUM_DISPOSAL_PREVIOUS,
  PLUM_DISPOSAL_REPLACE,
  PLUM_DISPOSAL_BACKGROUND_REPLACE,
  PLUM_DISPOSAL_PREVIOUS_REPLACE,
  PLUM_NUM_DISPOSAL_METHODS
};

enum plum_errors {
  PLUM_OK,
  PLUM_ERR_INVALID_ARGUMENTS,
  PLUM_ERR_INVALID_FILE_FORMAT,
  PLUM_ERR_INVALID_METADATA,
  PLUM_ERR_INVALID_COLOR_INDEX,
  PLUM_ERR_TOO_MANY_COLORS,
  PLUM_ERR_UNDEFINED_PALETTE,
  PLUM_ERR_IMAGE_TOO_LARGE,
  PLUM_ERR_NO_DATA,
  PLUM_ERR_NO_MULTI_FRAME,
  PLUM_ERR_FILE_INACCESSIBLE,
  PLUM_ERR_FILE_ERROR,
  PLUM_ERR_OUT_OF_MEMORY,
  PLUM_NUM_ERRORS
};

#define PLUM_COLOR_VALUE_32(red, green, blue, alpha) ((uint32_t) (((uint32_t) (red) & 0xff) | (((uint32_t) (green) & 0xff) << 8) | \
                                                                  (((uint32_t) (blue) & 0xff) << 16) | (((uint32_t) (alpha) & 0xff) << 24)))
#define PLUM_COLOR_VALUE_64(red, green, blue, alpha) ((uint64_t) (((uint64_t) (red) & 0xffffu) | (((uint64_t) (green) & 0xffffu) << 16) | \
                                                                  (((uint64_t) (blue) & 0xffffu) << 32) | (((uint64_t) (alpha) & 0xffffu) << 48)))
#define PLUM_COLOR_VALUE_16(red, green, blue, alpha) ((uint16_t) (((uint16_t) (red) & 0x1f) | (((uint16_t) (green) & 0x1f) << 5) | \
                                                                  (((uint16_t) (blue) & 0x1f) << 10) | (((uint16_t) (alpha) & 1) << 15)))
#define PLUM_COLOR_VALUE_32X(red, green, blue, alpha) ((uint32_t) (((uint32_t) (red) & 0x3ff) | (((uint32_t) (green) & 0x3ff) << 10) | \
                                                                   (((uint32_t) (blue) & 0x3ff) << 20) | (((uint32_t) (alpha) & 3) << 30)))

#define PLUM_RED_32(color) ((uint32_t) ((uint32_t) (color) & 0xff))
#define PLUM_RED_64(color) ((uint64_t) ((uint64_t) (color) & 0xffffu))
#define PLUM_RED_16(color) ((uint16_t) ((uint16_t) (color) & 0x1f))
#define PLUM_RED_32X(color) ((uint32_t) ((uint32_t) (color) & 0x3ff))
#define PLUM_GREEN_32(color) ((uint32_t) (((uint32_t) (color) >> 8) & 0xff))
#define PLUM_GREEN_64(color) ((uint64_t) (((uint64_t) (color) >> 16) & 0xffffu))
#define PLUM_GREEN_16(color) ((uint16_t) (((uint16_t) (color) >> 5) & 0x1f))
#define PLUM_GREEN_32X(color) ((uint32_t) (((uint32_t) (color) >> 10) & 0x3ff))
#define PLUM_BLUE_32(color) ((uint32_t) (((uint32_t) (color) >> 16) & 0xff))
#define PLUM_BLUE_64(color) ((uint64_t) (((uint64_t) (color) >> 32) & 0xffffu))
#define PLUM_BLUE_16(color) ((uint16_t) (((uint16_t) (color) >> 10) & 0x1f))
#define PLUM_BLUE_32X(color) ((uint32_t) (((uint32_t) (color) >> 20) & 0x3ff))
#define PLUM_ALPHA_32(color) ((uint32_t) (((uint32_t) (color) >> 24) & 0xff))
#define PLUM_ALPHA_64(color) ((uint64_t) (((uint64_t) (color) >> 48) & 0xffffu))
#define PLUM_ALPHA_16(color) ((uint16_t) (((uint16_t) (color) >> 15) & 1))
#define PLUM_ALPHA_32X(color) ((uint32_t) (((uint32_t) (color) >> 30) & 3))

#define PLUM_RED_MASK_32 ((uint32_t) 0xff)
#define PLUM_RED_MASK_64 ((uint64_t) 0xffffu)
#define PLUM_RED_MASK_16 ((uint16_t) 0x1f)
#define PLUM_RED_MASK_32X ((uint32_t) 0x3ff)
#define PLUM_GREEN_MASK_32 ((uint32_t) 0xff00u)
#define PLUM_GREEN_MASK_64 ((uint64_t) 0xffff0000u)
#define PLUM_GREEN_MASK_16 ((uint16_t) 0x3e0)
#define PLUM_GREEN_MASK_32X ((uint32_t) 0xffc00u)
#define PLUM_BLUE_MASK_32 ((uint32_t) 0xff0000u)
#define PLUM_BLUE_MASK_64 ((uint64_t) 0xffff00000000u)
#define PLUM_BLUE_MASK_16 ((uint16_t) 0x7c00)
#define PLUM_BLUE_MASK_32X ((uint32_t) 0x3ff00000u)
#define PLUM_ALPHA_MASK_32 ((uint32_t) 0xff000000u)
#define PLUM_ALPHA_MASK_64 ((uint64_t) 0xffff000000000000u)
#define PLUM_ALPHA_MASK_16 ((uint16_t) 0x8000u)
#define PLUM_ALPHA_MASK_32X ((uint32_t) 0xc0000000u)

#define PLUM_PIXEL_INDEX(image, col, row, frame) (((size_t) (frame) * (size_t) (image) -> height + (size_t) (row)) * (size_t) (image) -> width + (size_t) (col))

#define PLUM_PIXEL_8(image, col, row, frame) (((uint8_t *) (image) -> data)[PLUM_PIXEL_INDEX(image, col, row, frame)])
#define PLUM_PIXEL_16(image, col, row, frame) (((uint16_t *) (image) -> data)[PLUM_PIXEL_INDEX(image, col, row, frame)])
#define PLUM_PIXEL_32(image, col, row, frame) (((uint32_t *) (image) -> data)[PLUM_PIXEL_INDEX(image, col, row, frame)])
#define PLUM_PIXEL_64(image, col, row, frame) (((uint64_t *) (image) -> data)[PLUM_PIXEL_INDEX(image, col, row, frame)])

#if PLUM_VLA_SUPPORT
#define PLUM_PIXEL_ARRAY_TYPE(image) ((*)[(image) -> height][(image) -> width])
#define PLUM_PIXEL_ARRAY(declarator, image) ((* (declarator))[(image) -> height][(image) -> width])

#define PLUM_PIXELS_8(image) ((uint8_t PLUM_PIXEL_ARRAY_TYPE(image)) (image) -> data)
#define PLUM_PIXELS_16(image) ((uint16_t PLUM_PIXEL_ARRAY_TYPE(image)) (image) -> data)
#define PLUM_PIXELS_32(image) ((uint32_t PLUM_PIXEL_ARRAY_TYPE(image)) (image) -> data)
#define PLUM_PIXELS_64(image) ((uint64_t PLUM_PIXEL_ARRAY_TYPE(image)) (image) -> data)
#endif

struct plum_buffer {
  size_t size;
  void * data;
};

#ifdef __cplusplus
extern "C" /* function pointer member requires an explicit extern "C" declaration to be passed safely from C++ to C */
#endif
struct plum_callback {
  int (* callback) (void * userdata, void * buffer, int size);
  void * userdata;
};

struct plum_metadata {
  int type;
  size_t size;
  void * data;
  struct plum_metadata * next;
};

struct plum_image {
  uint16_t type;
  uint8_t max_palette_index;
  uint8_t color_format;
  uint32_t frames;
  uint32_t height;
  uint32_t width;
  void * allocator;
  struct plum_metadata * metadata;
#if PLUM_ANON_MEMBERS
  union {
#endif
    void * palette;
#if PLUM_ANON_MEMBERS
    uint16_t * palette16;
    uint32_t * palette32;
    uint64_t * palette64;
  };
  union {
#endif
    void * data;
#if PLUM_ANON_MEMBERS
    uint8_t * data8;
    uint16_t * data16;
    uint32_t * data32;
    uint64_t * data64;
  };
#endif
  void * userdata;
#ifdef __cplusplus
inline uint8_t & pixel8 (uint32_t col, uint32_t row, uint32_t frame = 0) {
  return ((uint8_t *) this -> data)[PLUM_PIXEL_INDEX(this, col, row, frame)];
}

inline const uint8_t & pixel8 (uint32_t col, uint32_t row, uint32_t frame = 0) const {
  return ((const uint8_t *) this -> data)[PLUM_PIXEL_INDEX(this, col, row, frame)];
}

inline uint16_t & pixel16 (uint32_t col, uint32_t row, uint32_t frame = 0) {
  return ((uint16_t *) this -> data)[PLUM_PIXEL_INDEX(this, col, row, frame)];
}

inline const uint16_t & pixel16 (uint32_t col, uint32_t row, uint32_t frame = 0) const {
  return ((const uint16_t *) this -> data)[PLUM_PIXEL_INDEX(this, col, row, frame)];
}

inline uint32_t & pixel32 (uint32_t col, uint32_t row, uint32_t frame = 0) {
  return ((uint32_t *) this -> data)[PLUM_PIXEL_INDEX(this, col, row, frame)];
}

inline const uint32_t & pixel32 (uint32_t col, uint32_t row, uint32_t frame = 0) const {
  return ((const uint32_t *) this -> data)[PLUM_PIXEL_INDEX(this, col, row, frame)];
}

inline uint64_t & pixel64 (uint32_t col, uint32_t row, uint32_t frame = 0) {
  return ((uint64_t *) this -> data)[PLUM_PIXEL_INDEX(this, col, row, frame)];
}

inline const uint64_t & pixel64 (uint32_t col, uint32_t row, uint32_t frame = 0) const {
  return ((const uint64_t *) this -> data)[PLUM_PIXEL_INDEX(this, col, row, frame)];
}

inline uint16_t & color16 (uint8_t index) {
  return ((uint16_t *) this -> palette)[index];
}

inline const uint16_t & color16 (uint8_t index) const {
  return ((const uint16_t *) this -> palette)[index];
}

inline uint32_t & color32 (uint8_t index) {
  return ((uint32_t *) this -> palette)[index];
}

inline const uint32_t & color32 (uint8_t index) const {
  return ((const uint32_t *) this -> palette)[index];
}

inline uint64_t & color64 (uint8_t index) {
  return ((uint64_t *) this -> palette)[index];
}

inline const uint64_t & color64 (uint8_t index) const {
  return ((const uint64_t *) this -> palette)[index];
}
#endif
};

/* keep declarations readable: redefine the "restrict" keyword, and undefine it later
   (note that, if this expands to "#define restrict restrict", that will NOT expand recursively) */
#define restrict PLUM_RESTRICT

#ifdef __cplusplus
extern "C" {
#endif

struct plum_image * plum_new_image(void);
struct plum_image * plum_copy_image(const struct plum_image * image);
void plum_destroy_image(struct plum_image * image);
struct plum_image * plum_load_image(const void * restrict buffer, size_t size_mode, unsigned flags, unsigned * restrict error);
struct plum_image * plum_load_image_limited(const void * restrict buffer, size_t size_mode, unsigned flags, size_t limit, unsigned * restrict error);
size_t plum_store_image(const struct plum_image * image, void * restrict buffer, size_t size_mode, unsigned * restrict error);
unsigned plum_validate_image(const struct plum_image * image);
const char * plum_get_error_text(unsigned error);
const char * plum_get_file_format_name(unsigned format);
uint32_t plum_get_version_number(void);
int plum_check_valid_image_size(uint32_t width, uint32_t height, uint32_t frames);
int plum_check_limited_image_size(uint32_t width, uint32_t height, uint32_t frames, size_t limit);
size_t plum_color_buffer_size(size_t size, unsigned flags);
size_t plum_pixel_buffer_size(const struct plum_image * image);
size_t plum_palette_buffer_size(const struct plum_image * image);
unsigned plum_rotate_image(struct plum_image * image, unsigned count, int flip);
void plum_convert_colors(void * restrict destination, const void * restrict source, size_t count, unsigned to, unsigned from);
uint64_t plum_convert_color(uint64_t color, unsigned from, unsigned to);
void plum_remove_alpha(struct plum_image * image);
unsigned plum_sort_palette(struct plum_image * image, unsigned flags);
unsigned plum_sort_palette_custom(struct plum_image * image, uint64_t (* callback) (void *, uint64_t), void * argument, unsigned flags);
unsigned plum_reduce_palette(struct plum_image * image);
const uint8_t * plum_validate_palette_indexes(const struct plum_image * image);
int plum_get_highest_palette_index(const struct plum_image * image);
int plum_convert_colors_to_indexes(uint8_t * restrict destination, const void * restrict source, void * restrict palette, size_t count, unsigned flags);
void plum_convert_indexes_to_colors(void * restrict destination, const uint8_t * restrict source, const void * restrict palette, size_t count, unsigned flags);
void plum_sort_colors(const void * restrict colors, uint8_t max_index, unsigned flags, uint8_t * restrict result);
void * plum_malloc(struct plum_image * image, size_t size);
void * plum_calloc(struct plum_image * image, size_t size);
void * plum_realloc(struct plum_image * image, void * buffer, size_t size);
void plum_free(struct plum_image * image, void * buffer);
struct plum_metadata * plum_allocate_metadata(struct plum_image * image, size_t size);
unsigned plum_append_metadata(struct plum_image * image, int type, const void * data, size_t size);
struct plum_metadata * plum_find_metadata(const struct plum_image * image, int type);

#ifdef __cplusplus
}
#endif

#undef restrict

/* if PLUM_UNPREFIXED_MACROS is defined, include shorter, unprefixed alternatives for some common macros */
/* this requires an explicit opt-in because it violates the principle of a library prefix as a namespace */
#ifdef PLUM_UNPREFIXED_MACROS
#define PIXEL(image, col, row, frame) PLUM_PIXEL_INDEX(image, col, row, frame)

#define PIXEL8(image, col, row, frame) PLUM_PIXEL_8(image, col, row, frame)
#define PIXEL16(image, col, row, frame) PLUM_PIXEL_16(image, col, row, frame)
#define PIXEL32(image, col, row, frame) PLUM_PIXEL_32(image, col, row, frame)
#define PIXEL64(image, col, row, frame) PLUM_PIXEL_64(image, col, row, frame)

#if PLUM_VLA_SUPPORT
#define PIXARRAY_T(image) PLUM_PIXEL_ARRAY_TYPE(image)
#define PIXARRAY(declarator, image) PLUM_PIXEL_ARRAY(declarator, image)

#define PIXELS8(image) PLUM_PIXELS_8(image)
#define PIXELS16(image) PLUM_PIXELS_16(image)
#define PIXELS32(image) PLUM_PIXELS_32(image)
#define PIXELS64(image) PLUM_PIXELS_64(image)
#endif

#define COLOR32(red, green, blue, alpha) PLUM_COLOR_VALUE_32(red, green, blue, alpha)
#define COLOR64(red, green, blue, alpha) PLUM_COLOR_VALUE_64(red, green, blue, alpha)
#define COLOR16(red, green, blue, alpha) PLUM_COLOR_VALUE_16(red, green, blue, alpha)
#define COLOR32X(red, green, blue, alpha) PLUM_COLOR_VALUE_32X(red, green, blue, alpha)

#define RED32(color) PLUM_RED_32(color)
#define RED64(color) PLUM_RED_64(color)
#define RED16(color) PLUM_RED_16(color)
#define RED32X(color) PLUM_RED_32X(color)
#define GREEN32(color) PLUM_GREEN_32(color)
#define GREEN64(color) PLUM_GREEN_64(color)
#define GREEN16(color) PLUM_GREEN_16(color)
#define GREEN32X(color) PLUM_GREEN_32X(color)
#define BLUE32(color) PLUM_BLUE_32(color)
#define BLUE64(color) PLUM_BLUE_64(color)
#define BLUE16(color) PLUM_BLUE_16(color)
#define BLUE32X(color) PLUM_BLUE_32X(color)
#define ALPHA32(color) PLUM_ALPHA_32(color)
#define ALPHA64(color) PLUM_ALPHA_64(color)
#define ALPHA16(color) PLUM_ALPHA_16(color)
#define ALPHA32X(color) PLUM_ALPHA_32X(color)
#endif

#endif

#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <setjmp.h>


union allocator_node {
  max_align_t alignment;
  struct {
    union allocator_node * previous;
    union allocator_node * next;
  };
};

struct data_node {
  union {
    struct {
      size_t size;
      struct data_node * previous;
      struct data_node * next;
    };
    max_align_t alignment;
  };
  unsigned char data[];
};

struct context {
  unsigned status;
  size_t size;
  union {
    const unsigned char * data;
    struct data_node * output; // reverse order: top of the list is the LAST node
  };
  union allocator_node * allocator;
  union {
    struct plum_image * image;
    const struct plum_image * source;
  };
  FILE * file;
  jmp_buf target;
};

struct compressed_GIF_code {
  alignas(uint32_t) int16_t reference; // align the first member to align the struct
  unsigned char value;
  unsigned char type;
};

struct PNG_chunk_locations {
  // includes APNG chunks; IHDR and IEND omitted because IHDR has a fixed offset and IEND contains no data
  size_t palette; // PLTE
  size_t bits; // sBIT
  size_t background; // bKGD
  size_t transparency; // tRNS
  size_t animation; // acTL
  size_t * data; // IDAT
  size_t * frameinfo; // fcTL
  size_t ** framedata; // fdAT
};

struct compressed_PNG_code {
  unsigned datacode:   9;
  unsigned dataextra:  5;
  unsigned distcode:   5;
  unsigned distextra: 13;
};

struct JPEG_marker_layout {
  unsigned char * frametype; // 0-15
  size_t * frames;
  size_t ** framescans;
  size_t *** framedata; // for each frame, for each scan, for each restart interval: offset, size
  unsigned char * markertype; // same as the follow-up byte from the marker itself
  size_t * markers; // for some markers only (DHT, DAC, DQT, DNL, DRI, EXP)
  size_t hierarchical; // DHP marker, if present
  size_t JFIF;
  size_t Exif;
  size_t Adobe;
};

struct JPEG_decoder_tables {
  short * Huffman[8]; // 4 DC, 4 AC
  unsigned short * quantization[4];
  unsigned char arithmetic[8]; // conditioning values: 4 DC, 4 AC
  uint16_t restart;
};

struct JPEG_component_info {
  unsigned index:   8;
  unsigned tableQ:  8;
  unsigned tableDC: 4;
  unsigned tableAC: 4;
  unsigned scaleH:  4;
  unsigned scaleV:  4;
};

struct JPEG_decompressor_state {
  union {
    int16_t (* restrict current_block[4])[64];
    uint16_t * restrict current_value[4];
  };
  size_t last_size;
  size_t restart_count;
  uint16_t row_skip_index;
  uint16_t row_skip_count;
  uint16_t column_skip_index;
  uint16_t column_skip_count;
  uint16_t row_offset[4];
  uint16_t unit_row_offset[4];
  uint8_t unit_offset[4];
  uint16_t restart_size;
  unsigned char component_count;
  unsigned char MCU[81];
};

enum JPEG_MCU_control_codes {
  MCU_ZERO_COORD = 0xfd,
  MCU_NEXT_ROW   = 0xfe,
  MCU_END_LIST   = 0xff
};

struct JPEG_arithmetic_decoder_state {
  unsigned probability: 15;
  bool switch_MPS:       1;
  unsigned next_MPS:     8;
  unsigned next_LPS:     8;
};

struct JPEG_encoded_value {
  unsigned code:   8;
  unsigned type:   1; // 0 for DC codes, 1 for AC codes
  unsigned bits:   7;
  unsigned value: 16;
};

struct PNM_image_header {
  uint8_t type; // 1-6: PNM header types, 7: unknown PAM, 11-13: PAM without alpha (B/W, grayscale, RGB), 14-16: PAM with alpha
  uint16_t maxvalue;
  uint32_t width;
  uint32_t height;
  size_t datastart;
  size_t datalength;
};

#include <stddef.h>
#include <stdint.h>


// JPEG block coordinates in zig-zag order (mapping cell indexes to (x, y) coordinates)
static const alignas(max_align_t) uint8_t JPEG_zigzag_rows[] = {
  0, 0, 1, 2, 1, 0, 0, 1, 2, 3, 4, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1, 0, 0, 1, 2, 3,
  4, 5, 6, 7, 7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3, 4, 5, 6, 7, 7, 6, 5, 6, 7, 7
};
static const alignas(max_align_t) uint8_t JPEG_zigzag_columns[] = {
  0, 1, 0, 0, 1, 2, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4,
  3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 5, 6, 7, 7, 6, 7
};

// code lengths for default Huffman table used by PNG compression (entries 0x000 - 0x11f: data and length tree; entries 0x120 - 0x13f: distance tree)
static const uint8_t default_PNG_Huffman_table_lengths[] = {
   //         00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
   /* 0x000 */ 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
   /* 0x020 */ 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
   /* 0x040 */ 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
   /* 0x060 */ 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
   /* 0x080 */ 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
   /* 0x0a0 */ 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
   /* 0x0c0 */ 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
   /* 0x0e0 */ 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
   /* 0x100 */ 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8,
   /* 0x120 */ 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
};

// bitmasks used to extract the alpha channel out of a color value for each color format
static const uint64_t alpha_component_masks[] = {0xff000000u, 0xffff000000000000u, 0x8000u, 0xc0000000u};

// start and step for each interlace pass for interlaced PNG images; vertical coordinates use entries 0-6 and horizontal coordinates use entries 1-7
static const uint8_t interlaced_PNG_pass_start[] = {0, 0, 4, 0, 2, 0, 1, 0};
static const uint8_t interlaced_PNG_pass_step[] = {8, 8, 8, 4, 4, 2, 2, 1};

// bytes per channel for each image type that the PNG writer can generate; 0 indicates that pixels are bitpacked (less than one byte per pixel)
static const uint8_t bytes_per_channel_PNG[] = {0, 0, 0, 1, 3, 4, 6, 8};

// encoding/decoding parameters for the PNG compressor; the base length and distance arrays contain one extra entry (with a value out of range)
static const uint16_t compressed_PNG_base_lengths[] = {
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258, 259
};
static const uint16_t compressed_PNG_base_distances[] = {
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577, 32769
};
static const uint8_t compressed_PNG_length_bits[] = {0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0};
static const uint8_t compressed_PNG_distance_bits[] = {0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13};
static const uint8_t compressed_PNG_code_table_order[] = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15};

// number of channels per pixel that a PNG image has, based on its image type (as encoded in its header); 0 = invalid
static const uint8_t channels_per_pixel_PNG[] = {1, 0, 3, 1, 2, 0, 4};

#include <stdint.h>

static inline uint16_t read_le16_unaligned (const unsigned char * data) {
  return (uint16_t) *data | ((uint16_t) data[1] << 8);
}

static inline uint32_t read_le32_unaligned (const unsigned char * data) {
  return (uint32_t) *data | ((uint32_t) data[1] << 8) | ((uint32_t) data[2] << 16) | ((uint32_t) data[3] << 24);
}

static inline uint16_t read_be16_unaligned (const unsigned char * data) {
  return (uint16_t) data[1] | ((uint16_t) *data << 8);
}

static inline uint32_t read_be32_unaligned (const unsigned char * data) {
  return (uint32_t) data[3] | ((uint32_t) data[2] << 8) | ((uint32_t) data[1] << 16) | ((uint32_t) *data << 24);
}

static inline void write_le16_unaligned (unsigned char * restrict buffer, uint16_t value) {
  bytewrite(buffer, value, value >> 8);
}

static inline void write_le32_unaligned (unsigned char * restrict buffer, uint32_t value) {
  bytewrite(buffer, value, value >> 8, value >> 16, value >> 24);
}

static inline void write_be16_unaligned (unsigned char * restrict buffer, uint32_t value) {
  bytewrite(buffer, value >> 8, value);
}

static inline void write_be32_unaligned (unsigned char * restrict buffer, uint32_t value) {
  bytewrite(buffer, value >> 24, value >> 16, value >> 8, value);
}

// allocator.c
internal void * attach_allocator_node(union allocator_node **, union allocator_node *);
internal void * allocate(union allocator_node **, size_t);
internal void * clear_allocate(union allocator_node **, size_t);
internal void deallocate(union allocator_node **, void *);
internal void * reallocate(union allocator_node **, void *, size_t);
internal void destroy_allocator_list(union allocator_node *);

// bmpread.c
internal void load_BMP_data(struct context *, unsigned, size_t);
internal uint8_t load_BMP_palette(struct context *, size_t, unsigned, uint64_t * restrict);
internal void load_BMP_bitmasks(struct context *, size_t, uint8_t * restrict, unsigned);
internal uint8_t * load_monochrome_BMP(struct context *, size_t, bool);
internal uint8_t * load_halfbyte_BMP(struct context *, size_t, bool);
internal uint8_t * load_byte_BMP(struct context *, size_t, bool);
internal uint8_t * load_halfbyte_compressed_BMP(struct context *, size_t, bool);
internal uint8_t * load_byte_compressed_BMP(struct context *, size_t, bool);
internal uint64_t * load_BMP_pixels(struct context *, size_t, bool, size_t, uint64_t (*) (const unsigned char *, const void *), const void *);
internal uint64_t load_BMP_halfword_pixel(const unsigned char *, const void *);
internal uint64_t load_BMP_word_pixel(const unsigned char *, const void *);
internal uint64_t load_BMP_RGB_pixel(const unsigned char *, const void *);
internal uint64_t load_BMP_bitmasked_pixel(uint_fast32_t, const uint8_t *);

// bmpwrite.c
internal void generate_BMP_data(struct context *);
internal void generate_BMP_bitmasked_data(struct context *, uint32_t, unsigned char *);
internal void generate_BMP_palette_halfbyte_data(struct context *, unsigned char *);
internal void generate_BMP_palette_byte_data(struct context *, unsigned char *);
internal size_t try_compress_BMP(struct context *, size_t, size_t (*) (uint8_t * restrict, const uint8_t * restrict, size_t));
internal size_t compress_BMP_halfbyte_row(uint8_t * restrict, const uint8_t * restrict, size_t);
internal unsigned emit_BMP_compressed_halfbyte_remainder(uint8_t * restrict, const uint8_t * restrict, unsigned);
internal size_t compress_BMP_byte_row(uint8_t * restrict, const uint8_t * restrict, size_t);
internal void append_BMP_palette(struct context *);
internal void generate_BMP_RGB_data(struct context *, unsigned char *);

// checksum.c
internal uint32_t compute_PNG_CRC(const unsigned char *, size_t);
internal uint32_t compute_Adler32_checksum(const unsigned char *, size_t);

// color.c
internal bool image_has_transparency(const struct plum_image *);
internal uint32_t get_true_color_depth(const struct plum_image *);

// framebuffer.c
internal void validate_image_size(struct context *, size_t);
internal void allocate_framebuffers(struct context *, unsigned, bool);
internal void write_framebuffer_to_image(struct plum_image *, const uint64_t * restrict, uint32_t, unsigned);
internal void write_palette_framebuffer_to_image(struct context *, const uint8_t * restrict, const uint64_t * restrict, uint32_t, unsigned, uint8_t);
internal void write_palette_to_image(struct context *, const uint64_t * restrict, unsigned);
internal void rotate_frame_8(uint8_t * restrict, uint8_t * restrict, size_t, size_t, size_t (*) (size_t, size_t, size_t, size_t));
internal void rotate_frame_16(uint16_t * restrict, uint16_t * restrict, size_t, size_t, size_t (*) (size_t, size_t, size_t, size_t));
internal void rotate_frame_32(uint32_t * restrict, uint32_t * restrict, size_t, size_t, size_t (*) (size_t, size_t, size_t, size_t));
internal void rotate_frame_64(uint64_t * restrict, uint64_t * restrict, size_t, size_t, size_t (*) (size_t, size_t, size_t, size_t));
internal size_t rotate_left_coordinate(size_t, size_t, size_t, size_t);
internal size_t rotate_right_coordinate(size_t, size_t, size_t, size_t);
internal size_t rotate_both_coordinate(size_t, size_t, size_t, size_t);
internal size_t flip_coordinate(size_t, size_t, size_t, size_t);
internal size_t rotate_left_flip_coordinate(size_t, size_t, size_t, size_t);
internal size_t rotate_right_flip_coordinate(size_t, size_t, size_t, size_t);
internal size_t rotate_both_flip_coordinate(size_t, size_t, size_t, size_t);

// frameduration.c
internal uint64_t adjust_frame_duration(uint64_t, int64_t * restrict);
internal void update_frame_duration_remainder(uint64_t, uint64_t, int64_t * restrict);
internal void calculate_frame_duration_fraction(uint64_t, uint32_t, uint32_t * restrict, uint32_t * restrict);

// gifcompress.c
internal unsigned char * compress_GIF_data(struct context *, const unsigned char * restrict, size_t, size_t *, unsigned);
internal void decompress_GIF_data(struct context *, unsigned char * restrict, const unsigned char * restrict, size_t, size_t, unsigned);
internal void initialize_GIF_compression_codes(struct compressed_GIF_code * restrict, unsigned);
internal uint8_t find_leading_GIF_code(const struct compressed_GIF_code * restrict, unsigned);
internal void emit_GIF_data(struct context *, const struct compressed_GIF_code * restrict, unsigned, unsigned char **, unsigned char *);

// gifread.c
internal void load_GIF_data(struct context *, unsigned, size_t);
internal uint64_t ** load_GIF_palettes_and_frame_count(struct context *, unsigned, size_t * restrict, uint64_t * restrict);
internal void load_GIF_palette(struct context *, uint64_t * restrict, size_t * restrict, unsigned);
internal void * load_GIF_data_blocks(struct context *, size_t * restrict, size_t * restrict);
internal void skip_GIF_data_blocks(struct context *, size_t * restrict);
internal void load_GIF_frame(struct context *, size_t * restrict, unsigned, uint32_t, const uint64_t * restrict, uint64_t, uint64_t * restrict, uint8_t * restrict);

// gifwrite.c
internal void generate_GIF_data(struct context *);
internal void generate_GIF_data_with_palette(struct context *, unsigned char *);
internal void generate_GIF_data_from_raw(struct context *, unsigned char *);
internal void generate_GIF_frame_data(struct context *, uint32_t * restrict, unsigned char * restrict, uint32_t, const struct plum_metadata *,
                                      const struct plum_metadata *, int64_t * restrict);
internal int_fast32_t get_GIF_background_color(struct context *);
internal void write_GIF_palette(struct context *, const uint32_t * restrict, unsigned);
internal void write_GIF_loop_info(struct context *);
internal void write_GIF_frame(struct context *, const unsigned char * restrict, const uint32_t * restrict, unsigned, int, uint32_t, unsigned, unsigned, unsigned,
                              unsigned, const struct plum_metadata *, const struct plum_metadata *, int64_t * restrict);
internal void write_GIF_data_blocks(struct context *, const unsigned char * restrict, size_t);

// huffman.c
internal void generate_Huffman_tree(struct context *, const size_t * restrict, unsigned char * restrict, size_t, unsigned char);
internal void generate_Huffman_codes(unsigned short * restrict, size_t, const unsigned char * restrict, bool);

// jpegarithmetic.c
internal void decompress_JPEG_arithmetic_scan(struct context *, struct JPEG_decompressor_state * restrict, const struct JPEG_decoder_tables *, size_t,
                                              const struct JPEG_component_info *, const size_t * restrict, unsigned, unsigned char, unsigned char, bool);
internal void decompress_JPEG_arithmetic_bit_scan(struct context *, struct JPEG_decompressor_state * restrict, size_t, const struct JPEG_component_info *,
                                                  const size_t * restrict, unsigned, unsigned char, unsigned char);
internal void decompress_JPEG_arithmetic_lossless_scan(struct context *, struct JPEG_decompressor_state * restrict, const struct JPEG_decoder_tables *, size_t,
                                                       const struct JPEG_component_info *, const size_t * restrict, unsigned char, unsigned);
internal void initialize_JPEG_arithmetic_counters(struct context *, size_t * restrict, size_t * restrict, uint32_t * restrict);
internal int16_t next_JPEG_arithmetic_value(struct context *, size_t * restrict, size_t * restrict, uint32_t * restrict, uint16_t * restrict,
                                            unsigned char * restrict, signed char * restrict, unsigned, unsigned, unsigned char);
internal unsigned char classify_JPEG_arithmetic_value(uint16_t, unsigned char);
internal bool next_JPEG_arithmetic_bit(struct context *, size_t * restrict, size_t * restrict, signed char * restrict, uint32_t * restrict, uint16_t * restrict,
                                       unsigned char * restrict);

// jpegcomponents.c
internal uint32_t determine_JPEG_components(struct context *, size_t);
internal unsigned get_JPEG_component_count(uint32_t);
internal void (* get_JPEG_component_transfer_function(struct context *, const struct JPEG_marker_layout *, uint32_t))
               (uint64_t * restrict, size_t, unsigned, const double **);
internal void append_JPEG_color_depth_metadata(struct context *, void (*) (uint64_t * restrict, size_t, unsigned, const double **), unsigned);
internal void JPEG_transfer_RGB(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_BGR(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_ABGR(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_grayscale(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_alpha_grayscale(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_YCbCr(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_CbYCr(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_YCbCrK(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_CbKYCr(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_ACbYCr(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_CMYK(uint64_t * restrict, size_t, unsigned, const double **);
internal void JPEG_transfer_CKMY(uint64_t * restrict, size_t, unsigned, const double **);

// jpegcompress.c
internal struct JPEG_encoded_value * generate_JPEG_luminance_data_stream(struct context *, double (* restrict)[64], size_t, const uint8_t [restrict static 64],
                                                                         size_t * restrict);
internal struct JPEG_encoded_value * generate_JPEG_chrominance_data_stream(struct context *, double (* restrict)[64], double (* restrict)[64], size_t,
                                                                           const uint8_t [restrict static 64], size_t * restrict);
internal double generate_JPEG_data_unit(struct JPEG_encoded_value *, size_t * restrict, const double [restrict static 64], const uint8_t [restrict static 64],
                                        double);
internal void encode_JPEG_value(struct JPEG_encoded_value *, int16_t, unsigned, unsigned char);
internal size_t generate_JPEG_Huffman_table(struct context *, const struct JPEG_encoded_value *, size_t, unsigned char * restrict,
                                            unsigned char [restrict static 0x100], unsigned char);
internal void encode_JPEG_scan(struct context *, const struct JPEG_encoded_value *, size_t, const unsigned char [restrict static 0x200]);

// jpegdct.c
internal double apply_JPEG_DCT(int16_t [restrict static 64], const double [restrict static 64], const uint8_t [restrict static 64], double);
internal void apply_JPEG_inverse_DCT(double [restrict static 64], const int16_t [restrict static 64], const uint16_t [restrict static 64]);

// jpegdecompress.c
internal void initialize_JPEG_decompressor_state(struct context *, struct JPEG_decompressor_state * restrict, const struct JPEG_component_info *,
                                                 const unsigned char *, size_t * restrict, size_t, size_t, size_t, unsigned char, unsigned char,
                                                 const struct JPEG_decoder_tables *, const size_t * restrict, int16_t (* restrict *)[64]);
internal void initialize_JPEG_decompressor_state_lossless(struct context *, struct JPEG_decompressor_state * restrict, const struct JPEG_component_info *,
                                                          const unsigned char *, size_t * restrict, size_t, size_t, size_t, unsigned char, unsigned char,
                                                          const struct JPEG_decoder_tables *, const size_t * restrict, uint16_t * restrict *);
internal void initialize_JPEG_decompressor_state_common(struct context *, struct JPEG_decompressor_state * restrict, const struct JPEG_component_info *,
                                                        const unsigned char *, size_t * restrict, size_t, size_t, size_t, unsigned char, unsigned char,
                                                        const struct JPEG_decoder_tables *, const size_t * restrict, unsigned char);
internal uint16_t predict_JPEG_lossless_sample(const uint16_t *, ptrdiff_t, bool, bool, unsigned, unsigned);

// jpeghierarchical.c
internal unsigned load_hierarchical_JPEG(struct context *, const struct JPEG_marker_layout *, uint32_t, double **);
internal void expand_JPEG_component_horizontally(struct context *, double * restrict, size_t, size_t, size_t, double * restrict);
internal void expand_JPEG_component_vertically(struct context *, double * restrict, size_t, size_t, size_t, double * restrict);
internal void normalize_JPEG_component(double * restrict, size_t, double);

// jpeghuffman.c
internal void decompress_JPEG_Huffman_scan(struct context *, struct JPEG_decompressor_state * restrict, const struct JPEG_decoder_tables *, size_t,
                                           const struct JPEG_component_info *, const size_t * restrict, unsigned, unsigned char, unsigned char, bool);
internal void decompress_JPEG_Huffman_bit_scan(struct context *, struct JPEG_decompressor_state * restrict, const struct JPEG_decoder_tables *, size_t,
                                               const struct JPEG_component_info *, const size_t * restrict, unsigned, unsigned char, unsigned char);
internal void decompress_JPEG_Huffman_lossless_scan(struct context *, struct JPEG_decompressor_state * restrict, const struct JPEG_decoder_tables *, size_t,
                                                    const struct JPEG_component_info *, const size_t * restrict, unsigned char, unsigned);
internal unsigned char next_JPEG_Huffman_value(struct context *, const unsigned char **, size_t * restrict, uint32_t * restrict, uint8_t * restrict,
                                               const short * restrict);

// jpegread.c
internal void load_JPEG_data(struct context *, unsigned, size_t);
internal struct JPEG_marker_layout * load_JPEG_marker_layout(struct context *);
internal unsigned get_JPEG_rotation(struct context *, size_t);
internal unsigned load_single_frame_JPEG(struct context *, const struct JPEG_marker_layout *, uint32_t, double **);
internal unsigned char process_JPEG_metadata_until_offset(struct context *, const struct JPEG_marker_layout *, struct JPEG_decoder_tables *, size_t * restrict,
                                                          size_t);

// jpegreadframe.c
internal void load_JPEG_DCT_frame(struct context *, const struct JPEG_marker_layout *, uint32_t, size_t, struct JPEG_decoder_tables *, size_t * restrict,
                                  double **, unsigned, size_t, size_t);
internal void load_JPEG_lossless_frame(struct context *, const struct JPEG_marker_layout *, uint32_t, size_t, struct JPEG_decoder_tables *, size_t * restrict,
                                       double **, unsigned, size_t, size_t);
internal unsigned get_JPEG_component_info(struct context *, const unsigned char *, struct JPEG_component_info * restrict, uint32_t);
internal const unsigned char * get_JPEG_scan_components(struct context *, size_t, struct JPEG_component_info * restrict, unsigned, unsigned char * restrict);
internal void unpack_JPEG_component(double * restrict, double * restrict, size_t, size_t, size_t, size_t, unsigned char, unsigned char, unsigned char,
                                    unsigned char);

// jpegtables.c
internal void initialize_JPEG_decoder_tables(struct context *, struct JPEG_decoder_tables *, const struct JPEG_marker_layout *);
internal short * process_JPEG_Huffman_table(struct context *, const unsigned char ** restrict, uint16_t * restrict);
internal void load_default_JPEG_Huffman_tables(struct context *, struct JPEG_decoder_tables * restrict);

// jpegwrite.c
internal void generate_JPEG_data(struct context *);
internal void calculate_JPEG_quantization_tables(struct context *, uint8_t [restrict static 64], uint8_t [restrict static 64]);
internal void convert_JPEG_components_to_YCbCr(struct context *, double (* restrict)[64], double (* restrict)[64], double (* restrict)[64]);
internal void convert_JPEG_colors_to_YCbCr(const void * restrict, size_t, unsigned char, double * restrict, double * restrict, double * restrict,
                                           uint64_t * restrict);
internal void subsample_JPEG_component(double (* restrict)[64], double (* restrict)[64], size_t, size_t);

// load.c
internal void load_image_buffer_data(struct context *, unsigned, size_t);
internal void prepare_image_buffer_data(struct context *, const void * restrict, size_t);
internal void load_file(struct context *, const char *);
internal void load_from_callback(struct context *, const struct plum_callback *);
internal void * resize_read_buffer(struct context *, void *, size_t * restrict);
internal void update_loaded_palette(struct context *, unsigned);

// metadata.c
internal void add_color_depth_metadata(struct context *, unsigned, unsigned, unsigned, unsigned, unsigned);
internal void add_background_color_metadata(struct context *, uint64_t, unsigned);
internal void add_loop_count_metadata(struct context *, uint32_t);
internal void add_animation_metadata(struct context *, uint64_t ** restrict, uint8_t ** restrict);
internal uint64_t get_background_color(const struct plum_image *, uint64_t);

// misc.c
internal int compare64(const void *, const void *);
internal int compare_index_value_pairs(const void *, const void *);

// newstruct.c
internal struct context * create_context(void);

// palette.c
internal void generate_palette(struct context *, unsigned);
internal void remove_palette(struct context *);
internal void sort_palette(struct plum_image *, unsigned);
internal void apply_sorted_palette(struct plum_image *, unsigned, const uint8_t *);
internal void reduce_palette(struct plum_image *);
internal unsigned check_image_palette(const struct plum_image *);
internal uint64_t get_color_sorting_score(uint64_t, unsigned);

// pngcompress.c
internal unsigned char * compress_PNG_data(struct context *, const unsigned char * restrict, size_t, size_t, size_t * restrict);
internal struct compressed_PNG_code * generate_compressed_PNG_block(struct context *, const unsigned char * restrict, size_t, size_t, uint16_t * restrict,
                                                                    size_t * restrict, size_t * restrict, bool);
internal size_t compute_uncompressed_PNG_block_size(const unsigned char * restrict, size_t, size_t, uint16_t * restrict);
internal unsigned find_PNG_reference(const unsigned char * restrict, const uint16_t * restrict, size_t, size_t, size_t * restrict);
internal void append_PNG_reference(const unsigned char * restrict, size_t, uint16_t * restrict);
internal uint16_t compute_PNG_reference_key(const unsigned char * data);
internal void emit_PNG_code(struct context *, struct compressed_PNG_code **, size_t * restrict, size_t * restrict, int, unsigned);
internal unsigned char * emit_PNG_compressed_block(struct context *, const struct compressed_PNG_code * restrict, size_t, bool, size_t * restrict,
                                                   uint32_t * restrict, uint8_t * restrict);
internal unsigned char * generate_PNG_Huffman_trees(struct context *, uint32_t * restrict, uint8_t * restrict, size_t * restrict,
                                                    const size_t [restrict static 0x120], const size_t [restrict static 0x20],
                                                    unsigned char [restrict static 0x120], unsigned char [restrict static 0x20]);

// pngdecompress.c
internal void * decompress_PNG_data(struct context *, const unsigned char *, size_t, size_t);
internal void extract_PNG_code_table(struct context *, const unsigned char **, size_t * restrict, unsigned char [restrict static 0x140], uint32_t * restrict,
                                     uint8_t * restrict);
internal void decompress_PNG_block(struct context *, const unsigned char **, unsigned char * restrict, size_t * restrict, size_t * restrict, size_t,
                                   uint32_t * restrict, uint8_t * restrict, const unsigned char [restrict static 0x140]);
internal short * decode_PNG_Huffman_tree(struct context *, const unsigned char *, unsigned);
internal uint16_t next_PNG_Huffman_code(struct context *, const short * restrict, const unsigned char **, size_t * restrict, uint32_t * restrict,
                                        uint8_t * restrict);

// pngread.c
internal void load_PNG_data(struct context *, unsigned, size_t);
internal struct PNG_chunk_locations * load_PNG_chunk_locations(struct context *);
internal void append_PNG_chunk_location(struct context *, size_t **, size_t, size_t * restrict);
internal void sort_PNG_animation_chunks(struct context *, struct PNG_chunk_locations * restrict, const size_t * restrict, size_t, size_t);
internal uint8_t load_PNG_palette(struct context *, const struct PNG_chunk_locations * restrict, uint8_t, uint64_t * restrict);
internal void add_PNG_bit_depth_metadata(struct context *, const struct PNG_chunk_locations *, uint8_t, uint8_t);
internal uint64_t add_PNG_background_metadata(struct context *, const struct PNG_chunk_locations *, const uint64_t *, uint8_t, uint8_t, uint8_t, unsigned);
internal uint64_t load_PNG_transparent_color(struct context *, size_t, uint8_t, uint8_t);
internal bool check_PNG_reduced_frames(struct context *, const struct PNG_chunk_locations *);
internal bool load_PNG_animation_frame_metadata(struct context *, size_t, uint64_t * restrict, uint8_t * restrict);

// pngreadframe.c
internal void load_PNG_frame(struct context *, const size_t *, uint32_t, const uint64_t *, uint8_t, uint8_t, uint8_t, bool, uint64_t, uint64_t);
internal void * load_PNG_frame_part(struct context *, const size_t *, int, uint8_t, uint8_t, bool, uint32_t, uint32_t, size_t);
internal uint8_t * load_PNG_palette_frame(struct context *, const void *, size_t, uint32_t, uint32_t, uint8_t, uint8_t, bool);
internal uint64_t * load_PNG_raw_frame(struct context *, const void *, size_t, uint32_t, uint32_t, uint8_t, uint8_t, bool);
internal void load_PNG_raw_frame_pass(struct context *, unsigned char * restrict, uint64_t * restrict, uint32_t, uint32_t, uint32_t, uint8_t, uint8_t,
                                      unsigned char, unsigned char, unsigned char, unsigned char, size_t);
internal void expand_bitpacked_PNG_data(unsigned char * restrict, const unsigned char * restrict, size_t, uint8_t);
internal void remove_PNG_filter(struct context *, unsigned char * restrict, uint32_t, uint32_t, uint8_t, uint8_t);

// pngwrite.c
internal void generate_PNG_data(struct context *);
internal void generate_APNG_data(struct context *);
internal unsigned generate_PNG_header(struct context *);
internal void append_PNG_header_chunks(struct context *, unsigned, uint32_t);
internal void append_PNG_palette_data(struct context *, bool);
internal void append_PNG_background_chunk(struct context *, const void * restrict, unsigned);
internal void append_PNG_image_data(struct context *, const void * restrict, unsigned, uint32_t * restrict);
internal void append_APNG_frame_header(struct context *, uint64_t, uint8_t, uint8_t, uint32_t * restrict, int64_t * restrict);
internal void output_PNG_chunk(struct context *, uint32_t, uint32_t, const void * restrict);
internal unsigned char * generate_PNG_frame_data(struct context *, const void * restrict, unsigned, size_t * restrict);
internal void generate_PNG_row_data(struct context *, const void * restrict, unsigned char * restrict, unsigned);
internal void filter_PNG_rows(unsigned char * restrict, const unsigned char * restrict, size_t, unsigned);
internal unsigned char select_PNG_filtered_row(const unsigned char *, size_t);

// pnmread.c
internal void load_PNM_data(struct context *, unsigned, size_t);
internal void load_PNM_header(struct context *, size_t, struct PNM_image_header * restrict);
internal void load_PAM_header(struct context *, size_t, struct PNM_image_header * restrict);
internal void skip_PNM_whitespace(struct context *, size_t * restrict);
internal void skip_PNM_line(struct context *, size_t * restrict);
internal unsigned next_PNM_token_length(struct context *, size_t);
internal void read_PNM_numbers(struct context *, size_t * restrict, uint32_t * restrict, size_t);
internal void add_PNM_bit_depth_metadata(struct context *, const struct PNM_image_header *);
internal void load_PNM_frame(struct context *, const struct PNM_image_header * restrict, uint64_t * restrict);
internal void load_PNM_bit_frame(struct context *, size_t, size_t, size_t, uint64_t * restrict);

// pnmwrite.c
internal void generate_PNM_data(struct context *);
internal uint32_t * get_true_PNM_frame_sizes(struct context *);
internal void generate_PPM_data(struct context *, const uint32_t * restrict, unsigned, uint64_t * restrict);
internal void generate_PPM_header(struct context *, uint32_t, uint32_t, unsigned);
internal void generate_PAM_data(struct context *, unsigned, uint64_t * restrict);
internal void generate_PAM_header(struct context *, unsigned);
internal size_t write_PNM_number(unsigned char * restrict, uint32_t);
internal void generate_PNM_frame_data(struct context *, const uint64_t *, uint32_t, uint32_t, unsigned, bool);
internal void generate_PNM_frame_data_from_palette(struct context *, const uint8_t *, const uint64_t *, uint32_t, uint32_t, unsigned, bool);

// store.c
internal void write_generated_image_data_to_file(struct context *, const char *);
internal void write_generated_image_data_to_callback(struct context *, const struct plum_callback *);
internal void write_generated_image_data(void * restrict, const struct data_node *);
internal size_t get_total_output_size(struct context *);

static inline noreturn throw (struct context * context, unsigned error) {
  context -> status = error;
  longjmp(context -> target, 1);
}

static inline void * ctxmalloc (struct context * context, size_t size) {
  void * result = allocate(&(context -> allocator), size);
  if (!result) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  return result;
}

static inline void * ctxcalloc (struct context * context, size_t size) {
  void * result = clear_allocate(&(context -> allocator), size);
  if (!result) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  return result;
}

static inline void * ctxrealloc (struct context * context, void * buffer, size_t size) {
  void * result = reallocate(&(context -> allocator), buffer, size);
  if (!result) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  return result;
}

static inline void ctxfree (struct context * context, void * buffer) {
  deallocate(&(context -> allocator), buffer);
}

static inline uintmax_t bitnegate (uintmax_t value) {
  // ensure that the value is negated correctly, without accidental unsigned-to-signed conversions getting in the way
  return ~value;
}

static inline uint16_t bitextend16 (uint16_t value, unsigned width) {
  uint_fast32_t result = value;
  while (width < 16) {
    result |= result << width;
    width <<= 1;
  }
  return result >> (width - 16);
}

static inline void * append_output_node (struct context * context, size_t size) {
  struct data_node * node = ctxmalloc(context, sizeof *node + size);
  *node = (struct data_node) {.size = size, .previous = context -> output, .next = NULL};
  if (context -> output) context -> output -> next = node;
  context -> output = node;
  return node -> data;
}

static inline bool bit_depth_less_than (uint32_t depth, uint32_t target) {
  // formally "less than or equal to", but that would be a very long name
  return !((target - depth) & 0x80808080u);
}

static inline int absolute_value (int value) {
  return (value < 0) ? -value : value;
}

static inline uint32_t shift_in_left (struct context * context, unsigned count, uint32_t * restrict dataword, uint8_t * restrict bits,
                                      const unsigned char ** data, size_t * restrict size) {
  while (*bits < count) {
    if (!*size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    *dataword |= (uint32_t) **data << *bits;
    ++ *data;
    -- *size;
    *bits += 8;
  }
  uint32_t result;
  if (count < 32) {
    result = *dataword & (((uint32_t) 1 << count) - 1);
    *dataword >>= count;
  } else {
    result = *dataword;
    *dataword = 0;
  }
  *bits -= count;
  return result;
}

static inline uint32_t shift_in_right_JPEG (struct context * context, unsigned count, uint32_t * restrict dataword, uint8_t * restrict bits,
                                            const unsigned char ** data, size_t * restrict size) {
  // unlike shift_in_left above, this function has to account for stuffed bytes (any number of 0xFF followed by a single 0x00)
  while (*bits < count) {
    if (!*size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    *dataword = (*dataword << 8) | **data;
    *bits += 8;
    while (**data == 0xff) {
      ++ *data;
      -- *size;
      if (!*size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
    ++ *data;
    -- *size;
  }
  *bits -= count;
  uint32_t result = *dataword >> *bits;
  *dataword &= ((uint32_t) 1 << *bits) - 1;
  return result;
}

static inline uint64_t color_from_floats (double red, double green, double blue, double alpha) {
  uint64_t outred = (red >= 0) ? red + 0.5 : 0;
  if (outred >= 0x10000u) outred = 0xffffu;
  uint64_t outgreen = (green >= 0) ? green + 0.5 : 0;
  if (outgreen >= 0x10000u) outgreen = 0xffffu;
  uint64_t outblue = (blue >= 0) ? blue + 0.5 : 0;
  if (outblue >= 0x10000u) outblue = 0xffffu;
  uint64_t outalpha = (alpha >= 0) ? alpha + 0.5 : 0;
  if (outalpha >= 0x10000u) outalpha = 0xffffu;
  return (outalpha << 48) | (outblue << 32) | (outgreen << 16) | outred;
}

static inline int16_t make_signed_16 (uint16_t value) {
  // this is a no-op (since int16_t must use two's complement), but it's necessary to avoid undefined behavior
  return (value >= 0x8000u) ? -(int16_t) bitnegate(value) - 1 : value;
}

static inline unsigned bit_width (uintmax_t value) {
  unsigned result;
  for (result = 0; value; result ++) value >>= 1;
  return result;
}

static inline bool is_whitespace (unsigned char value) {
  // checks if value is 0 or isspace(value), but independent of current locale and system encoding
  return !value || (value >= 9 && value <= 13) || value == 32;
}

void * attach_allocator_node (union allocator_node ** list, union allocator_node * node) {
  if (!node) return NULL;
  node -> previous = NULL;
  node -> next = *list;
  if (node -> next) node -> next -> previous = node;
  *list = node;
  return node + 1;
}

void * allocate (union allocator_node ** list, size_t size) {
  if (size >= (size_t) -sizeof(union allocator_node)) return NULL;
  return attach_allocator_node(list, malloc(sizeof(union allocator_node) + size));
}

void * clear_allocate (union allocator_node ** list, size_t size) {
  if (size >= (size_t) -sizeof(union allocator_node)) return NULL;
  return attach_allocator_node(list, calloc(1, sizeof(union allocator_node) + size));
}

void deallocate (union allocator_node ** list, void * item) {
  if (!item) return;
  union allocator_node * node = (union allocator_node *) item - 1;
  if (node -> previous)
    node -> previous -> next = node -> next;
  else
    *list = node -> next;
  if (node -> next) node -> next -> previous = node -> previous;
  free(node);
}

void * reallocate (union allocator_node ** list, void * item, size_t size) {
  if (size >= (size_t) -sizeof(union allocator_node)) return NULL;
  if (!item) return allocate(list, size);
  union allocator_node * node = (union allocator_node *) item - 1;
  node = realloc(node, sizeof *node + size);
  if (!node) return NULL;
  if (node -> previous)
    node -> previous -> next = node;
  else
    *list = node;
  if (node -> next) node -> next -> previous = node;
  return node + 1;
}

void destroy_allocator_list (union allocator_node * list) {
  while (list) {
    union allocator_node * node = list;
    list = node -> next;
    free(node);
  }
}

void * plum_malloc (struct plum_image * image, size_t size) {
  if (!image) return NULL;
  union allocator_node * list = image -> allocator;
  void * result = allocate(&list, size);
  image -> allocator = list;
  return result;
}

void * plum_calloc (struct plum_image * image, size_t size) {
  if (!image) return NULL;
  union allocator_node * list = image -> allocator;
  void * result = clear_allocate(&list, size);
  image -> allocator = list;
  return result;
}

void * plum_realloc (struct plum_image * image, void * buffer, size_t size) {
  if (!image) return NULL;
  union allocator_node * list = image -> allocator;
  void * result = reallocate(&list, buffer, size);
  image -> allocator = list;
  return result;
}

void plum_free (struct plum_image * image, void * buffer) {
  if (image) {
    union allocator_node * list = image -> allocator;
    deallocate(&list, buffer);
    image -> allocator = list;
  } else
    free(buffer); // special compatibility mode for bad runtimes without access to C libraries
}

void load_BMP_data (struct context * context, unsigned flags, size_t limit) {
  if (context -> size < 54) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint_fast32_t subheader = read_le32_unaligned(context -> data + 14);
  if (subheader < 40 || subheader >= 0xffffffe6u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  context -> image -> type = PLUM_IMAGE_BMP;
  context -> image -> frames = 1;
  context -> image -> width = read_le32_unaligned(context -> data + 18);
  context -> image -> height = read_le32_unaligned(context -> data + 22);
  if (context -> image -> width > 0x7fffffffu || context -> image -> height == 0x80000000u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  bool inverted = true;
  if (context -> image -> height > 0x7fffffffu) {
    context -> image -> height = -context -> image -> height;
    inverted = false;
  }
  validate_image_size(context, limit);
  uint_fast32_t dataoffset = read_le32_unaligned(context -> data + 10);
  if (dataoffset < subheader + 14 || dataoffset >= context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (read_le16_unaligned(context -> data + 26) != 1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint_fast16_t bits = read_le16_unaligned(context -> data + 28);
  uint_fast32_t compression = read_le32_unaligned(context -> data + 30);
  if (bits > 32 || compression > 3) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  allocate_framebuffers(context, flags, bits <= 8);
  void * frame;
  uint8_t bitmasks[8];
  uint64_t palette[256];
  switch (bits | (compression << 8)) {
    case 1: // palette-based, first pixel in MSB
      context -> image -> max_palette_index = load_BMP_palette(context, (size_t) 14 + subheader, 2, palette);
      frame = load_monochrome_BMP(context, dataoffset, inverted);
      write_palette_to_image(context, palette, flags);
      write_palette_framebuffer_to_image(context, frame, palette, 0, flags, context -> image -> max_palette_index);
      break;
    case 4: // palette-based, first pixel in upper half
      context -> image -> max_palette_index = load_BMP_palette(context, (size_t) 14 + subheader, 16, palette);
      frame = load_halfbyte_BMP(context, dataoffset, inverted);
      write_palette_to_image(context, palette, flags);
      write_palette_framebuffer_to_image(context, frame, palette, 0, flags, context -> image -> max_palette_index);
      break;
    case 0x204: // 4-bit RLE
      context -> image -> max_palette_index = load_BMP_palette(context, (size_t) 14 + subheader, 16, palette);
      frame = load_halfbyte_compressed_BMP(context, dataoffset, inverted);
      write_palette_to_image(context, palette, flags);
      write_palette_framebuffer_to_image(context, frame, palette, 0, flags, context -> image -> max_palette_index);
      break;
    case 8: // palette-based
      context -> image -> max_palette_index = load_BMP_palette(context, (size_t) 14 + subheader, 256, palette);
      frame = load_byte_BMP(context, dataoffset, inverted);
      write_palette_to_image(context, palette, flags);
      write_palette_framebuffer_to_image(context, frame, palette, 0, flags, context -> image -> max_palette_index);
      break;
    case 0x108: // 8-bit RLE
      context -> image -> max_palette_index = load_BMP_palette(context, (size_t) 14 + subheader, 256, palette);
      frame = load_byte_compressed_BMP(context, dataoffset, inverted);
      write_palette_to_image(context, palette, flags);
      write_palette_framebuffer_to_image(context, frame, palette, 0, flags, context -> image -> max_palette_index);
      break;
    case 16: // mask 0x7c00 red, 0x03e0 green, 0x001f blue
      add_color_depth_metadata(context, 5, 5, 5, 0, 0);
      frame = load_BMP_pixels(context, dataoffset, inverted, 2, &load_BMP_halfword_pixel, (const uint8_t []) {10, 5, 5, 5, 0, 5, 0, 0});
      write_framebuffer_to_image(context -> image, frame, 0, flags);
      break;
    case 0x310: // 16-bit bitfield-based
      load_BMP_bitmasks(context, subheader, bitmasks, 16);
      add_color_depth_metadata(context, bitmasks[1], bitmasks[3], bitmasks[5], bitmasks[7], 0);
      frame = load_BMP_pixels(context, dataoffset, inverted, 2, &load_BMP_halfword_pixel, bitmasks);
      write_framebuffer_to_image(context -> image, frame, 0, flags);
      break;
    case 24: // blue, green, red
      add_color_depth_metadata(context, 8, 8, 8, 0, 0);
      frame = load_BMP_pixels(context, dataoffset, inverted, 3, &load_BMP_RGB_pixel, NULL);
      write_framebuffer_to_image(context -> image, frame, 0, flags);
      break;
    case 32: // blue, green, red, ignored
      add_color_depth_metadata(context, 8, 8, 8, 0, 0);
      frame = load_BMP_pixels(context, dataoffset, inverted, 4, &load_BMP_word_pixel, (const uint8_t []) {16, 8, 8, 8, 0, 8, 0, 0});
      write_framebuffer_to_image(context -> image, frame, 0, flags);
      break;
    case 0x320: // 32-bit bitfield-based
      load_BMP_bitmasks(context, subheader, bitmasks, 32);
      add_color_depth_metadata(context, bitmasks[1], bitmasks[3], bitmasks[5], bitmasks[7], 0);
      frame = load_BMP_pixels(context, dataoffset, inverted, 4, &load_BMP_word_pixel, bitmasks);
      write_framebuffer_to_image(context -> image, frame, 0, flags);
      break;
    default:
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
  ctxfree(context, frame);
}

uint8_t load_BMP_palette (struct context * context, size_t offset, unsigned max_count, uint64_t * restrict palette) {
  uint_fast32_t count = read_le32_unaligned(context -> data + 46);
  if (!count || count > max_count) count = max_count;
  size_t end = offset + count * 4;
  if (end < offset || end > context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  for (unsigned p = 0; p < count; p ++, offset += 4)
    palette[p] = (((uint64_t) context -> data[offset] << 32) | ((uint64_t) context -> data[offset + 1] << 16) | (uint64_t) context -> data[offset + 2]) * 0x101;
  add_color_depth_metadata(context, 8, 8, 8, 0, 0);
  return count - 1;
}

void load_BMP_bitmasks (struct context * context, size_t headersize, uint8_t * restrict bitmasks, unsigned maxbits) {
  bool valid = false;
  const uint8_t * bp;
  unsigned count;
  if (headersize >= 56) {
    bp = context -> data + 54;
    count = 4;
  } else {
    if (context -> size <= headersize + 26) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    bp = context -> data + 14 + headersize;
    count = 3;
    bitmasks[6] = bitmasks[7] = 0;
  }
  while (count --) {
    uint_fast32_t mask = read_le32_unaligned(bp);
    *bitmasks = bitmasks[1] = 0;
    if (mask) {
      while (!(mask & 1)) {
        ++ *bitmasks;
        mask >>= 1;
      }
      while (mask & 1) {
        bitmasks[1] ++;
        mask >>= 1;
      }
      if (mask) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      if (bitmasks[1] > 16) {
        *bitmasks += bitmasks[1] - 16;
        bitmasks[1] = 16;
      }
      if (*bitmasks + bitmasks[1] > maxbits) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      valid = true; // at least one mask is not empty
    }
    bp += 4;
    bitmasks += 2;
  }
  if (!valid) throw(context, PLUM_ERR_NO_DATA);
}

uint8_t * load_monochrome_BMP (struct context * context, size_t offset, bool inverted) {
  size_t rowsize = ((context -> image -> width + 31) >> 3) & bitnegate(3);
  size_t imagesize = rowsize * context -> image -> height;
  if (imagesize > context -> size - offset) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint8_t * frame = ctxmalloc(context, (size_t) context -> image -> width * context -> image -> height);
  const unsigned char * rowdata = context -> data + offset + (inverted ? rowsize * (context -> image -> height - 1) : 0);
  size_t cell = 0;
  for (uint_fast32_t row = 0; row < context -> image -> height; row ++) {
    const unsigned char * pixeldata = rowdata;
    for (uint_fast32_t pos = (context -> image -> width >> 3); pos; pos --, pixeldata ++) {
      frame[cell ++] = !!(*pixeldata & 0x80);
      frame[cell ++] = !!(*pixeldata & 0x40);
      frame[cell ++] = !!(*pixeldata & 0x20);
      frame[cell ++] = !!(*pixeldata & 0x10);
      frame[cell ++] = !!(*pixeldata & 8);
      frame[cell ++] = !!(*pixeldata & 4);
      frame[cell ++] = !!(*pixeldata & 2);
      frame[cell ++] = *pixeldata & 1;
    }
    if (context -> image -> width & 7) {
      unsigned char remainder = *pixeldata;
      for (uint_fast8_t pos = context -> image -> width & 7; pos; pos --, remainder <<= 1) frame[cell ++] = !!(remainder & 0x80);
    }
    if (inverted)
      rowdata -= rowsize;
    else
      rowdata += rowsize;
  }
  return frame;
}

uint8_t * load_halfbyte_BMP (struct context * context, size_t offset, bool inverted) {
  size_t rowsize = ((context -> image -> width + 7) >> 1) & bitnegate(3);
  size_t imagesize = rowsize * context -> image -> height;
  if (imagesize > context -> size - offset) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint8_t * frame = ctxmalloc(context, (size_t) context -> image -> width * context -> image -> height);
  const unsigned char * rowdata = context -> data + offset + (inverted ? rowsize * (context -> image -> height - 1) : 0);
  size_t cell = 0;
  for (uint_fast32_t row = 0; row < context -> image -> height; row ++) {
    const unsigned char * pixeldata = rowdata;
    for (uint_fast32_t pos = context -> image -> width >> 1; pos; pos --) {
      frame[cell ++] = *pixeldata >> 4;
      frame[cell ++] = *(pixeldata ++) & 15;
    }
    if (context -> image -> width & 1) frame[cell ++] = *pixeldata >> 4;
    if (inverted)
      rowdata -= rowsize;
    else
      rowdata += rowsize;
  }
  return frame;
}

uint8_t * load_byte_BMP (struct context * context, size_t offset, bool inverted) {
  size_t rowsize = (context -> image -> width + 3) & bitnegate(3);
  size_t imagesize = rowsize * context -> image -> height;
  if (imagesize > context -> size - offset) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint8_t * frame = ctxmalloc(context, (size_t) context -> image -> width * context -> image -> height);
  if (inverted || (context -> image -> width & 3))
    for (uint_fast32_t row = 0; row < context -> image -> height; row ++)
      memcpy(frame + context -> image -> width * row,
             context -> data + offset + rowsize * (inverted ? context -> image -> height - 1 - row : row),
             context -> image -> width);
  else
    memcpy(frame, context -> data + offset, imagesize);
  return frame;
}

uint8_t * load_halfbyte_compressed_BMP (struct context * context, size_t offset, bool inverted) {
  if (!inverted) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  const unsigned char * data = context -> data + offset;
  size_t remaining = context -> size - offset;
  uint8_t * frame = ctxcalloc(context, (size_t) context -> image -> width * context -> image -> height);
  uint_fast32_t row = context -> image -> height - 1, col = 0;
  while (remaining >= 2) {
    unsigned char length = *(data ++);
    unsigned char databyte = *(data ++);
    remaining -= 2;
    if (length) {
      if (col + length > context -> image -> width) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      uint8_t * framedata = frame + (size_t) row * context -> image -> width + col;
      col += length;
      while (length) {
        *(framedata ++) = databyte >> 4;
        databyte = (databyte >> 4) | (databyte << 4);
        length --;
      }
    } else switch (databyte) {
      case 0:
        if (row) {
          row --;
          col = 0;
          break;
        }
      case 1:
        return frame;
      case 2:
        if (remaining < 2 || col + *data > context -> image -> width || data[1] > row) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        col += *(data ++);
        row -= *(data ++);
        remaining -= 2;
        break;
      default: {
        if (col + databyte > context -> image -> width) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        if (remaining < (((databyte + 3) & ~3u) >> 1)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        uint8_t * framedata = frame + (size_t) row * context -> image -> width + col;
        uint_fast8_t pos;
        for (pos = 0; pos < (databyte >> 1); pos ++) {
          *(framedata ++) = data[pos] >> 4;
          *(framedata ++) = data[pos] & 15;
        }
        if (databyte & 1) *framedata = data[pos] >> 4;
        col += databyte;
        data += ((databyte + 3) & ~3u) >> 1;
        remaining -= ((databyte + 3) & ~3u) >> 1;
      }
    }
  }
  throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
}

uint8_t * load_byte_compressed_BMP (struct context * context, size_t offset, bool inverted) {
  if (!inverted) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  const unsigned char * data = context -> data + offset;
  size_t remaining = context -> size - offset;
  uint8_t * frame = ctxcalloc(context, (size_t) context -> image -> width * context -> image -> height);
  uint_fast32_t row = context -> image -> height - 1, col = 0;
  while (remaining >= 2) {
    unsigned char length = *(data ++);
    unsigned char databyte = *(data ++);
    remaining -= 2;
    if (length) {
      if (col + length > context -> image -> width) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      memset(frame + (size_t) row * context -> image -> width + col, databyte, length);
      col += length;
    } else switch (databyte) {
      case 0:
        if (row) {
          row --;
          col = 0;
          break;
        }
      case 1:
        return frame;
      case 2:
        if (remaining < 2 || col + *data > context -> image -> width || data[1] > row) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        col += *(data ++);
        row -= *(data ++);
        remaining -= 2;
        break;
      default:
        if (col + databyte > context -> image -> width) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        if (remaining < ((databyte + 1) & ~1u)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        memcpy(frame + (size_t) row * context -> image -> width + col, data, databyte);
        col += databyte;
        data += (databyte + 1) & ~1u;
        remaining -= (databyte + 1) & ~1u;
    }
  }
  throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
}

uint64_t * load_BMP_pixels (struct context * context, size_t offset, bool inverted, size_t bytes,
                            uint64_t (* loader) (const unsigned char *, const void *), const void * loaderdata) {
  size_t rowsize = (context -> image -> width * bytes + 3) & bitnegate(3);
  size_t imagesize = rowsize * context -> image -> height;
  if (imagesize > context -> size - offset) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  const unsigned char * rowdata = context -> data + offset + (inverted ? rowsize * (context -> image -> height - 1) : 0);
  size_t cell = 0;
  uint64_t * frame = ctxmalloc(context, sizeof *frame * context -> image -> width * context -> image -> height);
  for (uint_fast32_t row = 0; row < context -> image -> height; row ++) {
    const unsigned char * pixeldata = rowdata;
    for (uint_fast32_t col = 0; col < context -> image -> width; col ++) {
      frame[cell ++] = loader(pixeldata, loaderdata);
      pixeldata += bytes;
    }
    if (inverted)
      rowdata -= rowsize;
    else
      rowdata += rowsize;
  }
  return frame;
}

uint64_t load_BMP_halfword_pixel (const unsigned char * data, const void * bitmasks) {
  return load_BMP_bitmasked_pixel(read_le16_unaligned(data), bitmasks);
}

uint64_t load_BMP_word_pixel (const unsigned char * data, const void * bitmasks) {
  return load_BMP_bitmasked_pixel(read_le32_unaligned(data), bitmasks);
}

uint64_t load_BMP_RGB_pixel (const unsigned char * data, const void * bitmasks) {
  (void) bitmasks;
  return (((uint64_t) *data << 32) | ((uint64_t) data[1] << 16) | (uint64_t) data[2]) * 0x101;
}

uint64_t load_BMP_bitmasked_pixel (uint_fast32_t pixel, const uint8_t * bitmasks) {
  uint64_t result = 0;
  if (bitmasks[1]) result |= bitextend16((pixel >> *bitmasks) & (((uint64_t) 1 << bitmasks[1]) - 1), bitmasks[1]);
  if (bitmasks[3]) result |= (uint64_t) bitextend16((pixel >> bitmasks[2]) & (((uint64_t) 1 << bitmasks[3]) - 1), bitmasks[3]) << 16;
  if (bitmasks[5]) result |= (uint64_t) bitextend16((pixel >> bitmasks[4]) & (((uint64_t) 1 << bitmasks[5]) - 1), bitmasks[5]) << 32;
  if (bitmasks[7]) result |= (~(uint64_t) bitextend16((pixel >> bitmasks[6]) & (((uint64_t) 1 << bitmasks[7]) - 1), bitmasks[7])) << 48;
  return result;
}

void generate_BMP_data (struct context * context) {
  if (context -> source -> frames > 1) throw(context, PLUM_ERR_NO_MULTI_FRAME);
  if (context -> source -> width > 0x7fffffffu || context -> source -> height > 0x7fffffffu) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  unsigned char * header = append_output_node(context, 14);
  bytewrite(header, 0x42, 0x4d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
  uint32_t depth = get_true_color_depth(context -> source);
  if (depth >= 0x1000000u)
    generate_BMP_bitmasked_data(context, depth, header + 10);
  else if (context -> source -> palette)
    if (context -> source -> max_palette_index < 16)
      generate_BMP_palette_halfbyte_data(context, header + 10);
    else
      generate_BMP_palette_byte_data(context, header + 10);
  else if (bit_depth_less_than(depth, 0x80808u))
    generate_BMP_RGB_data(context, header + 10);
  else
    generate_BMP_bitmasked_data(context, depth, header + 10);
  size_t filesize = get_total_output_size(context);
  if (filesize <= 0x7fffffffu) write_le32_unaligned(header + 2, filesize);
}

void generate_BMP_bitmasked_data (struct context * context, uint32_t depth, unsigned char * offset_pointer) {
  uint8_t reddepth = depth, greendepth = depth >> 8, bluedepth = depth >> 16, alphadepth = depth >> 24;
  uint_fast8_t totaldepth = reddepth + greendepth + bluedepth + alphadepth;
  if (totaldepth > 32) {
    reddepth = ((reddepth << 6) / totaldepth + 1) >> 1;
    greendepth = ((greendepth << 6) / totaldepth + 1) >> 1;
    bluedepth = ((bluedepth << 6) / totaldepth + 1) >> 1;
    alphadepth = ((alphadepth << 6) / totaldepth + 1) >> 1;
    totaldepth = reddepth + greendepth + bluedepth + alphadepth;
    while (totaldepth > 32) {
      if (alphadepth > 2) totaldepth --, alphadepth --;
      if (bluedepth > 2 && totaldepth > 32) totaldepth --, bluedepth --;
      if (reddepth > 2 && totaldepth > 32) totaldepth --, reddepth --;
      if (greendepth > 2 && totaldepth > 32) totaldepth --, greendepth --;
    }
  }
  uint8_t blueshift = reddepth + greendepth, alphashift = blueshift + bluedepth;
  unsigned char * attributes = append_output_node(context, 108);
  memset(attributes, 0, 108);
  write_le32_unaligned(offset_pointer, 122);
  *attributes = 108;
  write_le32_unaligned(attributes + 4, context -> source -> width);
  write_le32_unaligned(attributes + 8, context -> source -> height);
  attributes[12] = 1;
  attributes[14] = (totaldepth <= 16) ? 16 : 32;
  attributes[16] = 3;
  write_le32_unaligned(attributes + 40, ((uint32_t) 1 << reddepth) - 1);
  write_le32_unaligned(attributes + 44, (((uint32_t) 1 << greendepth) - 1) << reddepth);
  write_le32_unaligned(attributes + 48, (((uint32_t) 1 << bluedepth) - 1) << blueshift);
  write_le32_unaligned(attributes + 52, alphadepth ? (((uint32_t) 1 << alphadepth) - 1) << alphashift : 0);
  write_le32_unaligned(attributes + 56, 0x73524742u); // 'sRGB'
  size_t rowsize = (size_t) context -> source -> width * (attributes[14] >> 3);
  if (totaldepth <= 16 && (context -> source -> width & 1)) rowsize += 2;
  size_t imagesize = rowsize * context -> source -> height;
  if (imagesize <= 0x7fffffffu) write_le32_unaligned(attributes + 20, imagesize);
  unsigned char * data = append_output_node(context, imagesize);
  uint_fast32_t row = context -> source -> height - 1;
  do {
    size_t pos = (size_t) row * context -> source -> width;
    for (uint_fast32_t p = 0; p < context -> source -> width; p ++) {
      uint64_t color;
      const void * colordata = context -> source -> data;
      size_t index = pos ++;
      if (context -> source -> palette) {
        index = context -> source -> data8[index];
        colordata = context -> source -> palette;
      }
      switch (context -> source -> color_format & PLUM_COLOR_MASK) {
        case PLUM_COLOR_16: color = index[(const uint16_t *) colordata]; break;
        case PLUM_COLOR_64: color = index[(const uint64_t *) colordata]; break;
        default: color = index[(const uint32_t *) colordata];
      }
      color = plum_convert_color(color, context -> source -> color_format, PLUM_COLOR_64 | PLUM_ALPHA_INVERT);
      uint_fast32_t out = ((color & 0xffffu) >> (16 - reddepth)) | ((color & 0xffff0000u) >> (32 - greendepth) << reddepth) |
                          ((color & 0xffff00000000u) >> (48 - bluedepth) << blueshift);
      if (alphadepth) out |= color >> (64 - alphadepth) << alphashift;
      if (totaldepth <= 16) {
        write_le16_unaligned(data, out);
        data += 2;
      } else {
        write_le32_unaligned(data, out);
        data += 4;
      }
    }
    if (totaldepth <= 16 && (context -> source -> width & 1)) data += byteappend(data, 0x00, 0x00);
  } while (row --);
}

void generate_BMP_palette_halfbyte_data (struct context * context, unsigned char * offset_pointer) {
  unsigned char * attributes = append_output_node(context, 40);
  write_le32_unaligned(offset_pointer, 58 + 4 * context -> source -> max_palette_index);
  memset(attributes, 0, 40);
  *attributes = 40;
  write_le32_unaligned(attributes + 4, context -> source -> width);
  write_le32_unaligned(attributes + 8, context -> source -> height);
  attributes[12] = 1;
  attributes[14] = 4;
  write_le32_unaligned(attributes + 32, context -> source -> max_palette_index + 1);
  append_BMP_palette(context);
  size_t rowsize = ((context -> source -> width + 7) & ~7u) >> 1;
  if (context -> source -> max_palette_index < 2) rowsize = ((rowsize >> 2) + 3) & bitnegate(3);
  size_t imagesize = rowsize * context -> source -> height;
  unsigned char * data = append_output_node(context, imagesize);
  size_t compressed = try_compress_BMP(context, imagesize, &compress_BMP_halfbyte_row);
  if (compressed) {
    attributes[16] = 2;
    if (compressed <= 0x7fffffffu) write_le32_unaligned(attributes + 20, compressed);
    context -> output -> size = compressed;
    return;
  }
  uint_fast32_t row = context -> source -> height - 1;
  uint_fast8_t padding = 3u & ~((context -> source -> width - 1) >> ((context -> source -> max_palette_index < 2) ? 3 : 1));
  do {
    const uint8_t * source = context -> source -> data8 + (size_t) row * context -> source -> width;
    if (context -> source -> max_palette_index < 2) {
      uint_fast8_t value = 0;
      for (uint_fast32_t p = 0; p < context -> source -> width; p ++) {
        value = (value << 1) | source[p];
        if ((p & 7) == 7) {
          *(data ++) = value;
          value = 0;
        }
      }
      if (context -> source -> width & 7) *(data ++) = value << (8 - (context -> source -> width & 7));
      attributes[14] = 1;
    } else {
      for (uint_fast32_t p = 0; p < context -> source -> width - 1; p += 2) *(data ++) = (source[p] << 4) | source[p + 1];
      if (context -> source -> width & 1) *(data ++) = source[context -> source -> width - 1] << 4;
    }
    for (uint_fast8_t value = 0; value < padding; value ++) *(data ++) = 0;
  } while (row --);
}

void generate_BMP_palette_byte_data (struct context * context, unsigned char * offset_pointer) {
  unsigned char * attributes = append_output_node(context, 40);
  write_le32_unaligned(offset_pointer, 58 + 4 * context -> source -> max_palette_index);
  memset(attributes, 0, 40);
  *attributes = 40;
  write_le32_unaligned(attributes + 4, context -> source -> width);
  write_le32_unaligned(attributes + 8, context -> source -> height);
  attributes[12] = 1;
  attributes[14] = 8;
  write_le32_unaligned(attributes + 32, context -> source -> max_palette_index + 1);
  append_BMP_palette(context);
  size_t rowsize = (context -> source -> width + 3) & bitnegate(3), imagesize = rowsize * context -> source -> height;
  unsigned char * data = append_output_node(context, imagesize);
  size_t compressed = try_compress_BMP(context, imagesize, &compress_BMP_byte_row);
  if (compressed) {
    attributes[16] = 1;
    if (compressed <= 0x7fffffffu) write_le32_unaligned(attributes + 20, compressed);
    context -> output -> size = compressed;
    return;
  }
  uint_fast32_t row = context -> source -> height - 1;
  do {
    memcpy(data, context -> source -> data8 + row * context -> source -> width, context -> source -> width);
    if (rowsize != context -> source -> width) memset(data + context -> source -> width, 0, rowsize - context -> source -> width);
    data += rowsize;
  } while (row --);
}

size_t try_compress_BMP (struct context * context, size_t size, size_t (* rowhandler) (uint8_t * restrict, const uint8_t * restrict, size_t)) {
  uint8_t * rowdata = ctxmalloc(context, size * ((context -> source -> max_palette_index < 2) ? 8 : 2) + 2);
  uint8_t * output = context -> output -> data;
  size_t cumulative = 0;
  uint_fast32_t row = context -> source -> height - 1;
  do {
    size_t rowsize = rowhandler(rowdata, context -> source -> data8 + (size_t) row * context -> source -> width, context -> source -> width);
    cumulative += rowsize;
    if (cumulative >= size) {
      ctxfree(context, rowdata);
      return 0;
    }
    if (!row) rowdata[rowsize - 1] = 1; // convert a 0x00, 0x00 (EOL) into 0x00, 0x01 (EOF)
    memcpy(output, rowdata, rowsize);
    output += rowsize;
  } while (row --);
  ctxfree(context, rowdata);
  return cumulative;
}

size_t compress_BMP_halfbyte_row (uint8_t * restrict result, const uint8_t * restrict data, size_t count) {
  size_t size = 2; // account for the terminator
  while (count > 3)
    if (*data == data[2] && data[1] == data[3]) {
      uint_fast8_t length;
      for (length = 4; length < 0xff && length < count && data[length] == data[length - 2]; length ++);
      result += byteappend(result, length, (*data << 4) | data[1]);
      size += 2;
      data += length;
      count -= length;
    } else {
      size_t length;
      uint_fast8_t matches = 0;
      for (length = 2; length < count; length ++) {
        if (data[length] == data[length - 2])
          matches ++;
        else
          matches = 0;
        if (matches >= 5) {
          length -= matches;
          break;
        }
      }
      while (length > 2) {
        uint_fast8_t block = (length > 0xff) ? 0xfc : length;
        result += byteappend(result, 0, block);
        size += (block + 7) >> 2 << 1;
        length -= block;
        count -= block;
        while (block >= 4) {
          result += byteappend(result, (*data << 4) | data[1], (data[2] << 4) | data[3]);
          data += 4;
          block -= 4;
        }
        switch (block) {
          case 1: result += byteappend(result, *data << 4, 0); break;
          case 2: result += byteappend(result, (*data << 4) | data[1], 0); break;
          case 3: result += byteappend(result, (*data << 4) | data[1], data[2] << 4);
        }
        data += block;
      }
      matches = emit_BMP_compressed_halfbyte_remainder(result, data, length);
      result += matches;
      size += matches;
      data += length;
      count -= length;
    }
  count = emit_BMP_compressed_halfbyte_remainder(result, data, count);
  result[count] = result[count + 1] = 0;
  return size + count;
}

unsigned emit_BMP_compressed_halfbyte_remainder (uint8_t * restrict result, const uint8_t * restrict data, unsigned count) {
  switch (count) {
    case 1:
      bytewrite(result, 1, *data << 4);
      return 2;
    case 2:
      bytewrite(result, 2, (*data << 4) | data[1]);
      return 2;
    case 3:
      result += byteappend(result, 2 + (*data == data[2]), (*data << 4) | data[1]);
      if (*data == data[2]) return 2;
      bytewrite(result, 1, data[2] << 4);
      return 4;
    default:
      return 0;
  }
}

size_t compress_BMP_byte_row (uint8_t * restrict result, const uint8_t * restrict data, size_t count) {
  size_t size = 2; // account for the terminator
  while (count > 1)
    if (*data == data[1]) {
      uint_fast8_t length;
      for (length = 2; length < 0xff && length < count && *data == data[length]; length ++);
      result += byteappend(result, length, *data);
      size += 2;
      data += length;
      count -= length;
    } else {
      size_t length;
      uint_fast8_t matches = 0;
      for (length = 1; length < count; length ++) {
        if (data[length] == data[length - 1])
          matches ++;
        else
          matches = 0;
        if (matches >= 2) {
          length -= matches;
          break;
        }
      }
      while (length > 2) {
        uint_fast8_t block = (length > 0xff) ? 0xfe : length;
        result += byteappend(result, 0, block);
        memcpy(result, data, block);
        result += block;
        data += block;
        size += 2 + block;
        length -= block;
        count -= block;
        if (block & 1) {
          *(result ++) = 0;
          size ++;
        }
      }
      if (length == 2) {
        matches = 1 + (*data == data[1]);
        result += byteappend(result, matches, *data);
        size += 2;
        data += matches;
        count -= matches;
        length -= matches;
      }
      if (length == 1) {
        result += byteappend(result, 1, *data);
        data ++;
        size += 2;
        count --;
      }
    }
  if (count == 1) {
    result += byteappend(result, 1, *data);
    size += 2;
  }
  bytewrite(result, 0, 0);
  return size;
}

void append_BMP_palette (struct context * context) {
  unsigned char * data = append_output_node(context, 4 * (context -> source -> max_palette_index + 1));
  uint32_t * colors = ctxmalloc(context, sizeof *colors * (context -> source -> max_palette_index + 1));
  plum_convert_colors(colors, context -> source -> palette, context -> source -> max_palette_index + 1, PLUM_COLOR_32, context -> source -> color_format);
  for (unsigned p = 0; p <= context -> source -> max_palette_index; p ++) data += byteappend(data, colors[p] >> 16, colors[p] >> 8, colors[p], 0);
  ctxfree(context, colors);
}

void generate_BMP_RGB_data (struct context * context, unsigned char * offset_pointer) {
  unsigned char * attributes = append_output_node(context, 40);
  write_le32_unaligned(offset_pointer, 54);
  memset(attributes, 0, 40);
  *attributes = 40;
  write_le32_unaligned(attributes + 4, context -> source -> width);
  write_le32_unaligned(attributes + 8, context -> source -> height);
  attributes[12] = 1;
  attributes[14] = 24;
  uint32_t * data;
  if ((context -> source -> color_format & PLUM_COLOR_MASK) == PLUM_COLOR_32)
    data = context -> source -> data;
  else {
    data = ctxmalloc(context, sizeof *data * context -> source -> width * context -> source -> height);
    plum_convert_colors(data, context -> source -> data, (size_t) context -> source -> width * context -> source -> height,
                        PLUM_COLOR_32, context -> source -> color_format);
  }
  size_t rowsize = (size_t) context -> source -> width * 3, padding = 0;
  if (rowsize & 3) {
    padding = 4 - (rowsize & 3);
    rowsize += padding;
  }
  unsigned char * out = append_output_node(context, rowsize * context -> source -> height);
  uint_fast32_t row = context -> source -> height - 1;
  do {
    size_t pos = (size_t) row * context -> source -> width;
    for (uint_fast32_t remaining = context -> source -> width; remaining; pos ++, remaining --)
      out += byteappend(out, data[pos] >> 16, data[pos] >> 8, data[pos]);
    for (uint_fast32_t p = 0; p < padding; p ++) *(out ++) = 0;
  } while (row --);
  if (data != context -> source -> data) ctxfree(context, data);
}

uint32_t compute_PNG_CRC (const unsigned char * data, size_t size) {
  static const uint32_t table[] = {
    /* 0x00 */ 0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
    /* 0x08 */ 0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
    /* 0x10 */ 0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
    /* 0x18 */ 0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
    /* 0x20 */ 0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
    /* 0x28 */ 0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
    /* 0x30 */ 0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
    /* 0x38 */ 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
    /* 0x40 */ 0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
    /* 0x48 */ 0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
    /* 0x50 */ 0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
    /* 0x58 */ 0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
    /* 0x60 */ 0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
    /* 0x68 */ 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
    /* 0x70 */ 0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    /* 0x78 */ 0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
    /* 0x80 */ 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
    /* 0x88 */ 0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
    /* 0x90 */ 0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
    /* 0x98 */ 0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
    /* 0xa0 */ 0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
    /* 0xa8 */ 0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
    /* 0xb0 */ 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236, 0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
    /* 0xb8 */ 0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
    /* 0xc0 */ 0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
    /* 0xc8 */ 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
    /* 0xd0 */ 0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
    /* 0xd8 */ 0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
    /* 0xe0 */ 0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
    /* 0xe8 */ 0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    /* 0xf0 */ 0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
    /* 0xf8 */ 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
  };
  uint32_t checksum = 0xffffffff;
  while (size --) checksum = (checksum >> 8) ^ table[(uint8_t) checksum ^ *(data ++)];
  return ~checksum;
}

uint32_t compute_Adler32_checksum (const unsigned char * data, size_t size) {
  uint_fast32_t first = 1, second = 0;
  while (size --) {
    first += *(data ++);
    if (first >= 65521) first -= 65521;
    second += first;
    if (second >= 65521) second -= 65521;
  }
  return (second << 16) | first;
}

void plum_convert_colors (void * restrict destination, const void * restrict source, size_t count, unsigned to, unsigned from) {
  if (!(source && destination && count)) return;
  if ((from & (PLUM_COLOR_MASK | PLUM_ALPHA_INVERT)) == (to & (PLUM_COLOR_MASK | PLUM_ALPHA_INVERT))) {
    memcpy(destination, source, plum_color_buffer_size(count, to));
    return;
  }
  #define convert(sp) do                                                                                       \
    if ((to & PLUM_COLOR_MASK) == PLUM_COLOR_16)                                                               \
      for (uint16_t * dp = destination; count; count --) *(dp ++) = plum_convert_color(*(sp ++), from, to);    \
    else if ((to & PLUM_COLOR_MASK) == PLUM_COLOR_64)                                                          \
      for (uint64_t * dp = destination; count; count --) *(dp ++) = plum_convert_color(*(sp ++), from, to);    \
    else                                                                                                       \
      for (uint32_t * dp = destination; count; count --) *(dp ++) = plum_convert_color(*(sp ++), from, to);    \
  while (false)
  if ((from & PLUM_COLOR_MASK) == PLUM_COLOR_16) {
    const uint16_t * sp = source;
    convert(sp);
  } else if ((from & PLUM_COLOR_MASK) == PLUM_COLOR_64) {
    const uint64_t * sp = source;
    convert(sp);
  } else {
    const uint32_t * sp = source;
    convert(sp);
  }
  #undef convert
}

uint64_t plum_convert_color (uint64_t color, unsigned from, unsigned to) {
  // here be dragons
  uint64_t result;
  if ((from & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    from &= 0xffffu;
  else if ((from & PLUM_COLOR_MASK) != PLUM_COLOR_64)
    from &= 0xffffffffu;
  switch (((from & PLUM_COLOR_MASK) << 2) | (to & PLUM_COLOR_MASK)) {
    case 0: case 5: case 10: case 15: // no conversion
      result = color;
      break;
    case 1: // 32 to 64
      result = ((color & 0xff) | ((color << 8) & 0xff0000u) | ((color << 16) & 0xff00000000u) | ((color << 24) & 0xff000000000000u)) * 0x101;
      break;
    case 2: // 32 to 16
      result = ((color >> 3) & 0x1f) | ((color >> 6) & 0x3e0) | ((color >> 9) & 0x7c00) | ((color >> 16) & 0x8000u);
      break;
    case 3: // 32 to 32x
      result = ((color << 2) & 0x3fc) | ((color << 4) & 0xff000u) | ((color << 6) & 0x3fc00000u) | (color & 0xc0000000u) |
               ((color >> 6) & 3) | ((color >> 4) & 0xc00) | ((color >> 2) & 0x300000u);
      break;
    case 4: // 64 to 32
      result = ((color >> 8) & 0xff) | ((color >> 16) & 0xff00u) | ((color >> 24) & 0xff0000u) | ((color >> 32) & 0xff000000u);
      break;
    case 6: // 64 to 16
      result = ((color >> 11) & 0x1f) | ((color >> 22) & 0x3e0) | ((color >> 33) & 0x7c00) | ((color >> 48) & 0x8000u);
      break;
    case 7: // 64 to 32x
      result = ((color >> 6) & 0x3ff) | ((color >> 12) & 0xffc00u) | ((color >> 18) & 0x3ff00000u) | ((color >> 32) & 0xc0000000u);
      break;
    case 8: // 16 to 32
      result = ((color << 3) & 0xf8) | ((color << 6) & 0xf800u) | ((color << 9) & 0xf80000u) | ((color & 0x8000u) ? 0xff000000u : 0) |
               ((color >> 2) & 7) | ((color << 1) & 0x700) | ((color << 4) & 0x70000u);
      break;
    case 9: // 16 to 64
      result = (((color & 0x1f) | ((color << 11) & 0x1f0000u) | ((color << 22) & 0x1f00000000u)) * 0x842) | ((color & 0x8000u) ? 0xffff000000000000u : 0) |
               ((color >> 4) & 1) | ((color << 7) & 0x10000u) | ((color << 18) & 0x100000000u);
      break;
    case 11: // 16 to 32x
      result = (((color & 0x1f) | ((color << 5) & 0x7c00) | ((color << 10) & 0x1f00000u)) * 0x21) | ((color & 0x8000u) ? 0xc0000000u : 0);
      break;
    case 12: // 32x to 32
      result = ((color >> 2) & 0xff) | ((color >> 4) & 0xff00u) | ((color >> 6) & 0xff0000u) | ((color >> 30) * 0x55000000u);
      break;
    case 13: // 32x to 64
      result = ((color << 6) & 0xffc0u) | ((color << 12) & 0xffc00000u) | ((color << 18) & 0xffc000000000u) | ((color >> 30) * 0x5555000000000000u) |
               ((color >> 4) & 0x3f) | ((color << 2) & 0x3f0000u) | ((color << 8) & 0x3f00000000u);
      break;
    case 14: // 32x to 16
      result = ((color >> 5) & 0x1f) | ((color >> 10) & 0x3e0) | ((color >> 15) & 0x7c00) | ((color >> 16) & 0x8000u);
  }
  if ((to ^ from) & PLUM_ALPHA_INVERT) result ^= alpha_component_masks[to & PLUM_COLOR_MASK];
  return result;
}

void plum_remove_alpha (struct plum_image * image) {
  if (!(image && image -> data && plum_check_valid_image_size(image -> width, image -> height, image -> frames))) return;
  void * colordata;
  size_t count;
  if (image -> palette) {
    colordata = image -> palette;
    count = image -> max_palette_index + 1;
  } else {
    colordata = image -> data;
    count = (size_t) image -> width * image -> height * image -> frames;
  }
  switch (image -> color_format & PLUM_COLOR_MASK) {
    case PLUM_COLOR_32: {
      uint32_t * color = colordata;
      if (image -> color_format & PLUM_ALPHA_INVERT)
        while (count --) *(color ++) |= 0xff000000u;
      else
        while (count --) *(color ++) &= 0xffffffu;
    } break;
    case PLUM_COLOR_64: {
      uint64_t * color = colordata;
      if (image -> color_format & PLUM_ALPHA_INVERT)
        while (count --) *(color ++) |= 0xffff000000000000u;
      else
        while (count --) *(color ++) &= 0xffffffffffffu;
    } break;
    case PLUM_COLOR_16: {
      uint16_t * color = colordata;
      if (image -> color_format & PLUM_ALPHA_INVERT)
        while (count --) *(color ++) |= 0x8000u;
      else
        while (count --) *(color ++) &= 0x7fffu;
    } break;
    case PLUM_COLOR_32X: {
      uint32_t * color = colordata;
      if (image -> color_format & PLUM_ALPHA_INVERT)
        while (count --) *(color ++) |= 0xc0000000u;
      else
        while (count --) *(color ++) &= 0x3fffffffu;
    }
  }
}

bool image_has_transparency (const struct plum_image * image) {
  const void * colordata;
  size_t count;
  if (image -> palette) {
    colordata = image -> palette;
    count = image -> max_palette_index + 1;
  } else {
    colordata = image -> data;
    count = (size_t) image -> width * image -> height * image -> frames;
  }
  switch (image -> color_format & PLUM_COLOR_MASK) {
    case PLUM_COLOR_32: {
      const uint32_t * color = colordata;
      if (image -> color_format & PLUM_ALPHA_INVERT) {
        while (count --) if (*(color ++) < 0xff000000u) return true;
      } else
        while (count --) if (*(color ++) >= 0x1000000u) return true;
      return false;
    }
    case PLUM_COLOR_64: {
      const uint64_t * color = colordata;
      if (image -> color_format & PLUM_ALPHA_INVERT) {
        while (count --) if (*(color ++) < 0xffff000000000000u) return true;
      } else
        while (count --) if (*(color ++) >= 0x1000000000000u) return true;
      return false;
    }
    case PLUM_COLOR_16: {
      const uint16_t * color = colordata;
      if (image -> color_format & PLUM_ALPHA_INVERT) {
        while (count --) if (*(color ++) < 0x8000u) return true;
      } else
        while (count --) if (*(color ++) >= 0x7fff) return true;
      return false;
    }
    default: { // PLUM_COLOR_32X
      const uint32_t * color = colordata;
      if (image -> color_format & PLUM_ALPHA_INVERT) {
        while (count --) if (*(color ++) < 0xc0000000u) return true;
      } else
        while (count --) if (*(color ++) >= 0x40000000u) return true;
      return false;
    }
  }
}

uint32_t get_true_color_depth (const struct plum_image * image) {
  uint8_t red, green, blue, alpha;
  switch (image -> color_format & PLUM_COLOR_MASK) {
    case PLUM_COLOR_32:
      red = green = blue = alpha = 8;
      break;
    case PLUM_COLOR_64:
      red = green = blue = alpha = 16;
      break;
    case PLUM_COLOR_16:
      red = green = blue = 5;
      alpha = 1;
      break;
    case PLUM_COLOR_32X:
      red = green = blue = 10;
      alpha = 2;
  }
  const struct plum_metadata * colorinfo = plum_find_metadata(image, PLUM_METADATA_COLOR_DEPTH);
  if (colorinfo) {
    unsigned char * data = colorinfo -> data;
    if (*data || data[1] || data[2]) {
      if (*data) red = *data;
      if (data[1]) green = data[1];
      if (data[2]) blue = data[2];
    } else if (colorinfo -> size >= 5 && data[4])
      red = green = blue = data[4];
    if (colorinfo -> size >= 4 && data[3]) alpha = data[3];
  }
  if (!image_has_transparency(image)) alpha = 0;
  if (red > 16) red = 16;
  if (green > 16) green = 16;
  if (blue > 16) blue = 16;
  if (alpha > 16) alpha = 16;
  return (uint32_t) red | ((uint32_t) green << 8) | ((uint32_t) blue << 16) | ((uint32_t) alpha << 24);
}

void validate_image_size (struct context * context, size_t limit) {
  if (!(context -> image -> width && context -> image -> height && context -> image -> frames)) throw(context, PLUM_ERR_NO_DATA);
  if (!plum_check_limited_image_size(context -> image -> width, context -> image -> height, context -> image -> frames, limit))
    throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
}

int plum_check_valid_image_size (uint32_t width, uint32_t height, uint32_t frames) {
  return plum_check_limited_image_size(width, height, frames, SIZE_MAX);
}

int plum_check_limited_image_size (uint32_t width, uint32_t height, uint32_t frames, size_t limit) {
  if (!(width && height && frames)) return 0;
  size_t p = width;
  if (limit > SIZE_MAX / sizeof(uint64_t)) limit = SIZE_MAX / sizeof(uint64_t);
  if (p * height / height != p) return 0;
  p *= height;
  if (p * frames / frames != p) return 0;
  p *= frames;
  return p <= limit;
}

size_t plum_color_buffer_size (size_t count, unsigned flags) {
  if (count > SIZE_MAX / sizeof(uint64_t)) return 0;
  if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_64)
    return count * sizeof(uint64_t);
  else if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    return count * sizeof(uint16_t);
  else
    return count * sizeof(uint32_t);
}

size_t plum_pixel_buffer_size (const struct plum_image * image) {
  if (!image) return 0;
  if (!plum_check_valid_image_size(image -> width, image -> height, image -> frames)) return 0;
  size_t count = (size_t) image -> width * image -> height * image -> frames;
  return image -> palette ? count : plum_color_buffer_size(count, image -> color_format);
}

size_t plum_palette_buffer_size (const struct plum_image * image) {
  if (!image) return 0;
  return plum_color_buffer_size(image -> max_palette_index + 1, image -> color_format);
}

void allocate_framebuffers (struct context * context, unsigned flags, bool palette) {
  size_t size = (size_t) context -> image -> width * context -> image -> height * context -> image -> frames;
  if (!palette) size = plum_color_buffer_size(size, flags);
  if (!(context -> image -> data = plum_malloc(context -> image, size))) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  context -> image -> color_format = flags & (PLUM_COLOR_MASK | PLUM_ALPHA_INVERT);
}

void write_framebuffer_to_image (struct plum_image * image, const uint64_t * restrict framebuffer, uint32_t frame, unsigned flags) {
  size_t pixels = (size_t) image -> width * image -> height, framesize = plum_color_buffer_size(pixels, flags);
  plum_convert_colors(image -> data8 + framesize * frame, framebuffer, pixels, flags, PLUM_COLOR_64);
}

void write_palette_framebuffer_to_image (struct context * context, const uint8_t * restrict framebuffer, const uint64_t * restrict palette, uint32_t frame,
                                         unsigned flags, uint8_t max_palette_index) {
  size_t framesize = (size_t) context -> image -> width * context -> image -> height;
  if (max_palette_index < 0xff)
    for (size_t pos = 0; pos < framesize; pos ++) if (framebuffer[pos] > max_palette_index) throw(context, PLUM_ERR_INVALID_COLOR_INDEX);
  if (context -> image -> palette) {
    memcpy(context -> image -> data8 + framesize * frame, framebuffer, framesize);
    return;
  }
  void * converted = ctxmalloc(context, plum_color_buffer_size(max_palette_index + 1, flags));
  plum_convert_colors(converted, palette, max_palette_index + 1, flags, PLUM_COLOR_64);
  plum_convert_indexes_to_colors(context -> image -> data8 + plum_color_buffer_size(framesize, flags) * frame, framebuffer, converted, framesize, flags);
  ctxfree(context, converted);
}

void write_palette_to_image (struct context * context, const uint64_t * restrict palette, unsigned flags) {
  size_t size = plum_color_buffer_size(context -> image -> max_palette_index + 1, flags);
  if (!(context -> image -> palette = plum_malloc(context -> image, size))) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  plum_convert_colors(context -> image -> palette, palette, context -> image -> max_palette_index + 1, flags, PLUM_COLOR_64);
}

unsigned plum_rotate_image (struct plum_image * image, unsigned count, int flip) {
  unsigned error = plum_validate_image(image);
  if (error) return error;
  count &= 3;
  if (!(count || flip)) return 0;
  size_t framesize = (size_t) image -> width * image -> height;
  void * buffer;
  if (image -> palette)
    buffer = malloc(framesize);
  else
    buffer = malloc(plum_color_buffer_size(framesize, image -> color_format));
  if (!buffer) return PLUM_ERR_OUT_OF_MEMORY;
  if (count & 1) {
    uint_fast32_t temp = image -> width;
    image -> width = image -> height;
    image -> height = temp;
  }
  size_t (* coordinate) (size_t, size_t, size_t, size_t);
  switch (count) {
    case 0: coordinate = flip_coordinate; break; // we know flip has to be enabled because null rotations were excluded already
    case 1: coordinate = flip ? rotate_right_flip_coordinate : rotate_right_coordinate; break;
    case 2: coordinate = flip ? rotate_both_flip_coordinate : rotate_both_coordinate; break;
    case 3: coordinate = flip ? rotate_left_flip_coordinate : rotate_left_coordinate;
  }
  if (image -> palette)
    for (uint_fast32_t frame = 0; frame < image -> frames; frame ++)
      rotate_frame_8(image -> data8 + framesize * frame, buffer, image -> width, image -> height, coordinate);
  else if ((image -> color_format & PLUM_COLOR_MASK) == PLUM_COLOR_64)
    for (uint_fast32_t frame = 0; frame < image -> frames; frame ++)
      rotate_frame_64(image -> data64 + framesize * frame, buffer, image -> width, image -> height, coordinate);
  else if ((image -> color_format & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    for (uint_fast32_t frame = 0; frame < image -> frames; frame ++)
      rotate_frame_16(image -> data16 + framesize * frame, buffer, image -> width, image -> height, coordinate);
  else
    for (uint_fast32_t frame = 0; frame < image -> frames; frame ++)
      rotate_frame_32(image -> data32 + framesize * frame, buffer, image -> width, image -> height, coordinate);
  free(buffer);
  return 0;
}

#define ROTATE_FRAME_FUNCTION(bits) \
void rotate_frame_ ## bits (uint ## bits ## _t * restrict frame, uint ## bits ## _t * restrict buffer, size_t width, size_t height, \
                            size_t (* coordinate) (size_t, size_t, size_t, size_t)) {                                               \
  for (size_t row = 0; row < height; row ++) for (size_t col = 0; col < width; col ++)                                              \
    buffer[row * width + col] = frame[coordinate(row, col, width, height)];                                                         \
  memcpy(frame, buffer, sizeof *frame * width * height);                                                                            \
}

ROTATE_FRAME_FUNCTION(8)
ROTATE_FRAME_FUNCTION(16)
ROTATE_FRAME_FUNCTION(32)
ROTATE_FRAME_FUNCTION(64)

#undef ROTATE_FRAME_FUNCTION

size_t rotate_left_coordinate (size_t row, size_t col, size_t width, size_t height) {
  (void) width;
  return (col + 1) * height - (row + 1);
}

size_t rotate_right_coordinate (size_t row, size_t col, size_t width, size_t height) {
  return (width - 1 - col) * height + row;
}

size_t rotate_both_coordinate (size_t row, size_t col, size_t width, size_t height) {
  return height * width - 1 - (row * width + col);
}

size_t flip_coordinate (size_t row, size_t col, size_t width, size_t height) {
  return (height - 1 - row) * width + col;
}

size_t rotate_left_flip_coordinate (size_t row, size_t col, size_t width, size_t height) {
  (void) width;
  return col * height + row;
}

size_t rotate_right_flip_coordinate (size_t row, size_t col, size_t width, size_t height) {
  return height * width - 1 - (col * height + row);
}

size_t rotate_both_flip_coordinate (size_t row, size_t col, size_t width, size_t height) {
  (void) height;
  return (row + 1) * width - (col + 1);
}

uint64_t adjust_frame_duration (uint64_t duration, int64_t * restrict remainder) {
  if (*remainder < 0)
    if (duration < -*remainder) {
      *remainder += duration;
      return 0;
    } else {
      duration += (uint64_t) *remainder;
      *remainder = 0;
      return duration;
    }
  else {
    duration += *remainder;
    if (duration < *remainder) duration = UINT64_MAX;
    *remainder = 0;
    return duration;
  }
}

void update_frame_duration_remainder (uint64_t actual, uint64_t computed, int64_t * restrict remainder) {
  if (actual < computed) {
    uint64_t difference = computed - actual;
    if (difference > INT64_MAX) difference = INT64_MAX;
    if (*remainder >= 0)
      *remainder -= (int64_t) difference;
    else if (difference + -*remainder > -(uint64_t) INT64_MIN)
      *remainder = INT64_MIN;
    else
      *remainder -= (int64_t) difference;
  } else {
    uint64_t difference = actual - computed;
    if (difference > INT64_MAX) difference = INT64_MAX;
    if (*remainder < 0)
      *remainder += (int64_t) difference;
    else if (difference + *remainder > INT64_MAX)
      *remainder = INT64_MAX;
    else
      *remainder += (int64_t) difference;
  }
}

void calculate_frame_duration_fraction (uint64_t duration, uint32_t limit, uint32_t * restrict numerator, uint32_t * restrict denominator) {
  // if the number is too big to be represented at all, just fail early and return infinity
  if (duration >= 1000000000u * ((uint64_t) limit + 1)) {
    *numerator = 1;
    *denominator = 0;
    return;
  }
  // if the number can be represented exactly, do that
  *denominator = 1000000000u;
  while (!((duration | *denominator) & 1)) {
    duration >>= 1;
    *denominator >>= 1;
  }
  while (!(duration % 5 || *denominator % 5)) {
    duration /= 5;
    *denominator /= 5;
  }
  if (duration <= limit && *denominator <= limit) {
    *numerator = duration;
    return;
  }
  // otherwise, calculate the coefficients of the value's continued fraction representation until the represented fraction exceeds the range limit
  // this will necessarily stop before running out of coefficients because we know at this stage that the exact value doesn't fit
  uint64_t cumulative_numerator = duration / *denominator, cumulative_denominator = 1, previous_numerator = 1, previous_denominator = 0;
  uint32_t coefficient, original_denominator = *denominator;
  *numerator = duration % *denominator;
  while (true) {
    coefficient = *denominator / *numerator;
    uint64_t partial_numerator = *denominator % *numerator;
    *denominator = *numerator;
    *numerator = partial_numerator;
    if (cumulative_numerator > cumulative_denominator) {
      uint64_t partial_cumulative_numerator = cumulative_numerator * coefficient + previous_numerator;
      if (partial_cumulative_numerator > limit) break;
      previous_numerator = cumulative_numerator;
      cumulative_numerator = partial_cumulative_numerator;
      uint64_t partial_cumulative_denominator = cumulative_denominator * coefficient + previous_denominator;
      previous_denominator = cumulative_denominator;
      cumulative_denominator = partial_cumulative_denominator;
    } else {
      uint64_t partial_cumulative_denominator = cumulative_denominator * coefficient + previous_denominator;
      if (partial_cumulative_denominator > limit) break;
      previous_denominator = cumulative_denominator;
      cumulative_denominator = partial_cumulative_denominator;
      uint64_t partial_cumulative_numerator = cumulative_numerator * coefficient + previous_numerator;
      previous_numerator = cumulative_numerator;
      cumulative_numerator = partial_cumulative_numerator;
    }
  }
  // the current coefficient would be too large to fit, so try reducing it until it fits; if a good coefficient is found, use it
  uint64_t threshold = coefficient / 2 + 1;
  if (cumulative_numerator > cumulative_denominator) {
    while (-- coefficient >= threshold) if (cumulative_numerator * coefficient + previous_numerator <= limit) break;
  } else
    while (-- coefficient >= threshold) if (cumulative_denominator * coefficient + previous_denominator <= limit) break;
  if (coefficient >= threshold) {
    *numerator = cumulative_numerator * coefficient + previous_numerator;
    *denominator = cumulative_denominator * coefficient + previous_denominator;
    return;
  }
  // reducing the coefficient to half its original value may or may not improve accuracy, so this must be tested
  // if it doesn't, return the previous step's values; if it does, return the improved values
  *numerator = cumulative_numerator;
  *denominator = cumulative_denominator;
  if (coefficient) {
    cumulative_numerator = cumulative_numerator * coefficient + previous_numerator;
    cumulative_denominator = cumulative_denominator * coefficient + previous_denominator;
    if (cumulative_numerator > limit || cumulative_denominator > limit) return;
    /* The exact value, old approximation and new approximation are respectively proportional to the products of three quantities:
       exact value       ~ *denominator * duration * cumulative_denominator
       old approximation ~ *numerator * original_denominator * cumulative_denominator
       new approximation ~ *denominator * original_denominator * cumulative_numerator
       The problem is that these quantities are 96 bits wide, and thus some care must be exercised when computing them and comparing them. */
    uint32_t exact_low, old_low, new_low; // bits 0-31
    uint64_t exact_high, old_high, new_high; // bits 32-95
    uint64_t partial_exact = *denominator * cumulative_denominator;
    exact_high = (partial_exact >> 32) * duration + (duration >> 32) * partial_exact;
    partial_exact = (partial_exact & 0xffffffffu) * (duration & 0xffffffffu);
    exact_high += partial_exact >> 32;
    exact_low = partial_exact;
    uint64_t partial_old = *numerator * (uint64_t) original_denominator;
    old_high = (partial_old >> 32) * cumulative_denominator;
    partial_old = (partial_old & 0xffffffffu) * cumulative_denominator;
    old_high += partial_old >> 32;
    old_low = partial_old;
    uint64_t partial_new = *denominator * (uint64_t) original_denominator;
    new_high = (partial_new >> 32) * cumulative_numerator;
    partial_new = (partial_new & 0xffffffffu) * cumulative_numerator;
    new_high += partial_new >> 32;
    new_low = partial_new;
    // do the subtractions, and abuse two's complement to deal with negative results
    old_high -= exact_high;
    uint64_t old_diff = (uint64_t) old_low - exact_low;
    old_low = old_diff;
    if (old_diff & 0xffffffff00000000u) old_high --;
    if (old_high & 0x8000000000000000u)
      if (old_low) {
        old_high = ~old_high;
        old_low = -old_low;
      } else
        old_high = -old_high;
    new_high -= exact_high;
    uint64_t new_diff = (uint64_t) new_low - exact_low;
    new_low = new_diff;
    if (new_diff & 0xffffffff00000000u) new_high --;
    if (new_high & 0x8000000000000000u)
      if (new_low) {
        new_high = ~new_high;
        new_low = -new_low;
      } else
        new_high = -new_high;
    // and finally, compare and use the new results if they are better
    if (new_high < old_high || (new_high == old_high && new_low <= old_low)) {
      *numerator = cumulative_numerator;
      *denominator = cumulative_denominator;
    }
  }
}

unsigned char * compress_GIF_data (struct context * context, const unsigned char * restrict data, size_t count, size_t * length, unsigned codesize) {
  struct compressed_GIF_code * codes = ctxmalloc(context, sizeof *codes * 4097);
  initialize_GIF_compression_codes(codes, codesize);
  *length = 0;
  size_t allocated = 254; // initial size
  unsigned char * output = ctxmalloc(context, allocated);
  unsigned current_codesize = codesize + 1, bits = current_codesize, max_code = (1 << codesize) + 1, current_code = *(data ++);
  uint_fast32_t chain = 1, codeword = 1 << codesize;
  uint_fast8_t shortchains = 0;
  while (-- count) {
    uint_fast8_t search = *(data ++);
    uint_fast16_t p;
    for (p = 0; p <= max_code; p ++) if (!codes[p].type && codes[p].reference == current_code && codes[p].value == search) break;
    if (p <= max_code) {
      current_code = p;
      chain ++;
    } else {
      codeword |= current_code << bits;
      bits += current_codesize;
      codes[++ max_code] = (struct compressed_GIF_code) {.type = 0, .reference = current_code, .value = search};
      current_code = search;
      if (current_codesize > codesize + 2)
        if (chain <= current_codesize / codesize)
          shortchains ++;
        else if (shortchains)
          shortchains --;
      chain = 1;
      if (max_code > 4095) max_code = 4095;
      if (max_code == (1 << current_codesize)) current_codesize ++;
      if (shortchains > codesize + 8) {
        // output a clear code and reset the code table
        codeword |= 1 << (bits + codesize);
        bits += current_codesize;
        max_code = (1 << codesize) + 1;
        current_codesize = codesize + 1;
        shortchains = 0;
      }
    }
    while (bits >= 8) {
      if (allocated == *length) output = ctxrealloc(context, output, allocated <<= 1);
      output[(*length) ++] = codeword;
      codeword >>= 8;
      bits -= 8;
    }
  }
  codeword |= current_code << bits;
  bits += current_codesize;
  codeword |= ((1 << codesize) + 1) << bits;
  bits += current_codesize;
  while (bits) {
    if (allocated == *length) output = ctxrealloc(context, output, allocated += 4);
    output[(*length) ++] = codeword;
    codeword >>= 8;
    bits = (bits > 8) ? bits - 8 : 0;
  }
  ctxfree(context, codes);
  return output;
}

void decompress_GIF_data (struct context * context, unsigned char * restrict result, const unsigned char * restrict source, size_t expected_length,
                          size_t length, unsigned codesize) {
  struct compressed_GIF_code * codes = ctxmalloc(context, sizeof *codes * 4097);
  initialize_GIF_compression_codes(codes, codesize);
  unsigned bits = 0, current_codesize = codesize + 1, max_code = (1 << codesize) + 1;
  uint_fast32_t codeword = 0;
  int lastcode = -1;
  unsigned char * current = result;
  unsigned char * limit = result + expected_length;
  while (true) {
    while (bits < current_codesize) {
      if (!(length --)) {
        // handle images that are so broken that they never emit a stop code
        if (current != limit) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        ctxfree(context, codes);
        return;
      }
      codeword |= (uint_fast32_t) *(source ++) << bits;
      bits += 8;
    }
    uint_fast16_t code = codeword & ((1u << current_codesize) - 1);
    codeword >>= current_codesize;
    bits -= current_codesize;
    switch (codes[code].type) {
      case 0:
        emit_GIF_data(context, codes, code, &current, limit);
        if (lastcode >= 0)
          codes[++ max_code] = (struct compressed_GIF_code) {.reference = lastcode, .value = find_leading_GIF_code(codes, code), .type = 0};
        lastcode = code;
        break;
      case 1:
        initialize_GIF_compression_codes(codes, codesize);
        current_codesize = codesize + 1;
        max_code = (1 << codesize) + 1;
        lastcode = -1;
        break;
      case 2:
        if (current != limit) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        ctxfree(context, codes);
        return;
      case 3:
        if (code != max_code + 1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        if (lastcode < 0) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        codes[++ max_code] = (struct compressed_GIF_code) {.reference = lastcode, .value = find_leading_GIF_code(codes, lastcode), .type = 0};
        emit_GIF_data(context, codes, max_code, &current, limit);
        lastcode = code;
    }
    if (max_code >= 4095)
      max_code = 4095;
    else if (max_code == ((1 << current_codesize) - 1))
      current_codesize ++;
  }
}

void initialize_GIF_compression_codes (struct compressed_GIF_code * restrict codes, unsigned codesize) {
  unsigned code;
  for (code = 0; code < (1 << codesize); code ++) codes[code] = (struct compressed_GIF_code) {.reference = -1, .value = code, .type = 0};
  codes[code ++] = (struct compressed_GIF_code) {.type = 1, .reference = -1};
  codes[code ++] = (struct compressed_GIF_code) {.type = 2, .reference = -1};
  for (; code < 4096; code ++) codes[code] = (struct compressed_GIF_code) {.type = 3, .reference = -1};
}

uint8_t find_leading_GIF_code (const struct compressed_GIF_code * restrict codes, unsigned code) {
  return (codes[code].reference < 0) ? codes[code].value : find_leading_GIF_code(codes, codes[code].reference);
}

void emit_GIF_data (struct context * context, const struct compressed_GIF_code * restrict codes, unsigned code, unsigned char ** result, unsigned char * limit) {
  if (codes[code].reference >= 0) emit_GIF_data(context, codes, codes[code].reference, result, limit);
  if (*result >= limit) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  *((*result) ++) = codes[code].value;
}

void load_GIF_data (struct context * context, unsigned flags, size_t limit) {
  if (context -> size < 14) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  context -> image -> type = PLUM_IMAGE_GIF;
  context -> image -> width = read_le16_unaligned(context -> data + 6);
  context -> image -> height = read_le16_unaligned(context -> data + 8);
  size_t offset = 13;
  uint64_t transparent = 0xffff000000000000u;
  // note: load_GIF_palettes also initializes context -> image -> frames (and context -> image -> palette) and validates the image's structure
  uint64_t ** palettes = load_GIF_palettes_and_frame_count(context, flags, &offset, &transparent); // will be leaked (collected at the end)
  validate_image_size(context, limit);
  allocate_framebuffers(context, flags, !!context -> image -> palette);
  uint64_t * durations;
  uint8_t * disposals;
  add_animation_metadata(context, &durations, &disposals);
  for (uint_fast32_t frame = 0; frame < context -> image -> frames; frame ++)
    load_GIF_frame(context, &offset, flags, frame, palettes ? palettes[frame] : NULL, transparent, durations + frame, disposals + frame);
  if (!plum_find_metadata(context -> image, PLUM_METADATA_LOOP_COUNT)) add_loop_count_metadata(context, 1);
}

uint64_t ** load_GIF_palettes_and_frame_count (struct context * context, unsigned flags, size_t * restrict offset, uint64_t * restrict transparent_color) {
  // will also validate block order
  unsigned char depth = 1 + ((context -> data[10] >> 4) & 7);
  add_color_depth_metadata(context, depth, depth, depth, 1, 0);
  uint64_t * global_palette = ctxcalloc(context, 256 * sizeof *global_palette);
  unsigned global_palette_size = 0;
  if (context -> data[10] & 0x80) {
    global_palette_size = 2 << (context -> data[10] & 7);
    load_GIF_palette(context, global_palette, offset, global_palette_size);
    if (context -> data[11] < global_palette_size) {
      add_background_color_metadata(context, global_palette[context -> data[11]], flags);
      *transparent_color |= global_palette[context -> data[11]];
    }
  }
  size_t scan_offset = *offset;
  unsigned real_global_palette_size = global_palette_size, transparent_index = 256, next_transparent_index = 256;
  bool seen_extension = false;
  uint64_t ** result = NULL;
  while (scan_offset < context -> size) switch (context -> data[scan_offset ++]) {
    case 0x21: {
      if (scan_offset == context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      uint_fast8_t exttype = context -> data[scan_offset ++];
      if (exttype == 0xf9) {
        if (seen_extension) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        seen_extension = true;
        size_t extsize;
        unsigned char * extdata = load_GIF_data_blocks(context, &scan_offset, &extsize);
        if (extsize != 4) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        if (*extdata & 1)
          next_transparent_index = extdata[3];
        else
          next_transparent_index = 256;
        ctxfree(context, extdata);
      } else if (exttype < 0x80)
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      else
        skip_GIF_data_blocks(context, &scan_offset);
    } break;
    case 0x2c: {
      if (scan_offset > context -> size - 9) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      scan_offset += 9;
      context -> image -> frames ++;
      if (!context -> image -> frames) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
      bool smaller_size = read_le16_unaligned(context -> data + scan_offset - 9) || read_le16_unaligned(context -> data + scan_offset - 7) ||
                          read_le16_unaligned(context -> data + scan_offset - 5) != context -> image -> width ||
                          read_le16_unaligned(context -> data + scan_offset - 3) != context -> image -> height;
      uint64_t * local_palette = ctxmalloc(context, 256 * sizeof *local_palette);
      unsigned local_palette_size = 2 << (context -> data[scan_offset - 1] & 7);
      if (context -> data[scan_offset - 1] & 0x80)
        load_GIF_palette(context, local_palette, &scan_offset, local_palette_size);
      else
        local_palette_size = 0;
      if (!(local_palette_size || real_global_palette_size)) throw(context, PLUM_ERR_UNDEFINED_PALETTE);
      if (next_transparent_index < (local_palette_size ? local_palette_size : real_global_palette_size))
        local_palette[next_transparent_index] = *transparent_color;
      else
        next_transparent_index = 256;
      if (transparent_index == 256) transparent_index = next_transparent_index;
      if (global_palette_size && !result) {
        // check if the current palette is compatible with the global one; if so, don't add any per-frame palettes
        if (!(smaller_size && next_transparent_index == 256) && transparent_index == next_transparent_index) {
          if (!local_palette_size) goto added;
          unsigned min = (local_palette_size < global_palette_size) ? local_palette_size : global_palette_size;
          // temporarily reset this location so it won't fail the check on that spot
          if (next_transparent_index < min) local_palette[next_transparent_index] = global_palette[next_transparent_index];
          bool palcheck = !memcmp(local_palette, global_palette, min * sizeof *global_palette);
          if (next_transparent_index < min) local_palette[next_transparent_index] = *transparent_color;
          if (palcheck) {
            if (local_palette_size > global_palette_size) {
              memcpy(global_palette + global_palette_size, local_palette + global_palette_size,
                     (local_palette_size - global_palette_size) * sizeof *global_palette);
              global_palette_size = local_palette_size;
            }
            goto added;
          }
        }
        // palettes are incompatible: break down the current global palette into per-frame copies
        if (context -> image -> frames) {
          result = ctxmalloc(context, (context -> image -> frames - 1) * sizeof *result);
          uint64_t * palcopy = ctxcalloc(context, 256 * sizeof *palcopy);
          // it doesn't matter that the pointer is reused, because it won't be freed explicitly
          for (uint_fast32_t p = 0; p < context -> image -> frames - 1; p ++) result[p] = palcopy;
          memcpy(palcopy, global_palette, global_palette_size * sizeof *palcopy);
          if (transparent_index < global_palette_size) palcopy[transparent_index] = *transparent_color;
        }
      }
      result = ctxrealloc(context, result, context -> image -> frames * sizeof *result);
      result[context -> image -> frames - 1] = ctxcalloc(context, 256 * sizeof **result);
      if (local_palette_size)
        memcpy(result[context -> image -> frames - 1], local_palette, local_palette_size * sizeof **result);
      else {
        memcpy(result[context -> image -> frames - 1], global_palette, global_palette_size * sizeof **result);
        if (next_transparent_index < global_palette_size)
          result[context -> image -> frames - 1][next_transparent_index] = *transparent_color;
      }
      // either the frame palette has been added to the per-frame list or the global palette is still in use
      added:
      ctxfree(context, local_palette);
      scan_offset ++;
      if (scan_offset >= context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      skip_GIF_data_blocks(context, &scan_offset);
      next_transparent_index = 256;
      seen_extension = false;
    } break;
    case 0x3b:
      if (!seen_extension) goto done;
    default:
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
  throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  done:
  if (!context -> image -> frames) throw(context, PLUM_ERR_NO_DATA);
  if (!result) {
    if (transparent_index < global_palette_size) global_palette[transparent_index] = *transparent_color;
    context -> image -> max_palette_index = global_palette_size - 1;
    context -> image -> palette = plum_malloc(context -> image, plum_color_buffer_size(global_palette_size, flags));
    if (!context -> image -> palette) throw(context, PLUM_ERR_OUT_OF_MEMORY);
    plum_convert_colors(context -> image -> palette, global_palette, global_palette_size, flags, PLUM_COLOR_64);
  }
  ctxfree(context, global_palette);
  return result;
}

void load_GIF_palette (struct context * context, uint64_t * restrict palette, size_t * restrict offset, unsigned size) {
  if (3 * size > context -> size - *offset) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  while (size --) {
    uint_fast64_t color = context -> data[(*offset) ++];
    color |= (uint_fast64_t) context -> data[(*offset) ++] << 16;
    color |= (uint_fast64_t) context -> data[(*offset) ++] << 32;
    *(palette ++) = color * 0x101;
  }
}

void * load_GIF_data_blocks (struct context * context, size_t * restrict offset, size_t * restrict loaded_size) {
  if (*offset >= context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  size_t current_size = 0, p = *offset;
  uint_fast8_t block;
  while (block = context -> data[p ++]) {
    p += block;
    current_size += block;
    if (p >= context -> size || p <= block) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
  *loaded_size = current_size;
  unsigned char * result = ctxmalloc(context, current_size);
  for (size_t copied_size = 0; block = context -> data[(*offset) ++]; copied_size += block) {
    memcpy(result + copied_size, context -> data + *offset, block);
    *offset += block;
  }
  return result;
}

void skip_GIF_data_blocks (struct context * context, size_t * restrict offset) {
  uint_fast8_t skip;
  do {
    if (*offset >= context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    skip = context -> data[(*offset) ++];
    if (context -> size < skip || *offset > context -> size - skip) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    *offset += skip;
  } while (skip);
}

void load_GIF_frame (struct context * context, size_t * restrict offset, unsigned flags, uint32_t frame, const uint64_t * restrict palette,
                     uint64_t transparent_color, uint64_t * restrict duration, uint8_t * restrict disposal) {
  *duration = *disposal = 0;
  int transparent_index = -1;
  // frames have already been validated, so at this point, we can only have extensions (0x21 ID block block block...) or image descriptors
  while (context -> data[(*offset) ++] == 0x21) {
    unsigned char extkind = context -> data[(*offset) ++];
    if (extkind != 0xf9 && extkind != 0xff) {
      skip_GIF_data_blocks(context, offset);
      continue;
    }
    size_t extsize;
    unsigned char * extdata = load_GIF_data_blocks(context, offset, &extsize);
    if (extkind == 0xff) {
      if (extsize == 14 && bytematch(extdata, 0x4e, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2e, 0x30, 0x01)) {
        if (plum_find_metadata(context -> image, PLUM_METADATA_LOOP_COUNT)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        add_loop_count_metadata(context, read_le16_unaligned(extdata + 12));
      }
    } else {
      *duration = (uint64_t) 10000000 * read_le16_unaligned(extdata + 1);
      uint_fast8_t dispindex = (*extdata >> 2) & 7;
      if (dispindex > 3) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      if (dispindex) *disposal = dispindex - 1;
      if (*extdata & 1) transparent_index = extdata[3];
    }
    ctxfree(context, extdata);
  }
  if (!*duration) *duration = 1;
  uint_fast32_t left = read_le16_unaligned(context -> data + *offset);
  uint_fast32_t top = read_le16_unaligned(context -> data + *offset + 2);
  uint_fast32_t width = read_le16_unaligned(context -> data + *offset + 4);
  uint_fast32_t height = read_le16_unaligned(context -> data + *offset + 6);
  if (left + width > context -> image -> width || top + height > context -> image -> height) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint_fast8_t frameflags = context -> data[*offset + 8];
  *offset += 9;
  uint8_t max_palette_index;
  if (frameflags & 0x80) {
    *offset += 6 << (frameflags & 7);
    max_palette_index = (2 << (frameflags & 7)) - 1;
  } else
    max_palette_index = (2 << (context -> data[10] & 7)) - 1;
  uint8_t codesize = context -> data[(*offset) ++];
  if (codesize < 2 || codesize > 11) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  size_t length;
  unsigned char * compressed = load_GIF_data_blocks(context, offset, &length);
  unsigned char * buffer = ctxmalloc(context, (size_t) width * height);
  decompress_GIF_data(context, buffer, compressed, width * height, length, codesize);
  ctxfree(context, compressed);
  if (frameflags & 0x40) {
    // interlaced frame
    unsigned char * temp = ctxmalloc(context, (size_t) width * height);
    uint_fast32_t target = 0;
    for (uint_fast32_t row = 0; row < height; row += 8) memcpy(temp + row * width, buffer + (target ++) * width, width);
    for (uint_fast32_t row = 4; row < height; row += 8) memcpy(temp + row * width, buffer + (target ++) * width, width);
    for (uint_fast32_t row = 2; row < height; row += 4) memcpy(temp + row * width, buffer + (target ++) * width, width);
    for (uint_fast32_t row = 1; row < height; row += 2) memcpy(temp + row * width, buffer + (target ++) * width, width);
    ctxfree(context, buffer);
    buffer = temp;
  }
  for (size_t p = 0; p < width * height; p ++) if (buffer[p] > max_palette_index) throw(context, PLUM_ERR_INVALID_COLOR_INDEX);
  if (width == context -> image -> width && height == context -> image -> height)
    write_palette_framebuffer_to_image(context, buffer, palette, frame, flags, 0xff);
  else if (context -> image -> palette) {
    if (transparent_index < 0) throw(context, PLUM_ERR_INVALID_FILE_FORMAT); // if we got here somehow, it's irrecoverable
    uint8_t * fullframe = ctxmalloc(context, context -> image -> width * context -> image -> height);
    memset(fullframe, transparent_index, context -> image -> width * context -> image -> height);
    for (uint_fast16_t row = top; row < top + height; row ++)
      memcpy(fullframe + context -> image -> width * row + left, buffer + width * (row - top), width);
    write_palette_framebuffer_to_image(context, fullframe, palette, frame, flags, 0xff);
    ctxfree(context, fullframe);
  } else {
    uint64_t * fullframe = ctxmalloc(context, sizeof *fullframe * context -> image -> width * context -> image -> height);
    uint64_t * current = fullframe;
    for (uint_fast16_t row = 0; row < top; row ++)
      for (uint_fast16_t col = 0; col < context -> image -> width; col ++) *(current ++) = transparent_color;
    for (uint_fast16_t row = top; row < top + height; row ++) {
      for (uint_fast16_t col = 0; col < left; col ++) *(current ++) = transparent_color;
      for (uint_fast16_t col = left; col < left + width; col ++) *(current ++) = palette[buffer[(row - top) * width + col - left]];
      for (uint_fast16_t col = left + width; col < context -> image -> width; col ++) *(current ++) = transparent_color;
    }
    for (uint_fast16_t row = top + height; row < context -> image -> height; row ++)
      for (uint_fast16_t col = 0; col < context -> image -> width; col ++) *(current ++) = transparent_color;
    write_framebuffer_to_image(context -> image, fullframe, frame, flags);
    ctxfree(context, fullframe);
  }
  ctxfree(context, buffer);
}

void generate_GIF_data (struct context * context) {
  if (context -> source -> width > 0xffffu || context -> source -> height > 0xffffu) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  // technically, some GIFs could be 87a; however, at the time of writing, 89a is over three decades old and supported by everything relevant
  byteoutput(context, 0x47, 0x49, 0x46, 0x38, 0x39, 0x61);
  unsigned char * header = append_output_node(context, 7);
  write_le16_unaligned(header, context -> source -> width);
  write_le16_unaligned(header + 2, context -> source -> height);
  uint_fast32_t depth = get_true_color_depth(context -> source);
  uint8_t overall = depth;
  if ((uint8_t) (depth >> 8) > overall) overall = depth >> 8;
  if ((uint8_t) (depth >> 16) > overall) overall = depth >> 16;
  if (overall > 8) overall = 8;
  header[4] = (overall - 1) << 4;
  header[5] = header[6] = 0;
  if (context -> source -> palette)
    generate_GIF_data_with_palette(context, header);
  else
    generate_GIF_data_from_raw(context, header);
  byteoutput(context, 0x3b);
}

void generate_GIF_data_with_palette (struct context * context, unsigned char * header) {
  uint_fast16_t colors = context -> source -> max_palette_index + 1;
  uint32_t * palette = ctxcalloc(context, 256 * sizeof *palette);
  plum_convert_colors(palette, context -> source -> palette, colors, PLUM_COLOR_32, context -> source -> color_format);
  int transparent = -1;
  uint8_t * mapping = NULL;
  for (uint_fast16_t p = 0; p <= context -> source -> max_palette_index; p ++) {
    if (palette[p] & 0x80000000u)
      if (transparent < 0)
        transparent = p;
      else {
        if (!mapping) {
          mapping = ctxmalloc(context, colors * sizeof *mapping);
          for (uint_fast16_t index = 0; index <= context -> source -> max_palette_index; index ++) mapping[index] = index;
        }
        mapping[p] = transparent;
      }
    palette[p] &= 0xffffffu;
  }
  int_fast32_t background = get_GIF_background_color(context);
  if (background >= 0) {
    uint_fast16_t index;
    for (index = 0; index < colors; index ++) if (palette[index] == background) break;
    if (index == colors && colors < 256) palette[colors ++] = background;
    background = (index < colors) ? index : -1;
  }
  uint_fast16_t colorbits;
  for (colorbits = 0; colors > (2 << colorbits); colorbits ++);
  uint_fast16_t colorcount = 2 << colorbits;
  header[4] |= 0x80 + colorbits;
  if (background >= 0) header[5] = background;
  write_GIF_palette(context, palette, colorcount);
  ctxfree(context, palette);
  write_GIF_loop_info(context);
  size_t framesize = (size_t) context -> source -> width * context -> source -> height;
  unsigned char * framebuffer = ctxmalloc(context, framesize);
  const struct plum_metadata * durations = plum_find_metadata(context -> source, PLUM_METADATA_FRAME_DURATION);
  const struct plum_metadata * disposals = plum_find_metadata(context -> source, PLUM_METADATA_FRAME_DISPOSAL);
  int64_t duration_remainder = 0;
  for (uint_fast32_t frame = 0; frame < context -> source -> frames; frame ++) {
    if (mapping)
      for (size_t pixel = 0; pixel < framesize; pixel ++) framebuffer[pixel] = mapping[context -> source -> data8[frame * framesize + pixel]];
    else
      memcpy(framebuffer, context -> source -> data8 + frame * framesize, framesize);
    uint_fast16_t left = 0, top = 0, width = context -> source -> width, height = context -> source -> height;
    if (transparent >= 0) {
      size_t index;
      for (index = 0; index < framesize; index ++) if (framebuffer[index] != transparent) break;
      if (index == framesize)
        width = height = 1;
      else {
        top = index / width;
        height -= top;
        for (index = 0; index < framesize; index ++) if (framebuffer[framesize - 1 - index] != transparent) break;
        height -= index / width;
        for (left = 0; left < width; left ++) for (index = top; index < top + height; index ++)
          if (framebuffer[index * context -> source -> width + left] != transparent) goto leftdone;
        leftdone:
        width -= left;
        uint_fast16_t col;
        for (col = 0; col < width; col ++) for (index = top; index < top + height; index ++)
          if (framebuffer[(index + 1) * context -> source -> width - 1 - col] != transparent) goto rightdone;
        rightdone:
        width -= col;
        if (left || width != context -> source -> width) {
          unsigned char * target = framebuffer;
          for (index = 0; index < height; index ++) for (col = 0; col < width; col ++)
            *(target ++) = framebuffer[(index + top) * context -> source -> width + col + left];
        } else if (top)
          memmove(framebuffer, framebuffer + context -> source -> width * top, context -> source -> width * height);
      }
    }
    write_GIF_frame(context, framebuffer, NULL, colorcount, transparent, frame, left, top, width, height, durations, disposals, &duration_remainder);
  }
  if (mapping) ctxfree(context, mapping);
  ctxfree(context, framebuffer);
}

void generate_GIF_data_from_raw (struct context * context, unsigned char * header) {
  int_fast32_t background = get_GIF_background_color(context);
  if (background >= 0) {
    header[4] |= 0x80;
    write_GIF_palette(context, (const uint32_t []) {background, 0}, 2);
  }
  write_GIF_loop_info(context);
  size_t framesize = (size_t) context -> source -> width * context -> source -> height;
  uint32_t * colorbuffer = ctxmalloc(context, sizeof *colorbuffer * framesize);
  unsigned char * framebuffer = ctxmalloc(context, framesize);
  const struct plum_metadata * durations = plum_find_metadata(context -> source, PLUM_METADATA_FRAME_DURATION);
  const struct plum_metadata * disposals = plum_find_metadata(context -> source, PLUM_METADATA_FRAME_DISPOSAL);
  size_t offset = plum_color_buffer_size(framesize, context -> source -> color_format);
  int64_t duration_remainder = 0;
  for (uint_fast32_t frame = 0; frame < context -> source -> frames; frame ++) {
    plum_convert_colors(colorbuffer, context -> source -> data8 + offset * frame, framesize, PLUM_COLOR_32, context -> source -> color_format);
    generate_GIF_frame_data(context, colorbuffer, framebuffer, frame, durations, disposals, &duration_remainder);
  }
  ctxfree(context, framebuffer);
  ctxfree(context, colorbuffer);
}

void generate_GIF_frame_data (struct context * context, uint32_t * restrict pixels, unsigned char * restrict framebuffer, uint32_t frame,
                              const struct plum_metadata * durations, const struct plum_metadata * disposals, int64_t * restrict duration_remainder) {
  size_t framesize = (size_t) context -> source -> height * context -> source -> width;
  uint32_t transparent = 0;
  for (size_t index = 0; index < framesize; index ++)
    if (pixels[index] & 0x80000000u) {
      if (!transparent) transparent = 0xff000000u | pixels[index];
      pixels[index] = transparent;
    } else
      pixels[index] &= 0xffffffu;
  uint_fast16_t left = 0, top = 0, width = context -> source -> width, height = context -> source -> height;
  if (transparent) {
    size_t index;
    for (index = 0; index < framesize; index ++) if (pixels[index] != transparent) break;
    if (index == framesize)
      width = height = 1;
    else {
      top = index / width;
      height -= top;
      for (index = 0; index < framesize; index ++) if (pixels[framesize - 1 - index] != transparent) break;
      height -= index / width;
      for (left = 0; left < width; left ++) for (index = top; index < top + height; index ++)
        if (pixels[index * context -> source -> width + left] != transparent) goto leftdone;
      leftdone:
      width -= left;
      uint_fast16_t col;
      for (col = 0; col < width; col ++) for (index = top; index < top + height; index ++)
        if (pixels[(index + 1) * context -> source -> width - 1 - col] != transparent) goto rightdone;
      rightdone:
      width -= col;
      if (left || width != context -> source -> width) {
        uint32_t * target = pixels;
        for (index = 0; index < height; index ++) for (col = 0; col < width; col ++)
          *(target ++) = pixels[(index + top) * context -> source -> width + col + left];
      } else if (top)
        memmove(pixels, pixels + context -> source -> width * top, sizeof *pixels * context -> source -> width * height);
    }
  }
  uint32_t * palette = ctxcalloc(context, 256 * sizeof *palette);
  int colorcount = plum_convert_colors_to_indexes(framebuffer, pixels, palette, (size_t) width * height, PLUM_COLOR_32);
  if (colorcount < 0) throw(context, -colorcount);
  int transparent_index = -1;
  if (transparent)
    for (uint_fast16_t index = 0; index <= colorcount; index ++) if (palette[index] == transparent) {
      transparent_index = index;
      break;
    }
  write_GIF_frame(context, framebuffer, palette, colorcount + 1, transparent_index, frame, left, top, width, height, durations, disposals, duration_remainder);
  ctxfree(context, palette);
}

int_fast32_t get_GIF_background_color (struct context * context) {
  const struct plum_metadata * metadata = plum_find_metadata(context -> source, PLUM_METADATA_BACKGROUND);
  if (!metadata) return -1;
  uint32_t converted;
  plum_convert_colors(&converted, metadata -> data, 1, PLUM_COLOR_32, context -> source -> color_format);
  return converted & 0xffffffu;
}

void write_GIF_palette (struct context * context, const uint32_t * restrict palette, unsigned count) {
  for (unsigned char * data = append_output_node(context, 3 * count); count; count --, palette ++)
    data += byteappend(data, *palette, *palette >> 8, *palette >> 16);
}

void write_GIF_loop_info (struct context * context) {
  const struct plum_metadata * metadata = plum_find_metadata(context -> source, PLUM_METADATA_LOOP_COUNT);
  if (!metadata) return;
  uint_fast32_t count = *(const uint32_t *) metadata -> data;
  if (count > 0xffffu) count = 0; // too many loops, so just make it loop forever
  if (count == 1) return;
  byteoutput(context, 0x21, 0xff, 0x0b, 0x4e, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2e, 0x30, 0x03, 0x01, count, count >> 8, 0x00);
}

void write_GIF_frame (struct context * context, const unsigned char * restrict data, const uint32_t * restrict palette, unsigned colors, int transparent,
                      uint32_t frame, unsigned left, unsigned top, unsigned width, unsigned height, const struct plum_metadata * durations,
                      const struct plum_metadata * disposals, int64_t * restrict duration_remainder) {
  uint64_t duration = 0;
  uint8_t disposal = 0;
  if (durations && durations -> size > sizeof(uint64_t) * frame) {
    duration = frame[(const uint64_t *) durations -> data];
    if (duration) {
      if (duration == 1) duration = 0;
      uint64_t true_duration = adjust_frame_duration(duration, duration_remainder);
      duration = (true_duration / 5000000u + 1) >> 1;
      if (duration > 0xffffu) duration = 0xffffu; // maxed out
      update_frame_duration_remainder(true_duration, duration * 10000000u, duration_remainder);
    }
  }
  if (disposals && disposals -> size > frame) {
    disposal = frame[(const uint8_t *) disposals -> data];
    if (disposal >= PLUM_DISPOSAL_REPLACE) disposal -= PLUM_DISPOSAL_REPLACE;
  }
  uint_fast8_t colorbits;
  for (colorbits = 0; colors > (2 << colorbits); colorbits ++);
  unsigned colorcount = 2 << colorbits;
  byteoutput(context, 0x21, 0xf9, 0x04, (disposal + 1) * 4 + (transparent >= 0), duration, duration >> 8, (transparent >= 0) ? transparent : 0, 0x00,
                      0x2c, left, left >> 8, top, top >> 8, width, width >> 8, height, height >> 8, colorbits | (palette ? 0x80 : 0));
  if (palette) write_GIF_palette(context, palette, colorcount);
  if (!colorbits) colorbits = 1;
  byteoutput(context, ++ colorbits); // incremented because compression starts with one bit extra
  size_t length;
  unsigned char * output = compress_GIF_data(context, data, (size_t) width * height, &length, colorbits);
  write_GIF_data_blocks(context, output, length);
  ctxfree(context, output);
}

void write_GIF_data_blocks (struct context * context, const unsigned char * restrict data, size_t size) {
  uint_fast8_t remainder = size % 0xff;
  size /= 0xff;
  unsigned char * output = append_output_node(context, size * 0x100 + (remainder ? remainder + 2 : 1));
  while (size --) {
    *(output ++) = 0xff;
    memcpy(output, data, 0xff);
    output += 0xff;
    data += 0xff;
  }
  if (remainder) {
    *(output ++) = remainder;
    memcpy(output, data, remainder);
    output += remainder;
  }
  *output = 0;
}

void generate_Huffman_tree (struct context * context, const size_t * restrict counts, unsigned char * restrict lengths, size_t entries, unsigned char max) {
  uint64_t * sorted = ctxmalloc(context, 2 * entries * sizeof *sorted);
  size_t truecount = 0;
  for (size_t p = 0; p < entries; p ++) if (counts[p]) {
    sorted[2 * truecount] = p;
    sorted[2 * truecount + 1] = ~(uint64_t) counts[p];
    truecount ++;
  }
  memset(lengths, 0, entries);
  if (truecount < 2) {
    if (truecount) lengths[*sorted] = 1;
    ctxfree(context, sorted);
    return;
  }
  qsort(sorted, truecount, 2 * sizeof *sorted, &compare_index_value_pairs);
  size_t * parents = ctxmalloc(context, (entries + truecount) * sizeof *parents);
  size_t * pendingnodes = ctxmalloc(context, truecount * sizeof *pendingnodes);
  size_t * pendingcounts = ctxmalloc(context, truecount * sizeof *pendingcounts);
  size_t next = entries;
  for (size_t p = 0; p < truecount; p ++) {
    pendingnodes[p] = sorted[2 * p];
    pendingcounts[p] = counts[pendingnodes[p]];
  }
  uint64_t remaining = truecount;
  while (remaining > 1) {
    parents[pendingnodes[-- remaining]] = next;
    parents[pendingnodes[remaining - 1]] = next;
    size_t sum = pendingcounts[remaining - 1] + pendingcounts[remaining];
    size_t first = 0, last = remaining - 1;
    while (first < last) {
      size_t p = (first + last) >> 1;
      if (sum >= pendingcounts[p])
        last = p;
      else if (last > first + 1)
        first = p;
      else
        first = p + 1;
    }
    memmove(pendingnodes + first + 1, pendingnodes + first, sizeof *pendingnodes * (remaining - 1 - first));
    memmove(pendingcounts + first + 1, pendingcounts + first, sizeof *pendingcounts * (remaining - 1 - first));
    pendingnodes[first] = next ++;
    pendingcounts[first] = sum;
  }
  ctxfree(context, pendingcounts);
  ctxfree(context, pendingnodes);
  size_t root = next - 1;
  unsigned char maxlength = 0;
  for (size_t p = 0; p < truecount; p ++) {
    next = sorted[p * 2];
    unsigned char length = 0;
    while (next != root) {
      if (length < 0xff) length ++;
      next = parents[next];
    }
    lengths[sorted[p * 2]] = length;
    if (length > maxlength) maxlength = length;
  }
  ctxfree(context, parents);
  if (maxlength > max) {
    // the maximum length has been exceeded, so increase some other lengths to make everything fit
    remaining = (uint64_t) 1 << max;
    for (size_t p = 0; p < truecount; p ++) {
      next = sorted[p * 2];
      if (lengths[next] > max) {
        lengths[next] = max;
        remaining --;
      } else {
        while (((uint64_t) 1 << (max - lengths[next])) > remaining) lengths[next] ++;
        while (remaining - ((uint64_t) 1 << (max - lengths[next])) < truecount - p - 1) lengths[next] ++;
        remaining -= (uint64_t) 1 << (max - lengths[next]);
      }
    }
    for (size_t p = 0; remaining; p ++) {
      next = sorted[p * 2];
      while (lengths[next] > 1 && remaining >= ((uint64_t) 1 << (max - lengths[next]))) {
        remaining -= (uint64_t) 1 << (max - lengths[next]);
        lengths[next] --;
      }
    }
  }
  ctxfree(context, sorted);
}

void generate_Huffman_codes (unsigned short * restrict codes, size_t count, const unsigned char * restrict lengths, bool invert) {
  // generates codes in ascending order: shorter codes before longer codes, and for the same length, smaller values before larger values
  size_t remaining = 0;
  for (size_t p = 0; p < count; p ++) if (lengths[p]) remaining ++;
  uint_fast8_t length = 0;
  uint_fast16_t code = 0;
  for (size_t p = SIZE_MAX; remaining; p ++) {
    if (p >= count) {
      length ++;
      code <<= 1;
      p = 0;
    }
    if (lengths[p] != length) continue;
    if (invert) {
      // for some image formats, invert the code so it can be written out directly (first branch at the LSB)
      uint_fast16_t temp = code ++;
      codes[p] = 0;
      for (uint_fast8_t bits = 0; bits < length; bits ++) {
        codes[p] = (codes[p] << 1) | (temp & 1);
        temp >>= 1;
      }
    } else
      codes[p] = code ++;
    remaining --;
  }
}

void decompress_JPEG_arithmetic_scan (struct context * context, struct JPEG_decompressor_state * restrict state, const struct JPEG_decoder_tables * tables,
                                      size_t rowunits, const struct JPEG_component_info * components, const size_t * restrict offsets, unsigned shift,
                                      unsigned char first, unsigned char last, bool differential) {
  for (size_t restart_interval = 0; restart_interval <= state -> restart_count; restart_interval ++) {
    size_t units = (restart_interval == state -> restart_count) ? state -> last_size : state -> restart_size;
    if (!units) break;
    size_t offset = *(offsets ++);
    size_t remaining = *(offsets ++);
    size_t colcount = 0, rowcount = 0, skipunits = 0;
    uint16_t accumulator = 0;
    uint32_t current = 0;
    unsigned char bits = 0;
    initialize_JPEG_arithmetic_counters(context, &offset, &remaining, &current);
    signed char indexesDC[4][49] = {0};
    signed char indexesAC[4][245] = {0};
    uint16_t prevDC[4] = {0};
    uint16_t prevdiff[4] = {0};
    while (units --) {
      int16_t (* outputunit)[64];
      for (const unsigned char * decodepos = state -> MCU; *decodepos != MCU_END_LIST; decodepos ++) switch (*decodepos) {
        case MCU_ZERO_COORD:
          outputunit = state -> current_block[decodepos[1]];
          break;
        case MCU_NEXT_ROW:
          outputunit += state -> row_offset[decodepos[1]];
          break;
        default: {
          bool prevzero = false; // was the previous coefficient zero?
          for (uint_fast8_t p = first; p <= last; p ++) {
            if (skipunits)
              p[*outputunit] = 0;
            else if (p) {
              unsigned char conditioning = tables -> arithmetic[components[*decodepos].tableAC + 4];
              signed char * index = indexesAC[components[*decodepos].tableAC] + 3 * (p - 1);
              if (!prevzero && next_JPEG_arithmetic_bit(context, &offset, &remaining, index, &current, &accumulator, &bits)) {
                p[*outputunit] = 0;
                skipunits ++;
              } else if (next_JPEG_arithmetic_bit(context, &offset, &remaining, index + 1, &current, &accumulator, &bits)) {
                p[*outputunit] = next_JPEG_arithmetic_value(context, &offset, &remaining, &current, &accumulator, &bits, indexesAC[components[*decodepos].tableAC],
                                                            1, p, conditioning);
                prevzero = false;
              } else {
                p[*outputunit] = 0;
                prevzero = true;
              }
            } else {
              unsigned char conditioning = tables -> arithmetic[components[*decodepos].tableDC];
              unsigned char category = classify_JPEG_arithmetic_value(prevdiff[*decodepos], conditioning);
              if (next_JPEG_arithmetic_bit(context, &offset, &remaining, indexesDC[components[*decodepos].tableDC] + 4 * category, &current, &accumulator, &bits))
                prevdiff[*decodepos] = next_JPEG_arithmetic_value(context, &offset, &remaining, &current, &accumulator, &bits,
                                                                  indexesDC[components[*decodepos].tableDC], 0, category, conditioning);
              else
                prevdiff[*decodepos] = 0;
              if (differential)
                **outputunit = make_signed_16(prevdiff[*decodepos]);
              else
                prevDC[*decodepos] = **outputunit = make_signed_16(prevDC[*decodepos] + prevdiff[*decodepos]);
            }
            p[*outputunit] = make_signed_16((uint16_t) p[*outputunit] << shift);
          }
          outputunit ++;
          if (skipunits) skipunits --;
        }
      }
      if (++ colcount == rowunits) {
        colcount = 0;
        rowcount ++;
        if (rowcount == state -> row_skip_index) skipunits += (rowunits - state -> column_skip_count) * state -> row_skip_count;
      }
      if (colcount == state -> column_skip_index) skipunits += state -> column_skip_count;
      for (uint_fast8_t p = 0; p < 4; p ++) if (state -> current_block[p]) {
        state -> current_block[p] += state -> unit_offset[p];
        if (!colcount) state -> current_block[p] += state -> unit_row_offset[p];
      }
    }
    if (remaining || skipunits) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
}

void decompress_JPEG_arithmetic_bit_scan (struct context * context, struct JPEG_decompressor_state * restrict state, size_t rowunits,
                                          const struct JPEG_component_info * components, const size_t * restrict offsets, unsigned shift, unsigned char first,
                                          unsigned char last) {
  // this function is very similar to decompress_JPEG_arithmetic_scan, but it only decodes the next bit for already-initialized data
  if (last && !first) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  for (size_t restart_interval = 0; restart_interval <= state -> restart_count; restart_interval ++) {
    size_t units = (restart_interval == state -> restart_count) ? state -> last_size : state -> restart_size;
    if (!units) break;
    size_t offset = *(offsets ++);
    size_t remaining = *(offsets ++);
    size_t colcount = 0, rowcount = 0, skipunits = 0;
    uint16_t accumulator = 0;
    uint32_t current = 0;
    unsigned char bits = 0;
    initialize_JPEG_arithmetic_counters(context, &offset, &remaining, &current);
    signed char indexes[4][189] = {0}; // most likely very few will be actually used, but allocate for the worst case
    while (units --) {
      int16_t (* outputunit)[64];
      for (const unsigned char * decodepos = state -> MCU; *decodepos != MCU_END_LIST; decodepos ++) switch (*decodepos) {
        case MCU_ZERO_COORD:
          outputunit = state -> current_block[decodepos[1]];
          break;
        case MCU_NEXT_ROW:
          outputunit += state -> row_offset[decodepos[1]];
          break;
        default:
          if (skipunits)
            skipunits --;
          else if (first) {
            unsigned char lastnonzero; // last non-zero coefficient up to the previous scan (for the same component)
            for (lastnonzero = 63; lastnonzero; lastnonzero --) if (lastnonzero[*outputunit]) break;
            bool prevzero = false; // was the previous coefficient zero?
            for (uint_fast8_t p = first; p <= last; p ++) {
              signed char * index = indexes[components[*decodepos].tableAC] + 3 * (p - 1);
              if (!prevzero && p > lastnonzero && next_JPEG_arithmetic_bit(context, &offset, &remaining, index, &current, &accumulator, &bits)) break;
              if (p[*outputunit]) {
                prevzero = false;
                if (next_JPEG_arithmetic_bit(context, &offset, &remaining, index + 2, &current, &accumulator, &bits))
                  if (p[*outputunit] < 0)
                    p[*outputunit] -= 1 << shift;
                  else
                    p[*outputunit] += 1 << shift;
              } else if (next_JPEG_arithmetic_bit(context, &offset, &remaining, index + 1, &current, &accumulator, &bits)) {
                prevzero = false;
                p[*outputunit] = next_JPEG_arithmetic_bit(context, &offset, &remaining, NULL, &current, &accumulator, &bits) ?
                                 make_signed_16(0xffffu << shift) : (1 << shift);
              } else
                prevzero = true;
            }
          } else if (next_JPEG_arithmetic_bit(context, &offset, &remaining, NULL, &current, &accumulator, &bits))
            **outputunit += 1 << shift;
          outputunit ++;
      }
      if (++ colcount == rowunits) {
        colcount = 0;
        rowcount ++;
        if (rowcount == state -> row_skip_index) skipunits += (rowunits - state -> column_skip_count) * state -> row_skip_count;
      }
      if (colcount == state -> column_skip_index) skipunits += state -> column_skip_count;
      for (uint_fast8_t p = 0; p < 4; p ++) if (state -> current_block[p]) {
        state -> current_block[p] += state -> unit_offset[p];
        if (!colcount) state -> current_block[p] += state -> unit_row_offset[p];
      }
    }
    if (remaining || skipunits) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
}

void decompress_JPEG_arithmetic_lossless_scan (struct context * context, struct JPEG_decompressor_state * restrict state, const struct JPEG_decoder_tables * tables,
                                               size_t rowunits, const struct JPEG_component_info * components, const size_t * restrict offsets,
                                               unsigned char predictor, unsigned precision) {
  bool scancomponents[4] = {0};
  for (uint_fast8_t p = 0; state -> MCU[p] != MCU_END_LIST; p ++) if (state -> MCU[p] < 4) scancomponents[state -> MCU[p]] = true;
  uint16_t * rowdifferences[4] = {0};
  for (uint_fast8_t p = 0; p < 4; p ++) if (scancomponents[p])
    rowdifferences[p] = ctxmalloc(context, sizeof **rowdifferences * rowunits * ((state -> component_count > 1) ? components[p].scaleH : 1));
  for (size_t restart_interval = 0; restart_interval <= state -> restart_count; restart_interval ++) {
    size_t units = (restart_interval == state -> restart_count) ? state -> last_size : state -> restart_size;
    if (!units) break;
    size_t offset = *(offsets ++);
    size_t remaining = *(offsets ++);
    size_t colcount = 0, rowcount = 0, skipunits = 0;
    uint16_t accumulator = 0;
    uint32_t current = 0;
    unsigned char bits = 0;
    initialize_JPEG_arithmetic_counters(context, &offset, &remaining, &current);
    signed char indexes[4][158] = {0};
    for (uint_fast8_t p = 0; p < 4; p ++) if (scancomponents[p])
      for (uint_fast16_t x = 0; x < (rowunits * ((state -> component_count > 1) ? components[p].scaleH : 1)); x ++) rowdifferences[p][x] = 0;
    uint16_t coldifferences[4][4] = {0};
    while (units --) {
      uint_fast16_t x, y;
      uint16_t * outputpos;
      for (const unsigned char * decodepos = state -> MCU; *decodepos != MCU_END_LIST; decodepos ++) switch (*decodepos) {
        case MCU_ZERO_COORD:
          outputpos = state -> current_value[decodepos[1]];
          x = colcount * ((state -> component_count > 1) ? components[decodepos[1]].scaleH : 1);
          y = 0;
          break;
        case MCU_NEXT_ROW:
          outputpos += state -> row_offset[decodepos[1]];
          x = colcount * ((state -> component_count > 1) ? components[decodepos[1]].scaleH : 1);
          y ++;
          break;
        default:
          if (skipunits) {
            *(outputpos ++) = 0;
            skipunits --;
          } else {
            unsigned char conditioning = tables -> arithmetic[components[*decodepos].tableDC];
            size_t rowsize = rowunits * ((state -> component_count > 1) ? components[*decodepos].scaleH : 1);
            uint16_t difference, predicted = predict_JPEG_lossless_sample(outputpos, rowsize, !x, !(y || rowcount), predictor, precision);
            // the JPEG standard calculates this the other way around, but it makes no difference and doing it in this order enables an optimization
            unsigned char reference = 5 * classify_JPEG_arithmetic_value(rowdifferences[*decodepos][x], conditioning) +
                                      classify_JPEG_arithmetic_value(coldifferences[*decodepos][y], conditioning);
            if (next_JPEG_arithmetic_bit(context, &offset, &remaining, indexes[components[*decodepos].tableDC] + 4 * reference, &current, &accumulator, &bits))
              difference = next_JPEG_arithmetic_value(context, &offset, &remaining, &current, &accumulator, &bits, indexes[components[*decodepos].tableDC],
                                                      2, reference, conditioning);
            else
              difference = 0;
            rowdifferences[*decodepos][x] = coldifferences[*decodepos][y] = difference;
            *(outputpos ++) = predicted + difference;
          }
          x ++;
      }
      if (++ colcount == rowunits) {
        colcount = 0;
        rowcount ++;
        if (rowcount == state -> row_skip_index) skipunits += (rowunits - state -> column_skip_count) * state -> row_skip_count;
        memset(coldifferences, 0, sizeof coldifferences);
      }
      if (colcount == state -> column_skip_index) skipunits += state -> column_skip_count;
      for (uint_fast8_t p = 0; p < 4; p ++) if (state -> current_value[p]) {
        state -> current_value[p] += state -> unit_offset[p];
        if (!colcount) state -> current_value[p] += state -> unit_row_offset[p];
      }
    }
    if (remaining || skipunits) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
  for (uint_fast8_t p = 0; p < state -> component_count; p ++) ctxfree(context, rowdifferences[p]);
}

void initialize_JPEG_arithmetic_counters (struct context * context, size_t * restrict offset, size_t * restrict remaining, uint32_t * restrict current) {
  for (uint_fast8_t loopcount = 0; loopcount < 2; loopcount ++) {
    unsigned char data = 0;
    if (*remaining) {
      data = context -> data[(*offset) ++];
      -- *remaining;
    }
    if (data == 0xff) while (*remaining) {
      -- *remaining;
      if (context -> data[(*offset) ++] != 0xff) break;
    }
    *current = (*current | data) << 8;
  }
}

int16_t next_JPEG_arithmetic_value (struct context * context, size_t * restrict offset, size_t * restrict remaining, uint32_t * restrict current,
                                    uint16_t * restrict accumulator, unsigned char * restrict bits, signed char * restrict indexes, unsigned mode,
                                    unsigned reference, unsigned char conditioning) {
  // mode = 0 for DC (reference = DC category), 1 for AC (reference = coefficient index), 2 for lossless (reference = 5 * top category + left category)
  signed char * index = (mode == 1) ? NULL : (indexes + 4 * reference + 1);
  bool negative = next_JPEG_arithmetic_bit(context, offset, remaining, index, current, accumulator, bits);
  index = (mode == 1) ? indexes + 3 * reference - 1 : (index + 1 + negative);
  uint_fast8_t size = next_JPEG_arithmetic_bit(context, offset, remaining, index, current, accumulator, bits);
  uint16_t result = 0;
  if (size) {
    if (!mode)
      index = indexes + 20;
    else if (mode == 2)
      index = indexes + 100 + 29 * (reference >= 15);
    signed char * next_index = (mode == 1) ? indexes + 189 + 28 * (reference > conditioning) : (index + 1);
    while (next_JPEG_arithmetic_bit(context, offset, remaining, index, current, accumulator, bits)) {
      size ++;
      if (size > 15) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      index = next_index ++;
    }
    result = 1;
    index += 14;
    while (-- size) result = (result << 1) + next_JPEG_arithmetic_bit(context, offset, remaining, index, current, accumulator, bits);
  }
  result ++;
  if (negative) result = -result;
  return make_signed_16(result);
}

unsigned char classify_JPEG_arithmetic_value (uint16_t value, unsigned char conditioning) {
  // 0-4 for zero, small positive, small negative, large positive, large negative
  uint16_t absolute = (value >= 0x8000u) ? -value : value;
  uint16_t low = 0, high = (uint16_t) 1 << (conditioning >> 4);
  conditioning &= 15;
  if (conditioning) low = 1 << (conditioning - 1);
  if (absolute <= low) return 0;
  return ((value >= 0x8000u) ? 2 : 1) + 2 * (absolute > high);
}

bool next_JPEG_arithmetic_bit (struct context * context, size_t * restrict offset, size_t * restrict remaining, signed char * restrict index,
                               uint32_t * restrict current, uint16_t * restrict accumulator, unsigned char * restrict bits) {
  // negative state index: MPS = 1; null state: use 0 and don't update
  // index 0 implies MPS = 0; there's no way to encode index = 0 and MPS = 1 (because that'd be state = -0), but that state cannot happen
  static const struct JPEG_arithmetic_decoder_state states[] = {
    /*   0 */ {0x5a1d,  true,   1,   1}, {0x2586, false,   2,  14}, {0x1114, false,   3,  16}, {0x080b, false,   4,  18}, {0x03d8, false,   5,  20},
    /*   5 */ {0x01da, false,   6,  23}, {0x00e5, false,   7,  25}, {0x006f, false,   8,  28}, {0x0036, false,   9,  30}, {0x001a, false,  10,  33},
    /*  10 */ {0x000d, false,  11,  35}, {0x0006, false,  12,   9}, {0x0003, false,  13,  10}, {0x0001, false,  13,  12}, {0x5a7f,  true,  15,  15},
    /*  15 */ {0x3f25, false,  16,  36}, {0x2cf2, false,  17,  38}, {0x207c, false,  18,  39}, {0x17b9, false,  19,  40}, {0x1182, false,  20,  42},
    /*  20 */ {0x0cef, false,  21,  43}, {0x09a1, false,  22,  45}, {0x072f, false,  23,  46}, {0x055c, false,  24,  48}, {0x0406, false,  25,  49},
    /*  25 */ {0x0303, false,  26,  51}, {0x0240, false,  27,  52}, {0x01b1, false,  28,  54}, {0x0144, false,  29,  56}, {0x00f5, false,  30,  57},
    /*  30 */ {0x00b7, false,  31,  59}, {0x008a, false,  32,  60}, {0x0068, false,  33,  62}, {0x004e, false,  34,  63}, {0x003b, false,  35,  32},
    /*  35 */ {0x002c, false,   9,  33}, {0x5ae1,  true,  37,  37}, {0x484c, false,  38,  64}, {0x3a0d, false,  39,  65}, {0x2ef1, false,  40,  67},
    /*  40 */ {0x261f, false,  41,  68}, {0x1f33, false,  42,  69}, {0x19a8, false,  43,  70}, {0x1518, false,  44,  72}, {0x1177, false,  45,  73},
    /*  45 */ {0x0e74, false,  46,  74}, {0x0bfb, false,  47,  75}, {0x09f8, false,  48,  77}, {0x0861, false,  49,  78}, {0x0706, false,  50,  79},
    /*  50 */ {0x05cd, false,  51,  48}, {0x04de, false,  52,  50}, {0x040f, false,  53,  50}, {0x0363, false,  54,  51}, {0x02d4, false,  55,  52},
    /*  55 */ {0x025c, false,  56,  53}, {0x01f8, false,  57,  54}, {0x01a4, false,  58,  55}, {0x0160, false,  59,  56}, {0x0125, false,  60,  57},
    /*  60 */ {0x00f6, false,  61,  58}, {0x00cb, false,  62,  59}, {0x00ab, false,  63,  61}, {0x008f, false,  32,  61}, {0x5b12,  true,  65,  65},
    /*  65 */ {0x4d04, false,  66,  80}, {0x412c, false,  67,  81}, {0x37d8, false,  68,  82}, {0x2fe8, false,  69,  83}, {0x293c, false,  70,  84},
    /*  70 */ {0x2379, false,  71,  86}, {0x1edf, false,  72,  87}, {0x1aa9, false,  73,  87}, {0x174e, false,  74,  72}, {0x1424, false,  75,  72},
    /*  75 */ {0x119c, false,  76,  74}, {0x0f6b, false,  77,  74}, {0x0d51, false,  78,  75}, {0x0bb6, false,  79,  77}, {0x0a40, false,  48,  77},
    /*  80 */ {0x5832,  true,  81,  80}, {0x4d1c, false,  82,  88}, {0x438e, false,  83,  89}, {0x3bdd, false,  84,  90}, {0x34ee, false,  85,  91},
    /*  85 */ {0x2eae, false,  86,  92}, {0x299a, false,  87,  93}, {0x2516, false,  71,  86}, {0x5570,  true,  89,  88}, {0x4ca9, false,  90,  95},
    /*  90 */ {0x44d9, false,  91,  96}, {0x3e22, false,  92,  97}, {0x3824, false,  93,  99}, {0x32b4, false,  94,  99}, {0x2e17, false,  86,  93},
    /*  95 */ {0x56a8,  true,  96,  95}, {0x4f46, false,  97, 101}, {0x47e5, false,  98, 102}, {0x41cf, false,  99, 103}, {0x3c3d, false, 100, 104},
    /* 100 */ {0x375e, false,  93,  99}, {0x5231, false, 102, 105}, {0x4c0f, false, 103, 106}, {0x4639, false, 104, 107}, {0x415e, false,  99, 103},
    /* 105 */ {0x5627,  true, 106, 105}, {0x50e7, false, 107, 108}, {0x4b85, false, 103, 109}, {0x5597, false, 109, 110}, {0x504f, false, 107, 111},
    /* 110 */ {0x5a10,  true, 111, 110}, {0x5522, false, 109, 112}, {0x59eb,  true, 111, 112}
  };
  const struct JPEG_arithmetic_decoder_state * state = states + (index ? absolute_value(*index) : 0);
  bool decoded, predicted = index && *index < 0; // predict the MPS; decode a 1 if the prediction is false
  *accumulator -= state -> probability;
  if (*accumulator > (*current >> 8)) {
    if (*accumulator >= 0x8000u) return predicted;
    decoded = *accumulator < state -> probability;
  } else {
    decoded = *accumulator >= state -> probability;
    *current -= (uint32_t) *accumulator << 8;
    *accumulator = state -> probability;
  }
  if (index)
    if (decoded)
      *index = (predicted != state -> switch_MPS) ? -state -> next_LPS : state -> next_LPS;
    else
      *index = predicted ? -state -> next_MPS : state -> next_MPS;
  // normalize the counters, consuming new data if needed
  do {
    if (!*bits) {
      unsigned char data = 0;
      if (*remaining) {
        data = context -> data[(*offset) ++];
        -- *remaining;
      }
      if (data == 0xff) while (*remaining) {
        -- *remaining;
        if (context -> data[(*offset) ++] != 0xff) break;
      }
      *current |= data;
      *bits = 8;
    }
    *accumulator <<= 1;
    *current = (*current << 1) & 0xffffffu;
    -- *bits;
  } while (*accumulator < 0x8000u);
  return predicted != decoded;
}

uint32_t determine_JPEG_components (struct context * context, size_t offset) {
  uint_fast16_t size = read_be16_unaligned(context -> data + offset);
  if (size < 8) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint_fast8_t count = context -> data[offset + 7];
  if (!count || count > 4) throw(context, PLUM_ERR_INVALID_FILE_FORMAT); // only recognize up to four components
  if (size != 8 + 3 * count) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  unsigned char components[4] = {0};
  for (uint_fast8_t p = 0; p < count; p ++) components[p] = context -> data[offset + 8 + 3 * p];
  #define swap(first, second) do {    \
    uint_fast8_t temp = first;        \
    first = second, second = temp;    \
  } while (false)
  switch (count) {
    // since there's at most four components, a simple swap-based sort is the best implementation
    case 4:
      if (components[3] < *components) swap(*components, components[3]);
      if (components[3] < components[1]) swap(components[1], components[3]);
      if (components[3] < components[2]) swap(components[2], components[3]);
    case 3:
      if (components[2] < *components) swap(*components, components[2]);
      if (components[2] < components[1]) swap(components[1], components[2]);
    case 2:
      if (components[1] < *components) swap(*components, components[1]);
  }
  #undef swap
  for (uint_fast8_t p = 1; p < count; p ++) if (components[p - 1] == components[p]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  return read_le32_unaligned(components);
}

unsigned get_JPEG_component_count (uint32_t components) {
  if (components < 0x100)
    return 1;
  else if (components < 0x10000u)
    return 2;
  else if (components < 0x1000000u)
    return 3;
  else
    return 4;
}

void (* get_JPEG_component_transfer_function (struct context * context, const struct JPEG_marker_layout * layout, uint32_t components))
      (uint64_t * restrict, size_t, unsigned, const double **) {
  /* The JPEG standard has a very large deficiency: it specifies how to encode an arbitrary set of components of an
     image, but it doesn't specify what those components mean. Components have a single byte ID to identify them, but
     beyond that, the standard just hopes that applications can somehow figure it all out.
     Of course, this means that different extensions make different choices about what components an image can have
     and what those components' IDs should be. Determining the components of an image largely becomes a guessing
     process, typically based on what the IJG's libjpeg does (except that it's not even stable across versions...).
     This function therefore attempts to guess what the image's components mean, and errors out if it can't. */
  if (components < 0x100)
    // if there's only one component, assume the image is just grayscale
    return &JPEG_transfer_grayscale;
  if (layout -> Adobe) {
    if (read_be16_unaligned(context -> data + layout -> Adobe) < 14) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    // Adobe stores a color format ID and specifies four possibilities based on it
    switch (context -> data[layout -> Adobe + 13]) {
      case 0:
        // RGB or CMYK, so check the component count and try to detect the order
        if (components < 0x10000u)
          throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        else if (components < 0x1000000u)
          if (components == 0x524742u || components == 0x726762u) // 'R', 'G', 'B' (including lowercase)
            return &JPEG_transfer_BGR;
          else if (!((components + 0x102) % 0x10101u)) // any sequential IDs
            return &JPEG_transfer_RGB;
          else
            throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        else
          if (components == 0x594d4b43u || components == 0x796d6b63u) // 'C', 'M', 'Y', 'K' (including lowercase)
            return &JPEG_transfer_CKMY;
          else if (!((components + 0x10203u) % 0x1010101u)) // any sequential IDs
            return &JPEG_transfer_CMYK;
          else
            throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      case 1:
        // YCbCr: verify three components and detect the order
        if (components < 0x10000u || components >= 0x1000000u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        if (components == 0x635943u) // 'Y', 'C', 'c'
          return &JPEG_transfer_CbYCr;
        else if (!((components + 0x102) % 0x10101u)) // any sequential IDs
          return &JPEG_transfer_YCbCr;
        else
          throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      case 2:
        // YCbCrK: verify four components and detect the order
        if (components < 0x1000000u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        if (components == 0x63594b43u) // 'Y', 'C', 'c', 'K'
          return &JPEG_transfer_CbKYCr;
        else if (!((components + 0x10203u) % 0x1010101u)) // any sequential IDs
          return &JPEG_transfer_YCbCrK;
      default:
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
  }
  if (layout -> JFIF) {
    // JFIF mandates one of two possibilities: grayscale (handled already) or YCbCr with IDs of 1, 2, 3 (although some encoders also use 0, 1, 2)
    if (components == 0x30201u || components == 0x20100u) return &JPEG_transfer_YCbCr;
    throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
  // below this line it's pure guesswork: there are no application headers hinting at components, so just guess from popular ID values
  if ((*layout -> frametype & 3) == 3 && components >= 0x10000u && components < 0x1000000u && !((components + 0x102) % 0x10101u))
    // lossless encoding, three sequential component IDs
    return &JPEG_transfer_RGB;
  switch (components) {
    case 0x5941u: // 'Y', 'A'
      return &JPEG_transfer_alpha_grayscale;
    case 0x20100u: // 0, 1, 2: used by libjpeg sometimes
    case 0x30201u: // 1, 2, 3: JFIF's standard IDs
    case 0x232201u: // 1, 0x22, 0x23: used by some library for 'big gamut' colors
      return &JPEG_transfer_YCbCr;
    case 0x635943u: // 'Y', 'C', 'c'
      return &JPEG_transfer_CbYCr;
    case 0x524742u: // 'R', 'G', 'B'
    case 0x726762u: // 'r', 'g', 'b'
      return &JPEG_transfer_BGR;
    case 0x4030201u: // 1, 2, 3, 4
      return &JPEG_transfer_YCbCrK;
    case 0x63594b43u: // 'Y', 'C', 'c', 'K'
      return &JPEG_transfer_CbKYCr;
    case 0x63594341u: // 'Y', 'C', 'c', 'A'
      return &JPEG_transfer_ACbYCr;
    case 0x52474241u: // 'R', 'G', 'B', 'A'
    case 0x72676261u: // 'r', 'g', 'b', 'a'
      return &JPEG_transfer_ABGR;
    case 0x594d4b43u: // 'C', 'M', 'Y', 'K'
    case 0x796d6b63u: // 'c', 'm', 'y', 'k'
      return &JPEG_transfer_CKMY;
    default:
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
}

void append_JPEG_color_depth_metadata (struct context * context, void (* transfer) (uint64_t * restrict, size_t, unsigned, const double **), unsigned bitdepth) {
  if (transfer == &JPEG_transfer_grayscale)
    add_color_depth_metadata(context, 0, 0, 0, 0, bitdepth);
  else if (transfer == &JPEG_transfer_alpha_grayscale)
    add_color_depth_metadata(context, 0, 0, 0, bitdepth, bitdepth);
  else if (transfer == &JPEG_transfer_ABGR || transfer == &JPEG_transfer_ACbYCr)
    add_color_depth_metadata(context, bitdepth, bitdepth, bitdepth, bitdepth, 0);
  else
    add_color_depth_metadata(context, bitdepth, bitdepth, bitdepth, 0, 0);
}

void JPEG_transfer_RGB (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  double factor = 65535.0 / limit;
  const double * red = *input;
  const double * green = input[1];
  const double * blue = input[2];
  while (count --) *(output ++) = color_from_floats(*(red ++) * factor, *(green ++) * factor, *(blue ++) * factor, 0);
}

void JPEG_transfer_BGR (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  JPEG_transfer_RGB(output, count, limit, (const double * []) {input[2], input[1], *input});
}

void JPEG_transfer_ABGR (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  double factor = 65535.0 / limit;
  const double * red = input[3];
  const double * green = input[2];
  const double * blue = input[1];
  const double * alpha = *input;
  while (count --) *(output ++) = color_from_floats(*(red ++) * factor, *(green ++) * factor, *(blue ++) * factor, (limit - *(alpha ++)) * factor);
}

void JPEG_transfer_grayscale (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  double factor = 65535.0 / limit;
  const double * luma = *input;
  while (count --) {
    double scaled = *(luma ++) * factor;
    *(output ++) = color_from_floats(scaled, scaled, scaled, 0);
  }
}

void JPEG_transfer_alpha_grayscale (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  double factor = 65535.0 / limit;
  const double * luma = input[1];
  const double * alpha = *input;
  while (count --) {
    double scaled = *(luma ++) * factor;
    *(output ++) = color_from_floats(scaled, scaled, scaled, (limit - *(alpha ++)) * factor);
  }
}

// all constants are defined to have exactly 53 bits of precision (matching IEEE 754 doubles)
#define RED_COEF      0x0.b374bc6a7ef9d8p+0
#define BLUE_COEF     0x0.e2d0e560418938p+0
#define GREEN_CR_COEF 0x0.5b68d15d0f6588p+0
#define GREEN_CB_COEF 0x0.2c0ca8674cd62ep+0

void JPEG_transfer_YCbCr (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  double factor = 65535.0 / limit;
  const double * luma = *input;
  const double * blue_chroma = input[1];
  const double * red_chroma = input[2];
  while (count --) {
    double blue_offset = limit - *(blue_chroma ++) * 2;
    double red_offset = limit - *(red_chroma ++) * 2;
    double red = *luma - RED_COEF * red_offset, blue = *luma - BLUE_COEF * blue_offset;
    double green = *luma + GREEN_CB_COEF * blue_offset + GREEN_CR_COEF * red_offset;
    luma ++;
    *(output ++) = color_from_floats(red * factor, green * factor, blue * factor, 0);
  }
}

void JPEG_transfer_CbYCr (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  JPEG_transfer_YCbCr(output, count, limit, (const double * []) {input[1], *input, input[2]});
}

void JPEG_transfer_YCbCrK (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  // this function replicates the YCbCr transfer function, but then darkens each color by the K component
  double factor = 65535.0 / ((uint32_t) limit * limit);
  const double * luma = *input;
  const double * blue_chroma = input[1];
  const double * red_chroma = input[2];
  const double * black = input[3];
  while (count --) {
    double blue_offset = limit - *(blue_chroma ++) * 2;
    double red_offset = limit - *(red_chroma ++) * 2;
    double red = *luma - RED_COEF * red_offset, blue = *luma - BLUE_COEF * blue_offset;
    double green = *luma + GREEN_CB_COEF * blue_offset + GREEN_CR_COEF * red_offset;
    luma ++;
    double scale = *(black ++) * factor;
    *(output ++) = color_from_floats(red * scale, green * scale, blue * scale, 0);
  }
}

void JPEG_transfer_CbKYCr (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  JPEG_transfer_YCbCrK(output, count, limit, (const double * []) {input[2], *input, input[3], input[1]});
}

void JPEG_transfer_ACbYCr (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  // this function replicates the YCbCr transfer function and computes a separate alpha channel
  double factor = 65535.0 / limit;
  const double * luma = input[2];
  const double * blue_chroma = input[1];
  const double * red_chroma = input[3];
  const double * alpha = *input;
  while (count --) {
    double blue_offset = limit - *(blue_chroma ++) * 2;
    double red_offset = limit - *(red_chroma ++) * 2;
    double red = *luma - RED_COEF * red_offset, blue = *luma - BLUE_COEF * blue_offset;
    double green = *luma + GREEN_CB_COEF * blue_offset + GREEN_CR_COEF * red_offset;
    luma ++;
    *(output ++) = color_from_floats(red * factor, green * factor, blue * factor, (limit - *(alpha ++)) * factor);
  }
}

#undef RED_COEF
#undef BLUE_COEF
#undef GREEN_CR_COEF
#undef GREEN_CB_COEF

void JPEG_transfer_CMYK (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  double factor = 65535.0 / ((uint32_t) limit * limit);
  const double * cyan = *input;
  const double * magenta = input[1];
  const double * yellow = input[2];
  const double * black = input[3];
  while (count --) {
    double scale = *(black ++) * factor;
    *(output ++) = color_from_floats(*(cyan ++) * scale, *(magenta ++) * scale, *(yellow ++) * scale, 0);
  }
}

void JPEG_transfer_CKMY (uint64_t * restrict output, size_t count, unsigned limit, const double ** input) {
  JPEG_transfer_CMYK(output, count, limit, (const double * []) {*input, input[2], input[3], input[1]});
}

struct JPEG_encoded_value * generate_JPEG_luminance_data_stream (struct context * context, double (* restrict data)[64], size_t units,
                                                                 const uint8_t quantization[restrict static 64], size_t * restrict count) {
  *count = 0;
  size_t allocated = 3 * units + 64;
  struct JPEG_encoded_value * result = ctxmalloc(context, sizeof *result * allocated);
  double predicted = 0.0;
  for (size_t unit = 0; unit < units; unit ++) {
    if (allocated - *count < 64) {
      size_t newsize = allocated + 3 * (units - unit) + 64;
      if (newsize < allocated) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
      result = ctxrealloc(context, result, sizeof *result * (allocated = newsize));
    }
    predicted = generate_JPEG_data_unit(result, count, data[unit], quantization, predicted);
  }
  return ctxrealloc(context, result, *count * sizeof *result);
}

struct JPEG_encoded_value * generate_JPEG_chrominance_data_stream (struct context * context, double (* restrict blue)[64], double (* restrict red)[64],
                                                                   size_t units, const uint8_t quantization[restrict static 64], size_t * restrict count) {
  *count = 0;
  size_t allocated = 6 * units + 128;
  struct JPEG_encoded_value * result = ctxmalloc(context, sizeof *result * allocated);
  double predicted_blue = 0.0, predicted_red = 0.0;
  for (size_t unit = 0; unit < units; unit ++) {
    if (allocated - *count < 128) {
      size_t newsize = allocated + 6 * (units - unit) + 128;
      if (newsize < allocated) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
      result = ctxrealloc(context, result, sizeof *result * (allocated = newsize));
    }
    predicted_blue = generate_JPEG_data_unit(result, count, blue[unit], quantization, predicted_blue);
    predicted_red = generate_JPEG_data_unit(result, count, red[unit], quantization, predicted_red);
  }
  return ctxrealloc(context, result, *count * sizeof *result);
}

double generate_JPEG_data_unit (struct JPEG_encoded_value * data, size_t * restrict count, const double unit[restrict static 64],
                                const uint8_t quantization[restrict static 64], double predicted) {
  int16_t output[64];
  predicted = apply_JPEG_DCT(output, unit, quantization, predicted);
  uint_fast8_t last = 0;
  encode_JPEG_value(data + (*count) ++, *output, 0, 0);
  for (uint_fast8_t p = 1; p < 63; p ++) if (output[p]) {
    for (; (p - last) > 16; last += 16) data[(*count) ++] = (struct JPEG_encoded_value) {.code = 0xf0, .bits = 0, .type = 1};
    encode_JPEG_value(data + (*count) ++, output[p], 1, (p - last - 1) << 4);
    last = p;
  }
  if (last != 63) data[(*count) ++] = (struct JPEG_encoded_value) {.code = 0, .bits = 0, .type = 1};
  return predicted;
}

void encode_JPEG_value (struct JPEG_encoded_value * data, int16_t value, unsigned type, unsigned char addend) {
  unsigned bits = bit_width(absolute_value(value));
  if (value < 0) value += 0x7fff; // make it positive and subtract 1 from the significant bits
  value &= (1u << bits) - 1;
  *data = (struct JPEG_encoded_value) {.code = addend + bits, .bits = bits, .type = type, .value = value};
}

size_t generate_JPEG_Huffman_table (struct context * context, const struct JPEG_encoded_value * data, size_t count, unsigned char * restrict output,
                                    unsigned char table[restrict static 0x100], unsigned char index) {
  // returns the number of bytes spent encoding the table in the JPEG data (in output)
  size_t counts[0x101] = {[0x100] = 1}; // use 0x100 as a dummy value to absorb the highest (invalid) code
  unsigned char lengths[0x101];
  *output = index;
  index >>= 4;
  for (size_t p = 0; p < count; p ++) if (data[p].type == index) counts[data[p].code] ++;
  generate_Huffman_tree(context, counts, lengths, 0x101, 16);
  unsigned char codecounts[16] = {0};
  uint_fast8_t maxcode, maxlength = 0;
  for (uint_fast16_t p = 0; p < 0x100; p ++) if (lengths[p]) {
    codecounts[lengths[p] - 1] ++;
    if (lengths[p] > maxlength) {
      maxlength = lengths[p];
      maxcode = p;
    }
  }
  if (lengths[0x100] < maxlength) {
    codecounts[maxlength] --;
    codecounts[lengths[0x100]] ++;
    lengths[maxcode] = lengths[0x100];
  }
  memcpy(table, lengths, 0x100);
  memcpy(output + 1, codecounts, 16);
  size_t outsize = 17;
  for (uint_fast8_t length = 1; length <= 16; length ++) for (uint_fast16_t p = 0; p < 0x100; p ++) if (lengths[p] == length) output[outsize ++] = p;
  return outsize;
}

void encode_JPEG_scan (struct context * context, const struct JPEG_encoded_value * data, size_t count, const unsigned char table[restrict static 0x200]) {
  unsigned short codes[0x200]; // no need to create a dummy entry for the highest (invalid) code here: it simply won't be generated
  generate_Huffman_codes(codes, 0x100, table, false);
  generate_Huffman_codes(codes + 0x100, 0x100, table + 0x100, false);
  unsigned char * node = append_output_node(context, 0x4000);
  size_t size = 0;
  uint_fast32_t output = 0;
  unsigned char bits = 0;
  for (size_t p = 0; p < count; p ++) {
    if (size > 0x3ff8) {
      context -> output -> size = size;
      node = append_output_node(context, 0x4000);
      size = 0;
    }
    unsigned short index = data[p].type * 0x100 + data[p].code;
    output = (output << table[index]) | codes[index];
    bits += table[index];
    while (bits >= 8) {
      node[size ++] = output >> (bits -= 8);
      if (node[size - 1] == 0xff) node[size ++] = 0;
    }
    if (data[p].bits) {
      output = (output << data[p].bits) | data[p].value;
      bits += data[p].bits;
      while (bits >= 8) {
        node[size ++] = output >> (bits -= 8);
        if (node[size - 1] == 0xff) node[size ++] = 0;
      }
    }
  }
  if (bits) node[size ++] = output << (8 - bits);
  context -> output -> size = size;
}

// Cx = 0.5 * cos(x * pi / 16), rounded so that it fits exactly in 53 bits (standard precision for IEEE doubles)
// note that C4 = 0.5 / sqrt(2), so this value is also used for that purpose
#define C1 0x0.7d8a5f3fdd72c0p+0
#define C2 0x0.7641af3cca3518p+0
#define C3 0x0.6a6d98a43a868cp+0
#define C4 0x0.5a827999fcef34p+0
#define C5 0x0.471cece6b9a320p+0
#define C6 0x0.30fbc54d5d52c6p+0
#define C7 0x0.18f8b83c69a60bp+0

// half the square root of 2
#define HR2 0x0.b504f333f9de68p+0

double apply_JPEG_DCT (int16_t output[restrict static 64], const double input[restrict static 64], const uint8_t quantization[restrict static 64], double prevDC) {
  // coefficient(dst, src) = cos((2 * src + 1) * dst * pi / 16) / 2; this absorbs a leading factor of 1/4 (square rooted)
  static const double coefficients[8][8] = {
    {0.5,  C1,  C2,  C3,  C4,  C5,  C6,  C7},
    {0.5,  C3,  C6, -C7, -C4, -C1, -C2, -C5},
    {0.5,  C5, -C6, -C1, -C4,  C7,  C2,  C3},
    {0.5,  C7, -C2, -C5,  C4,  C3, -C6, -C1},
    {0.5, -C7, -C2,  C5,  C4, -C3, -C6,  C1},
    {0.5, -C5, -C6,  C1, -C4, -C7,  C2, -C3},
    {0.5, -C3,  C6,  C7, -C4,  C1, -C2,  C5},
    {0.5, -C1,  C2, -C3,  C4, -C5,  C6, -C7}
  };
  // factor(row, col) = (row ? 1 : 1 / sqrt(2)) * (col ? 1 : 1 / sqrt(2)); converted into zigzag order
  static const double factors[] = {
    0.5, HR2, HR2, HR2, 1.0, HR2, HR2, 1.0, 1.0, HR2, HR2, 1.0, 1.0, 1.0, HR2, HR2, 1.0, 1.0, 1.0, 1.0, HR2, HR2, 1.0, 1.0, 1.0, 1.0, 1.0, HR2, HR2, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, HR2, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0
  };
  // zero-flushing threshold: for later coefficients, round some values slightly larger than 0.5 to 0 instead of +/- 1 for better compression
  static const double zeroflush[] = {
    0x0.80p+0, 0x0.80p+0, 0x0.80p+0, 0x0.80p+0, 0x0.81p+0, 0x0.80p+0, 0x0.84p+0, 0x0.85p+0, 0x0.85p+0, 0x0.84p+0,
    0x0.88p+0, 0x0.89p+0, 0x0.8ap+0, 0x0.89p+0, 0x0.88p+0, 0x0.8cp+0, 0x0.8dp+0, 0x0.8ep+0, 0x0.8ep+0, 0x0.8dp+0,
    0x0.8cp+0, 0x0.90p+0, 0x0.91p+0, 0x0.92p+0, 0x0.93p+0, 0x0.92p+0, 0x0.91p+0, 0x0.90p+0, 0x0.94p+0, 0x0.95p+0,
    0x0.96p+0, 0x0.97p+0, 0x0.97p+0, 0x0.96p+0, 0x0.95p+0, 0x0.94p+0, 0x0.98p+0, 0x0.99p+0, 0x0.9ap+0, 0x0.9bp+0,
    0x0.9ap+0, 0x0.99p+0, 0x0.98p+0, 0x0.9cp+0, 0x0.9dp+0, 0x0.9ep+0, 0x0.9ep+0, 0x0.9dp+0, 0x0.9cp+0, 0x0.a0p+0,
    0x0.a1p+0, 0x0.a2p+0, 0x0.a1p+0, 0x0.a0p+0, 0x0.a4p+0, 0x0.a5p+0, 0x0.a5p+0, 0x0.a4p+0, 0x0.a8p+0, 0x0.a9p+0,
    0x0.a8p+0, 0x0.acp+0, 0x0.acp+0, 0x0.b0p+0
  };
  for (uint_fast8_t index = 0; index < 64; index ++) {
    uint_fast8_t p = 0;
    double converted = 0.0;
    for (uint_fast8_t row = 0; row < 8; row ++) for (uint_fast8_t col = 0; col < 8; col ++)
      converted += input[p ++] * coefficients[col][JPEG_zigzag_columns[index]] * coefficients[row][JPEG_zigzag_rows[index]];
    converted = converted * factors[index] / quantization[index];
    if (index)
      if (converted >= -zeroflush[index] && converted <= zeroflush[index])
        output[index] = 0;
      else if (converted > 1023.0)
        output[index] = 1023;
      else if (converted < -1023.0)
        output[index] = -1023;
      else if (converted < 0)
        output[index] = converted - 0.5;
      else
        output[index] = converted + 0.5;
    else {
      converted -= prevDC;
      if (converted > 2047.0)
        *output = 2047;
      else if (converted < -2047.0)
        *output = -2047;
      else if (converted < 0)
        *output = converted - 0.5;
      else
        *output = converted + 0.5;
    }
  }
  return prevDC + *output;
}

void apply_JPEG_inverse_DCT (double output[restrict static 64], const int16_t input[restrict static 64], const uint16_t quantization[restrict static 64]) {
  // coefficient(dst, src) = 0.5 * (src ? cos((2 * dst + 1) * src * pi / 16) : 1 / sqrt(2)); this absorbs a leading factor of 1/4 (square rooted)
  static const double coefficients[8][8] = {
    {C4,  C1,  C2,  C3,  C4,  C5,  C6,  C7},
    {C4,  C3,  C6, -C7, -C4, -C1, -C2, -C5},
    {C4,  C5, -C6, -C1, -C4,  C7,  C2,  C3},
    {C4,  C7, -C2, -C5,  C4,  C3, -C6, -C1},
    {C4, -C7, -C2,  C5,  C4, -C3, -C6,  C1},
    {C4, -C5, -C6,  C1, -C4, -C7,  C2, -C3},
    {C4, -C3,  C6,  C7, -C4,  C1, -C2,  C5},
    {C4, -C1,  C2, -C3,  C4, -C5,  C6, -C7}
  };
  double dequantized[64];
  for (uint_fast8_t index = 0; index < 64; index ++) dequantized[index] = (double) input[index] * quantization[index];
  uint_fast8_t p = 0;
  for (uint_fast8_t row = 0; row < 8; row ++) for (uint_fast8_t col = 0; col < 8; col ++) {
    output[p] = 0;
    for (uint_fast8_t index = 0; index < 64; index ++)
      output[p] += coefficients[col][JPEG_zigzag_columns[index]] * coefficients[row][JPEG_zigzag_rows[index]] * dequantized[index];
    p ++;
  }
}

#undef HR2
#undef C7
#undef C6
#undef C5
#undef C4
#undef C3
#undef C2
#undef C1

void initialize_JPEG_decompressor_state (struct context * context, struct JPEG_decompressor_state * restrict state, const struct JPEG_component_info * components,
                                         const unsigned char * componentIDs, size_t * restrict unitsH, size_t unitsV, size_t width, size_t height,
                                         unsigned char maxH, unsigned char maxV, const struct JPEG_decoder_tables * tables, const size_t * restrict offsets,
                                         int16_t (* restrict * output)[64]) {
  initialize_JPEG_decompressor_state_common(context, state, components, componentIDs, unitsH, unitsV, width, height, maxH, maxV, tables, offsets, 8);
  for (uint_fast8_t p = 0; p < 4; p ++) state -> current_block[p] = NULL;
  for (uint_fast8_t p = 0; p < state -> component_count; p ++) state -> current_block[componentIDs[p]] = output[componentIDs[p]];
}

void initialize_JPEG_decompressor_state_lossless (struct context * context, struct JPEG_decompressor_state * restrict state,
                                                  const struct JPEG_component_info * components, const unsigned char * componentIDs, size_t * restrict unitsH,
                                                  size_t unitsV, size_t width, size_t height, unsigned char maxH, unsigned char maxV,
                                                  const struct JPEG_decoder_tables * tables, const size_t * restrict offsets, uint16_t * restrict * output) {
  initialize_JPEG_decompressor_state_common(context, state, components, componentIDs, unitsH, unitsV, width, height, maxH, maxV, tables, offsets, 1);
  for (uint_fast8_t p = 0; p < 4; p ++) state -> current_value[p] = NULL;
  for (uint_fast8_t p = 0; p < state -> component_count; p ++) state -> current_value[componentIDs[p]] = output[componentIDs[p]];
}

void initialize_JPEG_decompressor_state_common (struct context * context, struct JPEG_decompressor_state * restrict state,
                                                const struct JPEG_component_info * components, const unsigned char * componentIDs, size_t * restrict unitsH,
                                                size_t unitsV, size_t width, size_t height, unsigned char maxH, unsigned char maxV,
                                                const struct JPEG_decoder_tables * tables, const size_t * restrict offsets, unsigned char unit_dimensions) {
  if (componentIDs[1] != 0xff) {
    unsigned char * entry = state -> MCU;
    uint_fast8_t component;
    for (component = 0; component < 4 && componentIDs[component] != 0xff; component ++) {
      uint_fast8_t p = componentIDs[component];
      state -> unit_offset[p] = components[p].scaleH;
      state -> row_offset[p] = *unitsH * state -> unit_offset[p];
      state -> unit_row_offset[p] = (components[p].scaleV - 1) * state -> row_offset[p];
      state -> row_offset[p] -= state -> unit_offset[p];
      for (uint_fast8_t row = 0; row < components[p].scaleV; row ++) {
        *(entry ++) = row ? MCU_NEXT_ROW : MCU_ZERO_COORD;
        for (uint_fast8_t col = 0; col < components[p].scaleH; col ++) *(entry ++) = p;
      }
    }
    *entry = MCU_END_LIST;
    state -> component_count = component;
    state -> row_skip_index = state -> row_skip_count = state -> column_skip_index = state -> column_skip_count = 0;
  } else {
    // if a scan contains a single component, it's considered a non-interleaved scan and the MCU is a single unit
    state -> component_count = 1;
    state -> unit_offset[*componentIDs] = 1;
    state -> row_offset[*componentIDs] = state -> unit_row_offset[*componentIDs] = 0;
    bytewrite(state -> MCU, MCU_ZERO_COORD, *componentIDs, MCU_END_LIST);
    *unitsH *= components[*componentIDs].scaleH;
    unitsV *= components[*componentIDs].scaleV;
    state -> column_skip_index = 1 + (width * components[*componentIDs].scaleH - 1) / (unit_dimensions * maxH);
    state -> column_skip_count = *unitsH - state -> column_skip_index;
    state -> row_skip_index = 1 + (height * components[*componentIDs].scaleV - 1) / (unit_dimensions * maxV);
    state -> row_skip_count = unitsV - state -> row_skip_index;
  }
  state -> last_size = *unitsH * unitsV;
  if (state -> restart_size = tables -> restart) {
    state -> restart_count = state -> last_size / state -> restart_size;
    state -> last_size %= state -> restart_size;
  } else
    state -> restart_count = 0;
  size_t true_restart_count = state -> restart_count + !!state -> last_size; // including the final restart interval
  for (size_t index = 0; index < true_restart_count; index ++) if (!offsets[2 * index]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (offsets[2 * true_restart_count]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
}

uint16_t predict_JPEG_lossless_sample (const uint16_t * next, ptrdiff_t rowsize, bool leftmost, bool topmost, unsigned predictor, unsigned precision) {
  if (!predictor) return 0;
  if (topmost)
    if (leftmost)
      return 1u << (precision - 1);
    else
      return next[-1];
  else if (leftmost)
    return next[-rowsize];
  uint_fast32_t left = next[-1], top = next[-rowsize], corner = next[-1 - rowsize];
  return predictor[(const uint16_t []) {0, left, top, corner, left + top - corner, left + ((top - corner) >> 1), top + ((left - corner) >> 1), (left + top) >> 1}];
}

unsigned load_hierarchical_JPEG (struct context * context, const struct JPEG_marker_layout * layout, uint32_t components, double ** output) {
  unsigned component_count = get_JPEG_component_count(components);
  unsigned char componentIDs[4];
  write_le32_unaligned(componentIDs, components);
  struct JPEG_decoder_tables tables;
  initialize_JPEG_decoder_tables(context, &tables, layout);
  unsigned precision = context -> data[layout -> hierarchical + 2];
  if (precision < 2 || precision > 16) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  size_t metadata_index = 0;
  uint16_t component_size[8] = {0}; // four widths followed by four heights
  for (size_t frame = 0; layout -> frames[frame]; frame ++) {
    if (context -> data[layout -> frames[frame] + 2] != precision) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    uint32_t framecomponents = determine_JPEG_components(context, layout -> frames[frame]);
    unsigned char frameIDs[4]; // IDs into the componentIDs array
    unsigned char framecount = 0;
    double * frameoutput[4] = {0};
    do {
      uint_fast8_t p;
      for (p = 0; p < component_count; p ++) if (((framecomponents >> (8 * framecount)) & 0xff) == componentIDs[p]) break;
      if (p == component_count) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      frameoutput[framecount] = output[p];
      frameIDs[framecount ++] = p;
    } while (framecount < 4 && (framecomponents >> (8 * framecount)));
    unsigned char expand = process_JPEG_metadata_until_offset(context, layout, &tables, &metadata_index, layout -> frames[frame]);
    uint16_t framewidth = read_be16_unaligned(context -> data + layout -> frames[frame] + 5);
    uint16_t frameheight = read_be16_unaligned(context -> data + layout -> frames[frame] + 3);
    if (!(framewidth && frameheight) || framewidth > context -> image -> width || frameheight > context -> image -> height)
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (layout -> frametype[frame] & 4) {
      for (uint_fast8_t p = 0; p < framecount; p ++) {
        if (!component_size[frameIDs[p]] || framewidth < component_size[frameIDs[p]] || frameheight < component_size[frameIDs[p] + 4])
          throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        // round all components to integers, since hierarchical progressions expect to compute differences against integers
        size_t limit = (size_t) component_size[frameIDs[p]] * component_size[frameIDs[p] + 4];
        double * data = output[frameIDs[p]];
        for (size_t index = 0; index < limit; index ++) data[index] = (uint16_t) (long) (data[index] + 65536.5); // avoid UB and round negative values correctly
      }
      if (expand) {
        double * buffer = ctxmalloc(context, sizeof *buffer * framewidth * frameheight);
        if (expand & 0x10) for (uint_fast8_t p = 0; p < framecount; p ++) {
          expand_JPEG_component_horizontally(context, output[frameIDs[p]], component_size[frameIDs[p]], component_size[frameIDs[p] + 4], framewidth, buffer);
          component_size[frameIDs[p]] = framewidth;
        }
        if (expand & 1) for (uint_fast8_t p = 0; p < framecount; p ++) {
          expand_JPEG_component_vertically(context, output[frameIDs[p]], component_size[frameIDs[p]], component_size[frameIDs[p] + 4], frameheight, buffer);
          component_size[frameIDs[p] + 4] = frameheight;
        }
        ctxfree(context, buffer);
      }
      for (uint_fast8_t p = 0; p < framecount; p ++) if (component_size[frameIDs[p]] != framewidth || component_size[frameIDs[p] + 4] != frameheight)
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    } else {
      if (expand) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      for (uint_fast8_t p = 0; p < framecount; p ++) {
        if (component_size[frameIDs[p]]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        component_size[frameIDs[p]] = framewidth;
        component_size[frameIDs[p] + 4] = frameheight;
      }
    }
    if ((layout -> frametype[frame] & 3) == 3)
      load_JPEG_lossless_frame(context, layout, framecomponents, frame, &tables, &metadata_index, frameoutput, precision, framewidth, frameheight);
    else
      load_JPEG_DCT_frame(context, layout, framecomponents, frame, &tables, &metadata_index, frameoutput, precision, framewidth, frameheight);
  }
  double normalization_offset;
  if (precision < 15)
    normalization_offset = 0.5;
  else if (precision == 15)
    normalization_offset = 0.25;
  else
    normalization_offset = 0.0;
  for (uint_fast8_t p = 0; p < component_count; p ++) {
    if (component_size[p] != context -> image -> width || component_size[p + 4] != context -> image -> height) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    normalize_JPEG_component(output[p], (size_t) context -> image -> width * context -> image -> height, normalization_offset);
  }
  return precision;
}

void expand_JPEG_component_horizontally (struct context * context, double * restrict component, size_t width, size_t height, size_t target,
                                         double * restrict buffer) {
  if ((target >> 1) > width) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  size_t index = 0;
  for (size_t row = 0; row < height; row ++) for (size_t col = 0; col < target; col ++)
    if (col & 1)
      if (((col + 1) >> 1) == width)
        buffer[index ++] = component[(row + 1) * width - 1];
      else
        buffer[index ++] = (uint32_t) ((long) component[row * width + (col >> 1)] + (long) component[row * width + ((col + 1) >> 1)]) >> 1;
    else
      buffer[index ++] = component[row * width + (col >> 1)];
  memcpy(component, buffer, index * sizeof *component);
}

void expand_JPEG_component_vertically (struct context * context, double * restrict component, size_t width, size_t height, size_t target,
                                       double * restrict buffer) {
  if ((target >> 1) > height) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  size_t index = 0;
  for (size_t row = 0; row < target; row ++)
    if (row & 1)
      if (((row + 1) >> 1) == height) {
        memcpy(buffer + index, component + (height - 1) * width, sizeof *component * width);
        index += width;
      } else
        for (size_t col = 0; col < width; col ++)
          buffer[index ++] = (uint32_t) ((long) component[(row >> 1) * width + col] + (long) component[((row + 1) >> 1) * width + col]) >> 1;
    else {
      memcpy(buffer + index, component + (row >> 1) * width, sizeof *component * width);
      index += width;
    }
  memcpy(component, buffer, index * sizeof *component);
}

void normalize_JPEG_component (double * restrict component, size_t count, double offset) {
  while (count --) {
    double high = *component / 65536.0 + offset;
    // this merely calculates adjustment = -floor(high); not using floor() directly to avoid linking in the math library just for a single function
    int64_t adjustment = 0;
    if (high < 0) {
      adjustment = 1 + (int64_t) -high;
      high += adjustment;
    }
    adjustment -= (int64_t) high;
    *(component ++) += adjustment * 65536.0;
  }
}

void decompress_JPEG_Huffman_scan (struct context * context, struct JPEG_decompressor_state * restrict state, const struct JPEG_decoder_tables * tables,
                                   size_t rowunits, const struct JPEG_component_info * components, const size_t * restrict offsets, unsigned shift,
                                   unsigned char first, unsigned char last, bool differential) {
  for (size_t restart_interval = 0; restart_interval <= state -> restart_count; restart_interval ++) {
    size_t units = (restart_interval == state -> restart_count) ? state -> last_size : state -> restart_size;
    if (!units) break;
    size_t colcount = 0, rowcount = 0, skipcount = 0, skipunits = 0;
    const unsigned char * data = context -> data + *(offsets ++);
    size_t count = *(offsets ++);
    uint16_t prevDC[4] = {0};
    int16_t nextvalue = 0;
    uint32_t dataword = 0;
    uint8_t bits = 0;
    while (units --) {
      int16_t (* outputunit)[64];
      for (const unsigned char * decodepos = state -> MCU; *decodepos != MCU_END_LIST; decodepos ++) switch (*decodepos) {
        case MCU_ZERO_COORD:
          outputunit = state -> current_block[decodepos[1]];
          break;
        case MCU_NEXT_ROW:
          outputunit += state -> row_offset[decodepos[1]];
          break;
        default:
          for (uint_fast8_t p = first; p <= last; p ++) {
            if (!(skipcount || nextvalue || skipunits)) {
              unsigned char decompressed;
              if (p) {
                decompressed = next_JPEG_Huffman_value(context, &data, &count, &dataword, &bits, tables -> Huffman[components[*decodepos].tableAC + 4]);
                if (decompressed & 15)
                  skipcount = decompressed >> 4;
                else if (decompressed == 0xf0)
                  skipcount = 16;
                else
                  skipunits = (1u << (decompressed >> 4)) + shift_in_right_JPEG(context, decompressed >> 4, &dataword, &bits, &data, &count);
                decompressed &= 15;
              } else {
                decompressed = next_JPEG_Huffman_value(context, &data, &count, &dataword, &bits, tables -> Huffman[components[*decodepos].tableDC]);
                if (decompressed > 15) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
              }
              if (decompressed) {
                uint_fast16_t extrabits = shift_in_right_JPEG(context, decompressed, &dataword, &bits, &data, &count);
                if (!(extrabits >> (decompressed - 1))) nextvalue = make_signed_16(1u - (1u << decompressed));
                nextvalue = make_signed_16(nextvalue + extrabits);
              }
            }
            if (skipcount || skipunits) {
              p[*outputunit] = 0;
              if (skipcount) skipcount --;
            } else {
              p[*outputunit] = nextvalue * (1 << shift);
              nextvalue = 0;
            }
            if (!(p || differential)) prevDC[*decodepos] = **outputunit = make_signed_16(prevDC[*decodepos] + (uint16_t) **outputunit);
          }
          outputunit ++;
          if (skipunits) skipunits --;
      }
      if (++ colcount == rowunits) {
        colcount = 0;
        rowcount ++;
        if (rowcount == state -> row_skip_index) skipunits += (rowunits - state -> column_skip_count) * state -> row_skip_count;
      }
      if (colcount == state -> column_skip_index) skipunits += state -> column_skip_count;
      for (uint_fast8_t p = 0; p < 4; p ++) if (state -> current_block[p]) {
        state -> current_block[p] += state -> unit_offset[p];
        if (!colcount) state -> current_block[p] += state -> unit_row_offset[p];
      }
    }
    if (count || skipcount || skipunits || nextvalue) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
}

void decompress_JPEG_Huffman_bit_scan (struct context * context, struct JPEG_decompressor_state * restrict state, const struct JPEG_decoder_tables * tables,
                                       size_t rowunits, const struct JPEG_component_info * components, const size_t * restrict offsets, unsigned shift,
                                       unsigned char first, unsigned char last) {
  // this function is essentially the same as decompress_JPEG_Huffman_scan, but it uses already-initialized component data, and it decodes one bit at a time
  if (last && !first) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  for (size_t restart_interval = 0; restart_interval <= state -> restart_count; restart_interval ++) {
    size_t units = (restart_interval == state -> restart_count) ? state -> last_size : state -> restart_size;
    if (!units) break;
    size_t colcount = 0, rowcount = 0, skipcount = 0, skipunits = 0;
    const unsigned char * data = context -> data + *(offsets ++);
    size_t count = *(offsets ++);
    int16_t nextvalue = 0;
    uint32_t dataword = 0;
    uint8_t bits = 0;
    while (units --) {
      int16_t (* outputunit)[64];
      for (const unsigned char * decodepos = state -> MCU; *decodepos != MCU_END_LIST; decodepos ++) switch (*decodepos) {
        case MCU_ZERO_COORD:
          outputunit = state -> current_block[decodepos[1]];
          break;
        case MCU_NEXT_ROW:
          outputunit += state -> row_offset[decodepos[1]];
          break;
        default:
          if (first) {
            for (uint_fast8_t p = first; p <= last; p ++) {
              if (!(skipcount || nextvalue || skipunits)) {
                unsigned char decompressed = next_JPEG_Huffman_value(context, &data, &count, &dataword, &bits,
                                                                     tables -> Huffman[components[*decodepos].tableAC + 4]);
                if (decompressed & 15)
                  skipcount = decompressed >> 4;
                else if (decompressed == 0xf0)
                  skipcount = 16;
                else
                  skipunits = (1u << (decompressed >> 4)) + shift_in_right_JPEG(context, decompressed >> 4, &dataword, &bits, &data, &count);
                decompressed &= 15;
                if (decompressed) {
                  uint_fast16_t extrabits = shift_in_right_JPEG(context, decompressed, &dataword, &bits, &data, &count);
                  if (!(extrabits >> (decompressed - 1))) nextvalue = make_signed_16(1u - (1u << decompressed));
                  nextvalue = make_signed_16(nextvalue + extrabits);
                }
              }
              if (p[*outputunit]) {
                if (shift_in_right_JPEG(context, 1, &dataword, &bits, &data, &count))
                  if (p[*outputunit] < 0)
                    p[*outputunit] -= 1 << shift;
                  else
                    p[*outputunit] += 1 << shift;
              } else if (skipcount || skipunits) {
                if (skipcount) skipcount --;
              } else {
                p[*outputunit] = nextvalue * (1 << shift);
                nextvalue = 0;
              }
            }
          } else if (!skipunits)
            **outputunit += shift_in_right_JPEG(context, 1, &dataword, &bits, &data, &count) << shift;
          outputunit ++;
          if (skipunits) skipunits --;
      }
      if (++ colcount == rowunits) {
        colcount = 0;
        rowcount ++;
        if (rowcount == state -> row_skip_index) skipunits += (rowunits - state -> column_skip_count) * state -> row_skip_count;
      }
      if (colcount == state -> column_skip_index) skipunits += state -> column_skip_count;
      for (uint_fast8_t p = 0; p < 4; p ++) if (state -> current_block[p]) {
        state -> current_block[p] += state -> unit_offset[p];
        if (!colcount) state -> current_block[p] += state -> unit_row_offset[p];
      }
    }
    if (count || skipcount || skipunits || nextvalue) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
}

void decompress_JPEG_Huffman_lossless_scan (struct context * context, struct JPEG_decompressor_state * restrict state, const struct JPEG_decoder_tables * tables,
                                            size_t rowunits, const struct JPEG_component_info * components, const size_t * restrict offsets,
                                            unsigned char predictor, unsigned precision) {
  for (size_t restart_interval = 0; restart_interval <= state -> restart_count; restart_interval ++) {
    size_t units = (restart_interval == state -> restart_count) ? state -> last_size : state -> restart_size;
    if (!units) break;
    const unsigned char * data = context -> data + *(offsets ++);
    size_t count = *(offsets ++);
    size_t colcount = 0, rowcount = 0, skipunits = 0;
    uint32_t dataword = 0;
    uint8_t bits = 0;
    while (units --) {
      uint16_t * outputpos;
      bool leftmost, topmost;
      for (const unsigned char * decodepos = state -> MCU; *decodepos != MCU_END_LIST; decodepos ++) switch (*decodepos) {
        case MCU_ZERO_COORD:
          outputpos = state -> current_value[decodepos[1]];
          leftmost = topmost = true;
          break;
        case MCU_NEXT_ROW:
          outputpos += state -> row_offset[decodepos[1]];
          leftmost = true;
          topmost = false;
          break;
        default:
          if (skipunits) {
            *(outputpos ++) = 0;
            skipunits --;
          } else {
            size_t rowsize = rowunits * ((state -> component_count > 1) ? components[*decodepos].scaleH : 1);
            uint16_t difference, predicted = predict_JPEG_lossless_sample(outputpos, rowsize, leftmost && !colcount, topmost && !rowcount, predictor, precision);
            unsigned char diffsize = next_JPEG_Huffman_value(context, &data, &count, &dataword, &bits, tables -> Huffman[components[*decodepos].tableDC]);
            if (diffsize > 16) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
            switch (diffsize) {
              case 0:
                difference = 0;
                break;
              case 16:
                difference = 0x8000u;
                break;
              default:
                difference = shift_in_right_JPEG(context, diffsize, &dataword, &bits, &data, &count);
                if (!(difference >> (diffsize - 1))) difference -= (1u << diffsize) - 1;
            }
            *(outputpos ++) = predicted + difference;
          }
          leftmost = false;
      }
      if (++ colcount == rowunits) {
        colcount = 0;
        rowcount ++;
        if (rowcount == state -> row_skip_index) skipunits += (rowunits - state -> column_skip_count) * state -> row_skip_count;
      }
      if (colcount == state -> column_skip_index) skipunits += state -> column_skip_count;
      for (uint_fast8_t p = 0; p < 4; p ++) if (state -> current_value[p]) {
        state -> current_value[p] += state -> unit_offset[p];
        if (!colcount) state -> current_value[p] += state -> unit_row_offset[p];
      }
    }
    if (count || skipunits) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
}

unsigned char next_JPEG_Huffman_value (struct context * context, const unsigned char ** data, size_t * restrict count, uint32_t * restrict dataword,
                                       uint8_t * restrict bits, const short * restrict table) {
  unsigned short index = 0;
  while (true) {
    index += shift_in_right_JPEG(context, 1, dataword, bits, data, count);
    if (table[index] >= 0) return table[index];
    if (table[index] == -1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    index = -table[index];
  }
}

void load_JPEG_data (struct context * context, unsigned flags, size_t limit) {
  struct JPEG_marker_layout * layout = load_JPEG_marker_layout(context); // will be leaked (to be collected by context release)
  uint32_t components = determine_JPEG_components(context, layout -> hierarchical ? layout -> hierarchical : *layout -> frames);
  void (* transfer) (uint64_t * restrict, size_t, unsigned, const double **) = get_JPEG_component_transfer_function(context, layout, components);
  context -> image -> type = PLUM_IMAGE_JPEG;
  context -> image -> frames = 1;
  if (layout -> hierarchical) {
    context -> image -> width = read_be16_unaligned(context -> data + layout -> hierarchical + 5);
    context -> image -> height = read_be16_unaligned(context -> data + layout -> hierarchical + 3);
  } else {
    if (layout -> frames[1]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    context -> image -> width = read_be16_unaligned(context -> data + *layout -> frames + 5);
    context -> image -> height = read_be16_unaligned(context -> data + *layout -> frames + 3);
    for (size_t p = 0; layout -> markers[p]; p ++) if (layout -> markertype[p] == 0xdc) { // DNL marker
      if (read_be16_unaligned(context -> data + layout -> markers[p]) != 4) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      uint_fast16_t markerheight = read_be16_unaligned(context -> data + layout -> markers[p] + 2);
      if (!markerheight) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      if (!context -> image -> height)
        context -> image -> height = markerheight;
      else if (context -> image -> height != markerheight)
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
  }
  validate_image_size(context, limit);
  size_t count = (size_t) context -> image -> width * context -> image -> height;
  double * component_data[4] = {0};
  for (uint_fast8_t p = 0; p < get_JPEG_component_count(components); p ++) component_data[p] = ctxmalloc(context, sizeof **component_data * count);
  unsigned bitdepth;
  if (layout -> hierarchical)
    bitdepth = load_hierarchical_JPEG(context, layout, components, component_data);
  else
    bitdepth = load_single_frame_JPEG(context, layout, components, component_data);
  append_JPEG_color_depth_metadata(context, transfer, bitdepth);
  allocate_framebuffers(context, flags, false);
  unsigned maxvalue = ((uint32_t) 1 << bitdepth) - 1;
  if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_64) {
    transfer(context -> image -> data64, count, maxvalue, (const double **) component_data);
    if (flags & PLUM_ALPHA_INVERT) for (size_t p = 0; p < count; p ++) context -> image -> data64[p] ^= 0xffff000000000000u;
  } else {
    uint64_t * buffer = ctxmalloc(context, count * sizeof *buffer);
    transfer(buffer, count, maxvalue, (const double **) component_data);
    plum_convert_colors(context -> image -> data, buffer, count, flags, PLUM_COLOR_64);
    ctxfree(context, buffer);
  }
  for (uint_fast8_t p = 0; p < 4; p ++) ctxfree(context, component_data[p]); // unused components will be NULL anyway
  if (layout -> Exif) {
    unsigned rotation = get_JPEG_rotation(context, layout -> Exif);
    if (rotation) {
      unsigned error = plum_rotate_image(context -> image, rotation & 3, rotation & 4);
      if (error) throw(context, error);
    }
  }
}

struct JPEG_marker_layout * load_JPEG_marker_layout (struct context * context) {
  size_t prev, offset = 1;
  while (context -> data[offset ++] == 0xff); // the first marker must be SOI (from file type detection), so skip it
  uint_fast8_t next_restart_marker = 0; // 0 if not in a scan
  size_t restart_offset, restart_interval, scan, frame = SIZE_MAX, markers = 0;
  struct JPEG_marker_layout * layout = ctxmalloc(context, sizeof *layout);
  *layout = (struct JPEG_marker_layout) {0}; // ensure that integers and pointers are properly zero-initialized
  while (offset < context -> size) {
    prev = offset;
    if (context -> data[offset ++] != 0xff)
      if (next_restart_marker)
        continue;
      else
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    while (offset < context -> size && context -> data[offset] == 0xff) offset ++;
    if (offset >= context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    uint_fast8_t marker = context -> data[offset ++];
    if (!marker)
      if (next_restart_marker)
        continue;
      else
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (marker < 0xc0 || marker == 0xc8 || marker == 0xd8 || (marker >= 0xf0 && marker != 0xfe)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (next_restart_marker) {
      layout -> framedata[frame][scan] = ctxrealloc(context, layout -> framedata[frame][scan], sizeof ***layout -> framedata * (restart_interval + 2));
      layout -> framedata[frame][scan][restart_interval ++] = restart_offset;
      layout -> framedata[frame][scan][restart_interval ++] = prev - restart_offset;
    }
    if (marker == 0xd9) break;
    if (marker == next_restart_marker) {
      if (++ next_restart_marker == 0xd8) next_restart_marker = 0xd0;
      restart_offset = offset;
      continue;
    } else if ((marker & ~7u) == 0xd0)
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    // if we find a marker other than RST, we're definitely ending the current scan, and the marker definitely has a size
    if (next_restart_marker) {
      layout -> framedata[frame][scan] = ctxrealloc(context, layout -> framedata[frame][scan], sizeof ***layout -> framedata * (restart_interval + 1));
      layout -> framedata[frame][scan][restart_interval] = 0;
      next_restart_marker = 0;
    }
    if (offset > context -> size - 2) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    uint_fast16_t marker_size = read_be16_unaligned(context -> data + offset);
    if (marker_size < 2 || marker_size > context -> size || offset > context -> size - marker_size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    switch (marker) {
      case 0xc0: case 0xc1: case 0xc2: case 0xc3: case 0xc5: case 0xc6:
      case 0xc7: case 0xc9: case 0xca: case 0xcb: case 0xcd: case 0xce: case 0xcf:
        // start a new frame
        if (frame != SIZE_MAX) {
          if (scan == SIZE_MAX) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
          layout -> framescans[frame] = ctxrealloc(context, layout -> framescans[frame], sizeof **layout -> framescans * ((++ scan) + 1));
          layout -> framescans[frame][scan] = 0;
        }
        layout -> frames = ctxrealloc(context, layout -> frames, sizeof *layout -> frames * ((size_t) (++ frame) + 1));
        layout -> frames[frame] = offset;
        layout -> framescans = ctxrealloc(context, layout -> framescans, sizeof *layout -> framescans * (frame + 1));
        layout -> framescans[frame] = NULL;
        layout -> framedata = ctxrealloc(context, layout -> framedata, sizeof *layout -> framedata * (frame + 1));
        layout -> framedata[frame] = NULL;
        layout -> frametype = ctxrealloc(context, layout -> frametype, sizeof *layout -> frametype * (frame + 1));
        layout -> frametype[frame] = marker & 15;
        scan = SIZE_MAX;
        break;
      case 0xda:
        // start a new scan
        if (frame == SIZE_MAX) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        layout -> framescans[frame] = ctxrealloc(context, layout -> framescans[frame], sizeof **layout -> framescans * ((size_t) (++ scan) + 1));
        layout -> framescans[frame][scan] = offset;
        layout -> framedata[frame] = ctxrealloc(context, layout -> framedata[frame], sizeof **layout -> framedata * (scan + 1));
        layout -> framedata[frame][scan] = NULL;
        restart_interval = 0;
        restart_offset = offset + marker_size;
        next_restart_marker = 0xd0;
        break;
      case 0xde:
        if (layout -> hierarchical || frame != SIZE_MAX) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        layout -> hierarchical = offset;
        break;
      case 0xdf:
        if (!layout -> hierarchical) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      case 0xc4: case 0xcc: case 0xdb: case 0xdc: case 0xdd:
        layout -> markers = ctxrealloc(context, layout -> markers, sizeof *layout -> markers * (markers + 1));
        layout -> markers[markers] = offset;
        layout -> markertype = ctxrealloc(context, layout -> markertype, sizeof *layout -> markertype * (markers + 1));
        layout -> markertype[markers ++] = marker;
        break;
      // For JFIF, Exif and Adobe markers, all want to come "first", i.e., immediately after SOI. This is obviously impossible if more than one is present.
      // Therefore, "first" is interpreted to mean "before any SOF/DHP marker" here.
      case 0xe0:
        if (layout -> JFIF || layout -> hierarchical || frame != SIZE_MAX) break;
        if (marker_size >= 7 && bytematch(context -> data + offset + 2, 0x4a, 0x46, 0x49, 0x46, 0x00)) layout -> JFIF = offset;
        break;
      case 0xe1:
        if (layout -> Exif || layout -> hierarchical || frame != SIZE_MAX) break;
        if (marker_size >= 16 && bytematch(context -> data + offset + 2, 0x45, 0x78, 0x69, 0x66, 0x00, 0x00)) layout -> Exif = offset;
        break;
      case 0xee:
        if (layout -> Adobe || layout -> hierarchical || frame != SIZE_MAX) break;
        if (marker_size >= 9 && bytematch(context -> data + offset + 2, 0x41, 0x64, 0x6f, 0x62, 0x65, 0x00) &&
            (context -> data[offset + 8] == 100 || context -> data[offset + 8] == 101))
          layout -> Adobe = offset;
    }
    offset += marker_size;
  }
  if (frame == SIZE_MAX) throw(context, PLUM_ERR_NO_DATA);
  if (scan == SIZE_MAX) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  layout -> markers = ctxrealloc(context, layout -> markers, sizeof *layout -> markers * (markers + 1));
  layout -> markers[markers] = 0;
  if (next_restart_marker) {
    layout -> framedata[frame][scan] = ctxrealloc(context, layout -> framedata[frame][scan], sizeof ***layout -> framedata * (restart_interval + 1));
    layout -> framedata[frame][scan][restart_interval] = 0;
  }
  layout -> framescans[frame] = ctxrealloc(context, layout -> framescans[frame], sizeof **layout -> framescans * (++ scan + 1));
  layout -> framescans[frame][scan] = 0;
  layout -> frames = ctxrealloc(context, layout -> frames, sizeof *layout -> frames * (++ frame + 1));
  layout -> frames[frame] = 0;
  return layout;
}

unsigned get_JPEG_rotation (struct context * context, size_t offset) {
  // returns rotation count in bits 0-1 and vertical inversion in bit 2
  uint_fast16_t size = read_be16_unaligned(context -> data + offset);
  const unsigned char * data = context -> data + offset + 8;
  size -= 8;
  uint_fast16_t tag = read_le16_unaligned(data);
  bool bigendian;
  if (tag == 0x4949)
    bigendian = false; // little endian
  else if (tag == 0x4d4d)
    bigendian = true;
  else
    return 0;
  tag = bigendian ? read_be16_unaligned(data + 2) : read_le16_unaligned(data + 2);
  if (tag != 42) return 0;
  uint_fast32_t pos = bigendian ? read_be32_unaligned(data + 4) : read_le32_unaligned(data + 4);
  if (pos > size - 2) return 0;
  uint_fast16_t count = bigendian ? read_be16_unaligned(data + pos) : read_le16_unaligned(data + pos);
  pos += 2;
  if (size - pos < (uint_fast32_t) count * 12) return 0;
  for (; count; pos += 12, count --) {
    tag = bigendian ? read_be16_unaligned(data + pos) : read_le16_unaligned(data + pos);
    if (tag == 0x112) break; // 0x112 = orientation data
  }
  if (!count) return 0;
  tag = bigendian ? read_be16_unaligned(data + pos + 2) : read_le16_unaligned(data + pos + 2);
  uint_fast32_t datasize = bigendian ? read_be32_unaligned(data + pos + 4) : read_le32_unaligned(data + pos + 4);
  if (tag != 3 || datasize != 1) return 0;
  tag = bigendian ? read_be16_unaligned(data + pos + 8) : read_le16_unaligned(data + pos + 8);
  static const unsigned rotations[] = {0, 6, 2, 4, 7, 1, 5, 3};
  if (-- tag >= sizeof rotations / sizeof *rotations) tag = 0;
  return rotations[tag];
}

unsigned load_single_frame_JPEG (struct context * context, const struct JPEG_marker_layout * layout, uint32_t components, double ** output) {
  if (*layout -> frametype & 4) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  struct JPEG_decoder_tables tables;
  initialize_JPEG_decoder_tables(context, &tables, layout);
  unsigned precision = context -> data[*layout -> frames + 2];
  if (precision < 2 || precision > 16) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  size_t metadata_index = 0;
  if (*layout -> frametype == 3 || *layout -> frametype == 11)
    load_JPEG_lossless_frame(context, layout, components, 0, &tables, &metadata_index, output, precision, context -> image -> width, context -> image -> height);
  else
    load_JPEG_DCT_frame(context, layout, components, 0, &tables, &metadata_index, output, precision, context -> image -> width, context -> image -> height);
  return precision;
}

unsigned char process_JPEG_metadata_until_offset (struct context * context, const struct JPEG_marker_layout * layout, struct JPEG_decoder_tables * tables,
                                                  size_t * restrict index, size_t limit) {
  unsigned char expansion = 0;
  for (; layout -> markers[*index] && layout -> markers[*index] < limit; ++ *index) {
    const unsigned char * markerdata = context -> data + layout -> markers[*index];
    uint16_t markersize = read_be16_unaligned(markerdata) - 2;
    markerdata += 2;
    switch (layout -> markertype[*index]) {
      case 0xc4: // DHT
        while (markersize) {
          if (*markerdata & ~0x13u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
          unsigned char target = (*markerdata & 3) | (*markerdata >> 2);
          markerdata ++;
          markersize --;
          if (tables -> Huffman[target]) ctxfree(context, tables -> Huffman[target]);
          tables -> Huffman[target] = process_JPEG_Huffman_table(context, &markerdata, &markersize);
        }
        break;
      case 0xcc: // DAC
        if (markersize % 2) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        for (uint_fast16_t count = markersize / 2; count; count --) {
          unsigned char target = *(markerdata ++);
          if (target & ~0x13u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
          target = (target >> 2) | (target & 3);
          if (target & 4) {
            if (!*markerdata || *markerdata > 63) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
          } else
            if ((*markerdata >> 4) < (*markerdata & 15)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
          tables -> arithmetic[target] = *(markerdata ++);
        }
        break;
      case 0xdb: // DQT
        while (markersize) {
          if (*markerdata & ~0x13u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
          unsigned char target = *markerdata & 3, type = *markerdata >> 4, length = type ? 128 : 64;
          markerdata ++;
          if (-- markersize < length) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
          markersize -= length;
          if (!tables -> quantization[target]) tables -> quantization[target] = ctxmalloc(context, 64 * sizeof *tables -> quantization[target]);
          if (type)
            for (uint_fast8_t p = 0; p < 64; p ++, markerdata += 2) tables -> quantization[target][p] = read_be16_unaligned(markerdata);
          else
            for (uint_fast8_t p = 0; p < 64; p ++) tables -> quantization[target][p] = *(markerdata ++);
        }
        break;
      case 0xdd: // DRI
        if (markersize != 2) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        tables -> restart = read_be16_unaligned(markerdata);
        break;
      case 0xdf: // EXP
        if (markersize != 1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        expansion = *markerdata;
    }
  }
  return expansion;
}

void load_JPEG_DCT_frame (struct context * context, const struct JPEG_marker_layout * layout, uint32_t components, size_t frameindex,
                          struct JPEG_decoder_tables * tables, size_t * restrict metadata_index, double ** output, unsigned precision, size_t width,
                          size_t height) {
  const size_t * scans = layout -> framescans[frameindex];
  const size_t ** offsets = (const size_t **) layout -> framedata[frameindex];
  // obtain this frame's components' parameters and compute the number of (non-subsampled) blocks per MCU (maximum scale factor for each dimension)
  struct JPEG_component_info component_info[4];
  uint_fast8_t maxH = 1, maxV = 1, count = get_JPEG_component_info(context, context -> data + layout -> frames[frameindex], component_info, components);
  for (uint_fast8_t p = 0; p < count; p ++) {
    if (component_info[p].scaleV > maxV) maxV = component_info[p].scaleV;
    if (component_info[p].scaleH > maxH) maxH = component_info[p].scaleH;
  }
  // compute the image dimensions in MCUs and allocate space for that many coefficients for each component (including padding blocks to fill up edge MCUs)
  size_t unitrow = (width - 1) / (8 * maxH) + 1, unitcol = (height - 1) / (8 * maxV) + 1, units = unitrow * unitcol;
  int16_t (* restrict component_data[4])[64] = {0};
  for (uint_fast8_t p = 0; p < count; p ++)
    component_data[p] = ctxmalloc(context, sizeof **component_data * units * component_info[p].scaleH * component_info[p].scaleV);
  unsigned char currentbits[4][64]; // successive approximation bit positions for each component and coefficient, for progressive scans
  memset(currentbits, 0xff, sizeof currentbits); // 0xff = no data yet (i.e., the coefficient hasn't shown up yet in any scans)
  for (; *scans; scans ++, offsets ++) {
    if (process_JPEG_metadata_until_offset(context, layout, tables, metadata_index, **offsets)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    unsigned char scancomponents[4];
    const unsigned char * progdata = get_JPEG_scan_components(context, *scans, component_info, count, scancomponents);
    // validate the spectral selection parameters
    uint_fast8_t first = *progdata, last = progdata[1];
    if (first > last || last > 63) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    // validate and update the successive approximation bit positions for each component and coefficient involved in the scan
    uint_fast8_t bitstart = progdata[2] >> 4, bitend = progdata[2] & 15;
    if ((bitstart && bitstart - 1 != bitend) || bitend > 13 || bitend >= precision) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (!bitstart) bitstart = 0xff; // 0xff = not a progressive scan (intentionally matches the "no data yet" 0xff in currentbits)
    for (uint_fast8_t p = 0; p < 4 && scancomponents[p] != 0xff; p ++) {
      // check that all quantization and Huffman tables (when applicable) used by the scan have already been loaded
      if (!tables -> quantization[component_info[scancomponents[p]].tableQ]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      if (!(layout -> frametype[frameindex] & 8)) {
        if (!first && !tables -> Huffman[component_info[scancomponents[p]].tableDC]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        if (last && !tables -> Huffman[component_info[scancomponents[p]].tableAC + 4]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      }
      // ensure that this scan's successive approximation bit parameters match what is expected based on previous scans, and update currentbits
      for (uint_fast8_t coefficient = first; coefficient <= last; coefficient ++) {
        if (currentbits[scancomponents[p]][coefficient] != bitstart) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        currentbits[scancomponents[p]][coefficient] = bitend;
      }
    }
    size_t scanunitrow = unitrow;
    struct JPEG_decompressor_state state;
    initialize_JPEG_decompressor_state(context, &state, component_info, scancomponents, &scanunitrow, unitcol, width, height, maxH, maxV, tables, *offsets,
                                       component_data);
    // call the decompression function, depending on the frame type (Huffman or arithmetic) and whether it is progressive or not
    if (bitstart == 0xff)
      if (layout -> frametype[frameindex] & 8)
        decompress_JPEG_arithmetic_scan(context, &state, tables, scanunitrow, component_info, *offsets, bitend, first, last, layout -> frametype[frameindex] & 4);
      else
        decompress_JPEG_Huffman_scan(context, &state, tables, scanunitrow, component_info, *offsets, bitend, first, last, layout -> frametype[frameindex] & 4);
    else
      if (layout -> frametype[frameindex] & 8)
        decompress_JPEG_arithmetic_bit_scan(context, &state, scanunitrow, component_info, *offsets, bitend, first, last);
      else
        decompress_JPEG_Huffman_bit_scan(context, &state, tables, scanunitrow, component_info, *offsets, bitend, first, last);
  }
  // ensure that the frame's scans contain all bits for all coefficients, for each one of its components
  for (uint_fast8_t p = 0; p < count; p ++) for (uint_fast8_t coefficient = 0; coefficient < 64; coefficient ++)
    if (currentbits[p][coefficient]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  // if the frame is non-differential, initialize all components in the final image to the level shift value
  if (!(layout -> frametype[frameindex] & 4)) {
    double levelshift = 1u << (precision - 1);
    for (uint_fast8_t p = 0; p < count; p ++) for (size_t i = 0; i < width * height; i ++) output[p][i] = levelshift;
  }
  // transform all blocks into component data and add it to the output (level shift value for non-differential frames, previous values for differential frames)
  // loop backwards so DCT data is released in reverse allocation order after transforming it into output data
  while (count --) {
    size_t compwidth = unitrow * component_info[count].scaleH * 8 + 2, compheight = unitcol * component_info[count].scaleV * 8 + 2;
    double * transformed = ctxmalloc(context, sizeof *transformed * compwidth * compheight); // component data buffer, plus a pixel of padding around the edges
    for (size_t y = 0; y < unitcol * component_info[count].scaleV; y ++) for (size_t x = 0; x < unitrow * component_info[count].scaleH; x ++) {
      // apply the reverse DCT to each block, transforming it into component data
      double buffer[64];
      apply_JPEG_inverse_DCT(buffer, component_data[count][y * unitrow * component_info[count].scaleH + x], tables -> quantization[component_info[count].tableQ]);
      // copy the block's data to the correct location in the component data buffer (accounting for the padding)
      double * current = transformed + (y * 8 + 1) * compwidth + x * 8 + 1;
      for (uint_fast8_t row = 0; row < 8; row ++) memcpy(current + compwidth * row, buffer + 8 * row, sizeof *buffer * 8);
    }
    // scale up subsampled components and add them to the output
    unpack_JPEG_component(output[count], transformed, width, height, compwidth, compheight, component_info[count].scaleH, component_info[count].scaleV, maxH, maxV);
    ctxfree(context, transformed);
    ctxfree(context, component_data[count]);
  }
}

void load_JPEG_lossless_frame (struct context * context, const struct JPEG_marker_layout * layout, uint32_t components, size_t frameindex,
                               struct JPEG_decoder_tables * tables, size_t * restrict metadata_index, double ** output, unsigned precision, size_t width,
                               size_t height) {
  const size_t * scans = layout -> framescans[frameindex];
  const size_t ** offsets = (const size_t **) layout -> framedata[frameindex];
  // obtain this frame's components' parameters and compute the number of pixels per MCU (maximum scale factor for each dimension)
  struct JPEG_component_info component_info[4];
  uint_fast8_t maxH = 1, maxV = 1, count = get_JPEG_component_info(context, context -> data + layout -> frames[frameindex], component_info, components);
  for (uint_fast8_t p = 0; p < count; p ++) {
    if (component_info[p].scaleV > maxV) maxV = component_info[p].scaleV;
    if (component_info[p].scaleH > maxH) maxH = component_info[p].scaleH;
  }
  // compute the image dimensions in MCUs and allocate space for that many pixels for each component (including padding pixels to fill edge MCUs)
  size_t unitrow = (width - 1) / maxH + 1, unitcol = (height - 1) / maxV + 1, units = unitrow * unitcol;
  uint16_t * restrict component_data[4] = {0};
  for (uint_fast8_t p = 0; p < count; p ++)
    component_data[p] = ctxmalloc(context, sizeof **component_data * units * component_info[p].scaleH * component_info[p].scaleV);
  double initial_value[4]; // offset to add to pixel data, to reduce rounding errors in shifted-down components (0 if no offset is needed)
  int component_shift[4] = {-1, -1, -1, -1}; // shift amounts for each component (negative: the component hasn't shown up in any scans yet)
  for (; *scans; scans ++, offsets ++) {
    if (process_JPEG_metadata_until_offset(context, layout, tables, metadata_index, **offsets)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    unsigned char scancomponents[4];
    const unsigned char * progdata = get_JPEG_scan_components(context, *scans, component_info, count, scancomponents);
    uint_fast8_t predictor = *progdata, shift = progdata[2] & 15;
    if (predictor > 7 || shift >= precision) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    for (uint_fast8_t p = 0; p < 4 && scancomponents[p] != 0xff; p ++) {
      // check that the components from this scan haven't already been decoded, and update the components' shift amount and initial value
      if (component_shift[scancomponents[p]] >= 0) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      component_shift[scancomponents[p]] = shift;
      if (layout -> hierarchical)
        initial_value[scancomponents[p]] = 0;
      else
        initial_value[scancomponents[p]] = shift ? 1u << (shift - 1) : 0;
      // if the frame is a Huffman frame, ensure that all Huffman tables used by the scan have already been loaded
      if (!((layout -> frametype[frameindex] & 8) || tables -> Huffman[component_info[scancomponents[p]].tableDC])) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
    size_t scanunitrow = unitrow;
    struct JPEG_decompressor_state state;
    initialize_JPEG_decompressor_state_lossless(context, &state, component_info, scancomponents, &scanunitrow, unitcol, width, height, maxH, maxV, tables,
                                                *offsets, component_data);
    // call the decompression function, depending on the frame type (Huffman or arithmetic) - lossless scans cannot be progressive
    if (layout -> frametype[frameindex] & 8)
      decompress_JPEG_arithmetic_lossless_scan(context, &state, tables, scanunitrow, component_info, *offsets, predictor, precision - shift);
    else
      decompress_JPEG_Huffman_lossless_scan(context, &state, tables, scanunitrow, component_info, *offsets, predictor, precision - shift);
  }
  // ensure that all components in the frame have appeared in some scan
  for (uint_fast8_t p = 0; p < count; p ++) if (component_shift[p] < 0) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  // convert all decoded component data into actual component pixels; loop backwards so that temporary component data is released in reverse allocation order
  while (count --) {
    size_t compwidth = unitrow * component_info[count].scaleH + 2, compheight = unitcol * component_info[count].scaleV + 2;
    double * converted = ctxmalloc(context, sizeof *converted * compwidth * compheight); // output data buffer, plus a pixel of padding around the edges
    // shift up all component pixels as needed, and store them in the correct location in the output data buffer (accounting for the padding)
    for (size_t y = 0; y < unitcol * component_info[count].scaleV; y ++) for (size_t x = 0; x < unitrow * component_info[count].scaleH; x ++)
      converted[(y + 1) * compwidth + x + 1] = component_data[count][y * unitrow * component_info[count].scaleH + x] << component_shift[count];
    // add the initial value to all component values and scale up subsampled components as needed
    if (!(layout -> frametype[frameindex] & 4)) for (size_t p = 0; p < width * height; p ++) output[count][p] = initial_value[count];
    unpack_JPEG_component(output[count], converted, width, height, compwidth, compheight, component_info[count].scaleH, component_info[count].scaleV, maxH, maxV);
    ctxfree(context, converted);
    ctxfree(context, component_data[count]);
  }
}

unsigned get_JPEG_component_info (struct context * context, const unsigned char * frameheader, struct JPEG_component_info * restrict output, uint32_t components) {
  // assumes the component list is correct - true by definition for single-frame images and checked elsewhere for hierarchical ones
  unsigned char component_numbers[4];
  write_le32_unaligned(component_numbers, components);
  uint_fast8_t count = get_JPEG_component_count(components);
  for (uint_fast8_t current = 0; current < count; current ++) {
    uint_fast8_t index;
    for (index = 0; index < count; index ++) if (component_numbers[index] == frameheader[8 + 3 * current]) break;
    output[index].index = component_numbers[index];
    uint_fast8_t p = frameheader[9 + 3 * current];
    output[index].scaleH = p >> 4;
    output[index].scaleV = p & 15;
    output[index].tableQ = frameheader[10 + 3 * current];
    if (!output[index].scaleH || output[index].scaleH > 4 || !output[index].scaleV || output[index].scaleV > 4 || output[index].tableQ > 3)
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
  return count;
}

const unsigned char * get_JPEG_scan_components (struct context * context, size_t offset, struct JPEG_component_info * restrict compinfo, unsigned framecount,
                                                unsigned char * restrict output) {
  uint_fast16_t headerlength = read_be16_unaligned(context -> data + offset);
  if (headerlength < 8) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint_fast8_t count = context -> data[offset + 2];
  if (headerlength != 6 + 2 * count) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  memset(output, 0xff, 4);
  for (uint_fast8_t p = 0; p < count; p ++) {
    uint_fast8_t index;
    for (index = 0; index < framecount; index ++) if (compinfo[index].index == context -> data[offset + 3 + 2 * p]) break;
    if (index == framecount) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    output[p] = index;
    compinfo[index].tableDC = context -> data[offset + 4 + 2 * p] >> 4;
    compinfo[index].tableAC = context -> data[offset + 4 + 2 * p] & 15;
    if (compinfo[index].tableDC > 3 || compinfo[index].tableAC > 3) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
  return context -> data + offset + 3 + 2 * count;
}

void unpack_JPEG_component (double * restrict result, double * restrict source, size_t width, size_t height, size_t scaled_width, size_t scaled_height,
                            unsigned char scaleH, unsigned char scaleV, unsigned char maxH, unsigned char maxV) {
  // fill the border of the component data (one pixel of dummy values around the edges) by copying values from the true edges
  size_t scaled_size = scaled_width * scaled_height;
  for (size_t p = 1; p < scaled_width - 1; p ++) source[p] = source[p + scaled_width];
  for (size_t p = 2; p < scaled_width; p ++) source[scaled_size - p] = source[scaled_size - p - scaled_width];
  for (size_t p = 0; p < scaled_height; p ++) {
    source[p * scaled_width] = source[p * scaled_width + 1];
    source[(p + 1) * scaled_width - 1] = source[(p + 1) * scaled_width - 2];
  }
  // if the scaling parameters form a reducible fraction, reduce it
  if (scaleH == maxH) scaleH = maxH = 1;
  if (scaleV == maxV) scaleV = maxV = 1;
  if ((maxH == 4) && (scaleH == 2)) {
    maxH = 2;
    scaleH = 1;
  }
  if ((maxV == 4) && (scaleV == 2)) {
    maxV = 2;
    scaleV = 1;
  }
  // indexes into the interpolation index lists: 1-4 for integer ratios (scale = 1 after normalization above), 0 for 3/2, 5 for 4/3
  unsigned char indexH = (scaleH == 2) ? 0 : (scaleH == 3) ? 5 : maxH, indexV = (scaleV == 2) ? 0 : (scaleV == 3) ? 5 : maxV;
  // weights for all possible scaling factors (3/2, 1 to 4, 4/3); a subset of these will be selected for each axis depending on the actual scale factor
  static const double interpolation_weights[] = {0x0.55555555555558p+0, 0x0.aaaaaaaaaaaaa8p+0, 1.0, 0x0.aaaaaaaaaaaaa8p+0, 0x0.55555555555558p+0, 0.0,
                                                 0x0.4p+0, 0x0.cp+0, 0x0.4p+0, 0x0.2aaaaaaaaaaaa8p+0, 0x0.8p+0, 0x0.d5555555555558p+0, 0x0.8p+0,
                                                 0x0.2aaaaaaaaaaaa8p+0, 0x0.2p+0, 0x0.6p+0, 0x0.ap+0, 0x0.ep+0, 0x0.ap+0, 0x0.6p+0, 0x0.2p+0};
  static const unsigned char first_interpolation_indexes[] = {9, 5, 7, 3, 17, 14};
  static const unsigned char second_interpolation_indexes[] = {11, 2, 6, 0, 14, 17};
  // actual interpolation weights for each pixel in a row/column of upscaled pixels
  const double * firstH = interpolation_weights + first_interpolation_indexes[indexH];
  const double * firstV = interpolation_weights + first_interpolation_indexes[indexV];
  const double * secondH = interpolation_weights + second_interpolation_indexes[indexH];
  const double * secondV = interpolation_weights + second_interpolation_indexes[indexV];
  // scale up the component, as determined by the scale parameters, by interpolating the decoded data
  unsigned char offsetV = maxV / (2 * scaleV), offsetH = maxH / (2 * scaleH);
  for (size_t p = 0, sourceY = 0, row = 0; row < height; row ++) {
    for (size_t sourceX = 0, col = 0; col < width; col ++) {
      result[p ++] += source[sourceX + sourceY * scaled_width] * firstH[offsetH] * firstV[offsetV] +
                      source[sourceX + 1 + sourceY * scaled_width] * secondH[offsetH] * firstV[offsetV] +
                      source[sourceX + (sourceY + 1) * scaled_width] * firstH[offsetH] * secondV[offsetV] +
                      source[sourceX + 1 + (sourceY + 1) * scaled_width] * secondH[offsetH] * secondV[offsetV];
      if (++ offsetH == maxH) {
        offsetH = 0;
        if (scaleH == 1) sourceX ++;
      } else if (scaleH != 1)
        sourceX ++;
    }
    if (++ offsetV == maxV) {
      offsetV = 0;
      if (scaleV == 1) sourceY ++;
    } else if (scaleV != 1)
      sourceY ++;
  }
}

void initialize_JPEG_decoder_tables (struct context * context, struct JPEG_decoder_tables * tables, const struct JPEG_marker_layout * layout) {
  *tables = (struct JPEG_decoder_tables) {
    .Huffman = {NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL},
    .quantization = {NULL, NULL, NULL, NULL},
    .arithmetic = {0x10, 0x10, 0x10, 0x10, 5, 5, 5, 5},
    .restart = 0
  };
  // if the image doesn't define a Huffman table (no DHT markers), load the standard's recommended tables as "default" tables
  for (size_t p = 0; layout -> markers[p]; p ++) if (layout -> markertype[p] == 0xc4) return;
  load_default_JPEG_Huffman_tables(context, tables);
}

short * process_JPEG_Huffman_table (struct context * context, const unsigned char ** restrict markerdata, uint16_t * restrict markersize) {
  if (*markersize < 16) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint_fast16_t totalsize = 0, tablesize = 16; // 16 so it counts the initial length bytes too
  const unsigned char * lengths = *markerdata;
  const unsigned char * data = *markerdata + 16;
  for (uint_fast8_t size = 0; size < 16; size ++) {
    tablesize += lengths[size];
    totalsize += lengths[size] * (size + 1) * 2; // not necessarily the real size of the table, but an easily calculated upper bound
  }
  if (*markersize < tablesize) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  *markersize -= tablesize;
  *markerdata += tablesize;
  short * result = ctxmalloc(context, totalsize * sizeof *result);
  for (uint_fast16_t p = 0; p < totalsize; p ++) result[p] = -1;
  uint_fast16_t code = 0, next = 2, offset = 0x8000u;
  // size is one less because we don't count the link to the leaf
  for (uint_fast8_t size = 0; size < 16; size ++, offset >>= 1) for (uint_fast8_t count = lengths[size]; count; count --) {
    uint_fast16_t current = 0x8000u, index = 0;
    for (uint_fast8_t remainder = size; remainder; remainder --) {
      if (code & current) index ++;
      current >>= 1;
      if (result[index] == -1) {
        result[index] = -(short) next;
        next += 2;
      }
      index = -result[index];
    }
    if (code & current) index ++;
    result[index] = *(data ++);
    if ((uint_fast32_t) code + offset > 0xffffu) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    code += offset;
  }
  return ctxrealloc(context, result, next * sizeof *result);
}

void load_default_JPEG_Huffman_tables (struct context * context, struct JPEG_decoder_tables * restrict tables) {
  /* default tables from the JPEG specification, already preprocessed into a tree, in the same format as other trees:
     two values per node, non-negative values are leaves, negative values are array indexes where the next node is
     found (always even, because each node takes up two entries), -1 is an empty branch; index 0 is the root node */
  static const short luminance_DC_table[] = {
    //           0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19
    /*   0 */   -2,   -6, 0x00,   -4, 0x01, 0x02,   -8,  -10, 0x03, 0x04, 0x05,  -12, 0x06,  -14, 0x07,  -16, 0x08,  -18, 0x09,  -20,
    /*  20 */ 0x0a,  -22, 0x0b,   -1
  };
  static const short chrominance_DC_table[] = {
    //           0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19
    /*   0 */   -2,   -4, 0x00, 0x01, 0x02,   -6, 0x03,   -8, 0x04,  -10, 0x05,  -12, 0x06,  -14, 0x07,  -16, 0x08,  -18, 0x09,  -20,
    /*  20 */ 0x0a,  -22, 0x0b,   -1
  };
  static const short luminance_AC_table[] = {
    //           0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19
    /*   0 */   -2,   -4, 0x01, 0x02,   -6,  -10, 0x03,   -8, 0x00, 0x04,  -12,  -16, 0x11,  -14, 0x05, 0x12,  -18,  -22, 0x21,  -20,
    /*  20 */ 0x31, 0x41,  -24,  -30,  -26,  -28, 0x06, 0x13, 0x51, 0x61,  -32,  -40,  -34,  -36, 0x07, 0x22, 0x71,  -38, 0x14, 0x32,
    /*  40 */  -42,  -50,  -44,  -46, 0x81, 0x91, 0xa1,  -48, 0x08, 0x23,  -52,  -60,  -54,  -56, 0x42, 0xb1, 0xc1,  -58, 0x15, 0x52,
    /*  60 */  -62,  -72,  -64,  -66, 0xd1, 0xf0,  -68,  -70, 0x24, 0x33, 0x62, 0x72,  -74, -198,  -76, -136,  -78, -106,  -80,  -92,
    /*  80 */  -82,  -86, 0x82,  -84, 0x09, 0x0a,  -88,  -90, 0x16, 0x17, 0x18, 0x19,  -94, -100,  -96,  -98, 0x1a, 0x25, 0x26, 0x27,
    /* 100 */ -102, -104, 0x28, 0x29, 0x2a, 0x34, -108, -122, -110, -116, -112, -114, 0x35, 0x36, 0x37, 0x38, -118, -120, 0x39, 0x3a,
    /* 120 */ 0x43, 0x44, -124, -130, -126, -128, 0x45, 0x46, 0x47, 0x48, -132, -134, 0x49, 0x4a, 0x53, 0x54, -138, -168, -140, -154,
    /* 140 */ -142, -148, -144, -146, 0x55, 0x56, 0x57, 0x58, -150, -152, 0x59, 0x5a, 0x63, 0x64, -156, -162, -158, -160, 0x65, 0x66,
    /* 160 */ 0x67, 0x68, -164, -166, 0x69, 0x6a, 0x73, 0x74, -170, -184, -172, -178, -174, -176, 0x75, 0x76, 0x77, 0x78, -180, -182,
    /* 180 */ 0x79, 0x7a, 0x83, 0x84, -186, -192, -188, -190, 0x85, 0x86, 0x87, 0x88, -194, -196, 0x89, 0x8a, 0x92, 0x93, -200, -262,
    /* 200 */ -202, -232, -204, -218, -206, -212, -208, -210, 0x94, 0x95, 0x96, 0x97, -214, -216, 0x98, 0x99, 0x9a, 0xa2, -220, -226,
    /* 220 */ -222, -224, 0xa3, 0xa4, 0xa5, 0xa6, -228, -230, 0xa7, 0xa8, 0xa9, 0xaa, -234, -248, -236, -242, -238, -240, 0xb2, 0xb3,
    /* 240 */ 0xb4, 0xb5, -244, -246, 0xb6, 0xb7, 0xb8, 0xb9, -250, -256, -252, -254, 0xba, 0xc2, 0xc3, 0xc4, -258, -260, 0xc5, 0xc6,
    /* 260 */ 0xc7, 0xc8, -264, -294, -266, -280, -268, -274, -270, -272, 0xc9, 0xca, 0xd2, 0xd3, -276, -278, 0xd4, 0xd5, 0xd6, 0xd7,
    /* 280 */ -282, -288, -284, -286, 0xd8, 0xd9, 0xda, 0xe1, -290, -292, 0xe2, 0xe3, 0xe4, 0xe5, -296, -310, -298, -304, -300, -302,
    /* 300 */ 0xe6, 0xe7, 0xe8, 0xe9, -306, -308, 0xea, 0xf1, 0xf2, 0xf3, -312, -318, -314, -316, 0xf4, 0xf5, 0xf6, 0xf7, -320, -322,
    /* 320 */ 0xf8, 0xf9, 0xfa,   -1
  };
  static const short chrominance_AC_table[] = {
    //           0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19
    /*   0 */   -2,   -4, 0x00, 0x01,   -6,  -10, 0x02,   -8, 0x03, 0x11,  -12,  -18,  -14,  -16, 0x04, 0x05, 0x21, 0x31,  -20,  -26,
    /*  20 */  -22,  -24, 0x06, 0x12, 0x41, 0x51,  -28,  -36,  -30,  -32, 0x07, 0x61, 0x71,  -34, 0x13, 0x22,  -38,  -48,  -40,  -42,
    /*  40 */ 0x32, 0x81,  -44,  -46, 0x08, 0x14, 0x42, 0x91,  -50,  -58,  -52,  -54, 0xa1, 0xb1, 0xc1,  -56, 0x09, 0x23,  -60,  -68,
    /*  60 */  -62,  -64, 0x33, 0x52, 0xf0,  -66, 0x15, 0x62,  -70,  -80,  -72,  -74, 0x72, 0xd1,  -76,  -78, 0x0a, 0x16, 0x24, 0x34,
    /*  80 */  -82, -198,  -84, -136,  -86, -106,  -88,  -92, 0xe1,  -90, 0x25, 0xf1,  -94, -100,  -96,  -98, 0x17, 0x18, 0x19, 0x1a,
    /* 100 */ -102, -104, 0x26, 0x27, 0x28, 0x29, -108, -122, -110, -116, -112, -114, 0x2a, 0x35, 0x36, 0x37, -118, -120, 0x38, 0x39,
    /* 120 */ 0x3a, 0x43, -124, -130, -126, -128, 0x44, 0x45, 0x46, 0x47, -132, -134, 0x48, 0x49, 0x4a, 0x53, -138, -168, -140, -154,
    /* 140 */ -142, -148, -144, -146, 0x54, 0x55, 0x56, 0x57, -150, -152, 0x58, 0x59, 0x5a, 0x63, -156, -162, -158, -160, 0x64, 0x65,
    /* 160 */ 0x66, 0x67, -164, -166, 0x68, 0x69, 0x6a, 0x73, -170, -184, -172, -178, -174, -176, 0x74, 0x75, 0x76, 0x77, -180, -182,
    /* 180 */ 0x78, 0x79, 0x7a, 0x82, -186, -192, -188, -190, 0x83, 0x84, 0x85, 0x86, -194, -196, 0x87, 0x88, 0x89, 0x8a, -200, -262,
    /* 200 */ -202, -232, -204, -218, -206, -212, -208, -210, 0x92, 0x93, 0x94, 0x95, -214, -216, 0x96, 0x97, 0x98, 0x99, -220, -226,
    /* 220 */ -222, -224, 0x9a, 0xa2, 0xa3, 0xa4, -228, -230, 0xa5, 0xa6, 0xa7, 0xa8, -234, -248, -236, -242, -238, -240, 0xa9, 0xaa,
    /* 240 */ 0xb2, 0xb3, -244, -246, 0xb4, 0xb5, 0xb6, 0xb7, -250, -256, -252, -254, 0xb8, 0xb9, 0xba, 0xc2, -258, -260, 0xc3, 0xc4,
    /* 260 */ 0xc5, 0xc6, -264, -294, -266, -280, -268, -274, -270, -272, 0xc7, 0xc8, 0xc9, 0xca, -276, -278, 0xd2, 0xd3, 0xd4, 0xd5,
    /* 280 */ -282, -288, -284, -286, 0xd6, 0xd7, 0xd8, 0xd9, -290, -292, 0xda, 0xe2, 0xe3, 0xe4, -296, -310, -298, -304, -300, -302,
    /* 300 */ 0xe5, 0xe6, 0xe7, 0xe8, -306, -308, 0xe9, 0xea, 0xf2, 0xf3, -312, -318, -314, -316, 0xf4, 0xf5, 0xf6, 0xf7, -320, -322,
    /* 320 */ 0xf8, 0xf9, 0xfa,   -1
  };
  *tables -> Huffman = memcpy(ctxmalloc(context, sizeof luminance_DC_table), luminance_DC_table, sizeof luminance_DC_table);
  tables -> Huffman[1] = memcpy(ctxmalloc(context, sizeof chrominance_DC_table), chrominance_DC_table, sizeof chrominance_DC_table);
  tables -> Huffman[4] = memcpy(ctxmalloc(context, sizeof luminance_AC_table), luminance_AC_table, sizeof luminance_AC_table);
  tables -> Huffman[5] = memcpy(ctxmalloc(context, sizeof chrominance_AC_table), chrominance_AC_table, sizeof chrominance_AC_table);
}

void generate_JPEG_data (struct context * context) {
  if (context -> source -> frames > 1) throw(context, PLUM_ERR_NO_MULTI_FRAME);
  if (context -> source -> width > 0xffffu || context -> source -> height > 0xffffu) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  byteoutput(context,
             0xff, 0xd8, // SOI
             0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01, 0x02, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, // JFIF marker (no thumbnail)
             0xff, 0xee, 0x00, 0x0e, 0x41, 0x64, 0x6f, 0x62, 0x65, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x01, // Adobe marker (YCbCr colorspace)
             0xff, 0xc0, 0x00, 0x11, 0x08, // SOF, baseline DCT coding, 8 bits per component...
             context -> source -> height >> 8, context -> source -> height, context -> source -> width >> 8, context -> source -> width, // dimensions...
             0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01 // 3 components, component 1 is 4:4:4, table 0, components 2-3 are 4:2:0, table 1
            );
  uint8_t luminance_table[64];
  uint8_t chrominance_table[64];
  calculate_JPEG_quantization_tables(context, luminance_table, chrominance_table);
  unsigned char * node = append_output_node(context, 134);
  bytewrite(node, 0xff, 0xdb, 0x00, 0x84, 0x00); // DQT, 132 bytes long, table 0 first
  memcpy(node + 5, luminance_table, sizeof luminance_table);
  node[69] = 1; // table 1 afterwards
  memcpy(node + 70, chrominance_table, sizeof chrominance_table);
  size_t unitsH = (context -> image -> width + 7) / 8, unitsV = (context -> image -> height + 7) / 8, units = unitsH * unitsV;
  double (* luminance)[64] = ctxmalloc(context, units * sizeof *luminance);
  double (* blue_chrominance)[64] = ctxmalloc(context, units * sizeof *blue_chrominance);
  double (* red_chrominance)[64] = ctxmalloc(context, units * sizeof *red_chrominance);
  convert_JPEG_components_to_YCbCr(context, luminance, blue_chrominance, red_chrominance);
  size_t reduced_units = ((unitsH + 1) >> 1) * ((unitsV + 1) >> 1);
  double (* buffer)[64] = ctxmalloc(context, reduced_units * sizeof *buffer);
  subsample_JPEG_component(blue_chrominance, buffer, unitsH, unitsV);
  ctxfree(context, blue_chrominance);
  blue_chrominance = buffer;
  buffer = ctxmalloc(context, reduced_units * sizeof *buffer);
  subsample_JPEG_component(red_chrominance, buffer, unitsH, unitsV);
  ctxfree(context, red_chrominance);
  red_chrominance = buffer;
  size_t luminance_count, chrominance_count;
  // do chrominance first, since it will generally use less memory, so the chrominance data can be freed afterwards to reduce overall memory usage
  struct JPEG_encoded_value * chrominance_data = generate_JPEG_chrominance_data_stream(context, blue_chrominance, red_chrominance, reduced_units,
                                                                                       chrominance_table, &chrominance_count);
  ctxfree(context, red_chrominance);
  ctxfree(context, blue_chrominance);
  struct JPEG_encoded_value * luminance_data = generate_JPEG_luminance_data_stream(context, luminance, units, luminance_table, &luminance_count);
  ctxfree(context, luminance);
  unsigned char Huffman_table_data[0x400]; // luminance DC, AC, chrominance DC, AC
  node = append_output_node(context, 1096);
  size_t size = 4;
  size += generate_JPEG_Huffman_table(context, luminance_data, luminance_count, node + size, Huffman_table_data, 0x00);
  size += generate_JPEG_Huffman_table(context, luminance_data, luminance_count, node + size, Huffman_table_data + 0x100, 0x10);
  size += generate_JPEG_Huffman_table(context, chrominance_data, chrominance_count, node + size, Huffman_table_data + 0x200, 0x01);
  size += generate_JPEG_Huffman_table(context, chrominance_data, chrominance_count, node + size, Huffman_table_data + 0x300, 0x11);
  bytewrite(node, 0xff, 0xc4, (size - 2) >> 8, size - 2); // DHT
  context -> output -> size = size;
  byteoutput(context, 0xff, 0xda, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3f, 0x00); // SOS, component 1, table 0, not progressive
  encode_JPEG_scan(context, luminance_data, luminance_count, Huffman_table_data);
  ctxfree(context, luminance_data);
  byteoutput(context, 0xff, 0xda, 0x00, 0x0a, 0x02, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3f, 0x00); // SOS, components 2-3, table 1, not progressive
  encode_JPEG_scan(context, chrominance_data, chrominance_count, Huffman_table_data + 0x200);
  ctxfree(context, chrominance_data);
  byteoutput(context, 0xff, 0xd9); // EOI
}

void calculate_JPEG_quantization_tables (struct context * context, uint8_t luminance_table[restrict static 64], uint8_t chrominance_table[restrict static 64]) {
  // start with the standard's tables (reduced by 1, since that will be added back later)
  static const uint8_t luminance_base[64] =   { 15,  10,  11,  13,  11,   9,  15,  13,  12,  13,  17,  16,  15,  18,  23,  39,  25,  23,  21,  21,  23,
                                                48,  34,  36,  28,  39,  57,  50,  60,  59,  56,  50,  55,  54,  63,  71,  91,  77,  63,  67,  86,  68,
                                                54,  55,  79, 108,  80,  86,  94,  97, 102, 103, 102,  61,  76, 112, 120, 111,  99, 119,  91, 100, 102,  98};
  static const uint8_t chrominance_base[64] = { 16,  17,  17,  23,  20,  23,  46,  25,  25,  46,  98,  65,  55,  65,  98,  98,  98,  98,  98,  98,  98,
                                                98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,
                                                98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98,  98};
  // compute a score based on the logarithm of the image's dimensions (approximated using integer math)
  uint_fast32_t current, score = 0;
  for (current = context -> source -> width; current > 4; current >>= 1) score += 2;
  score += current;
  for (current = context -> source -> height; current > 4; current >>= 1) score += 2;
  score += current;
  score = (score > 24) ? score - 22 : 2;
  // adjust the chrominance accuracy based on the color depth
  uint_fast32_t depth = get_true_color_depth(context -> source);
  uint_fast32_t adjustment = 72 - (depth & 0xff) - ((depth >> 8) & 0xff) - ((depth >> 16) & 0xff);
  // compute the final quantization coefficients based on the scores above
  for (uint_fast8_t p = 0; p < 64; p ++) {
    luminance_table[p] = 1 + luminance_base[p] * score / 25;
    chrominance_table[p] = 1 + chrominance_base[p] * score * adjustment / 1200;
  }
}

void convert_JPEG_components_to_YCbCr (struct context * context, double (* restrict luminance)[64], double (* restrict blue)[64], double (* restrict red)[64]) {
  const unsigned char * data = context -> source -> data;
  size_t offset = context -> source -> palette ? 1 : plum_color_buffer_size(1, context -> source -> color_format), rowoffset = offset * context -> source -> width;
  double palette_luminance[256];
  double palette_blue[256];
  double palette_red[256];
  uint64_t * buffer = ctxmalloc(context, sizeof *buffer * ((context -> source -> palette && context -> source -> max_palette_index > 7) ?
                                                           context -> source -> max_palette_index + 1 : 8));
  // define macros to reduce repetition within the function
  #define nextunit luminance ++, blue ++, red ++
  #define convertblock(rows, cols) do                                                                                                                          \
    if (context -> source -> palette)                                                                                                                          \
      for (uint_fast8_t row = 0; row < (rows); row ++) for (uint_fast8_t col = 0; col < (cols); col ++) {                                                      \
        unsigned char index = data[(unitrow * 8 + row) * context -> source -> width + unitcol * 8 + col], coord = row * 8 + col;                               \
        coord[*luminance] = palette_luminance[index];                                                                                                          \
        coord[*blue] = palette_blue[index];                                                                                                                    \
        coord[*red] = palette_red[index];                                                                                                                      \
      }                                                                                                                                                        \
    else {                                                                                                                                                     \
      size_t index = unitrow * 8 * rowoffset + unitcol * 8 * offset;                                                                                           \
      for (uint_fast8_t row = 0; row < (rows); row ++, index += rowoffset)                                                                                     \
        convert_JPEG_colors_to_YCbCr(data + index, cols, context -> source -> color_format, *luminance + 8 * row, *blue + 8 * row, *red + 8 * row, buffer);    \
    }                                                                                                                                                          \
  while (false)
  #define copyvalues(index, offset) do {                     \
    uint_fast8_t coord = (index), ref = coord - (offset);    \
    coord[*luminance] = ref[*luminance];                     \
    coord[*blue] = ref[*blue];                               \
    coord[*red] = ref[*red];                                 \
  } while (false)
  // actually do the conversion
  if (context -> source -> palette)
    convert_JPEG_colors_to_YCbCr(context -> source -> palette, context -> source -> max_palette_index + 1, context -> source -> color_format, palette_luminance,
                                 palette_blue, palette_red, buffer);
  size_t unitrow, unitcol; // used by convertblock (and thus required to keep their values after the loops exit)
  for (unitrow = 0; unitrow < (context -> source -> height >> 3); unitrow ++) {
    for (unitcol = 0; unitcol < (context -> source -> width >> 3); unitcol ++) {
      convertblock(8, 8);
      nextunit;
    }
    if (context -> source -> width & 7) {
      convertblock(8, context -> source -> width & 7);
      for (uint_fast8_t row = 0; row < 8; row ++) for (uint_fast8_t col = context -> source -> width & 7; col < 8; col ++) copyvalues(row * 8 + col, 1);
      nextunit;
    }
  }
  if (context -> source -> height & 7) {
    for (unitcol = 0; unitcol < (context -> source -> width >> 3); unitcol ++) {
      convertblock(context -> source -> height & 7, 8);
      for (uint_fast8_t p = 8 * (context -> source -> height & 7); p < 64; p ++) copyvalues(p, 8);
      nextunit;
    }
    if (context -> source -> width & 7) {
      convertblock(context -> source -> height & 7, context -> source -> width & 7);
      for (uint_fast8_t row = 0; row < (context -> source -> height & 7); row ++) for (uint_fast8_t col = context -> source -> width & 7; col < 8; col ++)
        copyvalues(row * 8 + col, 1);
      for (uint_fast8_t p = 8 * (context -> source -> height & 7); p < 64; p ++) copyvalues(p, 8);
    }
  }
  #undef copyvalues
  #undef convertblock
  #undef nextunit
  ctxfree(context, buffer);
}

void convert_JPEG_colors_to_YCbCr (const void * restrict colors, size_t count, unsigned char flags, double * restrict luminance, double * restrict blue,
                                   double * restrict red, uint64_t * restrict buffer) {
  plum_convert_colors(buffer, colors, count, PLUM_COLOR_64, flags);
  for (size_t p = 0; p < count; p ++) {
    double R = (double) (buffer[p] & 0xffffu) / 257.0, G = (double) ((buffer[p] >> 16) & 0xffffu) / 257.0, B = (double) ((buffer[p] >> 32) & 0xffffu) / 257.0;
    luminance[p] = 0x0.4c8b4395810628p+0 * R + 0x0.9645a1cac08310p+0 * G + 0x0.1d2f1a9fbe76c8p+0 * B - 128.0;
    blue[p] = 0.5 * (B - 1.0) - 0x0.2b32468049f7e8p+0 * R - 0x0.54cdb97fb60818p+0 * G;
    red[p] = 0.5 * (R - 1.0) - 0x0.6b2f1c1ead19ecp+0 * G - 0x0.14d0e3e152e614p+0 * B;
  }
}

void subsample_JPEG_component (double (* restrict component)[64], double (* restrict output)[64], size_t unitsH, size_t unitsV) {
  #define reduce(offset, shift, y, x) do {                                              \
    uint_fast8_t index = (y) * 8 + (x);                                                 \
    const double * ref = component[(offset) * unitsH] + (index * 2 - 64 * (offset));    \
    (*output)[index + (shift)] = (*ref + ref[1] + ref[8] + ref[9]) * 0.25;              \
  } while (false)
  for (size_t unitrow = 0; unitrow < (unitsV >> 1); unitrow ++) {
    for (size_t unitcol = 0; unitcol < (unitsH >> 1); unitcol ++) {
      for (uint_fast8_t p = 0; p < 8; p += 4) {
        for (uint_fast8_t row = 0; row < 4; row ++) for (uint_fast8_t col = 0; col < 4; col ++) {
          reduce(0, p, row, col);
          reduce(1, p, row + 4, col);
        }
        component ++;
      }
      output ++;
    }
    if (unitsH & 1) {
      for (uint_fast8_t row = 0; row < 4; row ++) for (uint_fast8_t col = 0; col < 4; col ++) {
        reduce(0, 0, row, col);
        reduce(1, 0, row + 4, col);
      }
      component ++;
      for (uint_fast8_t row = 0; row < 8; row ++) for (uint_fast8_t col = 4; col < 8; col ++) (*output)[row * 8 + col] = (*output)[row * 8 + col - 1];
      output ++;
    }
    component += unitsH; // skip odd rows
  }
  if (unitsV & 1) {
    for (size_t unitcol = 0; unitcol < (unitsH >> 1); unitcol ++) {
      for (uint_fast8_t p = 0; p < 8; p += 4) {
        for (uint_fast8_t row = 0; row < 4; row ++) for (uint_fast8_t col = 0; col < 4; col ++) reduce(0, p, row, col);
        component ++;
      }
      for (uint_fast8_t p = 32; p < 64; p ++) (*output)[p] = (*output)[p - 8];
      output ++;
    }
    if (unitsH & 1) {
      for (uint_fast8_t row = 0; row < 4; row ++) for (uint_fast8_t col = 0; col < 4; col ++) {
        reduce(0, 0, row, col);
        (*output)[row * 8 + col + 4] = (*output)[row * 8 + col];
      }
      for (uint_fast8_t p = 32; p < 64; p ++) (*output)[p] = (*output)[p - 8];
    }
  }
  #undef reduce
}

struct plum_image * plum_load_image (const void * restrict buffer, size_t size_mode, unsigned flags, unsigned * restrict error) {
  return plum_load_image_limited(buffer, size_mode, flags, SIZE_MAX, error);
}

struct plum_image * plum_load_image_limited (const void * restrict buffer, size_t size_mode, unsigned flags, size_t limit, unsigned * restrict error) {
  struct context * context = create_context();
  if (!context) {
    if (error) *error = PLUM_ERR_OUT_OF_MEMORY;
    return NULL;
  }
  if (!setjmp(context -> target)) {
    if (!buffer) throw(context, PLUM_ERR_INVALID_ARGUMENTS);
    if (!(context -> image = plum_new_image())) throw(context, PLUM_ERR_OUT_OF_MEMORY);
    prepare_image_buffer_data(context, buffer, size_mode);
    load_image_buffer_data(context, flags, limit);
    if (flags & PLUM_ALPHA_REMOVE) plum_remove_alpha(context -> image);
    if (flags & PLUM_PALETTE_GENERATE)
      if (context -> image -> palette) {
        int colors = plum_get_highest_palette_index(context -> image);
        if (colors < 0) throw(context, -colors);
        context -> image -> max_palette_index = colors;
        update_loaded_palette(context, flags);
      } else {
        generate_palette(context, flags);
        // PLUM_PALETTE_FORCE == PLUM_PALETTE_LOAD | PLUM_PALETTE_GENERATE
        if (!(context -> image -> palette) && (flags & PLUM_PALETTE_LOAD)) throw(context, PLUM_ERR_TOO_MANY_COLORS);
      }
    else if (context -> image -> palette)
      if ((flags & PLUM_PALETTE_MASK) == PLUM_PALETTE_NONE)
        remove_palette(context);
      else
        update_loaded_palette(context, flags);
  }
  if (context -> file) fclose(context -> file);
  if (error) *error = context -> status;
  struct plum_image * image = context -> image;
  if (context -> status) {
    plum_destroy_image(image);
    image = NULL;
  }
  destroy_allocator_list(context -> allocator);
  return image;
}

void load_image_buffer_data (struct context * context, unsigned flags, size_t limit) {
  if (context -> size == 7 && (bytematch(context -> data, 0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x3b) ||
                               bytematch(context -> data, 0x47, 0x49, 0x46, 0x38, 0x37, 0x61, 0x3b)))
    // empty GIF file
    throw(context, PLUM_ERR_NO_DATA);
  if (context -> size < 8) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (bytematch(context -> data, 0x42, 0x4d))
    load_BMP_data(context, flags, limit);
  else if (bytematch(context -> data, 0x47, 0x49, 0x46, 0x38, 0x39, 0x61))
    load_GIF_data(context, flags, limit);
  else if (bytematch(context -> data, 0x47, 0x49, 0x46, 0x38, 0x37, 0x61))
    // treat GIF87a as GIF89a for compatibility, since it's a strict subset anyway
    load_GIF_data(context, flags, limit);
  else if (bytematch(context -> data, 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a))
    // APNG files disguise as PNG files, so handle them all as PNG and split them later
    load_PNG_data(context, flags, limit);
  else if (*context -> data == 0x50 && context -> data[1] >= 0x31 && context -> data[1] <= 0x37)
    load_PNM_data(context, flags, limit);
  else if (bytematch(context -> data, 0xef, 0xbb, 0xbf, 0x50) && context -> data[4] >= 0x31 && context -> data[4] <= 0x37)
    // text-based PNM data destroyed by a UTF-8 BOM: load it anyway, just in case a broken text editor does this
    load_PNM_data(context, flags, limit);
  else {
    // JPEG detection: one or more 0xff bytes followed by 0xd8
    size_t position;
    for (position = 0; position < context -> size && context -> data[position] == 0xff; position ++);
    if (position && position < context -> size && context -> data[position] == 0xd8)
      load_JPEG_data(context, flags, limit);
    else
      // all attempts to detect the file type failed
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
}

void prepare_image_buffer_data (struct context * context, const void * restrict buffer, size_t size_mode) {
  switch (size_mode) {
    case PLUM_MODE_FILENAME:
      load_file(context, buffer);
      return;
    case PLUM_MODE_BUFFER:
      context -> data = ((const struct plum_buffer *) buffer) -> data;
      context -> size = ((const struct plum_buffer *) buffer) -> size;
      if (!context -> data) throw(context, PLUM_ERR_INVALID_ARGUMENTS);
      return;
    case PLUM_MODE_CALLBACK:
      load_from_callback(context, buffer);
      return;
    default:
      context -> data = buffer;
      context -> size = size_mode;
  }
}

void load_file (struct context * context, const char * filename) {
  context -> file = fopen(filename, "rb");
  if (!context -> file) throw(context, PLUM_ERR_FILE_INACCESSIBLE);
  size_t allocated;
  char * buffer = resize_read_buffer(context, NULL, &allocated);
  size_t size = fread(buffer, 1, allocated, context -> file);
  if (ferror(context -> file)) throw(context, PLUM_ERR_FILE_ERROR);
  while (!feof(context -> file)) {
    if (allocated - size < 0x4000) buffer = resize_read_buffer(context, buffer, &allocated);
    size += fread(buffer + size, 1, 0x4000, context -> file);
    if (ferror(context -> file)) throw(context, PLUM_ERR_FILE_ERROR);
  }
  fclose(context -> file);
  context -> file = NULL;
  context -> data = ctxrealloc(context, buffer, size);
  context -> size = size;
}

void load_from_callback (struct context * context, const struct plum_callback * callback) {
  size_t allocated;
  unsigned char * buffer = resize_read_buffer(context, NULL, &allocated);
  int iteration = callback -> callback(callback -> userdata, buffer, 0x4000 - sizeof(union allocator_node));
  if (iteration < 0 || iteration > 0x4000 - sizeof(union allocator_node)) throw(context, PLUM_ERR_FILE_ERROR);
  context -> size = iteration;
  while (iteration) {
    if (allocated - context -> size < 0x4000) buffer = resize_read_buffer(context, buffer, &allocated);
    iteration = callback -> callback(callback -> userdata, buffer + context -> size, 0x4000);
    if (iteration < 0 || iteration > 0x4000) throw(context, PLUM_ERR_FILE_ERROR);
    context -> size += iteration;
  }
  context -> data = buffer;
}

void * resize_read_buffer (struct context * context, void * buffer, size_t * restrict allocated) {
  // will set the buffer to its initial size on first call (buffer = NULL, allocated = ignored), or extend it on further calls
  if (buffer)
    if (*allocated < 0x20000u - sizeof(union allocator_node))
      *allocated += 0x4000;
    else
      *allocated += (size_t) 0x4000 << (bit_width(*allocated + sizeof(union allocator_node)) - 17);
  else
    *allocated = 0x4000 - sizeof(union allocator_node); // keep the buffer aligned to 4K memory pages
  return ctxrealloc(context, buffer, *allocated);
}

void update_loaded_palette (struct context * context, unsigned flags) {
  if (flags & PLUM_SORT_EXISTING) sort_palette(context -> image, flags);
  if (flags & PLUM_PALETTE_REDUCE) {
    reduce_palette(context -> image);
    context -> image -> palette = plum_realloc(context -> image, context -> image -> palette, plum_palette_buffer_size(context -> image));
    if (!context -> image -> palette) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  }
}

struct plum_metadata * plum_allocate_metadata (struct plum_image * image, size_t size) {
  union {
    struct plum_metadata result;
    max_align_t alignment;
  } * result = plum_malloc(image, sizeof *result + size);
  if (!result) return NULL;
  result -> result = (struct plum_metadata) {
    .type = PLUM_METADATA_NONE,
    .size = size,
    .data = result + 1,
    .next = NULL
  };
  return &(result -> result);
}

unsigned plum_append_metadata (struct plum_image * image, int type, const void * data, size_t size) {
  if (!image || (size && !data)) return PLUM_ERR_INVALID_ARGUMENTS;
  struct plum_metadata * metadata = plum_allocate_metadata(image, size);
  if (!metadata) return PLUM_ERR_OUT_OF_MEMORY;
  metadata -> type = type;
  if (size) memcpy(metadata -> data, data, size);
  metadata -> next = image -> metadata;
  image -> metadata = metadata;
  return 0;
}

struct plum_metadata * plum_find_metadata (const struct plum_image * image, int type) {
  if (!image) return NULL;
  for (struct plum_metadata * metadata = (struct plum_metadata *) image -> metadata; metadata; metadata = metadata -> next)
    if (metadata -> type == type) return metadata;
  return NULL;
}

void add_color_depth_metadata (struct context * context, unsigned red, unsigned green, unsigned blue, unsigned alpha, unsigned gray) {
  unsigned char counts[] = {red, green, blue, alpha, gray};
  unsigned result = plum_append_metadata(context -> image, PLUM_METADATA_COLOR_DEPTH, counts, sizeof counts);
  if (result) throw(context, result);
}

void add_background_color_metadata (struct context * context, uint64_t color, unsigned flags) {
  color = plum_convert_color(color, PLUM_COLOR_64, flags);
  size_t size = plum_color_buffer_size(1, flags);
  struct plum_metadata * metadata = plum_allocate_metadata(context -> image, size);
  if (!metadata) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  metadata -> type = PLUM_METADATA_BACKGROUND;
  if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_64)
    *(uint64_t *) (metadata -> data) = color;
  else if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    *(uint16_t *) (metadata -> data) = color;
  else
    *(uint32_t *) (metadata -> data) = color;
  metadata -> next = context -> image -> metadata;
  context -> image -> metadata = metadata;
}

void add_loop_count_metadata (struct context * context, uint32_t count) {
  unsigned result = plum_append_metadata(context -> image, PLUM_METADATA_LOOP_COUNT, &count, sizeof count);
  if (result) throw(context, result);
}

void add_animation_metadata (struct context * context, uint64_t ** restrict durations, uint8_t ** restrict disposals) {
  struct plum_metadata * durations_metadata = plum_allocate_metadata(context -> image, sizeof **durations * context -> image -> frames);
  struct plum_metadata * disposals_metadata = plum_allocate_metadata(context -> image, sizeof **disposals * context -> image -> frames);
  if (!(durations_metadata && disposals_metadata)) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  memset(*durations = durations_metadata -> data, 0, durations_metadata -> size);
  memset(*disposals = disposals_metadata -> data, 0, disposals_metadata -> size);
  durations_metadata -> type = PLUM_METADATA_FRAME_DURATION;
  disposals_metadata -> type = PLUM_METADATA_FRAME_DISPOSAL;
  durations_metadata -> next = disposals_metadata;
  disposals_metadata -> next = context -> image -> metadata;
  context -> image -> metadata = durations_metadata;
}

uint64_t get_background_color (const struct plum_image * image, uint64_t fallback) {
  const struct plum_metadata * background = plum_find_metadata(image, PLUM_METADATA_BACKGROUND);
  if (!background) return fallback;
  if ((image -> color_format & PLUM_COLOR_MASK) == PLUM_COLOR_64)
    return *(const uint64_t *) background -> data;
  else if ((image -> color_format & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    return *(const uint16_t *) background -> data;
  else
    return *(const uint32_t *) background -> data;
}

unsigned plum_validate_image (const struct plum_image * image) {
  if (!image) return PLUM_ERR_INVALID_ARGUMENTS;
  if (!(image -> width && image -> height && image -> frames && image -> data)) return PLUM_ERR_NO_DATA;
  if (!plum_check_valid_image_size(image -> width, image -> height, image -> frames)) return PLUM_ERR_IMAGE_TOO_LARGE;
  if (image -> type >= PLUM_NUM_IMAGE_TYPES) return PLUM_ERR_INVALID_FILE_FORMAT;
  bool found[PLUM_NUM_METADATA_TYPES - 1] = {0};
  for (const struct plum_metadata * metadata = image -> metadata; metadata; metadata = metadata -> next) {
    if (metadata -> size && !metadata -> data) return PLUM_ERR_INVALID_METADATA;
    if (metadata -> type <= 0) continue;
    if (metadata -> type >= PLUM_NUM_METADATA_TYPES || found[metadata -> type - 1]) return PLUM_ERR_INVALID_METADATA;
    found[metadata -> type - 1] = true;
    switch (metadata -> type) {
      case PLUM_METADATA_COLOR_DEPTH:
        if (metadata -> size < 3 || metadata -> size > 5) return PLUM_ERR_INVALID_METADATA;
        break;
      case PLUM_METADATA_BACKGROUND:
        if (metadata -> size != plum_color_buffer_size(1, image -> color_format)) return PLUM_ERR_INVALID_METADATA;
        break;
      case PLUM_METADATA_LOOP_COUNT:
        if (metadata -> size != sizeof(uint32_t)) return PLUM_ERR_INVALID_METADATA;
        break;
      case PLUM_METADATA_FRAME_DURATION:
        if (metadata -> size % sizeof(uint64_t)) return PLUM_ERR_INVALID_METADATA;
        break;
      case PLUM_METADATA_FRAME_DISPOSAL:
        for (size_t p = 0; p < metadata -> size; p ++) if (p[(uint8_t *) metadata -> data] >= PLUM_NUM_DISPOSAL_METHODS) return PLUM_ERR_INVALID_METADATA;
    }
  }
  return 0;
}

const char * plum_get_error_text (unsigned error) {
  static const char * const messages[PLUM_NUM_ERRORS] = {
    [PLUM_OK]                      = "success",
    [PLUM_ERR_INVALID_ARGUMENTS]   = "invalid argument for function",
    [PLUM_ERR_INVALID_FILE_FORMAT] = "invalid image data or unknown format",
    [PLUM_ERR_INVALID_METADATA]    = "invalid image metadata",
    [PLUM_ERR_INVALID_COLOR_INDEX] = "invalid palette index",
    [PLUM_ERR_TOO_MANY_COLORS]     = "too many colors in image",
    [PLUM_ERR_UNDEFINED_PALETTE]   = "image palette not defined",
    [PLUM_ERR_IMAGE_TOO_LARGE]     = "image dimensions too large",
    [PLUM_ERR_NO_DATA]             = "image contains no image data",
    [PLUM_ERR_NO_MULTI_FRAME]      = "multiple frames not supported",
    [PLUM_ERR_FILE_INACCESSIBLE]   = "could not access file",
    [PLUM_ERR_FILE_ERROR]          = "file input/output error",
    [PLUM_ERR_OUT_OF_MEMORY]       = "out of memory"
  };
  if (error >= PLUM_NUM_ERRORS) return NULL;
  return messages[error];
}

const char * plum_get_file_format_name (unsigned format) {
  static const char * const formats[PLUM_NUM_IMAGE_TYPES] = {
    [PLUM_IMAGE_NONE] = NULL, // default for invalid formats
    [PLUM_IMAGE_BMP]  = "BMP",
    [PLUM_IMAGE_GIF]  = "GIF",
    [PLUM_IMAGE_PNG]  = "PNG",
    [PLUM_IMAGE_APNG] = "APNG",
    [PLUM_IMAGE_JPEG] = "JPEG",
    [PLUM_IMAGE_PNM]  = "PNM"
  };
  if (format >= PLUM_NUM_IMAGE_TYPES) format = PLUM_IMAGE_NONE;
  return formats[format];
}

uint32_t plum_get_version_number (void) {
  return PLUM_VERSION;
}

int compare64 (const void * first, const void * second) {
  const uint64_t * p1 = first;
  const uint64_t * p2 = second;
  return (*p1 > *p2) - (*p1 < *p2);
}

int compare_index_value_pairs (const void * first, const void * second) {
  const uint64_t * p1 = first;
  const uint64_t * p2 = second;
  size_t index = p1[1] != p2[1];
  return (p1[index] > p2[index]) - (p1[index] < p2[index]);
}

struct plum_image * plum_new_image (void) {
  union allocator_node * allocator = NULL;
  struct plum_image * image = allocate(&allocator, sizeof *image);
  if (image) *image = (struct plum_image) {.allocator = allocator}; // zero-initialize all other members
  return image;
}

struct plum_image * plum_copy_image (const struct plum_image * image) {
  if (!(image && image -> data)) return NULL;
  struct plum_image * copy = plum_new_image();
  if (!copy) return NULL;
  copy -> type = image -> type;
  copy -> max_palette_index = image -> max_palette_index;
  copy -> color_format = image -> color_format;
  copy -> frames = image -> frames;
  copy -> height = image -> height;
  copy -> width = image -> width;
  copy -> userdata = image -> userdata;
  if (image -> metadata) {
    const struct plum_metadata * current = image -> metadata;
    struct plum_metadata * allocated = plum_allocate_metadata(copy, current -> size);
    if (!allocated) goto fail;
    allocated -> type = current -> type;
    memcpy(allocated -> data, current -> data, current -> size);
    struct plum_metadata * last = copy -> metadata = allocated;
    while (current = current -> next) {
      allocated = plum_allocate_metadata(copy, current -> size);
      if (!allocated) goto fail;
      allocated -> type = current -> type;
      memcpy(allocated -> data, current -> data, current -> size);
      last -> next = allocated;
      last = allocated;
    }
  }
  if (image -> width && image -> height && image -> frames) {
    size_t size = plum_pixel_buffer_size(image);
    if (!size) goto fail;
    void * buffer = plum_malloc(copy, size);
    if (!buffer) goto fail;
    memcpy(buffer, image -> data, size);
    copy -> data = buffer;
  }
  if (image -> palette) {
    size_t size = plum_palette_buffer_size(image);
    void * buffer = plum_malloc(copy, size);
    if (!buffer) goto fail;
    memcpy(buffer, image -> palette, size);
    copy -> palette = buffer;
  }
  return copy;
  fail:
  plum_destroy_image(copy);
  return NULL;
}

void plum_destroy_image (struct plum_image * image) {
  if (!image) return;
  union allocator_node * allocator = image -> allocator;
  image -> allocator = NULL;
  destroy_allocator_list(allocator);
}

struct context * create_context (void) {
  union allocator_node * allocator = NULL;
  struct context * context = allocate(&allocator, sizeof *context);
  if (context) *context = (struct context) {.allocator = allocator};
  return context;
}

void generate_palette (struct context * context, unsigned flags) {
  size_t count = (size_t) context -> image -> width * context -> image -> height * context -> image -> frames;
  void * palette = plum_malloc(context -> image, plum_color_buffer_size(0x100, context -> image -> color_format));
  uint8_t * indexes = plum_malloc(context -> image, count);
  if (!(palette || indexes)) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  int result = plum_convert_colors_to_indexes(indexes, context -> image -> data, palette, count, flags);
  if (result >= 0) {
    plum_free(context -> image, context -> image -> data);
    context -> image -> data = indexes;
    context -> image -> max_palette_index = result;
    context -> image -> palette = plum_realloc(context -> image, palette, plum_color_buffer_size(result + 1, context -> image -> color_format));
    if (!context -> image -> palette) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  } else if (result == -PLUM_ERR_TOO_MANY_COLORS) {
    plum_free(context -> image, palette);
    plum_free(context -> image, indexes);
  } else
    throw(context, -result);
}

void remove_palette (struct context * context) {
  size_t count = (size_t) context -> image -> width * context -> image -> height * context -> image -> frames;
  void * buffer = plum_malloc(context -> image, plum_color_buffer_size(count, context -> image -> color_format));
  if (!buffer) throw(context, PLUM_ERR_OUT_OF_MEMORY);
  plum_convert_indexes_to_colors(buffer, context -> image -> data8, context -> image -> palette, count, context -> image -> color_format);
  plum_free(context -> image, context -> image -> data8);
  plum_free(context -> image, context -> image -> palette);
  context -> image -> data = buffer;
  context -> image -> palette = NULL;
  context -> image -> max_palette_index = 0;
}

unsigned plum_sort_palette (struct plum_image * image, unsigned flags) {
  unsigned result = check_image_palette(image);
  if (!result) sort_palette(image, image -> color_format | (flags & PLUM_SORT_DARK_FIRST));
  return result;
}

unsigned plum_sort_palette_custom (struct plum_image * image, uint64_t (* callback) (void *, uint64_t), void * argument, unsigned flags) {
  if (!callback) return PLUM_ERR_INVALID_ARGUMENTS;
  unsigned error = check_image_palette(image);
  if (error) return error;
  uint64_t sortdata[0x200];
  #define filldata(bits) do                                                                                                       \
    for (uint_fast16_t p = 0; p <= image -> max_palette_index; p ++) {                                                            \
      sortdata[2 * p] = p;                                                                                                        \
      sortdata[2 * p + 1] = callback(argument, plum_convert_color(image -> palette ## bits[p], image -> color_format, flags));    \
    }                                                                                                                             \
  while (false)
  if ((image -> color_format & PLUM_COLOR_MASK) == PLUM_COLOR_64)
    filldata(64);
  else if ((image -> color_format & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    filldata(16);
  else
    filldata(32);
  #undef filldata
  qsort(sortdata, image -> max_palette_index + 1, 2 * sizeof *sortdata, &compare_index_value_pairs);
  uint8_t sorted[0x100];
  for (uint_fast16_t p = 0; p <= image -> max_palette_index; p ++) sorted[sortdata[2 * p]] = p;
  apply_sorted_palette(image, image -> color_format, sorted);
  return 0;
}

void sort_palette (struct plum_image * image, unsigned flags) {
  uint8_t indexes[0x100];
  plum_sort_colors(image -> palette, image -> max_palette_index, flags, indexes);
  uint8_t sorted[0x100];
  for (uint_fast16_t p = 0; p <= image -> max_palette_index; p ++) sorted[indexes[p]] = p;
  apply_sorted_palette(image, flags, sorted);
}

void apply_sorted_palette (struct plum_image * image, unsigned flags, const uint8_t * sorted) {
  size_t limit = (size_t) image -> width * image -> height * image -> frames;
  for (size_t p = 0; p < limit; p ++) image -> data8[p] = sorted[image -> data8[p]];
  #define sortpalette(bits) do {                                                                                         \
    uint ## bits ## _t colors[0x100];                                                                                    \
    for (uint_fast16_t p = 0; p <= image -> max_palette_index; p ++) colors[sorted[p]] = image -> palette ## bits[p];    \
    memcpy(image -> palette ## bits, colors, (image -> max_palette_index + 1) * sizeof *colors);                         \
  } while (false)
  if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_64)
    sortpalette(64);
  else if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    sortpalette(16);
  else
    sortpalette(32);
  #undef sortpalette
}

unsigned plum_reduce_palette (struct plum_image * image) {
  unsigned result = check_image_palette(image);
  if (!result) reduce_palette(image);
  return result;
}

void reduce_palette (struct plum_image * image) {
  // convert all colors to 64-bit for consistent handling: converting up to 64-bit and later back to the original format is lossless
  uint64_t colors[0x100];
  plum_convert_colors(colors, image -> palette, image -> max_palette_index + 1, PLUM_COLOR_64, image -> color_format);
  // expand from an array of colors to an interleaved array of indexes and colors (for sorting)
  uint64_t sorted[0x200];
  for (uint_fast16_t p = 0; p <= image -> max_palette_index; p ++) {
    sorted[2 * p] = p;
    sorted[2 * p + 1] = colors[p];
  }
  // mark all colors in the image as in use
  bool used[0x100] = {0};
  size_t size = (size_t) image -> width * image -> height * image -> frames;
  for (size_t p = 0; p < size; p ++) used[image -> data8[p]] = true;
  // sort the colors and check for duplicates; if duplicates are found, mark the duplicates as unused and the originals as in use
  qsort(sorted, image -> max_palette_index + 1, 2 * sizeof *sorted, &compare_index_value_pairs);
  for (uint_fast8_t p = image -> max_palette_index; p; p --) if (sorted[2 * p + 1] == sorted[2 * p - 1]) {
    used[sorted[2 * p - 2]] |= used[sorted[2 * p]];
    used[sorted[2 * p]] = false;
  }
  // create a mapping of colors (in the colors array) to indexes; colors in use (after duplicates were marked unused) get their own index
  // colors marked unused point to the previous color in use; this will deduplicate the colors, as duplicates come right after the originals
  // actually unused colors will get mapped to nonsensical indexes, but they don't matter, since they don't appear in the image
  uint8_t map[0x100];
  uint_fast8_t ref = 0; // initialize it to avoid reading an uninitialized variable in the loop (even though the copied value will never be used)
  for (uint_fast16_t p = 0; p <= image -> max_palette_index; p ++)
    if (used[sorted[2 * p]])
      ref = map[sorted[2 * p]] = sorted[2 * p];
    else
      map[sorted[2 * p]] = ref;
  // update the mapping table to preserve the order of the colors in the original palette, and generate the reduced palette (in the colors array)
  ref = 0;
  for (uint_fast16_t p = 0; p <= image -> max_palette_index; p ++)
    if (used[p]) {
      map[p] = ref;
      colors[ref ++] = colors[p];
    } else
      map[p] = map[map[p]];
  // update the image's palette (including the max_palette_index member) and data
  image -> max_palette_index = ref - 1;
  plum_convert_colors(image -> palette, colors, ref, image -> color_format, PLUM_COLOR_64);
  for (size_t p = 0; p < size; p ++) image -> data8[p] = map[image -> data8[p]];
}

unsigned check_image_palette (const struct plum_image * image) {
  unsigned result = plum_validate_image(image);
  if (result) return result;
  if (!image -> palette) return PLUM_ERR_UNDEFINED_PALETTE;
  if (plum_validate_palette_indexes(image)) return PLUM_ERR_INVALID_COLOR_INDEX;
  return 0;
}

const uint8_t * plum_validate_palette_indexes (const struct plum_image * image) {
  // NULL if OK, address of first error if failed
  if (!(image && image -> palette)) return NULL;
  if (image -> max_palette_index == 0xff) return NULL;
  size_t count = (size_t) image -> width * image -> height * image -> frames;
  for (const uint8_t * ptr = image -> data8; count; ptr ++, count --) if (*ptr > image -> max_palette_index) return ptr;
  return NULL;
}

int plum_get_highest_palette_index (const struct plum_image * image) {
  int result = plum_validate_image(image);
  if (result) return -result;
  if (!image -> palette) return -PLUM_ERR_UNDEFINED_PALETTE;
  // result is already initialized to 0
  size_t count = (size_t) image -> width * image -> height * image -> frames;
  for (size_t p = 0; p < count; p ++) if (image -> data8[p] > result) result = image -> data8[p];
  return result;
}

int plum_convert_colors_to_indexes (uint8_t * restrict destination, const void * restrict source, void * restrict palette, size_t count, unsigned flags) {
  if (!(destination && source && palette && count)) return -PLUM_ERR_INVALID_ARGUMENTS;
  uint64_t * colors = malloc(0x800 * sizeof *colors);
  uint64_t * sorted = malloc(0x100 * sizeof *sorted);
  uint8_t * counts = calloc(0x100, sizeof *counts);
  uint16_t * indexes = malloc(count * sizeof *indexes);
  int result = -PLUM_ERR_TOO_MANY_COLORS; // default result (which will be returned if generating the color table fails)
  if (!(colors && sorted && counts && indexes)) {
    result = -PLUM_ERR_OUT_OF_MEMORY;
    goto fail;
  }
  const unsigned char * sp = source;
  unsigned total = 0, offset = plum_color_buffer_size(1, flags);
  // first, store each color in a temporary hash table, and store the index into that table for each pixel
  for (size_t pos = 0; pos < count; pos ++, sp += offset) {
    uint64_t color;
    if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_64)
      color = *(const uint64_t *) sp;
    else if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_16)
      color = *(const uint16_t *) sp;
    else
      color = *(const uint32_t *) sp;
    uint_fast16_t index;
    unsigned char slot, hash = 0;
    for (uint_fast8_t p = 0; p < sizeof color; p ++) hash += (color >> (p * 8)) * (6 * p + 17);
    for (slot = 0; slot < (counts[hash] & 7); slot ++) {
      index = (hash << 3) | slot;
      if (colors[index] == color) goto found;
    }
    if (slot < 7)
      counts[hash] ++; // that hash code doesn't have all seven slots occupied: use the next free one and increase the count for the hash code
    else {
      // all seven slots for that hash code are occupied: check the overflow section, and if the color is not there either, store it there
      // the hash now becomes the index into the overflow section (must be unsigned char for its overflow behavior)
      for (; counts[hash] & 0x80; hash ++) {
        index = (hash << 3) | 7; // slot == 7 here
        if (colors[index] == color) goto found;
      }
      counts[hash] |= 0x80; // mark the overflow slot for that hash code as in use
    }
    if (total >= 0x100) goto fail;
    total ++;
    index = (hash << 3) | slot;
    colors[index] = color;
    found:
    indexes[pos] = index;
  }
  // then, compute a sorted color list (without gaps) to build the actual palette
  uint64_t * cc = sorted;
  for (uint_fast16_t pos = 0; pos < 0x100; pos ++) {
    uint_fast16_t index = pos << 3;
    for (uint_fast8_t p = 0; p < (counts[pos] & 7); p ++, index ++)
      *(cc ++) = (get_color_sorting_score(colors[index], flags) << 11) | index;
    if (counts[pos] & 0x80) {
      index |= 7;
      *(cc ++) = (get_color_sorting_score(colors[index], flags) << 11) | index;
    }
  }
  qsort(sorted, total, sizeof *sorted, &compare64);
  // afterwards, write the actual palette, and replace the colors with indexes into it
  #define copypalette(bits) do {                   \
    uint ## bits ## _t * pp = palette;             \
    for (size_t pos = 0; pos < total; pos ++) {    \
      *(pp ++) = colors[sorted[pos] & 0x7ff];      \
      colors[sorted[pos] & 0x7ff] = pos;           \
    }                                              \
  } while (false)
  if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_64)
    copypalette(64);
  else if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    copypalette(16);
  else
    copypalette(32);
  #undef copypalette
  // and finally, write out the color indexes to the frame buffer
  for (size_t pos = 0; pos < count; pos ++) destination[pos] = colors[indexes[pos]];
  result = total - 1;
  fail:
  free(indexes);
  free(counts);
  free(sorted);
  free(colors);
  return result;
}

uint64_t get_color_sorting_score (uint64_t color, unsigned flags) {
  color = plum_convert_color(color, flags, PLUM_COLOR_64 | PLUM_ALPHA_INVERT);
  uint64_t red = color & 0xffffu, green = (color >> 16) & 0xffffu, blue = (color >> 32) & 0xffffu, alpha = color >> 48;
  uint64_t luminance = red * 299 + green * 587 + blue * 114; // 26 bits
  if (flags & PLUM_SORT_DARK_FIRST) luminance ^= 0x3ffffffu;
  uint64_t sum = red + green + blue; // 18 bits
  return ~((luminance << 27) | (sum << 9) | (alpha >> 7)); // total: 53 bits
}

void plum_convert_indexes_to_colors (void * restrict destination, const uint8_t * restrict source, const void * restrict palette, size_t count, unsigned flags) {
  if (!(destination && source && palette)) return;
  if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_16) {
    uint16_t * dp = destination;
    const uint16_t * pal = palette;
    while (count --) *(dp ++) = pal[*(source ++)];
  } else if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_64) {
    uint64_t * dp = destination;
    const uint64_t * pal = palette;
    while (count --) *(dp ++) = pal[*(source ++)];
  } else {
    uint32_t * dp = destination;
    const uint32_t * pal = palette;
    while (count --) *(dp ++) = pal[*(source ++)];
  }
}

void plum_sort_colors (const void * restrict colors, uint8_t max_index, unsigned flags, uint8_t * restrict result) {
  // returns the ordered color indexes
  if (!(colors && result)) return;
  uint64_t keys[0x100]; // allocate on stack to avoid dealing with malloc() failure
  if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_64)
    for (uint_fast16_t p = 0; p <= max_index; p ++) keys[p] = p | (get_color_sorting_score(p[(const uint64_t *) colors], flags) << 8);
  else if ((flags & PLUM_COLOR_MASK) == PLUM_COLOR_16)
    for (uint_fast16_t p = 0; p <= max_index; p ++) keys[p] = p | (get_color_sorting_score(p[(const uint16_t *) colors], flags) << 8);
  else
    for (uint_fast16_t p = 0; p <= max_index; p ++) keys[p] = p | (get_color_sorting_score(p[(const uint32_t *) colors], flags) << 8);
  qsort(keys, max_index + 1, sizeof *keys, &compare64);
  for (uint_fast16_t p = 0; p <= max_index; p ++) result[p] = keys[p];
}

#define PNG_MAX_LOOKBACK_COUNT 64

unsigned char * compress_PNG_data (struct context * context, const unsigned char * restrict data, size_t size, size_t extra, size_t * restrict output_size) {
  // extra is the number of zero bytes inserted before the compressed data; they are not included in the size
  unsigned char * output = ctxmalloc(context, extra + 8); // two bytes extra to handle leftover bits in dataword
  memset(output, 0, extra);
  size_t inoffset = 0, outoffset = extra + byteappend(output + extra, 0x78, 0x5e);
  uint16_t * references = ctxmalloc(context, sizeof *references * 0x8000u * PNG_MAX_LOOKBACK_COUNT);
  for (size_t p = 0; p < (size_t) 0x8000u * PNG_MAX_LOOKBACK_COUNT; p ++) references[p] = 0xffffu;
  uint32_t dataword = 0;
  uint8_t bits = 0;
  bool force = false;
  while (inoffset < size) {
    size_t blocksize, count;
    struct compressed_PNG_code * compressed = generate_compressed_PNG_block(context, data, inoffset, size, references, &blocksize, &count, force);
    force = false;
    if (compressed) {
      inoffset += blocksize;
      if (inoffset == size) dataword |= 1u << bits;
      bits ++;
      unsigned char * compressed_data = emit_PNG_compressed_block(context, compressed, count, count >= 16, &blocksize, &dataword, &bits);
      if (SIZE_MAX - outoffset < blocksize + 6) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
      output = ctxrealloc(context, output, outoffset + blocksize + 6);
      memcpy(output + outoffset, compressed_data, blocksize);
      ctxfree(context, compressed_data);
      outoffset += blocksize;
    }
    if (inoffset >= size) break;
    blocksize = compute_uncompressed_PNG_block_size(data, inoffset, size, references);
    if (blocksize >= 32) {
      if (blocksize > 0xffffu) blocksize = 0xffffu;
      if (inoffset + blocksize == size) dataword |= 1u << bits;
      bits += 3;
      while (bits) {
        output[outoffset ++] = dataword;
        dataword >>= 8;
        bits = (bits >= 8) ? bits - 8 : 0;
      }
      if (SIZE_MAX - outoffset < blocksize + 10) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
      output = ctxrealloc(context, output, outoffset + blocksize + 10);
      write_le16_unaligned(output + outoffset, blocksize);
      write_le16_unaligned(output + outoffset + 2, 0xffffu - blocksize);
      memcpy(output + outoffset + 4, data + inoffset, blocksize);
      outoffset += blocksize + 4;
      inoffset += blocksize;
    } else
      force = true;
  }
  ctxfree(context, references);
  while (bits) {
    output[outoffset ++] = dataword;
    dataword >>= 8;
    bits = (bits >= 8) ? bits - 8 : 0;
  }
  write_be32_unaligned(output + outoffset, compute_Adler32_checksum(data, size));
  *output_size = outoffset + 4 - extra;
  return output;
}

struct compressed_PNG_code * generate_compressed_PNG_block (struct context * context, const unsigned char * restrict data, size_t offset, size_t size,
                                                            uint16_t * restrict references, size_t * restrict blocksize, size_t * restrict count, bool force) {
  size_t backref, current_offset = offset, allocated = 256;
  struct compressed_PNG_code * codes = ctxmalloc(context, allocated * sizeof *codes);
  *count = 0;
  int literals = 0, score = 0;
  unsigned length;
  while (size - current_offset >= 3 && size - current_offset < (SIZE_MAX >> 4))
    if (length = find_PNG_reference(data, references, current_offset, size, &backref)) {
      // we found a matching back reference, so emit any pending literals and the reference
      for (; literals; literals --) emit_PNG_code(context, &codes, &allocated, count, data[current_offset - literals], 0);
      emit_PNG_code(context, &codes, &allocated, count, -(int) length, current_offset - backref);
      score -= length - 1;
      if (score < 0) score = 0;
      for (; length; length --) append_PNG_reference(data, current_offset ++, references);
    } else {
      // no back reference: increase the pending literal count, and stop compressing data if a threshold is exceeded
      literals ++;
      score ++;
      append_PNG_reference(data, current_offset ++, references);
      if (score >= 64)
        if (force && *count < 16)
          score = 0;
        else
          break;
    }
  if (size - current_offset < 3) {
    literals += size - current_offset;
    current_offset = size;
  }
  *blocksize = current_offset - offset;
  if ((force && *blocksize < 32) || (*blocksize >= 32 && score < 64))
    for (; literals; literals --) emit_PNG_code(context, &codes, &allocated, count, data[current_offset - literals], 0);
  else
    *blocksize -= literals;
  if (*blocksize < 32 && !force) {
    ctxfree(context, codes);
    return NULL;
  }
  return codes;
}

size_t compute_uncompressed_PNG_block_size (const unsigned char * restrict data, size_t offset, size_t size, uint16_t * restrict references) {
  size_t current_offset = offset;
  for (unsigned score = 0; size - current_offset >= 3 && size - current_offset < 0xffffu; current_offset ++) {
    unsigned length = find_PNG_reference(data, references, current_offset, size, NULL);
    if (length) {
      score += length - 1;
      if (score >= 16) break;
    } else if (score > 0)
      score --;
    append_PNG_reference(data, current_offset, references);
  }
  if (size - current_offset < 3) current_offset = size;
  return current_offset - offset;
}

unsigned find_PNG_reference (const unsigned char * restrict data, const uint16_t * restrict references, size_t current_offset, size_t size,
                             size_t * restrict reference_offset) {
  uint_fast32_t search = compute_PNG_reference_key(data + current_offset) * (uint_fast32_t) PNG_MAX_LOOKBACK_COUNT;
  unsigned best = 0;
  for (uint_fast8_t p = 0; p < PNG_MAX_LOOKBACK_COUNT && references[search + p] != 0xffffu; p ++) {
    size_t backref = (current_offset & bitnegate(0x7fff)) | references[search + p];
    if (backref >= current_offset)
      if (current_offset < 0x8000u)
        continue;
      else
        backref -= 0x8000u;
    if (!memcmp(data + current_offset, data + backref, 3)) {
      uint_fast16_t length;
      for (length = 3; length < 258 && current_offset + length < size; length ++) if (data[current_offset + length] != data[backref + length]) break;
      if (length > best) {
        if (reference_offset) *reference_offset = backref;
        best = length;
        if (best == 258) break;
      }
    }
  }
  return best;
}

void append_PNG_reference (const unsigned char * restrict data, size_t offset, uint16_t * restrict references) {
  uint_fast32_t key = compute_PNG_reference_key(data + offset) * (uint_fast32_t) PNG_MAX_LOOKBACK_COUNT;
  memmove(references + key + 1, references + key, (PNG_MAX_LOOKBACK_COUNT - 1) * sizeof *references);
  references[key] = offset & 0x7fff;
}

uint16_t compute_PNG_reference_key (const unsigned char * data) {
  // should return a value between 0 and 0x7fff computed from the first three bytes of data
  uint_fast32_t key = (uint_fast32_t) *data | ((uint_fast32_t) data[1] << 8) | ((uint_fast32_t) data[2] << 16);
  // easy way out of a hash code: do a few iterations of a simple linear congruential RNG and return the upper bits of the final state
  for (uint_fast8_t p = 0; p < 3; p ++) key = 0x41c64e6du * key + 12345;
  return (key >> 17) & 0x7fff;
}

#undef PNG_MAX_LOOKBACK_COUNT

void emit_PNG_code (struct context * context, struct compressed_PNG_code ** codes, size_t * restrict allocated, size_t * restrict count, int code, unsigned ref) {
  // code >= 0 = literal; code < 0 = -length
  if (*count >= *allocated) {
    *allocated <<= 1;
    *codes = ctxrealloc(context, *codes, *allocated * sizeof **codes);
  }
  struct compressed_PNG_code result;
  if (code >= 0)
    result = (struct compressed_PNG_code) {.datacode = code};
  else {
    code = -code;
    // one extra entry to make looking codes up easier
    for (result.datacode = 0; compressed_PNG_base_lengths[result.datacode + 1] <= code; result.datacode ++);
    result.dataextra = code - compressed_PNG_base_lengths[result.datacode];
    result.datacode += 0x101;
    for (result.distcode = 0; compressed_PNG_base_distances[result.distcode + 1] <= ref; result.distcode ++);
    result.distextra = ref - compressed_PNG_base_distances[result.distcode];
  }
  (*codes)[(*count) ++] = result;
}

unsigned char * emit_PNG_compressed_block (struct context * context, const struct compressed_PNG_code * restrict codes, size_t count, bool custom_tree,
                                           size_t * restrict blocksize, uint32_t * restrict dataword, uint8_t * restrict bits) {
  // emit the code identifying whether the block is compressed with a fixed or custom tree
  *dataword |= (custom_tree + 1) << *bits;
  *bits += 2;
  // count up the frequency of each code; this will be used to generate a custom tree (if needed) and to precalculate the output size
  size_t codecounts[0x120] = {[0x100] = 1}; // other entries will be zero-initialized
  size_t distcounts[0x20] = {0};
  for (size_t p = 0; p < count; p ++) {
    codecounts[codes[p].datacode] ++;
    if (codes[p].datacode > 0x100) distcounts[codes[p].distcode] ++;
  }
  unsigned char * output = NULL;
  *blocksize = 0;
  // ensure that we have the proper tree: use the documented tree if fixed, or generate (and output) a custom tree if custom
  unsigned char lengthbuffer[0x140];
  const unsigned char * codelengths;
  if (custom_tree) {
    output = generate_PNG_Huffman_trees(context, dataword, bits, blocksize, codecounts, distcounts, lengthbuffer, lengthbuffer + 0x120);
    codelengths = lengthbuffer;
  } else
    codelengths = default_PNG_Huffman_table_lengths;
  const unsigned char * distlengths = codelengths + 0x120;
  // precalculate the output size and allocate enough space for the output (and a little extra); this must account for parameter size too
  size_t outsize = 7; // for rounding up
  for (uint_fast16_t p = 0; p < 0x11e; p ++) {
    uint_fast8_t valuesize = codelengths[p];
    if (p >= 0x109 && p < 0x11d) valuesize += (p - 0x105) >> 2;
    if (!valuesize) continue;
    if (codecounts[p] * valuesize / valuesize != codecounts[p] || SIZE_MAX - outsize < codecounts[p] * valuesize) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
    outsize += codecounts[p] * valuesize;
  }
  for (uint_fast8_t p = 0; p < 30; p ++) {
    uint_fast8_t valuesize = distlengths[p];
    if (p >= 4) valuesize += (p - 2) >> 1;
    if (!valuesize) continue;
    if (distcounts[p] * valuesize / valuesize != distcounts[p] || SIZE_MAX - outsize < distcounts[p] * valuesize) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
    outsize += distcounts[p] * valuesize;
  }
  outsize >>= 3;
  output = ctxrealloc(context, output, *blocksize + outsize + 4);
  // build the actual encoded values from the tree lengths, properly sorted
  unsigned short outcodes[0x120];
  unsigned short outdists[0x20];
  generate_Huffman_codes(outcodes, sizeof outcodes / sizeof *outcodes, codelengths, true);
  generate_Huffman_codes(outdists, sizeof outdists / sizeof *outdists, distlengths, true);
  // and output all of the codes in order, ending with a 0x100 code
  #define flush while (*bits >= 8) output[(*blocksize) ++] = *dataword, *dataword >>= 8, *bits -= 8
  while (count --) {
    *dataword |= (size_t) outcodes[codes -> datacode] << *bits;
    *bits += codelengths[codes -> datacode];
    flush;
    if (codes -> datacode > 0x100) {
      if (codes -> datacode >= 0x109 && codes -> datacode < 0x11d) {
        *dataword |= (size_t) codes -> dataextra << *bits;
        *bits += (codes -> datacode - 0x105) >> 2;
        // defer the flush because it can't overflow yet
      }
      *dataword |= (size_t) outdists[codes -> distcode] << *bits;
      *bits += distlengths[codes -> distcode];
      flush;
      if (codes -> distcode >= 4) {
        *dataword |= (size_t) codes -> distextra << *bits;
        *bits += (codes -> distcode - 2) >> 1;
        flush;
      }
    }
    codes ++;
  }
  *dataword |= (size_t) outcodes[0x100] << *bits;
  *bits += codelengths[0x100];
  flush;
  #undef flush
  return output;
}

unsigned char * generate_PNG_Huffman_trees (struct context * context, uint32_t * restrict dataword, uint8_t * restrict bits, size_t * restrict size,
                                            const size_t codecounts[restrict static 0x120], const size_t distcounts[restrict static 0x20],
                                            unsigned char codelengths[restrict static 0x120], unsigned char distlengths[restrict static 0x20]) {
  // this function will generate trees, discard them and only preserve the lengths; that way, the real (properly ordered) trees can be rebuilt later
  // also outputs the tree length data to the output stream and returns it
  generate_Huffman_tree(context, codecounts, codelengths, 0x120, 15);
  generate_Huffman_tree(context, distcounts, distlengths, 0x20, 15);
  unsigned char lengths[0x140];
  unsigned char encoded[0x140];
  unsigned repcount, maxcode, maxdist, encodedlength = 0, code = 0;
  for (maxcode = 0x11f; !codelengths[maxcode]; maxcode --);
  for (maxdist = 0x1f; maxdist && !distlengths[maxdist]; maxdist --);
  memcpy(lengths, codelengths, maxcode + 1);
  memcpy(lengths + maxcode + 1, distlengths, maxdist + 1);
  while (code < maxcode + maxdist + 2)
    if (!lengths[code]) {
      for (repcount = 1; repcount < 0x8a && code + repcount < maxcode + maxdist + 2 && !lengths[code + repcount]; repcount ++);
      if (repcount < 3) {
        encoded[encodedlength ++] = 0;
        code ++;
      } else {
        code += repcount;
        encoded[encodedlength ++] = 17 + (repcount > 10);
        encoded[encodedlength ++] = repcount - ((repcount >= 11) ? 11 : 3);
      }
    } else if (code && lengths[code] == lengths[code - 1]) {
      for (repcount = 1; repcount < 6 && code + repcount < maxcode + maxdist + 2 && lengths[code + repcount] == lengths[code - 1]; repcount ++);
      if (repcount < 3)
        encoded[encodedlength ++] = lengths[code ++];
      else {
        encoded[encodedlength ++] = 16;
        encoded[encodedlength ++] = repcount - 3;
        code += repcount;
      }
    } else
      encoded[encodedlength ++] = lengths[code ++];
  size_t encodedcounts[19] = {0};
  for (uint_fast16_t p = 0; p < encodedlength; p ++) {
    encodedcounts[encoded[p]] ++;
    if (encoded[p] >= 16) p ++;
  }
  generate_Huffman_tree(context, encodedcounts, lengths, 19, 7);
  unsigned short codes[19];
  for (repcount = 18; repcount > 3 && !lengths[compressed_PNG_code_table_order[repcount]]; repcount --);
  generate_Huffman_codes(codes, 19, lengths, true);
  *dataword |= (maxcode & 0x1f) << *bits;
  *bits += 5;
  *dataword |= maxdist << *bits;
  *bits += 5;
  *dataword |= (repcount - 3) << *bits;
  *bits += 4;
  unsigned char * result = ctxmalloc(context, 0x100);
  unsigned char * current = result;
  #define flush while (*bits >= 8) *(current ++) = *dataword, *dataword >>= 8, *bits -= 8
  flush;
  for (uint_fast8_t p = 0; p <= repcount; p ++) {
    *dataword |= lengths[compressed_PNG_code_table_order[p]] << *bits;
    *bits += 3;
    flush;
  }
  for (uint_fast16_t p = 0; p < encodedlength; p ++) {
    *dataword |= codes[encoded[p]] << *bits;
    *bits += lengths[encoded[p]];
    if (encoded[p] >= 16) {
      uint_fast8_t repeattype = encoded[p] - 16;
      *dataword |= encoded[++ p] << *bits;
      *bits += (2 << repeattype) - !!repeattype; // 0, 1, 2 maps to 2, 3, 7
    }
    flush;
  }
  #undef flush
  *size = current - result;
  return result;
}

void * decompress_PNG_data (struct context * context, const unsigned char * compressed, size_t size, size_t expected) {
  if (size <= 6) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if ((*compressed & 0x8f) != 8 || (compressed[1] & 0x20) || read_be16_unaligned(compressed) % 31) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  // ignore the window size - treat it as 0x8000 for simpler code (everything will be in memory anyway)
  compressed += 2;
  size -= 6; // pretend the checksum is not part of the data
  unsigned char * decompressed = ctxmalloc(context, expected);
  size_t current = 0;
  bool last_block;
  uint32_t dataword = 0;
  uint8_t bits = 0;
  do {
    last_block = shift_in_left(context, 1, &dataword, &bits, &compressed, &size);
    switch (shift_in_left(context, 2, &dataword, &bits, &compressed, &size)) {
      case 0: {
        dataword >>= bits & 7;
        bits &= ~7;
        uint32_t literalcount = shift_in_left(context, 32, &dataword, &bits, &compressed, &size);
        if (((literalcount >> 16) ^ (literalcount & 0xffffu)) != 0xffffu) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        literalcount &= 0xffffu;
        if (literalcount > expected - current) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        if (literalcount > size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        memcpy(decompressed + current, compressed, literalcount);
        current += literalcount;
        compressed += literalcount;
        size -= literalcount;
      } break;
      case 1:
        decompress_PNG_block(context, &compressed, decompressed, &size, &current, expected, &dataword, &bits, default_PNG_Huffman_table_lengths);
        break;
      case 2: {
        unsigned char codesizes[0x140];
        extract_PNG_code_table(context, &compressed, &size, codesizes, &dataword, &bits);
        decompress_PNG_block(context, &compressed, decompressed, &size, &current, expected, &dataword, &bits, codesizes);
      } break;
      default:
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
  } while (!last_block);
  if (size || current != expected) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (compute_Adler32_checksum(decompressed, expected) != read_be32_unaligned(compressed)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  return decompressed;
}

void extract_PNG_code_table (struct context * context, const unsigned char ** compressed, size_t * restrict size, unsigned char codesizes[restrict static 0x140],
                             uint32_t * restrict dataword, uint8_t * restrict bits) {
  uint_fast16_t header = shift_in_left(context, 14, dataword, bits, compressed, size);
  unsigned literals = 0x101 + (header & 0x1f);
  unsigned distances = 1 + ((header >> 5) & 0x1f);
  unsigned lengths = 4 + (header >> 10);
  unsigned char internal_sizes[19] = {0};
  for (uint_fast8_t p = 0; p < lengths; p ++) internal_sizes[compressed_PNG_code_table_order[p]] = shift_in_left(context, 3, dataword, bits, compressed, size);
  short * tree = decode_PNG_Huffman_tree(context, internal_sizes, sizeof internal_sizes);
  if (!tree) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint_fast16_t index = 0;
  while (index < literals + distances) {
    uint_fast8_t code = next_PNG_Huffman_code(context, tree, compressed, size, dataword, bits);
    switch (code) {
      case 16: {
        if (!index) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        uint_fast8_t codesize = codesizes[index - 1], count = 3 + shift_in_left(context, 2, dataword, bits, compressed, size);
        if (index + count > literals + distances) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        while (count --) codesizes[index ++] = codesize;
      } break;
      case 17: case 18: {
        uint_fast8_t count = ((code == 18) ? 11 : 3) + shift_in_left(context, (code == 18) ? 7 : 3, dataword, bits, compressed, size);
        if (index + count > literals + distances) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        while (count --) codesizes[index ++] = 0;
      } break;
      default:
        codesizes[index ++] = code;
    }
  }
  ctxfree(context, tree);
  if (literals < 0x120) memmove(codesizes + 0x120, codesizes + literals, distances);
  memset(codesizes + literals, 0, 0x120 - literals);
  memset(codesizes + 0x120 + distances, 0, 0x20 - distances);
}

void decompress_PNG_block (struct context * context, const unsigned char ** compressed, unsigned char * restrict decompressed, size_t * restrict size,
                           size_t * restrict current, size_t expected, uint32_t * restrict dataword, uint8_t * restrict bits,
                           const unsigned char codesizes[restrict static 0x140]) {
  // a single list of codesizes for all codes: 0x00-0xff for literals, 0x100 for end of codes, 0x101-0x11d for lengths, 0x120-0x13d for distances
  short * codetree = decode_PNG_Huffman_tree(context, codesizes, 0x120);
  if (!codetree) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  short * disttree = decode_PNG_Huffman_tree(context, codesizes + 0x120, 0x20);
  while (true) {
    uint_fast16_t code = next_PNG_Huffman_code(context, codetree, compressed, size, dataword, bits);
    if (code >= 0x11e) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (code == 0x100) break;
    if (code < 0x100) {
      if (*current >= expected) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      decompressed[(*current) ++] = code;
      continue;
    }
    if (!disttree) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    code -= 0x101;
    uint_fast16_t length = compressed_PNG_base_lengths[code];
    uint_fast8_t lengthbits = compressed_PNG_length_bits[code];
    if (lengthbits) length += shift_in_left(context, lengthbits, dataword, bits, compressed, size);
    uint_fast8_t distcode = next_PNG_Huffman_code(context, disttree, compressed, size, dataword, bits);
    if (distcode > 29) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    uint_fast16_t distance = compressed_PNG_base_distances[distcode];
    uint_fast8_t distbits = compressed_PNG_distance_bits[distcode];
    if (distbits) distance += shift_in_left(context, distbits, dataword, bits, compressed, size);
    if (distance > *current) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (*current + length > expected || *current + length < *current) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    for (; length; -- length, ++ *current) decompressed[*current] = decompressed[*current - distance];
  }
  ctxfree(context, disttree);
  ctxfree(context, codetree);
}

short * decode_PNG_Huffman_tree (struct context * context, const unsigned char * codesizes, unsigned count) {
  // root at index 0; each non-leaf node takes two entries (index for the 0 branch, index+1 for the 1 branch)
  // non-negative value: branch points to a leaf node; negative value: branch points to another non-leaf at -index
  // -1 is used as an invalid value, since -1 cannot ever occur (as index 1 would overlap with the root)
  uint_fast16_t total = 0;
  uint_fast8_t codelength = 0;
  for (uint_fast16_t p = 0; p < count; p ++) if (codesizes[p]) {
    total ++;
    if (codesizes[p] > codelength) codelength = codesizes[p];
  }
  if (!total) return NULL;
  uint_fast16_t maxlength = count * 2 * codelength;
  short * result = ctxmalloc(context, maxlength * sizeof *result);
  for (uint_fast16_t p = 0; p < maxlength; p ++) result[p] = -1;
  uint_fast16_t code = 0;
  short last = 2;
  for (uint_fast8_t curlength = 1; curlength <= codelength; curlength ++) {
    code <<= 1;
    for (uint_fast16_t p = 0; p < count; p ++) if (codesizes[p] == curlength) {
      if (code >= (1u << curlength)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      uint_fast16_t index = 0;
      for (uint_fast8_t bit = curlength - 1; bit; bit --) {
        if (code & (1u << bit)) index ++;
        if (result[index] == -1) {
          result[index] = -last;
          last += 2;
        }
        index = -result[index];
      }
      if (code & 1) index ++;
      result[index] = p;
      code ++;
    }
  }
  if (code > (1u << codelength)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  return ctxrealloc(context, result, last * sizeof *result);
}

uint16_t next_PNG_Huffman_code (struct context * context, const short * restrict tree, const unsigned char ** compressed, size_t * restrict size,
                                uint32_t * restrict dataword, uint8_t * restrict bits) {
  short index = 0;
  while (true) {
    index += shift_in_left(context, 1, dataword, bits, compressed, size);
    if (tree[index] >= 0) return tree[index];
    index = -tree[index];
    if (index == 1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
}

void load_PNG_data (struct context * context, unsigned flags, size_t limit) {
  struct PNG_chunk_locations * chunks = load_PNG_chunk_locations(context); // also sets context -> image -> frames for APNGs
  // load basic header data
  if (chunks -> animation) {
    context -> image -> type = PLUM_IMAGE_APNG;
    if (*chunks -> data < *chunks -> frameinfo) context -> image -> frames ++; // first frame is not part of the animation
  } else {
    context -> image -> type = PLUM_IMAGE_PNG;
    context -> image -> frames = 1;
  }
  context -> image -> width = read_be32_unaligned(context -> data + 16);
  context -> image -> height = read_be32_unaligned(context -> data + 20);
  if (context -> image -> width > 0x7fffffffu || context -> image -> height > 0x7fffffffu) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  validate_image_size(context, limit);
  int interlaced = context -> data[28];
  unsigned char bitdepth = context -> data[24], imagetype = context -> data[25];
  if (context -> data[26] || context -> data[27] || interlaced > 1 || imagetype > 6 || imagetype == 1 || imagetype == 5 || !bitdepth ||
      (bitdepth & (bitdepth - 1)) || bitdepth > 16 || (imagetype == 3 && bitdepth == 16) || (imagetype && imagetype != 3 && bitdepth < 8))
    throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  // load palette and color-related metadata
  uint64_t * palette = NULL;
  uint8_t max_palette_index = 0;
  if (chunks -> palette && (!imagetype || imagetype == 4)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (imagetype == 3) {
    palette = ctxcalloc(context, 256 * sizeof *palette);
    max_palette_index = load_PNG_palette(context, chunks, bitdepth, palette);
  }
  add_PNG_bit_depth_metadata(context, chunks, imagetype, bitdepth);
  uint64_t background = add_PNG_background_metadata(context, chunks, palette, imagetype, bitdepth, max_palette_index, flags);
  uint64_t transparent = 0xffffffffffffffffu;
  if (chunks -> transparency)
    if (imagetype <= 2)
      transparent = load_PNG_transparent_color(context, chunks -> transparency, imagetype, bitdepth);
    else if (imagetype >= 4)
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  // if there are no reduced APNG frames (i.e., frames that are smaller than the image), and we have a palette, load it into the struct
  if (palette && !(chunks -> animation && check_PNG_reduced_frames(context, chunks))) {
    context -> image -> max_palette_index = max_palette_index;
    context -> image -> palette = plum_malloc(context -> image, plum_color_buffer_size(max_palette_index + 1, flags));
    if (!context -> image -> palette) throw(context, PLUM_ERR_OUT_OF_MEMORY);
    plum_convert_colors(context -> image -> palette, palette, max_palette_index + 1, flags, PLUM_COLOR_64);
  }
  // allocate space for the image data and load the main image; for a PNG file, we're done here
  allocate_framebuffers(context, flags, context -> image -> palette);
  load_PNG_frame(context, chunks -> data, 0, palette, max_palette_index, imagetype, bitdepth, interlaced, background, transparent);
  if (!chunks -> animation) return;
  // load the animation control chunk and duration and disposal metadata
  uint32_t loops = read_be32_unaligned(context -> data + chunks -> animation + 4);
  if (loops > 0x7fffffffu) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  add_loop_count_metadata(context, loops);
  uint64_t * durations;
  uint8_t * disposals;
  add_animation_metadata(context, &durations, &disposals);
  const size_t * frameinfo = chunks -> frameinfo;
  const size_t * const * framedata = (const size_t * const *) chunks -> framedata;
  // handle the first frame's metadata, which is special and may or may not be part of the animation (the frame data will have already been loaded)
  bool replace_last = false;
  if (!*frameinfo) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (*frameinfo < *chunks -> data) {
    if (
      read_be32_unaligned(context -> data + *frameinfo + 4) != context -> image -> width ||
      read_be32_unaligned(context -> data + *frameinfo + 8) != context -> image -> height ||
      !bytematch(context -> data + *frameinfo + 12, 0, 0, 0, 0, 0, 0, 0, 0)
    ) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (**framedata) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    replace_last = load_PNG_animation_frame_metadata(context, *frameinfo, durations, disposals);
    frameinfo ++;
    framedata ++;
  } else {
    *disposals = PLUM_DISPOSAL_PREVIOUS;
    *durations = 0;
  }
  // actually load animation frames
  if (*frameinfo && *frameinfo < *chunks -> data) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  for (uint_fast32_t frame = 1; frame < context -> image -> frames; frame ++) {
    bool replace = load_PNG_animation_frame_metadata(context, *frameinfo, durations + frame, disposals + frame);
    if (replace) disposals[frame - 1] += PLUM_DISPOSAL_REPLACE;
    uint_fast32_t width = read_be32_unaligned(context -> data + *frameinfo + 4);
    uint_fast32_t height = read_be32_unaligned(context -> data + *frameinfo + 8);
    uint_fast32_t left = read_be32_unaligned(context -> data + *frameinfo + 12);
    uint_fast32_t top = read_be32_unaligned(context -> data + *frameinfo + 16);
    if ((width | height | left | top) & 0x80000000u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (width + left > context -> image -> width || height + top > context -> image -> height) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (width == context -> image -> width && height == context -> image -> height)
      load_PNG_frame(context, *framedata, frame, palette, max_palette_index, imagetype, bitdepth, interlaced, background, transparent);
    else {
      uint64_t * output = ctxmalloc(context, sizeof *output * context -> image -> width * context -> image -> height);
      uint64_t * current = output;
      size_t index = 0;
      if (palette) {
        uint8_t * pixels = load_PNG_frame_part(context, *framedata, max_palette_index, imagetype, bitdepth, interlaced, width, height, 4);
        for (size_t row = 0; row < context -> image -> height; row ++) for (size_t col = 0; col < context -> image -> width; col ++)
          if (row < top || col < left || row >= top + height || col >= left + width)
            *(current ++) = background | 0xffff000000000000u;
          else
            *(current ++) = palette[pixels[index ++]];
        ctxfree(context, pixels);
      } else {
        uint64_t * pixels = load_PNG_frame_part(context, *framedata, -1, imagetype, bitdepth, interlaced, width, height, 4);
        for (size_t row = 0; row < context -> image -> height; row ++) for (size_t col = 0; col < context -> image -> width; col ++)
          if (row < top || col < left || row >= top + height || col >= left + width)
            *(current ++) = background | 0xffff000000000000u;
          else {
            *current = pixels[index ++];
            if (transparent != 0xffffffffffffffffu && *current == transparent) *current = background | 0xffff000000000000u;
            current ++;
          }
        ctxfree(context, pixels);
      }
      write_framebuffer_to_image(context -> image, output, frame, flags);
      ctxfree(context, output);
    }
    frameinfo ++;
    framedata ++;
  }
  if (replace_last || (*chunks -> frameinfo >= *chunks -> data && *disposals >= PLUM_DISPOSAL_REPLACE))
    disposals[context -> image -> frames - 1] += PLUM_DISPOSAL_REPLACE;
  // we're done; a few things will be leaked here (chunk data, palette data...), but they are small and will be collected later
}

struct PNG_chunk_locations * load_PNG_chunk_locations (struct context * context) {
  if (context -> size < 45) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (!bytematch(context -> data + 12, 0x49, 0x48, 0x44, 0x52)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  size_t offset = 8;
  uint32_t chunk_type = 0;
  struct PNG_chunk_locations * result = ctxmalloc(context, sizeof *result);
  *result = (struct PNG_chunk_locations) {0}; // ensure that integers and pointers are properly zero-initialized
  size_t data_count = 0, frameinfo_count = 0, framedata_count = 0;
  size_t * framedata = NULL;
  bool invalid_animation = false;
  while (offset <= context -> size - 12) {
    uint32_t length = read_be32_unaligned(context -> data + offset);
    chunk_type = read_be32_unaligned(context -> data + offset + 4);
    offset += 8;
    if (length > 0x7fffffffu) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (offset + length + 4 < offset || offset + length + 4 > context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (read_be32_unaligned(context -> data + offset + length) != compute_PNG_CRC(context -> data + offset - 4, length + 4))
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    switch (chunk_type) {
      case 0x49484452u: // IHDR
        if (offset != 16 || length != 13) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        break;
      case 0x49454e44u: // IEND
        if (length) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        offset += 4;
        goto done;
      case 0x504c5445u: // PLTE
        if (result -> palette || length % 3 || length > 0x300 || !length) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        result -> palette = offset;
        break;
      case 0x49444154u: // IDAT
        // we don't really care if they are consecutive or not; this error is easy to tolerate
        append_PNG_chunk_location(context, &result -> data, offset, &data_count);
        break;
      case 0x73424954u: // sBIT
        if (result -> bits || !length || length > 4) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        result -> bits = offset;
        break;
      case 0x624b4744u: // bKGD
        if (result -> background || !length || length > 6) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        result -> background = offset;
        break;
      case 0x74524e53u: // tRNS
        if (result -> transparency || length > 256) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        result -> transparency = offset;
        break;
      case 0x6163544cu: // acTL
        if (!invalid_animation)
          if (result -> data || result -> animation || length != 8)
            invalid_animation = true;
          else
            result -> animation = offset;
        break;
      case 0x6663544cu: // fcTL
        if (!invalid_animation)
          if (length == 26)
            append_PNG_chunk_location(context, &result -> frameinfo, offset, &frameinfo_count);
          else
            invalid_animation = true;
        break;
      case 0x66644154u: // fdAT
        if (!invalid_animation)
          if (length >= 4)
            append_PNG_chunk_location(context, &framedata, offset, &framedata_count);
          else
            invalid_animation = true;
        break;
      default:
        if ((chunk_type & 0xe0c0c0c0u) != 0x60404040u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT); // invalid or critical
        while (chunk_type) {
          if (!(chunk_type & 0x1f) || (chunk_type & 0x1f) > 26) throw(context, PLUM_ERR_INVALID_FILE_FORMAT); // invalid
          chunk_type >>= 8;
        }
    }
    offset += length + 4;
  }
  done:
  if (offset != context -> size || chunk_type != 0x49454e44u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (!result -> data) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  append_PNG_chunk_location(context, &result -> data, 0, &data_count);
  append_PNG_chunk_location(context, &result -> frameinfo, 0, &frameinfo_count);
  frameinfo_count --;
  if (invalid_animation) {
    ctxfree(context, result -> frameinfo);
    result -> animation = 0;
    result -> frameinfo = NULL;
  } else if (result -> animation) {
    // validate and initialize frame counts here to avoid having to count them up later
    if (frameinfo_count != read_be32_unaligned(context -> data + result -> animation)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    sort_PNG_animation_chunks(context, result, framedata, frameinfo_count, framedata_count);
    context -> image -> frames = frameinfo_count;
  }
  ctxfree(context, framedata);
  return result;
}

void append_PNG_chunk_location (struct context * context, size_t ** locations, size_t location, size_t * restrict count) {
  *locations = ctxrealloc(context, *locations, sizeof **locations * (*count + 1));
  (*locations)[(*count) ++] = location;
}

void sort_PNG_animation_chunks (struct context * context, struct PNG_chunk_locations * restrict locations, const size_t * restrict framedata,
                                size_t frameinfo_count, size_t framedata_count) {
  if ((frameinfo_count + framedata_count) > 0x80000000u) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (!frameinfo_count || (frameinfo_count > 1 && !framedata_count)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint64_t * indexes = ctxmalloc(context, sizeof *indexes * (frameinfo_count + framedata_count));
  for (uint_fast32_t p = 0; p < frameinfo_count; p ++)
    indexes[p] = ((uint64_t) read_be32_unaligned(context -> data + locations -> frameinfo[p]) << 32) | 0x80000000u | p;
  for (uint_fast32_t p = 0; p < framedata_count; p ++)
    indexes[p + frameinfo_count] = ((uint64_t) read_be32_unaligned(context -> data + framedata[p]) << 32) | p;
  qsort(indexes, frameinfo_count + framedata_count, sizeof *indexes, &compare64);
  if (!(*indexes & 0x80000000u)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT); // fdAT before fcTL
  size_t * frames = ctxmalloc(context, sizeof *frames * frameinfo_count);
  locations -> framedata = ctxmalloc(context, sizeof *locations -> framedata * frameinfo_count);
  uint_fast32_t infoindex = 0, datacount = 0;
  // special handling for the first entry
  if (*indexes >> 32) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  *locations -> framedata = NULL;
  *frames = locations -> frameinfo[*indexes & 0x7fffffffu];
  for (uint_fast32_t p = 1; p < frameinfo_count + framedata_count; p ++) {
    if ((indexes[p] >> 32) != p) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    locations -> framedata[infoindex] = ctxrealloc(context, locations -> framedata[infoindex], sizeof **locations -> framedata * (datacount + 1));
    if (indexes[p] & 0x80000000u) {
      locations -> framedata[infoindex ++][datacount] = 0;
      locations -> framedata[infoindex] = NULL;
      frames[infoindex] = locations -> frameinfo[indexes[p] & 0x7fffffffu];
      datacount = 0;
    } else
      locations -> framedata[infoindex][datacount ++] = framedata[indexes[p] & 0x7fffffffu];
  }
  locations -> framedata[infoindex] = ctxrealloc(context, locations -> framedata[infoindex], sizeof **locations -> framedata * (datacount + 1));
  locations -> framedata[infoindex][datacount] = 0;
  memcpy(locations -> frameinfo, frames, sizeof *frames * frameinfo_count);
  ctxfree(context, frames);
  ctxfree(context, indexes);
}

uint8_t load_PNG_palette (struct context * context, const struct PNG_chunk_locations * restrict chunks, uint8_t bitdepth, uint64_t * restrict palette) {
  if (!chunks -> palette) throw(context, PLUM_ERR_UNDEFINED_PALETTE);
  uint_fast32_t count = read_be32_unaligned(context -> data + chunks -> palette - 8) / 3;
  if (count > (1 << bitdepth)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  const unsigned char * data = context -> data + chunks -> palette;
  for (uint_fast32_t p = 0; p < count; p ++) palette[p] = (data[p * 3] | ((uint64_t) data[p * 3 + 1] << 16) | ((uint64_t) data[p * 3 + 2] << 32)) * 0x101;
  if (chunks -> transparency) {
    uint_fast32_t transparency_count = read_be32_unaligned(context -> data + chunks -> transparency - 8);
    if (transparency_count > count) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    data = context -> data + chunks -> transparency;
    for (uint_fast32_t p = 0; p < transparency_count; p ++) palette[p] |= 0x101000000000000u * (0xff ^ *(data ++));
  }
  return count - 1;
}

void add_PNG_bit_depth_metadata (struct context * context, const struct PNG_chunk_locations * chunks, uint8_t imagetype, uint8_t bitdepth) {
  uint8_t red, green, blue, alpha, gray;
  switch (imagetype) {
    case 0:
      red = green = blue = 0;
      alpha = !!chunks -> transparency;
      gray = bitdepth;
      if (chunks -> bits) {
        if (read_be32_unaligned(context -> data + chunks -> bits - 8) != 1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        gray = context -> data[chunks -> bits];
        if (gray > bitdepth) gray = bitdepth;
      }
      break;
    case 2:
      red = green = blue = bitdepth;
      alpha = !!chunks -> transparency;
      gray = 0;
      if (chunks -> bits) {
        if (read_be32_unaligned(context -> data + chunks -> bits - 8) != 3) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        red = context -> data[chunks -> bits];
        if (red > bitdepth) red = bitdepth;
        green = context -> data[chunks -> bits + 1];
        if (green > bitdepth) green = bitdepth;
        blue = context -> data[chunks -> bits + 2];
        if (blue > bitdepth) blue = bitdepth;
      }
      break;
    case 3:
      red = green = blue = 8;
      alpha = chunks -> transparency ? 8 : 0;
      gray = 0;
      if (chunks -> bits) {
        if (read_be32_unaligned(context -> data + chunks -> bits - 8) != 3) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        red = context -> data[chunks -> bits];
        if (red > 8) red = 8;
        green = context -> data[chunks -> bits + 1];
        if (green > 8) green = 8;
        blue = context -> data[chunks -> bits + 2];
        if (blue > 8) blue = 8;
      }
      break;
    case 4:
      red = green = blue = 0;
      gray = alpha = bitdepth;
      if (chunks -> bits) {
        if (read_be32_unaligned(context -> data + chunks -> bits - 8) != 2) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        gray = context -> data[chunks -> bits];
        if (gray > bitdepth) gray = bitdepth;
        alpha = context -> data[chunks -> bits + 1];
        if (alpha > bitdepth) alpha = bitdepth;
      }
      break;
    case 6:
      red = green = blue = alpha = bitdepth;
      gray = 0;
      if (chunks -> bits) {
        if (read_be32_unaligned(context -> data + chunks -> bits - 8) != 4) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        red = context -> data[chunks -> bits];
        if (red > bitdepth) red = bitdepth;
        green = context -> data[chunks -> bits + 1];
        if (green > bitdepth) green = bitdepth;
        blue = context -> data[chunks -> bits + 2];
        if (blue > bitdepth) blue = bitdepth;
        alpha = context -> data[chunks -> bits + 3];
        if (alpha > bitdepth) alpha = bitdepth;
      }
  }
  add_color_depth_metadata(context, red, green, blue, alpha, gray);
}

uint64_t add_PNG_background_metadata (struct context * context, const struct PNG_chunk_locations * chunks, const uint64_t * palette, uint8_t imagetype,
                                      uint8_t bitdepth, uint8_t max_palette_index, unsigned flags) {
  if (!chunks -> background) return 0;
  uint64_t color;
  const unsigned char * data = context -> data + chunks -> background;
  switch (imagetype) {
    case 0: case 4:
      if (read_be32_unaligned(data - 8) != 2) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      color = read_le16_unaligned(data);
      if (color >> bitdepth) return 0;
      color = 0x100010001u * (uint64_t) bitextend16(color, bitdepth);
      break;
    case 3:
      if (read_be32_unaligned(data - 8) != 1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      if (*data > max_palette_index) return 0;
      color = palette[*data];
      break;
    default:
      if (read_be32_unaligned(data - 8) != 6) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      if (bitdepth == 8) {
        if (*data || data[2] || data[4]) return 0;
        color = ((uint64_t) data[1] | ((uint64_t) data[3] << 16) | ((uint64_t) data[5] << 32)) * 0x101;
      } else
        color = read_be16_unaligned(data) | ((uint64_t) read_be16_unaligned(data + 2) << 16) | ((uint64_t) read_be16_unaligned(data + 4) << 32);
  }
  add_background_color_metadata(context, color, flags);
  return color;
}

uint64_t load_PNG_transparent_color (struct context * context, size_t offset, uint8_t imagetype, uint8_t bitdepth) {
  // only for image types 0 or 2
  const unsigned char * data = context -> data + offset;
  if (read_be32_unaligned(data - 8) != (imagetype ? 6 : 2)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (!imagetype) {
    uint_fast32_t color = read_be16_unaligned(data); // cannot be 16-bit because of the potential >> 16 in the next line
    if (color >> bitdepth) return 0xffffffffffffffffu;
    return 0x100010001u * (uint64_t) bitextend16(color, bitdepth);
  } else if (bitdepth == 8) {
    if (*data || data[2] || data[4]) return 0xffffffffffffffffu;
    return ((uint64_t) data[1] | ((uint64_t) data[3] << 16) | ((uint64_t) data[5] << 32)) * 0x101;
  } else
    return (uint64_t) read_be16_unaligned(data) | ((uint64_t) read_be16_unaligned(data + 2) << 16) | ((uint64_t) read_be16_unaligned(data + 4) << 32);
}

bool check_PNG_reduced_frames (struct context * context, const struct PNG_chunk_locations * chunks) {
  for (const size_t * frameinfo = chunks -> frameinfo; *frameinfo; frameinfo ++) {
    uint_fast32_t width = read_be32_unaligned(context -> data + *frameinfo + 4);
    uint_fast32_t height = read_be32_unaligned(context -> data + *frameinfo + 8);
    uint_fast32_t left = read_be32_unaligned(context -> data + *frameinfo + 12);
    uint_fast32_t top = read_be32_unaligned(context -> data + *frameinfo + 16);
    if (top || left || width != context -> image -> width || height != context -> image -> height) return true;
  }
  return false;
}

bool load_PNG_animation_frame_metadata (struct context * context, size_t offset, uint64_t * restrict duration, uint8_t * restrict disposal) {
  // returns if the previous frame should be replaced
  uint_fast16_t numerator = read_be16_unaligned(context -> data + offset + 20), denominator = read_be16_unaligned(context -> data + offset + 22);
  if ((*disposal = context -> data[offset + 24]) > 2) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  uint_fast8_t blend = context -> data[offset + 25];
  if (blend > 1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (numerator) {
    if (!denominator) denominator = 100;
    *duration = ((uint64_t) numerator * 1000000000 + denominator / 2) / denominator;
  } else
    *duration = 1;
  return !blend;
}

void load_PNG_frame (struct context * context, const size_t * chunks, uint32_t frame, const uint64_t * palette, uint8_t max_palette_index,
                     uint8_t imagetype, uint8_t bitdepth, bool interlaced, uint64_t background, uint64_t transparent) {
  void * data = load_PNG_frame_part(context, chunks, palette ? max_palette_index : -1, imagetype, bitdepth, interlaced,
                                    context -> image -> width, context -> image -> height, frame ? 4 : 0);
  if (palette)
    write_palette_framebuffer_to_image(context, data, palette, frame, context -> image -> color_format, 0xff); // 0xff to avoid a redundant range check
  else {
    if (transparent != 0xffffffffffffffffu) {
      size_t count = (size_t) context -> image -> width * context -> image -> height;
      for (uint64_t * current = data; count; count --, current ++) if (*current == transparent) *current = background | 0xffff000000000000u;
    }
    write_framebuffer_to_image(context -> image, data, frame, context -> image -> color_format);
  }
  ctxfree(context, data);
}

void * load_PNG_frame_part (struct context * context, const size_t * chunks, int max_palette_index, uint8_t imagetype, uint8_t bitdepth, bool interlaced,
                            uint32_t width, uint32_t height, size_t chunkoffset) {
  // max_palette_index < 0: no palette (return uint64_t *); otherwise, use a palette (return uint8_t *)
  size_t p = 0, total_compressed_size = 0;
  for (const size_t * chunk = chunks; *chunk; chunk ++) total_compressed_size += read_be32_unaligned(context -> data + *chunk - 8) - chunkoffset;
  unsigned char * compressed = ctxmalloc(context, total_compressed_size);
  for (const size_t * chunk = chunks; *chunk; chunk ++) {
    size_t current = read_be32_unaligned(context -> data + *chunk - 8) - chunkoffset;
    memcpy(compressed + p, context -> data + *chunk + chunkoffset, current);
    p += current;
  }
  void * result;
  if (max_palette_index < 0)
    result = load_PNG_raw_frame(context, compressed, total_compressed_size, width, height, imagetype, bitdepth, interlaced);
  else
    result = load_PNG_palette_frame(context, compressed, total_compressed_size, width, height, bitdepth, max_palette_index, interlaced);
  ctxfree(context, compressed);
  return result;
}

uint8_t * load_PNG_palette_frame (struct context * context, const void * compressed, size_t compressed_size, uint32_t width, uint32_t height, uint8_t bitdepth,
                                  uint8_t max_palette_index, bool interlaced) {
  // imagetype must be 3 here
  uint8_t * result = ctxmalloc(context, (size_t) width * height);
  unsigned char * decompressed;
  if (interlaced) {
    size_t widths[] = {(width + 7) / 8, (width + 3) / 8, (width + 3) / 4, (width + 1) / 4, (width + 1) / 2, width / 2, width};
    size_t heights[] = {(height + 7) / 8, (height + 7) / 8, (height + 3) / 8, (height + 3) / 4, (height + 1) / 4, (height + 1) / 2, height / 2};
    size_t rowsizes[7];
    size_t cumulative_size = 0;
    for (uint_fast8_t pass = 0; pass < 7; pass ++) if (widths[pass] && heights[pass]) {
      rowsizes[pass] = ((size_t) widths[pass] * bitdepth + 7) / 8 + 1;
      cumulative_size += heights[pass] * rowsizes[pass];
    }
    decompressed = decompress_PNG_data(context, compressed, compressed_size, cumulative_size);
    unsigned char * current = decompressed;
    unsigned char * rowdata = ctxmalloc(context, width);
    for (uint_fast8_t pass = 0; pass < 7; pass ++) if (widths[pass] && heights[pass]) {
      remove_PNG_filter(context, current, widths[pass], heights[pass], 3, bitdepth);
      for (size_t row = 0; row < heights[pass]; row ++) {
        expand_bitpacked_PNG_data(rowdata, current + 1, widths[pass], bitdepth);
        current += rowsizes[pass];
        for (size_t col = 0; col < widths[pass]; col ++)
          result[(row * interlaced_PNG_pass_step[pass] + interlaced_PNG_pass_start[pass]) * width +
                 col * interlaced_PNG_pass_step[pass + 1] + interlaced_PNG_pass_start[pass + 1]] = rowdata[col];
      }
    }
    ctxfree(context, rowdata);
  } else {
    size_t rowsize = ((size_t) width * bitdepth + 7) / 8 + 1;
    decompressed = decompress_PNG_data(context, compressed, compressed_size, rowsize * height);
    remove_PNG_filter(context, decompressed, width, height, 3, bitdepth);
    for (size_t row = 0; row < height; row ++) expand_bitpacked_PNG_data(result + row * width, decompressed + row * rowsize + 1, width, bitdepth);
  }
  ctxfree(context, decompressed);
  for (size_t p = 0; p < (size_t) width * height; p ++) if (result[p] > max_palette_index) throw(context, PLUM_ERR_INVALID_COLOR_INDEX);
  return result;
}

uint64_t * load_PNG_raw_frame (struct context * context, const void * compressed, size_t compressed_size, uint32_t width, uint32_t height, uint8_t imagetype,
                               uint8_t bitdepth, bool interlaced) {
  // imagetype is not 3 here
  uint64_t * result = ctxmalloc(context, sizeof *result * width * height);
  unsigned char * decompressed;
  size_t pixelsize = bitdepth / 8 * channels_per_pixel_PNG[imagetype]; // 0 will be treated as a special value
  if (interlaced) {
    size_t widths[] = {(width + 7) / 8, (width + 3) / 8, (width + 3) / 4, (width + 1) / 4, (width + 1) / 2, width / 2, width};
    size_t heights[] = {(height + 7) / 8, (height + 7) / 8, (height + 3) / 8, (height + 3) / 4, (height + 1) / 4, (height + 1) / 2, height / 2};
    size_t rowsizes[7];
    size_t cumulative_size = 0;
    for (uint_fast8_t pass = 0; pass < 7; pass ++) if (widths[pass] && heights[pass]) {
      rowsizes[pass] = pixelsize ? pixelsize * widths[pass] + 1 : (((size_t) widths[pass] * bitdepth + 7) / 8 + 1);
      cumulative_size += rowsizes[pass] * heights[pass];
    }
    decompressed = decompress_PNG_data(context, compressed, compressed_size, cumulative_size);
    unsigned char * current = decompressed;
    for (uint_fast8_t pass = 0; pass < 7; pass ++) if (widths[pass] && heights[pass]) {
      load_PNG_raw_frame_pass(context, current, result, heights[pass], widths[pass], width, imagetype, bitdepth, interlaced_PNG_pass_start[pass + 1],
                              interlaced_PNG_pass_start[pass], interlaced_PNG_pass_step[pass + 1], interlaced_PNG_pass_step[pass], rowsizes[pass]);
      current += rowsizes[pass] * heights[pass];
    }
  } else {
    size_t rowsize = pixelsize ? pixelsize * width + 1 : (((size_t) width * bitdepth + 7) / 8 + 1);
    decompressed = decompress_PNG_data(context, compressed, compressed_size, rowsize * height);
    load_PNG_raw_frame_pass(context, decompressed, result, height, width, width, imagetype, bitdepth, 0, 0, 1, 1, rowsize);
  }
  ctxfree(context, decompressed);
  return result;
}

void load_PNG_raw_frame_pass (struct context * context, unsigned char * restrict data, uint64_t * restrict output, uint32_t height, uint32_t width,
                              uint32_t fullwidth, uint8_t imagetype, uint8_t bitdepth, unsigned char coordH, unsigned char coordV, unsigned char offsetH,
                              unsigned char offsetV, size_t rowsize) {
  remove_PNG_filter(context, data, width, height, imagetype, bitdepth);
  for (size_t row = 0; row < height; row ++) {
    uint64_t * rowoutput = output + (row * offsetV + coordV) * fullwidth;
    unsigned char * rowdata = data + 1;
    switch (bitdepth + imagetype) {
      // since bitdepth must be 8 or 16 here unless imagetype is 0, all combinations are unique
      case 8: // imagetype = 0, bitdepth = 8
        for (size_t col = 0; col < width; col ++) rowoutput[col * offsetH + coordH] = (uint64_t) rowdata[col] * 0x10101010101u;
        break;
      case 10: // imagetype = 2, bitdepth = 8
        for (size_t col = 0; col < width; col ++)
          rowoutput[col * offsetH + coordH] = (rowdata[3 * col] | ((uint64_t) rowdata[3 * col + 1] << 16) | ((uint64_t) rowdata[3 * col + 2] << 32)) * 0x101;
        break;
      case 12: // imagetype = 4, bitdepth = 8
        for (size_t col = 0; col < width; col ++)
          rowoutput[col * offsetH + coordH] = ((uint64_t) rowdata[2 * col] * 0x10101010101u) | ((uint64_t) (rowdata[2 * col + 1] ^ 0xff) * 0x101000000000000u);
        break;
      case 14: // imagetype = 6, bitdepth = 8
        for (size_t col = 0; col < width; col ++)
          rowoutput[col * offsetH + coordH] = 0x101 * (rowdata[4 * col] | ((uint64_t) rowdata[4 * col + 1] << 16) |
                                                       ((uint64_t) rowdata[4 * col + 2] << 32) | ((uint64_t) (rowdata[4 * col + 3] ^ 0xff) << 48));
        break;
      case 16: // imagetype = 0, bitdepth = 16
        for (size_t col = 0; col < width; col ++) rowoutput[col * offsetH + coordH] = (uint64_t) read_be16_unaligned(rowdata + 2 * col) * 0x100010001u;
        break;
      case 18: // imagetype = 2, bitdepth = 16
        for (size_t col = 0; col < width; col ++)
          rowoutput[col * offsetH + coordH] = read_be16_unaligned(rowdata + 6 * col) | ((uint64_t) read_be16_unaligned(rowdata + 6 * col + 2) << 16) |
                                              ((uint64_t) read_be16_unaligned(rowdata + 6 * col + 4) << 32);
        break;
      case 20: // imagetype = 4, bitdepth = 16
        for (size_t col = 0; col < width; col ++)
          rowoutput[col * offsetH + coordH] = ((uint64_t) read_be16_unaligned(rowdata + 4 * col) * 0x100010001u) |
                                              ((uint64_t) ~read_be16_unaligned(rowdata + 4 * col + 2) << 48);
        break;
      case 22: // imagetype = 6, bitdepth = 16
        for (size_t col = 0; col < width; col ++)
          rowoutput[col * offsetH + coordH] = read_be16_unaligned(rowdata + 8 * col) | ((uint64_t) read_be16_unaligned(rowdata + 8 * col + 2) << 16) |
                                              ((uint64_t) read_be16_unaligned(rowdata + 8 * col + 4) << 32) |
                                              ((uint64_t) ~read_be16_unaligned(rowdata + 8 * col + 6) << 48);
        break;
      default: { // imagetype = 0, bitdepth < 8
        unsigned char * buffer = ctxmalloc(context, width);
        expand_bitpacked_PNG_data(buffer, rowdata, width, bitdepth);
        for (size_t col = 0; col < width; col ++) rowoutput[col * offsetH + coordH] = (uint64_t) bitextend16(buffer[col], bitdepth) * 0x100010001u;
        ctxfree(context, buffer);
      }
    }
    data += rowsize;
  }
}

void expand_bitpacked_PNG_data (unsigned char * restrict result, const unsigned char * restrict source, size_t count, uint8_t bitdepth) {
  switch (bitdepth) {
    case 1:
      for (; count > 7; count -= 8) {
        *(result ++) = !!(*source & 0x80);
        *(result ++) = !!(*source & 0x40);
        *(result ++) = !!(*source & 0x20);
        *(result ++) = !!(*source & 0x10);
        *(result ++) = !!(*source & 8);
        *(result ++) = !!(*source & 4);
        *(result ++) = !!(*source & 2);
        *(result ++) = *(source ++) & 1;
      }
      if (count) for (unsigned char remainder = *source; count; count --, remainder <<= 1) *(result ++) = remainder >> 7;
      break;
    case 2:
      for (; count > 3; count -= 4) {
        *(result ++) = *source >> 6;
        *(result ++) = (*source >> 4) & 3;
        *(result ++) = (*source >> 2) & 3;
        *(result ++) = *(source ++) & 3;
      }
      if (count) for (unsigned char remainder = *source; count; count --, remainder <<= 2) *(result ++) = remainder >> 6;
      break;
    case 4:
      for (; count > 1; count -= 2) {
        *(result ++) = *source >> 4;
        *(result ++) = *(source ++) & 15;
      }
      if (count) *result = *source >> 4;
      break;
    default:
      memcpy(result, source, count);
  }
}

void remove_PNG_filter (struct context * context, unsigned char * restrict data, uint32_t width, uint32_t height, uint8_t imagetype, uint8_t bitdepth) {
  ptrdiff_t pixelsize = bitdepth / 8 * channels_per_pixel_PNG[imagetype];
  if (!pixelsize) {
    pixelsize = 1;
    width = ((size_t) width * bitdepth + 7) / 8;
  }
  if ((size_t) pixelsize * width + 1 > PTRDIFF_MAX) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  ptrdiff_t rowsize = pixelsize * width + 1;
  for (uint_fast32_t row = 0; row < height; row ++) {
    unsigned char * rowdata = data + 1;
    switch (*data) {
      case 4:
        for (size_t p = 0; p < pixelsize * width; p ++) {
          int top = row ? rowdata[p - rowsize] : 0, left = (p < pixelsize) ? 0 : rowdata[p - pixelsize];
          int diagonal = (row && p >= pixelsize) ? rowdata[p - pixelsize - rowsize] : 0;
          int topdiff = absolute_value(left - diagonal), leftdiff = absolute_value(top - diagonal), diagdiff = absolute_value(left + top - diagonal * 2);
          rowdata[p] += (leftdiff <= topdiff && leftdiff <= diagdiff) ? left : (topdiff <= diagdiff) ? top : diagonal;
        }
        break;
      case 3:
        if (row) {
          for (size_t p = 0; p < pixelsize; p ++) rowdata[p] += rowdata[p - rowsize] >> 1;
          for (size_t p = pixelsize; p < pixelsize * width; p ++) rowdata[p] += (rowdata[p - pixelsize] + rowdata[p - rowsize]) >> 1;
        } else
          for (size_t p = pixelsize; p < pixelsize * width; p ++) rowdata[p] += rowdata[p - pixelsize] >> 1;
        break;
      case 2:
        if (row) for (size_t p = 0; p < pixelsize * width; p ++) rowdata[p] += rowdata[p - rowsize];
        break;
      case 1:
        for (size_t p = pixelsize; p < pixelsize * width; p ++) rowdata[p] += rowdata[p - pixelsize];
      case 0:
        break;
      default:
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
    data += rowsize;
  }
}

void generate_PNG_data (struct context * context) {
  if (context -> source -> frames > 1) throw(context, PLUM_ERR_NO_MULTI_FRAME);
  unsigned type = generate_PNG_header(context);
  append_PNG_image_data(context, context -> source -> data, type, NULL);
  output_PNG_chunk(context, 0x49454e44u, 0, NULL); // IEND
}

void generate_APNG_data (struct context * context) {
  if (context -> source -> frames > 0x40000000u) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  unsigned type = generate_PNG_header(context);
  uint32_t loops = 1;
  const struct plum_metadata * metadata = plum_find_metadata(context -> source, PLUM_METADATA_LOOP_COUNT);
  if (metadata) {
    loops = *(uint32_t *) metadata -> data;
    if (loops > 0x7fffffffu) loops = 0; // too many loops, so just make it loop forever
  }
  const uint64_t * durations = NULL;
  const uint8_t * disposals = NULL;
  size_t duration_count = 0, disposal_count = 0;
  if (metadata = plum_find_metadata(context -> source, PLUM_METADATA_FRAME_DURATION)) {
    durations = metadata -> data;
    duration_count = metadata -> size / sizeof(uint64_t);
  }
  if (metadata = plum_find_metadata(context -> source, PLUM_METADATA_FRAME_DISPOSAL)) {
    disposals = metadata -> data;
    disposal_count = metadata -> size;
  }
  uint32_t chunkID = 0;
  uint_fast8_t last_disposal = (disposal_count >= context -> source -> frames) ? disposals[context -> source -> frames - 1] : 0;
  unsigned char animation_data[8];
  write_be32_unaligned(animation_data + 4, loops);
  int64_t duration_remainder = 0;
  if ((duration_count && *durations) || context -> source -> frames == 1) {
    write_be32_unaligned(animation_data, context -> source -> frames);
    output_PNG_chunk(context, 0x6163544cu, sizeof animation_data, animation_data); // acTL
    uint_fast8_t disposal = disposal_count ? *disposals : 0;
    append_APNG_frame_header(context, duration_count ? *durations : 0, disposal, last_disposal, &chunkID, &duration_remainder);
    last_disposal = disposal;
  } else {
    write_be32_unaligned(animation_data, context -> source -> frames - 1);
    output_PNG_chunk(context, 0x6163544cu, sizeof animation_data, animation_data); // acTL
  }
  append_PNG_image_data(context, context -> source -> data, type, NULL);
  size_t framesize = (size_t) context -> source -> width * context -> source -> height;
  if (!context -> source -> palette) framesize = plum_color_buffer_size(framesize, context -> source -> color_format);
  for (uint_fast32_t frame = 1; frame < context -> source -> frames; frame ++) {
    uint_fast8_t disposal = (disposal_count > frame) ? disposals[frame] : 0;
    append_APNG_frame_header(context, (duration_count > frame) ? durations[frame] : 0, disposal, last_disposal, &chunkID, &duration_remainder);
    last_disposal = disposal;
    append_PNG_image_data(context, context -> source -> data8 + framesize * frame, type, &chunkID);
  }
  output_PNG_chunk(context, 0x49454e44u, 0, NULL); // IEND
}

unsigned generate_PNG_header (struct context * context) {
  // returns the selected type of image: 0, 1, 2, 3: paletted (1 << type bits), 4, 5: 8-bit RGB (without and with alpha), 6, 7: 16-bit RGB
  byteoutput(context, 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a);
  uint_fast8_t type;
  uint32_t depth = get_true_color_depth(context -> source);
  if (context -> source -> palette)
    if (context -> source -> max_palette_index < 2)
      type = 0;
    else if (context -> source -> max_palette_index < 4)
      type = 1;
    else if (context -> source -> max_palette_index < 16)
      type = 2;
    else
      type = 3;
  else if (bit_depth_less_than(depth, 0x8080808u))
    type = 4 + (depth >= 0x1000000u);
  else
    type = 6 + (depth >= 0x1000000u);
  append_PNG_header_chunks(context, type, depth);
  if (type < 4) append_PNG_palette_data(context, depth >= 0x1000000u);
  const struct plum_metadata * background = plum_find_metadata(context -> source, PLUM_METADATA_BACKGROUND);
  if (background) append_PNG_background_chunk(context, background -> data, type);
  return type;
}

void append_PNG_header_chunks (struct context * context, unsigned type, uint32_t depth) {
  if (context -> source -> width > 0x7fffffffu || context -> source -> height > 0x7fffffffu) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  unsigned char header[13];
  write_be32_unaligned(header, context -> image -> width);
  write_be32_unaligned(header + 4, context -> image -> height);
  header[8] = (type < 4) ? 1 << type : (8 << (type >= 6));
  header[9] = (type >= 4) ? 2 + 4 * (type & 1) : 3;
  bytewrite(header + 10, 0, 0, 0);
  output_PNG_chunk(context, 0x49484452u, sizeof header, header); // IHDR
  unsigned char depthdata[4];
  write_le32_unaligned(depthdata, depth); // this will write each byte of depth in the expected position
  if (type < 4) {
    if (*depthdata > 8) *depthdata = 8;
    if (depthdata[1] > 8) depthdata[1] = 8;
    if (depthdata[2] > 8) depthdata[2] = 8;
  }
  output_PNG_chunk(context, 0x73424954u, 3 + ((type & 5) == 5), depthdata); // sBIT
}

void append_PNG_palette_data (struct context * context, bool use_alpha) {
  uint32_t color_buffer[256];
  plum_convert_colors(color_buffer, context -> source -> palette, context -> source -> max_palette_index + 1, PLUM_COLOR_32 | PLUM_ALPHA_INVERT,
                      context -> source -> color_format);
  unsigned char data[768];
  for (uint_fast16_t index = 0; index <= context -> source -> max_palette_index; index ++)
    bytewrite(data + index * 3, color_buffer[index], color_buffer[index] >> 8, color_buffer[index] >> 16);
  output_PNG_chunk(context, 0x504c5445u, 3 * (context -> source -> max_palette_index + 1), data); // PLTE
  if (use_alpha) {
    unsigned char alpha[256];
    for (uint_fast16_t index = 0; index <= context -> source -> max_palette_index; index ++) alpha[index] = color_buffer[index] >> 24;
    output_PNG_chunk(context, 0x74524e53u, context -> source -> max_palette_index + 1, alpha); // tRNS
  }
}

void append_PNG_background_chunk (struct context * context, const void * restrict data, unsigned type) {
  if (type >= 4) {
    unsigned char chunkdata[6];
    uint64_t color;
    plum_convert_colors(&color, data, 1, PLUM_COLOR_64, context -> source -> color_format);
    if (type < 6) color = (color >> 8) & 0xff00ff00ffu;
    write_be16_unaligned(chunkdata, color);
    write_be16_unaligned(chunkdata + 2, color >> 16);
    write_be16_unaligned(chunkdata + 4, color >> 32);
    output_PNG_chunk(context, 0x624b4744u, sizeof chunkdata, chunkdata); // bKGD
  } else {
    size_t size = plum_color_buffer_size(1, context -> source -> color_format);
    const unsigned char * current = context -> source -> palette;
    for (uint_fast16_t pos = 0; pos <= context -> source -> max_palette_index; pos ++, current += size) if (!memcmp(current, data, size)) {
      unsigned char byte = pos;
      output_PNG_chunk(context, 0x624b4744u, 1, &byte); // bKGD
      return;
    }
  }
}

void append_PNG_image_data (struct context * context, const void * restrict data, unsigned type, uint32_t * restrict chunkID) {
  // chunkID counts animation data chunks (fcTL, fdAT); if chunkID is null, emit IDAT chunks instead
  size_t raw, size;
  unsigned char * uncompressed = generate_PNG_frame_data(context, data, type, &raw);
  // if chunkID is non-null, compress_PNG_data will insert four bytes of padding before the compressed data so this function can write a chunk ID there
  unsigned char * compressed = compress_PNG_data(context, uncompressed, raw, chunkID ? 4 : 0, &size);
  ctxfree(context, uncompressed);
  unsigned char * current = compressed;
  if (chunkID) {
    current += 4;
    while (size > 0x7ffffffbu) {
      if (*chunkID > 0x7fffffffu) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
      write_be32_unaligned(current - 4, (*chunkID) ++);
      output_PNG_chunk(context, 0x66644154u, 0x7ffffffcu, current - 4); // fdAT
      current += 0x7ffffff8u;
      size -= 0x7ffffff8u;
    }
    if (size) {
      if (*chunkID > 0x7fffffffu) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
      write_be32_unaligned(current - 4, (*chunkID) ++);
      output_PNG_chunk(context, 0x66644154u, size + 4, current - 4); // fdAT
    }
  } else {
    while (size > 0x7fffffffu) {
      output_PNG_chunk(context, 0x49444154u, 0x7ffffffcu, current); // IDAT
      current += 0x7ffffffcu;
      size -= 0x7ffffffcu;
    }
    if (size) output_PNG_chunk(context, 0x49444154u, size, current); // IDAT
  }
  ctxfree(context, compressed);
}

void append_APNG_frame_header (struct context * context, uint64_t duration, uint8_t disposal, uint8_t previous, uint32_t * restrict chunkID,
                               int64_t * restrict duration_remainder) {
  if (*chunkID > 0x7fffffffu) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  uint32_t numerator = 0, denominator = 0;
  if (duration) {
    if (duration == 1) duration = 0;
    duration = adjust_frame_duration(duration, duration_remainder);
    calculate_frame_duration_fraction(duration, 0xffffu, &numerator, &denominator);
    if (!numerator) {
      denominator = 0;
      update_frame_duration_remainder(duration, 0, duration_remainder);
    } else {
      if (!denominator) {
        // duration too large (calculation returned infinity), so max it out
        numerator = 0xffffu;
        denominator = 1;
      }
      update_frame_duration_remainder(duration, ((uint64_t) 1000000000u * numerator + denominator / 2) / denominator, duration_remainder);
    }
  }
  unsigned char data[26];
  write_be32_unaligned(data, (*chunkID) ++);
  write_be32_unaligned(data + 4, context -> source -> width);
  write_be32_unaligned(data + 8, context -> source -> height);
  memset(data + 12, 0, 8);
  write_be16_unaligned(data + 20, numerator);
  write_be16_unaligned(data + 22, denominator);
  bytewrite(data + 24, disposal % PLUM_DISPOSAL_REPLACE, previous < PLUM_DISPOSAL_REPLACE);
  output_PNG_chunk(context, 0x6663544cu, sizeof data, data); // fcTL
}

void output_PNG_chunk (struct context * context, uint32_t type, uint32_t size, const void * restrict data) {
  unsigned char * node = append_output_node(context, size + 12);
  write_be32_unaligned(node, size);
  write_be32_unaligned(node + 4, type);
  if (size) memcpy(node + 8, data, size);
  write_be32_unaligned(node + size + 8, compute_PNG_CRC(node + 4, size + 4));
}

unsigned char * generate_PNG_frame_data (struct context * context, const void * restrict data, unsigned type, size_t * restrict size) {
  size_t rowsize, pixelsize = bytes_per_channel_PNG[type];
  if (pixelsize)
    rowsize = context -> source -> width * pixelsize + 1;
  else
    rowsize = (((size_t) context -> source -> width << type) + 7) / 8 + 1;
  *size = rowsize * context -> source -> height;
  if (*size > SIZE_MAX - 2 || rowsize > SIZE_MAX / 6 || *size / rowsize != context -> source -> height) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  // allocate and initialize two extra bytes so the compressor can operate safely
  unsigned char * result = ctxcalloc(context, *size + 2);
  unsigned char * rowbuffer = ctxcalloc(context, 6 * rowsize);
  size_t rowoffset = (type < 4) ? context -> source -> width : plum_color_buffer_size(context -> source -> width, context -> source -> color_format);
  for (uint_fast32_t row = 0; row < context -> source -> height; row ++) {
    generate_PNG_row_data(context, (const unsigned char *) data + rowoffset * row, rowbuffer, type);
    filter_PNG_rows(rowbuffer, rowbuffer + 5 * rowsize, context -> source -> width, type);
    memcpy(rowbuffer + 5 * rowsize, rowbuffer, rowsize);
    memcpy(result + rowsize * row, rowbuffer + rowsize * select_PNG_filtered_row(rowbuffer, rowsize), rowsize);
  }
  ctxfree(context, rowbuffer);
  return result;
}

void generate_PNG_row_data (struct context * context, const void * restrict data, unsigned char * restrict output, unsigned type) {
  *(output ++) = 0;
  switch (type) {
    case 0: case 1: case 2: {
      const unsigned char * indexes = data;
      uint_fast8_t dataword = 0, bits = 0, pixelbits = 1 << type;
      for (uint_fast32_t p = 0; p < context -> source -> width; p ++) {
        dataword = (dataword << pixelbits) | *(indexes ++);
        bits += pixelbits;
        if (bits == 8) {
          *(output ++) = dataword;
          bits = 0;
        }
      }
      if (bits) *output = dataword << (8 - bits);
    } break;
    case 3:
      memcpy(output, data, context -> source -> width);
      break;
    case 4: case 5: {
      uint32_t * pixels = ctxmalloc(context, sizeof *pixels * context -> source -> width);
      plum_convert_colors(pixels, data, context -> source -> width, PLUM_COLOR_32 | PLUM_ALPHA_INVERT, context -> source -> color_format);
      if (type == 5)
        for (uint_fast32_t p = 0; p < context -> source -> width; p ++) write_le32_unaligned(output + 4 * p, pixels[p]);
      else
        for (uint_fast32_t p = 0; p < context -> source -> width; p ++) output += byteappend(output, pixels[p], pixels[p] >> 8, pixels[p] >> 16);
      ctxfree(context, pixels);
    } break;
    case 6: case 7: {
      uint64_t * pixels = ctxmalloc(context, sizeof *pixels * context -> source -> width);
      plum_convert_colors(pixels, data, context -> source -> width, PLUM_COLOR_64 | PLUM_ALPHA_INVERT, context -> source -> color_format);
      if (type == 7)
        for (uint_fast32_t p = 0; p < context -> source -> width; p ++)
          output += byteappend(output, pixels[p] >> 8, pixels[p], pixels[p] >> 24, pixels[p] >> 16, pixels[p] >> 40, pixels[p] >> 32,
                               pixels[p] >> 56, pixels[p] >> 48);
      else
        for (uint_fast32_t p = 0; p < context -> source -> width; p ++)
          output += byteappend(output, pixels[p] >> 8, pixels[p], pixels[p] >> 24, pixels[p] >> 16, pixels[p] >> 40, pixels[p] >> 32);
      ctxfree(context, pixels);
    }
  }
}

void filter_PNG_rows (unsigned char * restrict rowdata, const unsigned char * restrict previous, size_t count, unsigned type) {
  ptrdiff_t rowsize, pixelsize = bytes_per_channel_PNG[type];
  // rowsize doesn't include the filter type byte
  if (pixelsize)
    rowsize = count * pixelsize;
  else {
    rowsize = ((count << type) + 7) / 8;
    pixelsize = 1; // treat packed bits as a single pixel
  }
  rowdata ++;
  previous ++;
  unsigned char * output = rowdata + rowsize;
  *(output ++) = 1;
  for (ptrdiff_t p = 0; p < pixelsize; p ++) *(output ++) = rowdata[p];
  for (ptrdiff_t p = pixelsize; p < rowsize; p ++) *(output ++) = rowdata[p] - rowdata[p - pixelsize];
  *(output ++) = 2;
  for (ptrdiff_t p = 0; p < rowsize; p ++) *(output ++) = rowdata[p] - previous[p];
  *(output ++) = 3;
  for (ptrdiff_t p = 0; p < pixelsize; p ++) *(output ++) = rowdata[p] - (previous[p] >> 1);
  for (ptrdiff_t p = pixelsize; p < rowsize; p ++) *(output ++) = rowdata[p] - ((previous[p] + rowdata[p - pixelsize]) >> 1);
  *(output ++) = 4;
  for (ptrdiff_t p = 0; p < rowsize; p ++) {
    int top = previous[p], left = (p >= pixelsize) ? rowdata[p - pixelsize] : 0, diagonal = (p >= pixelsize) ? previous[p - pixelsize] : 0;
    int topdiff = absolute_value(left - diagonal), leftdiff = absolute_value(top - diagonal), diagdiff = absolute_value(left + top - diagonal * 2);
    *(output ++) = rowdata[p] - ((leftdiff <= topdiff && leftdiff <= diagdiff) ? left : (topdiff <= diagdiff) ? top : diagonal);
  }
}

unsigned char select_PNG_filtered_row (const unsigned char * rowdata, size_t rowsize) {
  // recommended by the standard: treat each byte as signed and pick the filter that results in the smallest sum of absolute values
  // ties are broken by smallest filter number, because lower-numbered filters are simpler than higher-numbered filters
  uint_fast64_t best_score = 0;
  for (size_t p = 0; p < rowsize; p ++, rowdata ++) best_score += (*rowdata >= 0x80) ? 0x100 - *rowdata : *rowdata;
  uint_fast8_t best = 0;
  for (uint_fast8_t current = 1; current < 5; current ++) {
    uint_fast64_t current_score = 0;
    for (size_t p = 0; p < rowsize; p ++, rowdata ++) current_score += (*rowdata >= 0x80) ? 0x100 - *rowdata : *rowdata;
    if (current_score < best_score) {
      best = current;
      best_score = current_score;
    }
  }
  return best;
}

void load_PNM_data (struct context * context, unsigned flags, size_t limit) {
  struct PNM_image_header * headers = NULL;
  size_t offset = 0;
  context -> image -> type = PLUM_IMAGE_PNM;
  // all image fields are zero-initialized, so the sizes are set to 0
  do {
    if (context -> image -> frames == 0xffffffffu) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
    headers = ctxrealloc(context, headers, (context -> image -> frames + 1) * sizeof *headers);
    struct PNM_image_header * header = headers + (context -> image -> frames ++);
    load_PNM_header(context, offset, header);
    if (context -> size - header -> datastart < header -> datalength) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    if (header -> width > context -> image -> width) context -> image -> width = header -> width;
    if (header -> height > context -> image -> height) context -> image -> height = header -> height;
    validate_image_size(context, limit);
    offset = header -> datastart + header -> datalength;
    skip_PNM_whitespace(context, &offset);
  } while (offset < context -> size);
  allocate_framebuffers(context, flags, false);
  add_PNM_bit_depth_metadata(context, headers);
  uint64_t * buffer = ctxmalloc(context, sizeof *buffer * context -> image -> width * context -> image -> height);
  offset = plum_color_buffer_size((size_t) context -> image -> width * context -> image -> height, flags);
  for (uint_fast32_t frame = 0; frame < context -> image -> frames; frame ++) {
    load_PNM_frame(context, headers + frame, buffer);
    plum_convert_colors(context -> image -> data8 + offset * frame, buffer, (size_t) context -> image -> width * context -> image -> height, flags,
                        PLUM_COLOR_64 | PLUM_ALPHA_INVERT);
  }
  ctxfree(context, buffer);
  ctxfree(context, headers);
}

void load_PNM_header (struct context * context, size_t offset, struct PNM_image_header * restrict header) {
  if (context -> size - offset < 8) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (bytematch(context -> data, 0xef, 0xbb, 0xbf)) offset += 3; // if a broken text editor somehow inserted a UTF-8 BOM, skip it
  if (context -> data[offset ++] != 0x50) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  header -> type = context -> data[offset ++] - 0x30;
  if (!header -> type || header -> type > 7 || !is_whitespace(context -> data[offset])) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (header -> type == 7) {
    load_PAM_header(context, offset, header);
    return;
  }
  uint32_t dimensions[3];
  dimensions[2] = 1;
  read_PNM_numbers(context, &offset, dimensions, 2 + (header -> type != 1 && header -> type != 4));
  if (!(*dimensions && dimensions[1] && dimensions[2]) || dimensions[2] > 0xffffu || offset == context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  header -> width = *dimensions;
  header -> height = dimensions[1];
  header -> maxvalue = dimensions[2];
  header -> datastart = ++ offset;
  if (!plum_check_valid_image_size(header -> width, header -> height, 1)) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  switch (header -> type) {
    case 5: case 6:
      header -> datalength = (size_t) header -> width * header -> height * (1 + (header -> maxvalue > 0xff));
      if (header -> type == 6) header -> datalength *= 3;
      break;
    case 4:
      header -> datalength = (size_t) ((header -> width - 1) / 8 + 1) * header -> height;
      break;
    default: {
      header -> datalength = context -> size - offset;
      size_t minchars = (header -> type == 3) ? 6 : header -> type; // minimum characters per pixel for each type
      if (header -> datalength < minchars * header -> width * header -> height - 1) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
  }
}

void load_PAM_header (struct context * context, size_t offset, struct PNM_image_header * restrict header) {
  unsigned fields = 15; // bits 0-3: width, height, max, depth (bit set indicates the field hasn't been read yet)
  uint32_t value, depth;
  while (true) {
    skip_PNM_line(context, &offset);
    skip_PNM_whitespace(context, &offset);
    unsigned length = next_PNM_token_length(context, offset);
    if (length == 6 && bytematch(context -> data + offset, 0x45, 0x4e, 0x44, 0x48, 0x44, 0x52)) { // ENDHDR
      offset += 6;
      break;
    } else if (length == 5 && bytematch(context -> data + offset, 0x57, 0x49, 0x44, 0x54, 0x48)) { // WIDTH
      offset += 5;
      if (!(fields & 1)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      read_PNM_numbers(context, &offset, &value, 1);
      if (!value) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      header -> width = value;
      fields &= ~1u;
    } else if (length == 6 && bytematch(context -> data + offset, 0x48, 0x45, 0x49, 0x47, 0x48, 0x54)) { // HEIGHT
      offset += 6;
      if (!(fields & 2)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      read_PNM_numbers(context, &offset, &value, 1);
      if (!value) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      header -> height = value;
      fields &= ~2u;
    } else if (length == 6 && bytematch(context -> data + offset, 0x4d, 0x41, 0x58, 0x56, 0x41, 0x4c)) { // MAXVAL
      offset += 6;
      if (!(fields & 4)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      read_PNM_numbers(context, &offset, &value, 1);
      if (!value || value > 0xffffu) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      header -> maxvalue = value;
      fields &= ~4u;
    } else if (length == 5 && bytematch(context -> data + offset, 0x44, 0x45, 0x50, 0x54, 0x48)) { // DEPTH
      offset += 5;
      if (!(fields & 8)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      read_PNM_numbers(context, &offset, &depth, 1);
      fields &= ~8u;
    } else if (length == 8 && bytematch(context -> data + offset, 0x54, 0x55, 0x50, 0x4c, 0x54, 0x59, 0x50, 0x45)) { // TUPLTYPE
      if (header -> type != 7) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      offset += 8;
      skip_PNM_whitespace(context, &offset);
      // while the TUPLTYPE line is, by the spec, not tokenized, the only recognized tuple types are a single token
      length = next_PNM_token_length(context, offset);
      if (length == 13 && bytematch(context -> data + offset, 0x42, 0x4c, 0x41, 0x43, 0x4b, 0x41, 0x4e, 0x44, 0x57, 0x48, 0x49, 0x54, 0x45)) // BLACKANDWHITE
        header -> type = 11;
      else if (length == 9 && bytematch(context -> data + offset, 0x47, 0x52, 0x41, 0x59, 0x53, 0x43, 0x41, 0x4c, 0x45)) // GRAYSCALE
        header -> type = 12;
      else if (length == 3 && bytematch(context -> data + offset, 0x52, 0x47, 0x42)) // RGB
        header -> type = 13;
      else if (length == 19 && bytematch(context -> data + offset, 0x42, 0x4c, 0x41, 0x43, 0x4b, 0x41, 0x4e, 0x44, 0x57, 0x48,
                                                                   0x49, 0x54, 0x45, 0x5f, 0x41, 0x4c, 0x50, 0x48, 0x41)) // BLACKANDWHITE_ALPHA
        header -> type = 14;
      else if (length == 15 && bytematch(context -> data + offset, 0x47, 0x52, 0x41, 0x59, 0x53, 0x43, 0x41, 0x4c, 0x45, 0x5f,
                                                                   0x41, 0x4c, 0x50, 0x48, 0x41)) // GRAYSCALE_ALPHA
        header -> type = 15;
      else if (length == 9 && bytematch(context -> data + offset, 0x52, 0x47, 0x42, 0x5f, 0x41, 0x4c, 0x50, 0x48, 0x41)) // RGB_ALPHA
        header -> type = 16;
      else
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
      offset += length;
    } else
      throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  }
  if (fields || header -> type == 7) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (!plum_check_valid_image_size(header -> width, header -> height, 1)) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
  static const unsigned char components[] = {1, 1, 3, 2, 2, 4};
  if (depth != components[header -> type - 11]) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (header -> maxvalue != 1 && (header -> type == 11 || header -> type == 14)) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  skip_PNM_line(context, &offset);
  header -> datastart = offset;
  header -> datalength = (size_t) header -> width * header -> height * depth;
  if (header -> maxvalue > 0xff) header -> datalength *= 2;
}

void skip_PNM_whitespace (struct context * context, size_t * restrict offset) {
  while (*offset < context -> size)
    if (context -> data[*offset] == 0x23) // '#'
      while (*offset < context -> size && context -> data[*offset] != 10) ++ *offset;
    else if (is_whitespace(context -> data[*offset]))
      ++ *offset;
    else
      break;
}

void skip_PNM_line (struct context * context, size_t * restrict offset) {
  for (bool comment = false; *offset < context -> size && context -> data[*offset] != 10; ++ *offset)
    if (!comment)
      if (context -> data[*offset] == 0x23) // '#'
        comment = true;
      else if (!is_whitespace(context -> data[*offset]))
        throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
  if (*offset < context -> size) ++ *offset;
}

unsigned next_PNM_token_length (struct context * context, size_t offset) {
  // stops at 20 because the longest recognized token is 19 characters long
  unsigned result = 0;
  while (offset < context -> size && result < 20 && !is_whitespace(context -> data[offset])) result ++, offset ++;
  return (result == 20) ? 0 : result;
}

void read_PNM_numbers (struct context * context, size_t * restrict offset, uint32_t * restrict result, size_t count) {
  while (count --) {
    skip_PNM_whitespace(context, offset);
    if (*offset >= context -> size || context -> data[*offset] < 0x30 || context -> data[*offset] > 0x39) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    uint_fast64_t current = context -> data[(*offset) ++] - 0x30; // 64-bit so it can catch overflows
    while (*offset < context -> size && context -> data[*offset] >= 0x30 && context -> data[*offset] <= 0x39) {
      current = current * 10 + context -> data[(*offset) ++] - 0x30;
      if (current > 0xffffffffu) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
    if (*offset < context -> size && !is_whitespace(context -> data[*offset])) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    *(result ++) = current;
  }
}

void add_PNM_bit_depth_metadata (struct context * context, const struct PNM_image_header * headers) {
  uint_fast8_t colordepth = 0, alphadepth = 0;
  bool colored = false;
  for (uint_fast32_t frame = 0; frame < context -> image -> frames; frame ++) {
    uint_fast8_t depth = bit_width(headers[frame].maxvalue);
    if (headers[frame].type == 3 || headers[frame].type == 6 || headers[frame].type == 13 || headers[frame].type == 16) colored = true;
    if (colordepth < depth) colordepth = depth;
    if (headers[frame].type >= 14 && alphadepth < depth) alphadepth = depth;
  }
  if (colored)
    add_color_depth_metadata(context, colordepth, colordepth, colordepth, alphadepth, 0);
  else
    add_color_depth_metadata(context, 0, 0, 0, alphadepth, colordepth);
}

void load_PNM_frame (struct context * context, const struct PNM_image_header * restrict header, uint64_t * restrict buffer) {
  size_t offset = header -> datastart, imagewidth = context -> image -> width, imageheight = context -> image -> height;
  if (header -> width < imagewidth)
    for (uint_fast32_t row = 0; row < header -> height; row ++)
      for (size_t p = imagewidth * row + header -> width; p < imagewidth * (row + 1); p ++) buffer[p] = 0;
  if (header -> height < imageheight)
    for (size_t p = imagewidth * header -> height; p < imagewidth * imageheight; p ++) buffer[p] = 0;
  if (header -> type == 4) {
    load_PNM_bit_frame(context, header -> width, header -> height, offset, buffer);
    return;
  }
  uint32_t values[4];
  values[3] = header -> maxvalue;
  uint_fast8_t bits = bit_width(header -> maxvalue);
  if (((header -> maxvalue + 1) >> (bits - 1)) == 1) bits = 0; // check if header -> maxvalue isn't (1 << bits) - 1, avoiding UB
  for (uint_fast32_t row = 0; row < header -> height; row ++) for (size_t p = imagewidth * row; p < imagewidth * row + header -> width; p ++) {
    switch (header -> type) {
      case 1:
        // sometimes the 0s and 1s are not delimited at all here, so it needs a special parser
        while (offset < context -> size && (context -> data[offset] & ~1u) != 0x30) offset ++;
        if (offset >= context -> size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
        values[2] = values[1] = *values = ~context -> data[offset ++] & 1;
        break;
      case 2:
        read_PNM_numbers(context, &offset, values, 1);
        values[2] = values[1] = *values;
        break;
      case 3:
        read_PNM_numbers(context, &offset, values, 3);
        break;
      case 6: case 13: case 16:
        if (header -> maxvalue > 0xff) {
          *values = read_be16_unaligned(context -> data + offset);
          offset += 2;
          values[1] = read_be16_unaligned(context -> data + offset);
          offset += 2;
          values[2] = read_be16_unaligned(context -> data + offset);
          offset += 2;
          if (header -> type >= 14) {
            values[3] = read_be16_unaligned(context -> data + offset);
            offset += 2;
          }
        } else {
          *values = context -> data[offset ++];
          values[1] = context -> data[offset ++];
          values[2] = context -> data[offset ++];
          if (header -> type >= 14) values[3] = context -> data[offset ++];
        }
        break;
      default:
        if (header -> maxvalue > 0xff) {
          *values = read_be16_unaligned(context -> data + offset);
          offset += 2;
          if (header -> type >= 14) {
            values[3] = read_be16_unaligned(context -> data + offset);
            offset += 2;
          }
        } else {
          *values = context -> data[offset ++];
          if (header -> type >= 14) values[3] = context -> data[offset ++];
        }
        values[2] = values[1] = *values;
    }
    buffer[p] = 0;
    for (uint_fast8_t color = 0; color < 4; color ++) {
      uint64_t converted;
      if (bits)
        converted = bitextend16(values[color], bits);
      else
        converted = (values[color] * 0xffffu + header -> maxvalue / 2) / header -> maxvalue;
      buffer[p] |= converted << (color * 16);
    }
  }
}

void load_PNM_bit_frame (struct context * context, size_t width, size_t height, size_t offset, uint64_t * restrict buffer) {
  for (size_t row = 0; row < height; row ++) {
    size_t p = row * context -> image -> width;
    for (size_t col = 0; col < (width & bitnegate(7)); col += 8) {
      uint_fast8_t value = context -> data[offset ++];
      for (uint_fast8_t bit = 0; bit < 8; bit ++) {
        buffer[p ++] = (value & 0x80) ? 0xffff000000000000u : 0xffffffffffffffffu;
        value <<= 1;
      }
    }
    if (width & 7) {
      uint_fast8_t value = context -> data[offset ++];
      for (uint_fast8_t bit = 0; bit < (width & 7); bit ++) {
        buffer[p ++] = (value & 0x80) ? 0xffff000000000000u : 0xffffffffffffffffu;
        value <<= 1;
      }
    }
  }
}

void generate_PNM_data (struct context * context) {
  uint32_t depth = get_true_color_depth(context -> source);
  uint_fast8_t max = 0;
  for (uint_fast8_t p = 0; p < 32; p += 8) if (((depth >> p) & 0xff) > max) max = (depth >> p) & 0xff;
  uint64_t * buffer;
  if (context -> source -> palette) {
    buffer = ctxmalloc(context, sizeof *buffer * (context -> source -> max_palette_index + 1));
    plum_convert_colors(buffer, context -> source -> palette, context -> source -> max_palette_index + 1, PLUM_COLOR_64 | PLUM_ALPHA_INVERT,
                        context -> source -> color_format);
  } else
    buffer = ctxmalloc(context, sizeof *buffer * context -> source -> width * context -> source -> height);
  if (depth < 0x1000000u)
    generate_PPM_data(context, NULL, max, buffer);
  else if (context -> source -> frames == 1)
    generate_PAM_data(context, max, buffer);
  else {
    uint32_t * sizes = get_true_PNM_frame_sizes(context);
    if (sizes) {
      generate_PPM_data(context, sizes, max, buffer);
      ctxfree(context, sizes);
    } else
      generate_PAM_data(context, max, buffer);
  }
  ctxfree(context, buffer);
}

uint32_t * get_true_PNM_frame_sizes (struct context * context) {
  // returns width, height pairs for each frame if the only transparency in those frames is an empty border on the bottom and right edges
  unsigned char format = context -> source -> color_format & PLUM_COLOR_MASK;
  uint64_t mask = alpha_component_masks[format], check = 0, color = get_background_color(context -> source, 0) & ~mask;
  if (context -> source -> color_format & PLUM_ALPHA_INVERT)
    check = mask;
  else
    color |= mask;
  uint32_t * result = ctxmalloc(context, sizeof *result * 2 * context -> source -> frames);
  size_t width, height, offset = (size_t) context -> source -> width * context -> source -> height;
  if (context -> source -> palette) {
    unsigned char colorclass[0x100]; // 0 for a solid color, 1 for empty pixels (fully transparent background), 2 for everything else
    #define checkclasses(bits) do                                                     \
      for (uint_fast16_t p = 0; p <= context -> source -> max_palette_index; p ++)    \
        if (context -> source -> palette ## bits[p] == color)                         \
          colorclass[p] = 1;                                                          \
        else if ((context -> source -> palette ## bits[p] & mask) == check)           \
          colorclass[p] = 0;                                                          \
        else                                                                          \
          colorclass[p] = 2;                                                          \
    while (false)
    if (format == PLUM_COLOR_16)
      checkclasses(16);
    else if (format == PLUM_COLOR_64)
      checkclasses(64);
    else
      checkclasses(32);
    #undef checkclasses
    for (uint_fast32_t frame = 0; frame < context -> source -> frames; frame ++) {
      const uint8_t * data = context -> source -> data8 + offset * frame;
      if (colorclass[*data]) goto fail;
      for (width = 1; width < context -> source -> width; width ++) if (colorclass[data[width]]) break;
      for (height = 1; height < context -> source -> height; height ++) if (colorclass[data[height * context -> source -> width]]) break;
      for (size_t row = 0; row < context -> source -> height; row ++) for (size_t col = 0; col < context -> source -> width; col ++)
        if (colorclass[data[row * context -> source -> width + col]] != (row >= height || col >= width)) goto fail;
      result[frame * 2] = width;
      result[frame * 2 + 1] = height;
    }
  } else {
    #define checkframe(bits) do                                                                                                             \
      for (uint_fast32_t frame = 0; frame < context -> source -> frames; frame ++) {                                                        \
        const uint ## bits ## _t * data = context -> source -> data ## bits + offset * frame;                                               \
        if (*data == color) goto fail;                                                                                                      \
        for (width = 1; width < context -> source -> width; width ++) if (data[width] == color) break;                                      \
        for (height = 1; height < context -> source -> height; height ++) if (data[height * context -> source -> width] == color) break;    \
        for (size_t row = 0; row < height; row ++) for (size_t col = 0; col < width; col ++)                                                \
          if ((data[row * context -> source -> width + col] & mask) != check) goto fail;                                                    \
        for (size_t row = 0; row < context -> source -> height; row ++)                                                                     \
          for (size_t col = (row < height) ? width : 0; col < context -> source -> width; col ++)                                           \
            if (data[row * context -> source -> width + col] != color) goto fail;                                                           \
        result[frame * 2] = width;                                                                                                          \
        result[frame * 2 + 1] = height;                                                                                                     \
      }                                                                                                                                     \
    while (false)
    if (format == PLUM_COLOR_16)
      checkframe(16);
    else if (format == PLUM_COLOR_64)
      checkframe(64);
    else
      checkframe(32);
    #undef checkframe
  }
  width = height = 0;
  for (uint_fast32_t frame = 0; frame < context -> source -> frames && !(width && height); frame ++) {
    if (result[frame * 2] == context -> source -> width) width = 1;
    if (result[frame * 2 + 1] == context -> source -> height) height = 1;
  }
  if (width && height) return result;
  fail:
  ctxfree(context, result);
  return NULL;
}

void generate_PPM_data (struct context * context, const uint32_t * restrict sizes, unsigned bitdepth, uint64_t * restrict buffer) {
  size_t offset = (size_t) context -> source -> width * context -> source -> height;
  if (!context -> source -> palette) offset = plum_color_buffer_size(offset, context -> source -> color_format);
  for (size_t frame = 0; frame < context -> source -> frames; frame ++) {
    size_t width = sizes ? sizes[frame * 2] : context -> source -> width;
    size_t height = sizes ? sizes[frame * 2 + 1] : context -> source -> height;
    generate_PPM_header(context, width, height, bitdepth);
    if (context -> source -> palette)
      generate_PNM_frame_data_from_palette(context, context -> source -> data8 + offset * frame, buffer, width, height, bitdepth, false);
    else {
      plum_convert_colors(buffer, context -> source -> data8 + offset * frame, height * context -> source -> width, PLUM_COLOR_64 | PLUM_ALPHA_INVERT,
                          context -> source -> color_format);
      generate_PNM_frame_data(context, buffer, width, height, bitdepth, false);
    }
  }
}

void generate_PPM_header (struct context * context, uint32_t width, uint32_t height, unsigned bitdepth) {
  unsigned char * node = append_output_node(context, 32);
  size_t offset = byteappend(node, 0x50, 0x36, 0x0a); // P6<newline>
  offset += write_PNM_number(node + offset, width);
  node[offset ++] = 0x20; // space
  offset += write_PNM_number(node + offset, height);
  node[offset ++] = 0x0a; // newline
  offset += write_PNM_number(node + offset, ((uint32_t) 1 << bitdepth) - 1);
  node[offset ++] = 0x0a; // newline
  context -> output -> size = offset;
}

void generate_PAM_data (struct context * context, unsigned bitdepth, uint64_t * restrict buffer) {
  size_t size = (size_t) context -> source -> width * context -> source -> height, offset = plum_color_buffer_size(size, context -> source -> color_format);
  for (uint_fast32_t frame = 0; frame < context -> source -> frames; frame ++) {
    generate_PAM_header(context, bitdepth);
    if (context -> source -> palette)
      generate_PNM_frame_data_from_palette(context, context -> source -> data8 + size * frame, buffer, context -> source -> width, context -> source -> height,
                                           bitdepth, true);
    else {
      plum_convert_colors(buffer, context -> source -> data8 + offset * frame, size, PLUM_COLOR_64 | PLUM_ALPHA_INVERT, context -> source -> color_format);
      generate_PNM_frame_data(context, buffer, context -> source -> width, context -> source -> height, bitdepth, true);
    }
  }
}

void generate_PAM_header (struct context * context, unsigned bitdepth) {
  unsigned char * node = append_output_node(context, 96);
  size_t offset = byteappend(node,
                             0x50, 0x37, 0x0a, // P7<newline>
                             0x54, 0x55, 0x50, 0x4c, 0x54, 0x59, 0x50, 0x45, 0x20, // TUPLTYPE<space>
                             0x52, 0x47, 0x42, 0x5f, 0x41, 0x4c, 0x50, 0x48, 0x41, 0x0a, // RGB_ALPHA<newline>
                             0x57, 0x49, 0x44, 0x54, 0x48, 0x20 // WIDTH<space>
                            );
  offset += write_PNM_number(node + offset, context -> source -> width);
  offset += byteappend(node + offset, 0x0a, 0x48, 0x45, 0x49, 0x47, 0x48, 0x54, 0x20); // <newline>HEIGHT<space>
  offset += write_PNM_number(node + offset, context -> source -> height);
  offset += byteappend(node + offset, 0x0a, 0x4d, 0x41, 0x58, 0x56, 0x41, 0x4c, 0x20); // <newline>MAXVAL<space>
  offset += write_PNM_number(node + offset, ((uint32_t) 1 << bitdepth) - 1);
  offset += byteappend(node + offset,
                       0x0a, // <newline>
                       0x44, 0x45, 0x50, 0x54, 0x48, 0x20, 0x34, 0x0a, // DEPTH 4<newline>
                       0x45, 0x4e, 0x44, 0x48, 0x44, 0x52, 0x0a // ENDHDR<newline>
                      );
  context -> output -> size = offset;
}

size_t write_PNM_number (unsigned char * restrict buffer, uint32_t number) {
  // won't work for 0, but there's no need to write a 0 anywhere
  unsigned char data[10];
  uint_fast8_t size = 0;
  while (number) {
    data[size ++] = 0x30 + number % 10;
    number /= 10;
  }
  for (uint_fast8_t p = size; p; *(buffer ++) = data[-- p]);
  return size;
}

void generate_PNM_frame_data (struct context * context, const uint64_t * data, uint32_t width, uint32_t height, unsigned bitdepth, bool alpha) {
  uint_fast8_t shift = 16 - bitdepth, mask = (1 << ((bitdepth > 8) ? bitdepth - 8 : bitdepth)) - 1;
  const uint64_t * rowdata = data;
  unsigned char * output = append_output_node(context, (size_t) (3 + alpha) * ((bitdepth + 7) / 8) * width * height);
  if (shift >= 8)
    for (uint_fast32_t row = 0; row < height; row ++, rowdata += context -> source -> width) for (uint_fast32_t col = 0; col < width; col ++) {
      output += byteappend(output, (rowdata[col] >> shift) & mask, (rowdata[col] >> (shift + 16)) & mask, (rowdata[col] >> (shift + 32)) & mask);
      if (alpha) *(output ++) = rowdata[col] >> (shift + 48);
    }
  else
    for (uint_fast32_t row = 0; row < height; row ++, rowdata += context -> source -> width) for (uint_fast32_t col = 0; col < width; col ++) {
      output += byteappend(output, (rowdata[col] >> (shift + 8)) & mask, rowdata[col] >> shift, (rowdata[col] >> (shift + 24)) & mask,
                                   rowdata[col] >> (shift + 16), (rowdata[col] >> (shift + 40)) & mask, rowdata[col] >> (shift + 32));
      if (alpha) output += byteappend(output, rowdata[col] >> (shift + 56), rowdata[col] >> (shift + 48));
    }
}

void generate_PNM_frame_data_from_palette (struct context * context, const uint8_t * data, const uint64_t * palette, uint32_t width, uint32_t height,
                                           unsigned bitdepth, bool alpha) {
  // very similar to the previous function, but adjusted to use the color from the palette and to read 8-bit data
  uint_fast8_t shift = 16 - bitdepth, mask = (1 << ((bitdepth > 8) ? bitdepth - 8 : bitdepth)) - 1;
  const uint8_t * rowdata = data;
  unsigned char * output = append_output_node(context, (size_t) (3 + alpha) * ((bitdepth + 7) / 8) * width * height);
  if (shift >= 8)
    for (uint_fast32_t row = 0; row < height; row ++, rowdata += context -> source -> width) for (uint_fast32_t col = 0; col < width; col ++) {
      uint64_t color = palette[rowdata[col]];
      output += byteappend(output, (color >> shift) & mask, (color >> (shift + 16)) & mask, (color >> (shift + 32)) & mask);
      if (alpha) *(output ++) = color >> (shift + 48);
    }
  else
    for (uint_fast32_t row = 0; row < height; row ++, rowdata += context -> source -> width) for (uint_fast32_t col = 0; col < width; col ++) {
      uint64_t color = palette[rowdata[col]];
      output += byteappend(output, (color >> (shift + 8)) & mask, color >> shift, (color >> (shift + 24)) & mask, color >> (shift + 16),
                                   (color >> (shift + 40)) & mask, color >> (shift + 32));
      if (alpha) output += byteappend(output, color >> (shift + 56), color >> (shift + 48));
    }
}

size_t plum_store_image (const struct plum_image * image, void * restrict buffer, size_t size_mode, unsigned * restrict error) {
  struct context * context = create_context();
  if (!context) {
    if (error) *error = PLUM_ERR_OUT_OF_MEMORY;
    return 0;
  }
  context -> source = image;
  if (!setjmp(context -> target)) {
    if (!(image && buffer && size_mode)) throw(context, PLUM_ERR_INVALID_ARGUMENTS);
    unsigned rv = plum_validate_image(image);
    if (rv) throw(context, rv);
    if (plum_validate_palette_indexes(image)) throw(context, PLUM_ERR_INVALID_COLOR_INDEX);
    switch (image -> type) {
      case PLUM_IMAGE_BMP: generate_BMP_data(context); break;
      case PLUM_IMAGE_GIF: generate_GIF_data(context); break;
      case PLUM_IMAGE_PNG: generate_PNG_data(context); break;
      case PLUM_IMAGE_APNG: generate_APNG_data(context); break;
      case PLUM_IMAGE_JPEG: generate_JPEG_data(context); break;
      case PLUM_IMAGE_PNM: generate_PNM_data(context); break;
      default: throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    }
    size_t output_size = get_total_output_size(context);
    if (!output_size) throw(context, PLUM_ERR_INVALID_FILE_FORMAT);
    switch (size_mode) {
      case PLUM_MODE_FILENAME:
        write_generated_image_data_to_file(context, buffer);
        break;
      case PLUM_MODE_BUFFER: {
        void * out = malloc(output_size);
        if (!out) throw(context, PLUM_ERR_OUT_OF_MEMORY);
        // the function must succeed after reaching this point (otherwise, memory would be leaked)
        *(struct plum_buffer *) buffer = (struct plum_buffer) {.size = output_size, .data = out};
        write_generated_image_data(out, context -> output);
      } break;
      case PLUM_MODE_CALLBACK:
        write_generated_image_data_to_callback(context, buffer);
        break;
      default:
        if (output_size > size_mode) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
        write_generated_image_data(buffer, context -> output);
    }
    context -> size = output_size;
  }
  if (context -> file) fclose(context -> file);
  if (error) *error = context -> status;
  size_t result = context -> size;
  destroy_allocator_list(context -> allocator);
  return result;
}

void write_generated_image_data_to_file (struct context * context, const char * filename) {
  context -> file = fopen(filename, "wb");
  if (!context -> file) throw(context, PLUM_ERR_FILE_INACCESSIBLE);
  const struct data_node * node;
  for (node = context -> output; node -> previous; node = node -> previous);
  while (node) {
    const unsigned char * data = node -> data;
    size_t size = node -> size;
    while (size) {
      unsigned count = fwrite(data, 1, (size > 0x4000) ? 0x4000 : size, context -> file);
      if (ferror(context -> file) || !count) throw(context, PLUM_ERR_FILE_ERROR);
      data += count;
      size -= count;
    }
    node = node -> next;
  }
  fclose(context -> file);
  context -> file = NULL;
}

void write_generated_image_data_to_callback (struct context * context, const struct plum_callback * callback) {
  struct data_node * node;
  for (node = context -> output; node -> previous; node = node -> previous);
  while (node) {
    unsigned char * data = node -> data; // not const because the callback takes an unsigned char *
    size_t size = node -> size;
    while (size) {
      int block = (size > 0x4000) ? 0x4000 : size;
      int count = callback -> callback(callback -> userdata, data, block);
      if (count < 0 || count > block) throw(context, PLUM_ERR_FILE_ERROR);
      data += count;
      size -= count;
    }
    node = node -> next;
  }
}

void write_generated_image_data (void * restrict buffer, const struct data_node * data) {
  const struct data_node * node;
  for (node = data; node -> previous; node = node -> previous);
  for (unsigned char * out = buffer; node; node = node -> next) {
    memcpy(out, node -> data, node -> size);
    out += node -> size;
  }
}

size_t get_total_output_size (struct context * context) {
  size_t result = 0;
  for (const struct data_node * node = context -> output; node; node = node -> previous) {
    if (result + node -> size < result) throw(context, PLUM_ERR_IMAGE_TOO_LARGE);
    result += node -> size;
  }
  return result;
}
