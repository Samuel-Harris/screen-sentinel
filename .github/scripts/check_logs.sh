#!/bin/bash
tail -n 100 screen_sentinel_output.log
if grep -q "panic" screen_sentinel_output.log; then
  echo "CLI crashed"
  exit 1
fi
if ! grep -q "Server listening on 0.0.0.0:3130" screen_sentinel_output.log; then
  echo "Server did not start correctly"
  exit 1
fi
if grep -q "No windows found" screen_sentinel_output.log; then
  echo "No windows were detected"
  exit 1
fi
if grep -q "tesseract not found" screen_sentinel_output.log; then
  echo "Tesseract OCR not found"
  exit 1
fi
echo "CLI ran successfully without crashing"
