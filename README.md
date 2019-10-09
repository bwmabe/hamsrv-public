# hamsrv
Repository for CS431

TODO:
 * Implement reading of request headers
   * They can be read, nothing reads them yet
 * Finish empty page dir listing
 * ~~Test error pages~~
   * Add function to supply them on error
 * Respect keep-alive and close
   * **STOP SENDING 'Connection: close' ALL THE TIME**
   * In-progress
 * ~~Finish web-root~~
 * ~~Supply E-Tag and modified on HEAD~~
 * Re-read tests to find more items
   * ~~Quote E-Tags~~
 * create date comparison function
   * More importantly, create date regex and checks
   * Ask about dates to accept in "If-Modified-Since"
   * I think they're in RFC 7230/7231
