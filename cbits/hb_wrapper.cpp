#include "hb.h"

#ifdef HAVE_FREETYPE
#include "hb-ft.h"
#endif

extern "C" unsigned int hbw_build_probe(void);

unsigned int hbw_build_probe(void)
{
  hb_buffer_t *buffer = hb_buffer_create();
  if (!buffer)
    return 0;

  hb_buffer_destroy(buffer);
  return HB_VERSION_MAJOR * 10000u + HB_VERSION_MINOR * 100u + HB_VERSION_MICRO;
}
