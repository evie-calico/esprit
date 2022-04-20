/*
 * mod2gbt v3.1 (Part of GBT Player)
 *
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2009-2018, Antonio Niño Díaz <antonio_nd@outlook.com>
 *
 * This version has been modified by Eievui to allow for an explicit output
 * path.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int perform_speed_convertion = 1;

#define abs(x) (((x) > 0) ? (x) : -(x))
#define BIT(n) (1 << (n))

typedef struct __attribute__((packed)) {
  char name[22];
  uint16_t length;
  uint8_t finetune; // 4 lower bits
  uint8_t volume;   // 0-64
  uint16_t repeat_point;
  uint16_t repeat_length; // Loop if length > 1
} _sample_t;

typedef struct __attribute__((packed)) {
  uint8_t info[64][4][4]; // [step][channel][byte]
} _pattern_t;

typedef struct __attribute__((packed)) {
  char name[20];
  _sample_t sample[31];
  uint8_t song_length;        // Length in patterns
  uint8_t unused;             // Set to 127, used by Noisetracker
  uint8_t pattern_table[128]; // 0..63
  char identifier[4];
  // Only 64 patterns allowed (see pattern_table) but set to 256 anyway...
  _pattern_t pattern[256];
  // Followed by sample data, unused by the converter
} mod_file_t;

void *load_file(const char *filename) {
  unsigned int size;
  void *buffer = NULL;
  FILE *datafile = fopen(filename, "rb");

  if (datafile == NULL) {
    printf("ERROR: %s couldn't be opened!\n", filename);
    return NULL;
  }

  fseek(datafile, 0, SEEK_END);
  size = ftell(datafile);
  if (size == 0) {
    printf("ERROR: Size of %s is 0!\n", filename);
    fclose(datafile);
    return NULL;
  }

  rewind(datafile);
  buffer = malloc(size);
  if (buffer == NULL) {
    printf("ERROR: Not enought memory to load %s!\n", filename);
    fclose(datafile);
    return NULL;
  }

  if (fread(buffer, size, 1, datafile) != 1) {
    printf("ERROR: Error while reading.\n");
    fclose(datafile);
    free(buffer);
    return NULL;
  }

  fclose(datafile);

  return buffer;
}

void unpack_info(uint8_t *info, uint8_t *sample_num, uint16_t *sample_period, uint8_t *effect_num,
                 uint8_t *effect_param) {
  *sample_num = (info[0] & 0xF0) | ((info[2] & 0xF0) >> 4);
  *sample_period = info[1] | ((info[0] & 0x0F) << 8);
  *effect_num = info[2] & 0x0F;
  *effect_param = info[3];
}

const uint16_t mod_period[6 * 12] = {
    1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960, 907,
    856,  808,  762,  720,  678,  640,  604,  570,  538,  508,  480, 453,
    428,  404,  381,  360,  339,  320,  302,  285,  269,  254,  240, 226,
    214,  202,  190,  180,  170,  160,  151,  143,  135,  127,  120, 113,
    107,  101,  95,   90,   85,   80,   75,   71,   67,   63,   60,  56,
    53,   50,   47,   45,   42,   40,   37,   35,   33,   31,   30,  28};

uint8_t mod_get_index_from_period(uint16_t period, int pattern, int step, int channel) {
  if (period > 0) {
    if (period < mod_period[(6 * 12) - 1]) {
      if (channel != 4) // Pitch ignored for noise channel
      {
        printf("\nPattern %d, Step %d, Channel %d. Note too high!\n", pattern,
               step, channel);
      }
    } else if (period > mod_period[0]) {
      if (channel != 4) // Pitch ignored for noise channel
      {
        printf("\nPattern %d, Step %d, Channel %d. Note too low!\n", pattern,
               step, channel);
      }
    }
  } else {
    return -1;
  }

  int i;
  for (i = 0; i < 6 * 12; i++)
    if (period == mod_period[i])
      return i;

  // Couldn't find exact match... get nearest value

  uint16_t nearest_value = 0xFFFF;
  uint8_t nearest_index = 0;
  for (i = 0; i < 6 * 12; i++) {
    int test_distance = abs(((int)period) - ((int)mod_period[i]));
    int nearest_distance = abs(((int)period) - nearest_value);

    if (test_distance < nearest_distance) {
      nearest_value = mod_period[i];
      nearest_index = i;
    }
  }

  return nearest_index;
}

FILE *output_file;
char label_name[64];

void out_open(const char *filename) { output_file = fopen(filename, "w"); }
void out_write_str(const char *asm_str) { fprintf(output_file, "%s", asm_str); }
void out_write_dec(uint8_t number) { fprintf(output_file, "%d", number); }
void out_write_hex(uint8_t number) { fprintf(output_file, "%02X", number); }
void out_close(void) { fclose(output_file); }

int volume_mod_to_gb(int v) { return (v == 64) ? 0xF : (v >> 2); }

int volume_mod_to_gb_ch3(int v) {
  int vol = volume_mod_to_gb(v);

  switch (vol) {
  case 0: case 1: case 2: case 3: return 0;
  case 4: case 5: case 6: case 7: return 3;
  case 8: case 9: case 10: case 11: return 2;
  default: case 12: case 13: case 14: case 15: return 1;
  }

  return 0;
}

int speed_mod_to_gb(int s) {
  if (perform_speed_convertion) // Amiga's 50 Hz to GB's 60 Hz
    return (s * 60) / 50;
  else
    return s;
}

// Returns 1 if ok
int effect_mod_to_gb(uint8_t pattern_number, uint8_t step_number, uint8_t channel,
                     uint8_t effectnum, uint8_t effectparams, uint8_t *converted_num,
                     uint8_t *converted_params) {
  switch (effectnum) {
  case 0x0: {
    *converted_num = 1;
    *converted_params = effectparams;
    return 1;
  }
  case 0xB: {
    *converted_num = 8;
    *converted_params = effectparams;
    return 1;
  }
  case 0xC: {
    printf("Strange error at pattern %d, step %d, channel %d: "
           "%01X%02X\n",
           pattern_number, step_number, channel, effectnum, effectparams);
    return 0;
  }
  case 0xD: {
    *converted_num = 9; // Effect value is BCD, convert to integer
    *converted_params =
        (((effectparams & 0xF0) >> 4) * 10) + (effectparams & 0x0F);
    //*converted_params = effectparams; // ... or not?
    return 1;
  }
  case 0xE: {
    if ((effectparams & 0xF0) == 0x80) // Pan
    {
      uint8_t left = 0;
      uint8_t right = 0;

      switch (effectparams & 0xF) {
      case 0: case 1: case 2: case 3:
        left = 1;
        break;
      default: case 4: case 5: case 6: case 7: case 8: case 9: case 10: case 11:
        left = 1;
        right = 1;
        break;

      case 12: case 13: case 14: case 15:
        right = 1;
        break;
      }
      *converted_num = 0;
      *converted_params =
          (left << (3 + channel)) | (right << (channel - 1)); // Channel 1-4
      return 1;
    }
    if ((effectparams & 0xF0) == 0xC0) {
      *converted_num = 2;
      *converted_params = (effectparams & 0xF);
      return 1;
    } else {
      printf("Unsupported effect at pattern %d, step %d, channel %d: "
             "%01X%02X\n",
             pattern_number, step_number, channel, effectnum, effectparams);
      return 0;
    }
    break;
  }
  case 0xF: {
    if (effectparams > 0x1F) {
      printf("Unsupported BPM speed effect at pattern %d, step %d, "
             "channel %d: %01X%02X\n",
             pattern_number, step_number, channel, effectnum, effectparams);
      return 0;
    } else {
      *converted_num = 10;
      *converted_params = speed_mod_to_gb(effectparams);
      return 1;
    }
    break;
  }
  default: {
    printf("Unsupported effect at pattern %d, step %d, channel %d: "
           "%01X%02X\n",
           pattern_number, step_number, channel, effectnum, effectparams);
    return 0;
  }
  }
  return 0;
}

void convert_channel1(uint8_t pattern_number, uint8_t step_number, uint8_t note_index,
                      uint8_t samplenum, uint8_t effectnum, uint8_t effectparams) {
  uint8_t result[3] = {0, 0, 0};
  int command_len = 1; // NOP

  uint8_t instrument = samplenum & 3;

  if (note_index > (6 * 12 - 1)) {
    if ((effectnum != 0) || (effectparams != 0)) {
      // Volume or others?
      if (effectnum == 0xC) {
        // Volume
        result[0] = BIT(5) | volume_mod_to_gb(effectparams);
        command_len = 1;
      } else {
        // Others
        uint8_t converted_num, converted_params;
        if (effect_mod_to_gb(pattern_number, step_number, 1, effectnum,
                             effectparams, &converted_num,
                             &converted_params) == 1) {
          result[0] = BIT(6) | (instrument << 4) | converted_num;
          result[1] = converted_params;
          command_len = 2;
        } else {
          if (effectnum != 0) {
            printf("Invalid command at pattern %d, step %d, channel"
                   " 1: %01X%02X\n",
                   pattern_number, step_number, effectnum, effectparams);
          }

          // NOP
          result[0] = 0;
          command_len = 1;
        }
      }
    } else {
      // NOP
      result[0] = 0;
      command_len = 1;
    }
  } else {
    uint8_t converted_num, converted_params;
    if (effectnum == 0xC) {
      // Note + Volume
      result[0] = BIT(7) | note_index;
      result[1] = (instrument << 4) | volume_mod_to_gb(effectparams);
      command_len = 2;
    } else {
      if (effect_mod_to_gb(pattern_number, step_number, 1, effectnum,
                           effectparams, &converted_num,
                           &converted_params) == 1) {
        // Note + Effect
        result[0] = BIT(7) | note_index;
        result[1] = BIT(7) | (instrument << 4) | converted_num;
        result[2] = converted_params;
        command_len = 3;
      } else {
        printf("Invalid command at pattern %d, step %d, channel 1: "
               "%01X%02X\n",
               pattern_number, step_number, effectnum, effectparams);

        if (effectnum == 0)
          printf("Volume must be set when using a note.\n");
      }
    }
  }

  out_write_str("$");
  out_write_hex(result[0]);

  if (command_len > 1) {
    out_write_str(",$");
    out_write_hex(result[1]);

    if (command_len > 2) {
      out_write_str(",$");
      out_write_hex(result[2]);
    }
  }
}

void convert_channel2(uint8_t pattern_number, uint8_t step_number, uint8_t note_index,
                      uint8_t samplenum, uint8_t effectnum, uint8_t effectparams) {
  uint8_t result[3] = {0, 0, 0};
  int command_len = 1; // NOP

  uint8_t instrument = samplenum & 3;

  if (note_index > (6 * 12 - 1)) {
    if ((effectnum != 0) || (effectparams != 0)) {
      // Volume or others?
      if (effectnum == 0xC) {
        // Volume
        result[0] = BIT(5) | volume_mod_to_gb(effectparams);
        command_len = 1;
      } else {
        // Others
        uint8_t converted_num, converted_params;
        if (effect_mod_to_gb(pattern_number, step_number, 2, effectnum,
                             effectparams, &converted_num,
                             &converted_params) == 1) {
          result[0] = BIT(6) | (instrument << 4) | converted_num;
          result[1] = converted_params;
          command_len = 2;
        } else {
          if (effectnum != 0) {
            printf("Invalid command at pattern %d, step %d, channel"
                   " 2: %01X%02X\n",
                   pattern_number, step_number, effectnum, effectparams);
          }

          // NOP
          result[0] = 0;
          command_len = 1;
        }
      }
    } else {
      // NOP
      result[0] = 0;
      command_len = 1;
    }
  } else {
    uint8_t converted_num, converted_params;
    if (effectnum == 0xC) {
      // Note + Volume
      result[0] = BIT(7) | note_index;
      result[1] = (instrument << 4) | volume_mod_to_gb(effectparams);
      command_len = 2;
    } else {
      if (effect_mod_to_gb(pattern_number, step_number, 2, effectnum,
                           effectparams, &converted_num,
                           &converted_params) == 1) {
        // Note + Effect
        result[0] = BIT(7) | note_index;
        result[1] = BIT(7) | (instrument << 4) | converted_num;
        result[2] = converted_params;
        command_len = 3;
      } else {
        printf("Invalid command at pattern %d, step %d, channel 2: "
               "%01X%02X\n",
               pattern_number, step_number, effectnum, effectparams);

        if (effectnum == 0)
          printf("Volume must be set when using a new note.\n");
      }
    }
  }

  out_write_str("$");
  out_write_hex(result[0]);

  if (command_len > 1) {
    out_write_str(",$");
    out_write_hex(result[1]);

    if (command_len > 2) {
      out_write_str(",$");
      out_write_hex(result[2]);
    }
  }
}

void convert_channel3(uint8_t pattern_number, uint8_t step_number, uint8_t note_index,
                      uint8_t samplenum, uint8_t effectnum, uint8_t effectparams) {
  uint8_t result[3] = {0, 0, 0};
  int command_len = 1; // NOP

  if (note_index > (6 * 12 - 1)) {
    if ((effectnum != 0) || (effectparams != 0)) {
      // Volume or others?
      if (effectnum == 0xC) {
        // Volume
        result[0] = BIT(5) | volume_mod_to_gb_ch3(effectparams);
        command_len = 1;
      } else {
        // Others
        uint8_t converted_num, converted_params;
        if (effect_mod_to_gb(pattern_number, step_number, 3, effectnum,
                             effectparams, &converted_num,
                             &converted_params) == 1) {
          result[0] = BIT(6) | converted_num;
          result[1] = converted_params;
          command_len = 2;
        } else {
          if (effectnum != 0) {
            printf("Invalid command at pattern %d, step %d, channel"
                   " 3: %01X%02X\n",
                   pattern_number, step_number, effectnum, effectparams);
          }

          // NOP
          result[0] = 0;
          command_len = 1;
        }
      }
    } else {
      // NOP
      result[0] = 0;
      command_len = 1;
    }
  } else {
    uint8_t instrument = (samplenum - 8) & 15; // Only 0-7 implemented

    uint8_t converted_num, converted_params;
    if (effectnum == 0xC) {
      // Note + Volume
      result[0] = BIT(7) | note_index;
      result[1] = (volume_mod_to_gb_ch3(effectparams) << 4) | instrument;
      command_len = 2;
    } else {
      if (effect_mod_to_gb(pattern_number, step_number, 3, effectnum,
                           effectparams, &converted_num,
                           &converted_params) == 1) {
        if (converted_num > 7) {
          printf("Invalid command at pattern %d, step %d, channel 3: "
                 "%01X%02X\nOnly 0-7 allowed in this mode.\n",
                 pattern_number, step_number, effectnum, effectparams);
        } else {
          // Note + Effect
          result[0] = BIT(7) | note_index;
          result[1] = BIT(7) | (converted_num << 4) | instrument;
          result[2] = converted_params;
          command_len = 3;
        }
      } else {
        printf("Invalid command at pattern %d, step %d, channel 3: "
               "%01X%02X\n",
               pattern_number, step_number, effectnum, effectparams);

        if (effectnum == 0)
          printf("Volume must be set when using a note.\n");
      }
    }
  }

  out_write_str("$");
  out_write_hex(result[0]);

  if (command_len > 1) {
    out_write_str(",$");
    out_write_hex(result[1]);

    if (command_len > 2) {
      out_write_str(",$");
      out_write_hex(result[2]);
    }
  }
}

void convert_channel4(uint8_t pattern_number, uint8_t step_number, uint8_t note_index,
                      uint8_t samplenum, uint8_t effectnum, uint8_t effectparams) {
  uint8_t result[3] = {0, 0, 0};
  int command_len = 1; // NOP

  if (note_index > (6 * 12 - 1)) {
    if ((effectnum != 0) || (effectparams != 0)) {
      // Volume or others?
      if (effectnum == 0xC) {
        // Volume
        result[0] = BIT(5) | volume_mod_to_gb(effectparams);
        command_len = 1;
      } else {
        // Others
        uint8_t converted_num, converted_params;
        if (effect_mod_to_gb(pattern_number, step_number, 4, effectnum,
                             effectparams, &converted_num,
                             &converted_params) == 1) {
          result[0] = BIT(6) | converted_num;
          result[1] = converted_params;
          command_len = 2;
        } else {
          if (effectnum != 0) {
            printf("Invalid command at pattern %d, step %d, channel"
                   " 4: %01X%02X\n",
                   pattern_number, step_number, effectnum, effectparams);
          }

          // NOP
          result[0] = 0;
          command_len = 1;
        }
      }
    } else {
      // NOP
      result[0] = 0;
      command_len = 1;
    }
  } else {
    uint8_t instrument = (samplenum - 16) & 0x1F; // Only 0 - 0xF implemented

    uint8_t converted_num, converted_params;
    if (effectnum == 0xC) {
      // Note + Volume
      result[0] = BIT(7) | instrument;
      result[1] = volume_mod_to_gb(effectparams);
      command_len = 2;
    } else {
      if (effect_mod_to_gb(pattern_number, step_number, 4, effectnum,
                           effectparams, &converted_num,
                           &converted_params) == 1) {
        // Note + Effect
        result[0] = BIT(7) | instrument;
        result[1] = BIT(7) | converted_num;
        result[2] = converted_params;
        command_len = 3;
      } else // Note + No effect!! -> We need at least volume change!
      {
        printf("Invalid command at pattern %d, step %d, channel 4: "
               "%01X%02X\n",
               pattern_number, step_number, effectnum, effectparams);

        if (effectnum == 0)
          printf("Volume must be set when using a new note.\n");
      }
    }
  }

  out_write_str("$");
  out_write_hex(result[0]);

  if (command_len > 1) {
    out_write_str(",$");
    out_write_hex(result[1]);

    if (command_len > 2) {
      out_write_str(",$");
      out_write_hex(result[2]);
    }
  }
}

void convert_pattern(_pattern_t *pattern, uint8_t number) {
  out_write_str("    SECTION \"");
  out_write_str(label_name);
  out_write_str("_");
  out_write_dec(number);
  out_write_str("\", ROMX\n");

  out_write_str(label_name);
  out_write_str("_");
  out_write_dec(number);
  out_write_str(":\n");

  int step;
  for (step = 0; step < 64; step++) {
    out_write_str("    DB  ");

    uint8_t data[4]; // Packed data

    uint8_t samplenum; // Unpacked data
    uint16_t sampleperiod;
    uint8_t effectnum, effectparams;

    uint8_t note_index;

    // Channel 1
    memcpy(data, pattern->info[step][0], 4);
    unpack_info(data, &samplenum, &sampleperiod, &effectnum, &effectparams);
    note_index = mod_get_index_from_period(sampleperiod, number, step, 1);
    convert_channel1(number, step, note_index, samplenum, effectnum,
                     effectparams);
    out_write_str(", ");

    // Channel 2
    memcpy(data, pattern->info[step][1], 4);
    unpack_info(data, &samplenum, &sampleperiod, &effectnum, &effectparams);
    note_index = mod_get_index_from_period(sampleperiod, number, step, 2);
    convert_channel2(number, step, note_index, samplenum, effectnum,
                     effectparams);
    out_write_str(", ");

    // Channel 3
    memcpy(data, pattern->info[step][2], 4);
    unpack_info(data, &samplenum, &sampleperiod, &effectnum, &effectparams);
    note_index = mod_get_index_from_period(sampleperiod, number, step, 3);
    convert_channel3(number, step, note_index, samplenum, effectnum,
                     effectparams);
    out_write_str(", ");

    // Channel 4
    memcpy(data, pattern->info[step][3], 4);
    unpack_info(data, &samplenum, &sampleperiod, &effectnum, &effectparams);
    note_index = mod_get_index_from_period(sampleperiod, number, step, 4);
    convert_channel4(number, step, note_index, samplenum, effectnum,
                     effectparams);

    out_write_str("\n");
  }

  out_write_str("\n");
}

void print_usage(void) {
  printf("Usage: mod2gbt modfile.mod outfile.asm song_name [-speed] "
         "[-512-banks]\n\n");
  printf("       -speed      Don't convert speed from 50 Hz to 60 Hz.\n");
  printf("       -512-banks  Prepare for a ROM with more than 256 banks.\n");
  printf("\n\n");
}

int main(int argc, char *argv[]) {
  int more_than_256_banks = 0;

  int i;
  if ((argc < 4) || (argc > 6)) {
    print_usage();
    return -1;
  }

  char *outfile = argv[2];
  strncpy(label_name, argv[3], sizeof(label_name));

  for (i = 4; i < argc; i++) {
    if (strcmp(argv[i], "-speed") == 0) {
      perform_speed_convertion = 0;
      printf("Disabled speed convertion.\n\n");
    } else if (strcmp(argv[i], "-512-banks") == 0) {
      more_than_256_banks = 1;
      printf("Output for a ROM with more than 256 banks.\n\n");
    } else {
      print_usage();
      return -1;
    }
  }

  mod_file_t *modfile = load_file(argv[1]);

  if (modfile == NULL)
    return -2;

  if (strncmp(modfile->identifier, "M.K.", 4) != 0) {
    printf("ERROR: Not a valid mod file.\n"
           "Only 4 channel mod files with 31 samples allowed.\n");
    return -3;
  }

  uint8_t num_patterns = 0;

  for (i = 0; i < 128; i++)
    if (modfile->pattern_table[i] > num_patterns)
      num_patterns = modfile->pattern_table[i];

  num_patterns++;

  out_open(outfile);

  out_write_str("\n; File created by mod2gbt\n\n");

  for (i = 0; i < num_patterns; i++)
    convert_pattern(&(modfile->pattern[i]), i);

  out_write_str("  SECTION \"");
  out_write_str(label_name);
  out_write_str("_data\", ROMX\n");

  out_write_str(label_name);
  out_write_str("_data::\n");

  if (more_than_256_banks) {
    for (i = 0; i < modfile->song_length; i++) {
      out_write_str("    DW  BANK(");
      out_write_str(label_name);
      out_write_str("_");
      out_write_dec(modfile->pattern_table[i]);
      out_write_str("), ");
      out_write_str(label_name);
      out_write_str("_");
      out_write_dec(modfile->pattern_table[i]);
      out_write_str("\n");
    }
    out_write_str("    DW  $0000, $0000\n\n");
  } else {
    for (i = 0; i < modfile->song_length; i++) {
      out_write_str("    DB  BANK(");
      out_write_str(label_name);
      out_write_str("_");
      out_write_dec(modfile->pattern_table[i]);
      out_write_str(")\n    DW  ");
      out_write_str(label_name);
      out_write_str("_");
      out_write_dec(modfile->pattern_table[i]);
      out_write_str("\n");
    }
    out_write_str("    DB  $00\n    DW  $0000\n\n");
  }

  out_close();

  return 0;
}
