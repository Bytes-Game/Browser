// Copyright (c) 2025 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.
//
// ---------------------------------------------------------------------------
//
// This file was generated by the CEF translator tool. If making changes by
// hand only do so within the body of existing method and function
// implementations. See the translator.README.txt file in the tools directory
// for more information.
//
// $hash=c8f63523b3f7d6d1321d0b2617d22d12e9163e92$
//

#include "libcef_dll/cpptoc/drag_handler_cpptoc.h"

#include "libcef_dll/ctocpp/browser_ctocpp.h"
#include "libcef_dll/ctocpp/drag_data_ctocpp.h"
#include "libcef_dll/ctocpp/frame_ctocpp.h"
#include "libcef_dll/shutdown_checker.h"

namespace {

// MEMBER FUNCTIONS - Body may be edited by hand.

int CEF_CALLBACK drag_handler_on_drag_enter(struct _cef_drag_handler_t* self,
                                            struct _cef_browser_t* browser,
                                            struct _cef_drag_data_t* dragData,
                                            cef_drag_operations_mask_t mask) {
  shutdown_checker::AssertNotShutdown();

  // AUTO-GENERATED CONTENT - DELETE THIS COMMENT BEFORE MODIFYING

  DCHECK(self);
  if (!self) {
    return 0;
  }
  // Verify param: browser; type: refptr_diff
  DCHECK(browser);
  if (!browser) {
    return 0;
  }
  // Verify param: dragData; type: refptr_diff
  DCHECK(dragData);
  if (!dragData) {
    return 0;
  }

  // Execute
  bool _retval = CefDragHandlerCppToC::Get(self)->OnDragEnter(
      CefBrowserCToCpp_Wrap(browser), CefDragDataCToCpp_Wrap(dragData), mask);

  // Return type: bool
  return _retval;
}

void CEF_CALLBACK drag_handler_on_draggable_regions_changed(
    struct _cef_drag_handler_t* self,
    struct _cef_browser_t* browser,
    struct _cef_frame_t* frame,
    size_t regionsCount,
    cef_draggable_region_t const* regions) {
  shutdown_checker::AssertNotShutdown();

  // AUTO-GENERATED CONTENT - DELETE THIS COMMENT BEFORE MODIFYING

  DCHECK(self);
  if (!self) {
    return;
  }
  // Verify param: browser; type: refptr_diff
  DCHECK(browser);
  if (!browser) {
    return;
  }
  // Verify param: frame; type: refptr_diff
  DCHECK(frame);
  if (!frame) {
    return;
  }
  // Verify param: regions; type: simple_vec_byref_const
  DCHECK(regionsCount == 0 || regions);
  if (regionsCount > 0 && !regions) {
    return;
  }

  // Translate param: regions; type: simple_vec_byref_const
  std::vector<CefDraggableRegion> regionsList;
  if (regionsCount > 0) {
    for (size_t i = 0; i < regionsCount; ++i) {
      CefDraggableRegion regionsVal = regions[i];
      regionsList.push_back(regionsVal);
    }
  }

  // Execute
  CefDragHandlerCppToC::Get(self)->OnDraggableRegionsChanged(
      CefBrowserCToCpp_Wrap(browser), CefFrameCToCpp_Wrap(frame), regionsList);
}

}  // namespace

// CONSTRUCTOR - Do not edit by hand.

CefDragHandlerCppToC::CefDragHandlerCppToC() {
  GetStruct()->on_drag_enter = drag_handler_on_drag_enter;
  GetStruct()->on_draggable_regions_changed =
      drag_handler_on_draggable_regions_changed;
}

// DESTRUCTOR - Do not edit by hand.

CefDragHandlerCppToC::~CefDragHandlerCppToC() {
  shutdown_checker::AssertNotShutdown();
}

template <>
CefRefPtr<CefDragHandler>
CefCppToCRefCounted<CefDragHandlerCppToC, CefDragHandler, cef_drag_handler_t>::
    UnwrapDerived(CefWrapperType type, cef_drag_handler_t* s) {
  CHECK(false) << __func__ << " called with unexpected class type " << type;
  return nullptr;
}

template <>
CefWrapperType CefCppToCRefCounted<CefDragHandlerCppToC,
                                   CefDragHandler,
                                   cef_drag_handler_t>::kWrapperType =
    WT_DRAG_HANDLER;
