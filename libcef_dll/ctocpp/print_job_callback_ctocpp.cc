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
// $hash=938750132f616560b31ea791768868c61db1eb30$
//

#include "libcef_dll/ctocpp/print_job_callback_ctocpp.h"

#include "libcef_dll/shutdown_checker.h"

// VIRTUAL METHODS - Body may be edited by hand.

NO_SANITIZE("cfi-icall") void CefPrintJobCallbackCToCpp::Continue() {
  shutdown_checker::AssertNotShutdown();

  auto* _struct = GetStruct();
  if (!_struct->cont) {
    return;
  }

  // AUTO-GENERATED CONTENT - DELETE THIS COMMENT BEFORE MODIFYING

  // Execute
  _struct->cont(_struct);
}

// CONSTRUCTOR - Do not edit by hand.

CefPrintJobCallbackCToCpp::CefPrintJobCallbackCToCpp() {}

// DESTRUCTOR - Do not edit by hand.

CefPrintJobCallbackCToCpp::~CefPrintJobCallbackCToCpp() {
  shutdown_checker::AssertNotShutdown();
}

template <>
cef_print_job_callback_t* CefCToCppRefCounted<
    CefPrintJobCallbackCToCpp,
    CefPrintJobCallback,
    cef_print_job_callback_t>::UnwrapDerived(CefWrapperType type,
                                             CefPrintJobCallback* c) {
  CHECK(false) << __func__ << " called with unexpected class type " << type;
  return nullptr;
}

template <>
CefWrapperType CefCToCppRefCounted<CefPrintJobCallbackCToCpp,
                                   CefPrintJobCallback,
                                   cef_print_job_callback_t>::kWrapperType =
    WT_PRINT_JOB_CALLBACK;
