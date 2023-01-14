#include "deadbeef.h"

// Structs we pass to C need to be defined in C header file, to get same padding and layout

typedef struct {
    DB_fileinfo_t info;
    int frequency;

    float m_phase;
    DB_FILE *file;

} toneFileInfo;
