#include "include/camerax/camerax_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gtk/gtk.h>
#include <math.h>
#include <stdio.h>
#include <sys/utsname.h>

#include <cstring>

#include "camerax_plugin_private.h"

static FlMethodResponse* process_capture_image(FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(
        fl_method_error_response_new("bad_args", "expected map", nullptr));
  }
  FlValue* in_v = fl_value_lookup_string(args, "inputPath");
  FlValue* out_v = fl_value_lookup_string(args, "outputPath");
  FlValue* ar_v = fl_value_lookup_string(args, "aspectRatio");
  if (!in_v || !out_v || !ar_v) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "bad_args", "inputPath, outputPath, aspectRatio", nullptr));
  }
  if (fl_value_get_type(in_v) != FL_VALUE_TYPE_STRING ||
      fl_value_get_type(out_v) != FL_VALUE_TYPE_STRING) {
    return FL_METHOD_RESPONSE(
        fl_method_error_response_new("bad_args", "path strings", nullptr));
  }
  const gchar* input = fl_value_get_string(in_v);
  const gchar* output = fl_value_get_string(out_v);
  double aspect = 0.0;
  if (fl_value_get_type(ar_v) == FL_VALUE_TYPE_FLOAT) {
    aspect = fl_value_get_float(ar_v);
  } else if (fl_value_get_type(ar_v) == FL_VALUE_TYPE_INT) {
    aspect = static_cast<double>(fl_value_get_int(ar_v));
  } else {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "bad_args", "aspectRatio number", nullptr));
  }
  gint64 quality = 95;
  FlValue* q_v = fl_value_lookup_string(args, "quality");
  if (q_v && fl_value_get_type(q_v) == FL_VALUE_TYPE_INT) {
    quality = fl_value_get_int(q_v);
  }
  if (quality < 1) {
    quality = 1;
  }
  if (quality > 100) {
    quality = 100;
  }

  GError* err = nullptr;
  GdkPixbuf* pb = gdk_pixbuf_new_from_file(input, &err);
  if (!pb) {
    g_autoptr(FlValue) ev =
        fl_value_new_string(err && err->message ? err->message : "load");
    if (err) {
      g_error_free(err);
    }
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "process_failed", "gdk_pixbuf_new_from_file", ev));
  }

  int w = gdk_pixbuf_get_width(pb);
  int h = gdk_pixbuf_get_height(pb);
  double sa = static_cast<double>(w) / static_cast<double>(h);
  GdkPixbuf* work = nullptr;
  if (fabs(sa - aspect) < 0.01) {
    work = GDK_PIXBUF(g_object_ref(pb));
  } else {
    int crop_w = w;
    int crop_h = h;
    if (sa > aspect) {
      crop_w = static_cast<int>(static_cast<double>(h) * aspect + 0.5);
    } else {
      crop_h = static_cast<int>(static_cast<double>(w) / aspect + 0.5);
    }
    if (crop_w < 1) {
      crop_w = 1;
    }
    if (crop_h < 1) {
      crop_h = 1;
    }
    if (crop_w > w) {
      crop_w = w;
    }
    if (crop_h > h) {
      crop_h = h;
    }
    int left = (w - crop_w) / 2;
    int top = (h - crop_h) / 2;
    work = gdk_pixbuf_new_subpixbuf(pb, left, top, crop_w, crop_h);
  }
  g_object_unref(pb);
  if (!work) {
    return FL_METHOD_RESPONSE(
        fl_method_error_response_new("process_failed", "subpixbuf", nullptr));
  }

  char qbuf[16];
  snprintf(qbuf, sizeof qbuf, "%d", static_cast<int>(quality));
  gboolean save_ok = gdk_pixbuf_save(work, output, "jpeg", &err, "quality",
                                     qbuf, nullptr);
  g_object_unref(work);
  if (!save_ok) {
    g_autoptr(FlValue) ev =
        fl_value_new_string(err && err->message ? err->message : "save");
    if (err) {
      g_error_free(err);
    }
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "process_failed", "gdk_pixbuf_save", ev));
  }
  if (err) {
    g_error_free(err);
  }
  g_autoptr(FlValue) val = fl_value_new_bool(TRUE);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(val));
}

#define CAMERAX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), camerax_plugin_get_type(), \
                              CameraxPlugin))

struct _CameraxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(CameraxPlugin, camerax_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void camerax_plugin_handle_method_call(
    CameraxPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else if (strcmp(method, "processCaptureImage") == 0) {
    response = process_capture_image(method_call);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void camerax_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(camerax_plugin_parent_class)->dispose(object);
}

static void camerax_plugin_class_init(CameraxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = camerax_plugin_dispose;
}

static void camerax_plugin_init(CameraxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  CameraxPlugin* plugin = CAMERAX_PLUGIN(user_data);
  camerax_plugin_handle_method_call(plugin, method_call);
}

void camerax_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  CameraxPlugin* plugin = CAMERAX_PLUGIN(
      g_object_new(camerax_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "camerax",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
