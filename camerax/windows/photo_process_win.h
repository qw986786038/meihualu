#ifndef CAMERAX_PHOTO_PROCESS_WIN_H_
#define CAMERAX_PHOTO_PROCESS_WIN_H_

#include <string>

namespace camerax {

/// UTF-8 paths. Returns true on success.
bool ProcessCaptureImageWin(const std::string& input_utf8,
                            const std::string& output_utf8,
                            double aspect_ratio,
                            int quality);

}  // namespace camerax

#endif  // CAMERAX_PHOTO_PROCESS_WIN_H_
