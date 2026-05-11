#include "photo_process_win.h"

#include <cmath>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <vector>

#include <windows.h>
#include <objidl.h>
#include <gdiplus.h>

#pragma comment(lib, "Gdiplus.lib")
#pragma comment(lib, "Ole32.lib")

namespace camerax {

namespace {

ULONG_PTR g_gdiplus_token = 0;
bool g_gdiplus_started = false;

void EnsureGdiplus() {
  if (g_gdiplus_started) {
    return;
  }
  Gdiplus::GdiplusStartupInput input;
  if (Gdiplus::GdiplusStartup(&g_gdiplus_token, &input, nullptr) == Gdiplus::Ok) {
    g_gdiplus_started = true;
  }
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) {
    return L"";
  }
  int n =
      MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  if (n <= 0) {
    return L"";
  }
  std::wstring w(static_cast<size_t>(n), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, &w[0], n);
  if (!w.empty() && w.back() == L'\0') {
    w.pop_back();
  }
  return w;
}

int GetEncoderClsid(const WCHAR* mime, CLSID* clsid) {
  UINT count = 0;
  UINT size = 0;
  Gdiplus::GetImageEncodersSize(&count, &size);
  if (size == 0) {
    return -1;
  }
  std::vector<BYTE> buffer(size);
  auto* codecs = reinterpret_cast<Gdiplus::ImageCodecInfo*>(buffer.data());
  if (Gdiplus::GetImageEncoders(count, size, codecs) != Gdiplus::Ok) {
    return -1;
  }
  for (UINT j = 0; j < count; ++j) {
    if (wcscmp(codecs[j].MimeType, mime) == 0) {
      *clsid = codecs[j].Clsid;
      return static_cast<int>(j);
    }
  }
  return -1;
}

void ApplyExifOrientation(Gdiplus::Bitmap* bmp) {
  UINT psz = bmp->GetPropertyItemSize(Gdiplus::PropertyTagOrientation);
  if (psz == 0) {
    return;
  }
  Gdiplus::PropertyItem* item =
      reinterpret_cast<Gdiplus::PropertyItem*>(malloc(psz));
  if (!item) {
    return;
  }
  if (bmp->GetPropertyItem(Gdiplus::PropertyTagOrientation, psz, item) !=
      Gdiplus::Ok) {
    free(item);
    return;
  }
  if (item->length < 1) {
    free(item);
    return;
  }
  BYTE orient = reinterpret_cast<BYTE*>(item->value)[0];
  free(item);
  Gdiplus::RotateFlipType op = Gdiplus::RotateNoneFlipNone;
  switch (orient) {
    case 1:
      return;
    case 2:
      op = Gdiplus::RotateNoneFlipX;
      break;
    case 3:
      op = Gdiplus::Rotate180FlipNone;
      break;
    case 4:
      op = Gdiplus::Rotate180FlipX;
      break;
    case 5:
      op = Gdiplus::Rotate90FlipX;
      break;
    case 6:
      op = Gdiplus::Rotate90FlipNone;
      break;
    case 7:
      op = Gdiplus::Rotate270FlipX;
      break;
    case 8:
      op = Gdiplus::Rotate270FlipNone;
      break;
    default:
      return;
  }
  bmp->RotateFlip(op);
}

bool SaveJpeg(Gdiplus::Bitmap* bmp,
              const std::wstring& path,
              ULONG quality_1_100) {
  CLSID clsid{};
  if (GetEncoderClsid(L"image/jpeg", &clsid) < 0) {
    return false;
  }
  ULONG q = quality_1_100;
  if (q < 1) {
    q = 1;
  }
  if (q > 100) {
    q = 100;
  }
  Gdiplus::EncoderParameters params{};
  params.Count = 1;
  params.Parameter[0].Guid = Gdiplus::EncoderQuality;
  params.Parameter[0].Type = Gdiplus::EncoderParameterValueTypeLong;
  params.Parameter[0].NumberOfValues = 1;
  params.Parameter[0].Value = &q;
  return bmp->Save(path.c_str(), &clsid, &params) == Gdiplus::Ok;
}

}  // namespace

bool ProcessCaptureImageWin(const std::string& input_utf8,
                            const std::string& output_utf8,
                            double aspect_ratio,
                            int quality) {
  if (!(aspect_ratio > 0.0) || std::isnan(aspect_ratio)) {
    return false;
  }
  EnsureGdiplus();
  if (!g_gdiplus_started) {
    return false;
  }

  std::wstring in_path = Utf8ToWide(input_utf8);
  std::wstring out_path = Utf8ToWide(output_utf8);
  if (in_path.empty() || out_path.empty()) {
    return false;
  }

  std::unique_ptr<Gdiplus::Bitmap> bmp(
      Gdiplus::Bitmap::FromFile(in_path.c_str(), FALSE));
  if (!bmp || bmp->GetLastStatus() != Gdiplus::Ok) {
    return false;
  }

  ApplyExifOrientation(bmp.get());

  const UINT wi = bmp->GetWidth();
  const UINT hi = bmp->GetHeight();
  if (wi == 0 || hi == 0) {
    return false;
  }

  const double w = static_cast<double>(wi);
  const double h = static_cast<double>(hi);
  const double source_aspect = w / h;
  ULONG qul = static_cast<ULONG>(quality);
  if (qul < 1) {
    qul = 1;
  }
  if (qul > 100) {
    qul = 100;
  }

  if (std::abs(source_aspect - aspect_ratio) < 0.01) {
    return SaveJpeg(bmp.get(), out_path, qul);
  }

  int crop_w = static_cast<int>(wi);
  int crop_h = static_cast<int>(hi);
  if (source_aspect > aspect_ratio) {
    crop_w = static_cast<int>(std::lround(h * aspect_ratio));
  } else {
    crop_h = static_cast<int>(std::lround(w / aspect_ratio));
  }
  crop_w = (std::max)(1, (std::min)(crop_w, static_cast<int>(wi)));
  crop_h = (std::max)(1, (std::min)(crop_h, static_cast<int>(hi)));
  const int left = (static_cast<int>(wi) - crop_w) / 2;
  const int top = (static_cast<int>(hi) - crop_h) / 2;

  std::unique_ptr<Gdiplus::Bitmap> out(
      new Gdiplus::Bitmap(crop_w, crop_h, PixelFormat32bppARGB));
  if (!out || out->GetLastStatus() != Gdiplus::Ok) {
    return false;
  }
  Gdiplus::Graphics g(out.get());
  if (g.GetLastStatus() != Gdiplus::Ok) {
    return false;
  }
  g.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
  g.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHighQuality);
  g.DrawImage(bmp.get(), Gdiplus::Rect(0, 0, crop_w, crop_h), left, top, crop_w,
              crop_h, Gdiplus::UnitPixel);

  return SaveJpeg(out.get(), out_path, qul);
}

}  // namespace camerax
