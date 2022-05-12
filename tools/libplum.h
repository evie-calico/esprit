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
